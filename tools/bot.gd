extends RefCounted
# A scriptable player used by tools/sim.gd (headless) and tools/midgame.gd (real UI).
var g
var strategy = "careful"
var focus = []
var stats = {"clearances": 0}

func _init(game, strat):
	g = game
	strategy = strat
	var cats = g.CATEGORIES.duplicate()
	cats.shuffle()
	focus = [cats[0], cats[1]]

func play_day():
	if not try_clearance():
		play_market()
	play_home()

func est_net(item, gross):
	var costs = g.selling_costs(item, gross)
	return gross - costs["fee"] - costs["postage"] - costs["insurance"] - costs["packaging"]

func try_clearance():
	if strategy in ["naive", "reckless", "gambler", "greedy"]:
		return false
	if not g.can_do_clearances() or g.clearance_leads.size() == 0:
		return false
	var lead = g.clearance_leads[0]
	g.start_clearance(lead["id"])
	if g.clearance == null:
		return false
	for r in range(g.clearance["rooms"].size()):
		if g.energy >= 30:
			g.clearance_look(r)
	var est = 0.0
	for it in g.clearance["items"]:
		var c = g.perceived_center(it)
		est += est_net(it, c)
	var price = float(g.clearance["price"])
	if est > price * 1.5 and g.cash > price + 80 and g.inventory_space_used() + g.clearance_space_needed() <= g.storage_capacity():
		g.accept_clearance()
		stats["clearances"] += 1
	else:
		g.walk_away_clearance()
	return true

func play_market():
	var reserve_energy = 38
	var order = range(g.stalls.size())
	for s in order:
		if g.current_time_minutes >= 12 * 60 - 10 or g.energy < reserve_energy:
			return
		var stall = g.stalls[s]
		if g.current_time_minutes >= int(stall["packing_minute"]) or stall.get("banned_today", false):
			continue
		if s != g.current_stall_index or not stall.get("visited", false):
			g.go_to_stall(s)
		var digs = 0
		while true:
			var i = 0
			while i < int(stall["revealed"]):
				var before = stall["stock"].size()
				consider_item(stall, i)
				if stall["stock"].size() < before:
					continue
				i += 1
				if g.energy < reserve_energy or g.current_time_minutes >= int(stall["packing_minute"]):
					break
			if g.pending_special_offer != null:
				consider_offer()
			if digs < 1 and g.energy > 55 and int(stall["revealed"]) < stall["stock"].size():
				g.browse_stall()
				digs += 1
			else:
				break
	if g.mystery_packages_left > 0 and strategy == "gambler" and g.cash > 60:
		g.buy_mystery_package()

func consider_offer():
	var item = g.pending_special_offer["item"]
	if strategy == "reckless" and g.cash > item["asking"] * 1.5:
		g.accept_special_offer()
	else:
		g.decline_special_offer()

