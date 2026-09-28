extends SceneTree
# Headless bot playtests that drive the real game code.
# Usage: godot --headless --path . --script tools/sim.gd -- <strategy> <runs> <days> [seed]
# Prints one JSON summary line per run, then an aggregate line.

var g
var strategy = "careful"

func _initialize():
	var args = OS.get_cmdline_user_args()
	strategy = args[0] if args.size() > 0 else "careful"
	var runs = int(args[1]) if args.size() > 1 else 20
	var days = int(args[2]) if args.size() > 2 else 40
	var seed_base = int(args[3]) if args.size() > 3 else 1000
	var finals = []
	var bankrupt = 0
	var errors = 0
	for r in range(runs):
		var res = run_one(seed_base + r, days)
		finals.append(res)
		if res["bankrupt_day"] > 0:
			bankrupt += 1
		print(JSON.stringify(res))
	var nw = []
	for f in finals:
		nw.append(f["net_worth"])
	nw.sort()
	var mean = 0.0
	for v in nw:
		mean += v
	mean /= max(1, nw.size())
	print("AGG " + JSON.stringify({"strategy": strategy, "runs": runs, "days": days, "bankrupt": bankrupt, "median_net_worth": nw[nw.size() / 2], "mean_net_worth": mean, "p10": nw[int(nw.size() * 0.1)], "p90": nw[int(nw.size() * 0.9)]}))
	quit()

func new_game(seed):
	if g != null:
		g.free()
	g = load("res://main.gd").new()
	g.sim_mode = true
	g.rng.seed = seed
	seed(seed)
	# minimal UI stubs so functions that touch labels don't crash
	g.status_label = Label.new()
	g.footer_label = Label.new()
	g.init_new_run()

func comps_median(item):
	var v = item.get("comps_values", [])
	if v.size() == 0:
		return 0.0
	return float(v[v.size() / 2])

func est_net(item, gross):
	var costs = g.selling_costs(item, gross)
	return gross - costs["fee"] - costs["postage"] - costs["insurance"] - costs["packaging"]

func run_one(seed, days):
	new_game(seed)
	var curve = []
	var bankrupt_day = 0
	var bought = 0
	for d in range(days):
		play_market()
		play_home()
		var before_day = g.day
		g.end_day()
		if g.game_over:
			bankrupt_day = before_day
			break
		spend_upgrades()
		curve.append(int(g.cash + g.inventory_book_value()))
	var returns = 0
	return {"seed": seed, "strategy": strategy, "day": g.day, "cash": snapped(g.cash, 0.01), "stock": g.inventory.size(),
		"net_worth": snapped(g.cash + g.inventory_book_value(), 0.01), "bankrupt_day": bankrupt_day,
		"sold": g.sold_history.size(), "level": g.player_level, "profit": snapped(g.total_lifetime_profit, 0.01),
		"rating": snapped(g.seller_rating, 0.1), "upgrades": [g.bag_level, g.storage_level, g.toolbox_level, g.eye_level, g.fee_level],
		"curve": curve}

func play_market():
	var reserve_energy = 38
	for s in range(g.stalls.size()):
		if g.current_time_minutes >= 12 * 60 - 10 or g.energy < reserve_energy:
			return
		var stall = g.stalls[s]
		if g.current_time_minutes >= int(stall["packing_minute"]) or stall.get("banned_today", false):
			continue
		if s != g.current_stall_index:
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
		# No research: buys whatever looks cheap vs a rough idea of what that kind of thing costs.
		var fam_mid = 0.0
		for f in g.item_families:
			if f["name"] == item["name"]:
				fam_mid = (float(f["value"][0]) + float(f["value"][1])) / 2.0
		if not item["quick_look_done"] and g.energy > 45:
			g.quick_look(i)
		if item.get("perceived_condition", 6) <= 3:
			return
		if asking < fam_mid * 0.6 and g.rng.randf() < 0.7:
			g.buy_item(i)
		return
	# careful / quickseller / researcher / greedy: research first
	if not item["basic_researched"]:
		if g.energy < 4:
			return
		g.current_stall_index = g.stalls.find(stall)
		g.prebuy_research(i)
	var med = comps_median(item)
	if med <= 0.0:
		return
	if strategy == "casual":
		if med > asking * 1.2:
			g.buy_item(i)
		return
	if strategy == "casual_fee":
		if est_net(item, med) > asking * 1.2 and est_net(item, med) - asking > 3.0:
			g.buy_item(i)
		return
	var expected_net = est_net(item, med * 0.95)
	if expected_net < asking * 1.45 or expected_net - asking < 6.0:
		return
	# Worth a closer look: check condition on anything non-trivial
	if asking >= 15.0 and not item["condition_checked"] and g.cash > 40 and g.energy > 45:
		g.check_condition(i)
		if item["condition"] <= 4:
			return
		if (not item["testable"]) and item["fault"] and item["fault_severity"] in ["Major", "Dead"]:
			return
	# haggle once, gently
	if not item["haggle_attempted"]:
		var offer = round(asking * 0.85)
		if g.compute_haggle_chance(item, stall["seller"], offer) >= 0.6 and asking >= 8:
			var le = LineEdit.new()
			le.text = str(int(offer))
			g.haggle_item(i, le)
			le.free()
			if item["haggle_result"] == "refused" or stall.get("banned_today", false):
				return
	g.buy_item(i)