func consider_item(stall, i):
	var item = stall["stock"][i]
	if item["dismissed"] or item.get("seller_refuses", false):
		return
	var asking = float(item["asking"])
	if asking > g.cash * 0.6:
		return
	if not g.can_carry(item) or not g.can_store(item):
		return
	if strategy == "reckless":
		if g.rng.randf() < 0.35:
			g.buy_item(i)
		return
	if strategy == "gambler":
		if g.rng.randf() < 0.25:
			g.buy_item(i)
		return
	if strategy == "naive":
		var fam = g.content.family(item["name"])
		var fam_mid = (float(fam["value"][0]) + float(fam["value"][1])) / 2.0
		if not item["quick_look_done"] and g.energy > 45:
			g.quick_look(i)
		if item.get("perceived_condition", 6) <= 3:
			return
		if asking < fam_mid * 0.6 and g.rng.randf() < 0.7:
			g.buy_item(i)
		return
	var in_focus = focus.has(item["category"])
	if strategy == "specialist" and not in_focus and g.rng.randf() < 0.6:
		return
	if not item["quick_look_done"] and g.energy > 45:
		g.quick_look(i)
	if g.can_specialist_check(item) and g.energy > 45:
		g.specialist_check("stall", i)
	if not item["basic_researched"]:
		if g.energy < 4:
			return
		g.prebuy_research(i)
	var med = g.perceived_center(item) if not item["basic_researched"] else comps_median(item)
	if med <= 0.0:
		return
	if strategy == "casual_fee":
		if est_net(item, med) > asking * 1.2 and est_net(item, med) - asking > 3.0:
			g.buy_item(i)
		return
	var margin = 1.45 if strategy != "specialist" else 1.35
	var expected_net = est_net(item, max(med * 0.95, g.perceived_center(item) * 0.95))
	if expected_net < asking * margin or expected_net - asking < 6.0:
		return
	if asking >= 15.0 and not item["condition_checked"] and g.cash > 40 and g.energy > 45:
		g.check_condition(i)
		if item["condition"] <= 4:
			return
		if (not item["testable"]) and item["fault"] and item["fault_severity"] in ["Major", "Dead"]:
			return
		expected_net = est_net(item, g.perceived_center(item) * 0.95)
		if expected_net < asking * (margin - 0.1):
			return
	if asking >= 8 and g.haggle_open(item, stall):
		for f in g.item_flaws(item):
			g.point_out_flaw(i, f[0])
		var pct = 0.65 if strategy == "haggler" else 0.8
		var offer = max(round(float(item["asking"]) * pct), g.haggle_insult_below(item, stall) + 1.0)
		for round_i in range(3 if strategy == "haggler" else 2):
			if not g.haggle_open(item, stall):
				break
			g.haggle_item(i, offer)
			if item["haggle_result"] == "refused" or stall.get("banned_today", false):
				return
			offer = round((offer + float(item["asking"])) * 0.5)
	g.buy_item(i)

func comps_median(item):
	var v = item.get("comps_values", [])
	if v.size() == 0:
		return 0.0
	return float(v[v.size() / 2])

func play_home():
	for idx in range(g.inventory.size() - 1, -1, -1):
		if idx >= g.inventory.size():
			continue
		var item = g.inventory[idx]
		if item["listed"] or item["auctioned"] or item.get("on_shop_floor", false):
			continue
		if g.is_unsorted_lot(item) and g.energy >= 6 and strategy != "naive":
			g.sort_lot(idx)
			item = g.inventory[idx]
		if item["testable"] and not item["tested"]:
			if g.cash >= g.test_cost() and g.energy >= g.test_energy():
				g.test_item(idx)
			else:
				continue
		if g.can_clean(item) and g.energy >= 4 and g.cash > 20:
			g.clean_item(idx)
		if g.has_equip("parts") and g.known_fixable(item, "parts").size() > 0 and g.cash > 20 and g.energy >= 3:
			g.parts_fix(idx)
		if g.can_specialist_check(item) and g.energy >= 3:
			g.specialist_check("inv", idx)
		if (strategy == "researcher" or (strategy in ["specialist", "tycoon"] and focus.has(item["category"]))) and not item["deep_researched"] and float(item["paid"]) >= 20 and g.energy >= 12 and g.cash > 80:
			g.deep_research(idx)
		if item["auth_status"] == "Unauthenticated" and float(item["fake_chance"]) >= 0.08 and float(item["paid"]) >= 30 and strategy != "reckless" and g.cash > 60 and g.energy >= 6:
			g.authenticate_item(idx)
		if item["auth_status"] == "Confirmed Counterfeit":
			g.scrap_item(idx)
			continue
		if g.can_repair(item) and g.energy >= 10 and g.cash > 30:
			g.repair_item(idx)
		if g.collector_contact_available(item) and g.collector_offer_for(item) > g.perceived_center(item) * 0.85:
			g.sell_to_collector(idx)
			continue
		var price = g.suggested_price(item) * (1.02 if strategy == "careful" else 1.0)
		if strategy == "greedy":
			price = round(float(g.estimate_identified_potential(item)[1]) * 1.6)
		if g.auctions_unlocked() and (item["rarity"] != "Common" or float(g.current_trends.get(item["category"], 1.0)) >= 1.10):
			if g.active_listing_count() < g.listing_cap():
				g.start_auction(idx)
				continue
		if g.shop_floor_enabled() and g.shop_floor_count() < g.shop_floor_cap():
			g.put_on_shop_floor(idx, price)
			continue
		if g.cash < 25 and float(item["paid"]) < 15:
			g.quick_sell_item(idx)
			continue
		if g.active_listing_count() >= g.listing_cap():
			if strategy == "hoarder":
				continue
			if g.estimated_profit_at(item, price) < 0 or float(item.get("days_owned", 0)) > 10:
				g.quick_sell_item(idx)
			continue
		g.create_listing(idx, price)
	# Stale stock: drop the price on anything listed for 4+ days
	for idx in range(g.inventory.size() - 1, -1, -1):
		var item = g.inventory[idx]
		if item["listed"] and strategy != "greedy" and g.day - int(item.get("listed_day", g.day)) >= 4:
			var newp = round(float(item["listing"]) * 0.85)
			g.unlist_item(idx)
			g.create_listing(idx, max(1, newp))