func play_home():
	for idx in range(g.inventory.size() - 1, -1, -1):
		if idx >= g.inventory.size():
			continue
		var item = g.inventory[idx]
		if item["listed"] or item["auctioned"]:
			continue
		if item["testable"] and not item["tested"]:
			if g.cash >= 2 and g.energy >= 5:
				g.test_item(idx)
			else:
				continue
		if strategy == "researcher" and not item["deep_researched"] and float(item["paid"]) >= 25 and g.energy >= 12 and g.cash > 80:
			g.deep_research(idx)
		if item["auth_status"] == "Unauthenticated" and float(item["fake_chance"]) >= 0.08 and float(item["paid"]) >= 30 and strategy != "reckless" and g.cash > 60 and g.energy >= 6:
			g.authenticate_item(idx)
		if item["auth_status"] == "Confirmed Counterfeit":
			g.scrap_item(idx)
			continue
		if strategy == "quickseller":
			g.quick_sell_item(idx)
			continue
		var pot = g.estimate_identified_potential(item)
		var price = round((pot[0] + pot[1]) / 2.0 * (1.0 if strategy != "careful" else 1.02))
		if strategy == "greedy":
			price = round(float(pot[1]) * 1.6)
		if item["fault"] and g.fault_is_known(item) and g.toolbox_level > 0 and not item["repair_attempted"] and g.energy >= 10 and g.cash > 30:
			g.repair_item(idx)
			pot = g.estimate_identified_potential(item)
			price = round((pot[0] + pot[1]) / 2.0)
		if g.player_level >= 6 and (item["rarity"] != "Common" or float(g.current_trends.get(item["category"], 1.0)) >= 1.10):
			g.start_auction(idx)
			continue
		if g.cash < 25 and float(item["paid"]) < 15:
			g.quick_sell_item(idx)
			continue
		var le = LineEdit.new()
		le.text = str(int(price))
		g.create_listing(idx, le)
		le.free()
	# Stale stock: drop price on anything listed for 4+ days
	for idx in range(g.inventory.size() - 1, -1, -1):
		var item = g.inventory[idx]
		if item["listed"] and strategy != "greedy" and g.day - int(item.get("listed_day", g.day)) >= 4:
			var newp = round(float(item["listing"]) * 0.85)
			g.unlist_item(idx)
			var le = LineEdit.new()
			le.text = str(int(max(1, newp)))
			g.create_listing(idx, le)
			le.free()

func spend_upgrades():
	if strategy == "reckless":
		return
	# Sensible upgrade path: storage when near full, eye, bag, fees
	var cash = g.cash
	var used = g.inventory_space_used()
	var cap = int(g.storage_upgrades[g.storage_level]["capacity"])
	if used > cap * 0.7 and g.storage_level < g.storage_upgrades.size() - 1 and cash > float(g.storage_upgrades[g.storage_level + 1]["cost"]) * 2.5:
		g.buy_upgrade("storage")
		return
	if g.bag_level < g.bag_upgrades.size() - 1 and cash > float(g.bag_upgrades[g.bag_level + 1]["cost"]) * 3.0:
		g.buy_upgrade("bag")
		return
	if g.fee_level < g.fee_upgrades.size() - 1 and cash > float(g.fee_upgrades[g.fee_level + 1]["cost"]) * 3.0:
		g.buy_upgrade("fee")
		return
	if g.toolbox_level < 1 and cash > 400:
		g.buy_upgrade("toolbox")