func spend_upgrades():
	if strategy in ["reckless", "naive", "gambler"]:
		return
	var cash = g.cash
	var reserve = 150.0 if strategy != "tycoon" else 100.0
	var used = g.inventory_space_used()
	var cap = g.storage_capacity()
	var Biz = g.Biz
	# vehicle: trolley early, estate/van later
	if g.vehicle_level < Biz.VEHICLES.size() - 1:
		var nv = Biz.VEHICLES[g.vehicle_level + 1]
		var mult = 2.0 if g.vehicle_level == 0 else 2.5
		if strategy == "tycoon":
			mult = 1.3
		if cash - float(nv["cost"]) > reserve and cash > float(nv["cost"]) * mult:
			g.buy_vehicle()
			return
	if (used > cap * 0.7 or (strategy == "tycoon" and g.vehicle_level >= 3)) and g.can_buy_premises():
		var np = Biz.PREMISES[g.premises_level + 1]
		if cash > float(np["cost"]) * (2.0 if strategy != "tycoon" else 1.3):
			g.buy_premises()
			return
	if used > cap * 0.75 and g.equip_level("shelving") < 2 and g.workshop_slots_used() < g.workshop_slots() or (g.equip_level("shelving") == 1 and used > cap * 0.8):
		var c = g.equipment_next_cost("shelving")
		if c > 0 and cash > c * 2.5:
			g.buy_equipment("shelving")
			return
	for id in ["cleaning", "photo", "repair", "parts", "test_rig", "library", "packing", "auth"]:
		if g.workshop_slots_used() >= g.workshop_slots() and g.equip_level(id) == 0:
			continue
		var c = g.equipment_next_cost(id)
		if c > 0 and cash > c * 3.0 + reserve:
			g.buy_equipment(id)
			return
	if g.fee_level < Biz.ACCOUNTS.size() - 1 and g.account_requirements_met(g.fee_level + 1):
		var na = Biz.ACCOUNTS[g.fee_level + 1]
		if cash > float(na["cost"]) * 3.0:
			g.buy_account()
			return
	if g.skill_points_available() > 0:
		for id in ["keen_eye", "good_photos", "trade_contacts", "quick_study", "silver_tongue", "hunch", "frugal", "auctioneer", "early_bird", "thick_skin", "polymath"]:
			var p = g.perk_def(id)
			if not g.has_perk(id) and g.skill_points_available() >= int(p["cost"]) and (p["requires"] == "" or g.has_perk(p["requires"])):
				g.buy_perk(id)
				break
