extends RefCounted
# 0.14 "High Stakes": the Vault, taped-up boxes at stalls, the Fixer's back room,
# and the scratch card on the night report. Every one of them is a visible roll.
#
# State lives in main.w2 (via g.world.st()) so it saves with everything else.

var g

func _init(main):
	g = main

func st():
	return g.world.st()

func retarget(item, value):
	# Set what an item is really worth (before its traits), the way mystery boxes do.
	item["rarity"] = "Common"
	item["one_in"] = 1
	item["hidden_special"] = ""
	item["special_premium"] = 1.0
	var tp = 1.0
	for t in item.get("traits", []):
		tp *= float(t["mult"])
	item["true_value"] = max(1.0, float(value) / g.condition_factor(int(item["condition"])) * tp)

func item_in_cat(seller, cat, small_only = false):
	var it = null
	for i in range(10):
		it = g.generate_item(seller, {"cats": [cat]})
		if it["category"] == cat and (not small_only or str(it["size"]) != "large"):
			return it
	return it

# =============================================================================
# The Vault
# =============================================================================
const VAULT = [
	{"name": "Floor Safe", "slots": 6, "cost": 1200, "upkeep": 2.0, "desc": "A safe bolted into the shop floor. Six pieces, out of the damp and out of sight."},
	{"name": "Strongroom", "slots": 12, "cost": 3500, "upkeep": 5.0, "desc": "A proper room with a proper door. Insurers stop sighing at you."},
	{"name": "Bank Vault", "slots": 24, "cost": 8000, "upkeep": 10.0, "desc": "A box at the bank, a hushed corridor, and a man called Clive who calls you sir."},
]
# The weekly market move for anything in the vault: [name, cumulative, colour, effect].
const VAULT_MOVES = {"Collector frenzy": 1.60, "Climbing": 1.25, "Up": 1.10, "Flat": 1.0, "Slipped": 0.85}

func vault_level():
	return int(st().get("vault_level", 0))

func has_vault():
	return vault_level() > 0

func vault_allowed():
	return g.premises_level >= 3

func vault_slots():
	return int(VAULT[vault_level() - 1]["slots"]) if has_vault() else 0

func vault_upkeep():
	return float(VAULT[vault_level() - 1]["upkeep"]) if has_vault() else 0.0

func vault_asset_value():
	var v = 0.0
	for i in range(vault_level()):
		v += float(VAULT[i]["cost"]) * 0.6
	return v

func vaulted():
	var out = []
	for it in g.inventory:
		if it.get("vaulted", false):
			out.append(it)
	return out

func vault_used():
	return vaulted().size()

func buy_vault():
	if not vault_allowed():
		g.queue_popup("A vault needs a High Street Shop or bigger.")
		return
	if vault_level() >= VAULT.size():
		return
	var nxt = VAULT[vault_level()]
	if g.cash < float(nxt["cost"]):
		g.queue_popup("You need %s for the %s." % [g.fmt_money(nxt["cost"]), nxt["name"]])
		return
	g.cash -= float(nxt["cost"])
	g.day_stats["business_spend"] = float(g.day_stats.get("business_spend", 0.0)) + float(nxt["cost"])
	st()["vault_level"] = vault_level() + 1
	g.add_journal("Put in %s." % g.a_an(nxt["name"].to_lower()), "level")
	g.show_big_popup(nxt["name"].to_upper(), "%s\n\n%d pieces. Every week the market moves on what's inside: you'll see the roll." % [nxt["desc"], int(nxt["slots"])], "level")
	g.play_sfx("level")
	g.save_game()
	g.show_business()

func vault_bands(it):
	# Odds for one piece's weekly move. The trend, a collection, and rarity all tilt it.
	var trend = float(g.current_trends.get(it["category"], 1.0))
	var same = 0
	for v in vaulted():
		if v["category"] == it["category"]:
			same += 1
	var shift = clamp((trend - 1.0) * 0.6, -0.12, 0.12) + 0.015 * float(clamp(same - 1, 0, 4))
	var rar = {"Uncommon": 0.01, "Rare": 0.02, "Very Rare": 0.035, "Grail": 0.05}.get(str(it.get("rarity", "Common")), 0.0)
	shift += rar
	var f = clamp(0.03 + shift * 0.3, 0.01, 0.12)
	var c = clamp(f + 0.11 + shift * 0.3, f + 0.03, 0.40)
	var u = clamp(c + 0.26 + shift * 0.4, c + 0.05, 0.75)
	var fl = clamp(u + 0.33, u + 0.05, 0.92)
	return [["Collector frenzy", f, "purple", "+60% on this piece"], ["Climbing", c, "gold", "+25%"], ["Up", u, "green", "+10%"], ["Flat", fl, "blue", "no change"]]

func vault_odds_text(it):
	var b = vault_bands(it)
	var lo = 0.0
	var parts = []
	for x in b:
		parts.append("%s%% %s" % [g.luck.pct_text(float(x[1]) - lo), str(x[3]).replace(" on this piece", "")])
		lo = float(x[1])
	parts.append("%s%% −15%%" % g.luck.pct_text(1.0 - lo))
	return " · ".join(parts)

func vault_collection_note(it):
	var same = 0
	for v in vaulted():
		if v["category"] == it["category"]:
			same += 1
	if same >= 2:
		return "Collection of %d %s pieces: better odds for each." % [same, it["category"]]
	return ""

func put_in_vault(index):
	if index < 0 or index >= g.inventory.size():
		return
	var it = g.inventory[index]
	if not has_vault():
		return
	if vault_used() >= vault_slots():
		g.queue_popup("The vault's full (%d pieces)." % vault_slots())
		return
	if it["listed"] or it["auctioned"] or it.get("on_shop_floor", false) or it.get("consigned", false):
		g.queue_popup("Take it off sale first.")
		return
	if it["auth_status"] == "Confirmed Counterfeit":
		g.queue_popup("Nobody vaults a known fake.")
		return
	it["vaulted"] = true
	it["vault_day"] = g.day
	if not it.has("vault_mult"):
		it["vault_mult"] = 1.0
	g.hist(it, "Put in the vault.")
	g.add_toast("%s is in the vault. The market moves on it every week." % it["name"], "success")
	g.play_sfx("confirm")
	g.save_game()
	g.refresh_after("inv")

func take_out(index):
	if index < 0 or index >= g.inventory.size():
		return
	var it = g.inventory[index]
	if not it.get("vaulted", false):
		return
	if g.inventory_space_used() + g.size_units(it) > g.storage_capacity():
		g.queue_popup("No room in your stock for it (storage %d/%d)." % [g.inventory_space_used(), g.storage_capacity()])
		return
	it["vaulted"] = false
	var pct = int(round((float(it.get("vault_mult", 1.0)) - 1.0) * 100.0))
	g.hist(it, "Taken out of the vault (%s%d%% while inside)." % ["+" if pct >= 0 else "", pct])
	g.save_game()
	g.refresh_after("inv")

func vault_week():
	# Once a week: the market moves on everything in the vault.
	var items = vaulted()
	if items.size() == 0:
		return
	var entries = []
	var ups = 0
	var downs = 0
	var lines = []
	for it in items:
		var bands = vault_bands(it)
		var hit_upto = float(bands[bands.size() - 1][1])
		var r = g.luck.roll("vault", hit_upto, "Vault: %s" % it["name"])
		g.luck.tier_bands(r, bands, "slipped: −15%")
		r["label"] = it["name"].left(12)
		entries.append(r)
		var move = "Slipped" if not r["hit"] else str(r["band"])
		var m = float(VAULT_MOVES.get(move, 1.0))
		it["vault_mult"] = clamp(float(it.get("vault_mult", 1.0)) * m, 0.4, 4.0)
		if m > 1.0:
			ups += 1
		elif m < 1.0:
			downs += 1
		if m != 1.0:
			lines.append("%s %s%d%%" % [it["name"], "+" if m > 1.0 else "", int(round((m - 1.0) * 100.0))])
			g.hist(it, "Vault week: %s (%s%d%%)." % [move.to_lower(), "+" if m > 1.0 else "", int(round((m - 1.0) * 100.0))])
		if move == "Collector frenzy":
			g.add_journal("Collector frenzy on your %s: +60%% in the vault." % g.lc(it["name"]), "good")
	var text = "%d up, %d down." % [ups, downs] + ((" " + ", ".join(lines.slice(0, 4)) + ".") if lines.size() > 0 else " A quiet week.")
	g.night_events.append({"kind": "info", "text": "The vault: the market moved", "sub": text})
	g.show_roll("THE VAULT · WEEKLY MOVE", entries, text)

# =============================================================================
# Taped-up boxes at stalls
# =============================================================================
const BOX_HINTS = ["Heavy, and it rattles.", "Light. Something wrapped in newspaper.", "Clinks when you tilt it.", "Taped up three times. Someone cared.", "Smells of loft.", "\"Haven't looked in it. Honest.\"", "Feels like books. Or bricks.", "Soft, and something hard in the middle."]
const BOX_TIERS = {"Treasure": [3.0, 6.0], "Good": [1.5, 2.2], "Fair": [0.8, 1.4], "Junk": [0.25, 0.6]}

func maybe_add_box(stall):
	if g.rng.randf() > 0.22:
		return
	var cats = []
	for it in stall["stock"]:
		cats.append(it["category"])
	if cats.size() == 0:
		return
	var cat = cats[g.rng.randi_range(0, cats.size() - 1)]
	var price = round(clamp(8.0 + float(g.day) * 0.12, 8.0, 30.0) * g.rng.randf_range(0.8, 1.3))
	stall["box"] = {"cat": cat, "price": price, "hint": BOX_HINTS[g.rng.randi_range(0, BOX_HINTS.size() - 1)], "bought": false}

func box_bands(stall):
	var b = stall["box"]
	var tier = float(g.expertise_tier(b["cat"]))
	var seller_bonus = {"Clueless Seller": 0.02, "House Clearance": 0.02, "Desperate Seller": 0.01, "Dealer": -0.02, "Collector": -0.01}.get(str(stall["seller"]), 0.0)
	var t = clamp(0.04 + 0.01 * tier + seller_bonus * 0.5, 0.02, 0.12)
	var gd = clamp(t + 0.16 + 0.03 * tier + seller_bonus, t + 0.05, 0.5)
	var fr = clamp(gd + 0.40, gd + 0.1, 0.85)
	return [["Treasure", t, "purple", "worth 3–6× what you paid"], ["Good", gd, "gold", "worth 1.5–2.2×"], ["Fair", fr, "green", "worth about what you paid"]]

func box_odds_text(stall):
	var b = box_bands(stall)
	var lo = 0.0
	var parts = []
	for x in b:
		parts.append("%s %s%%" % [x[0], g.luck.pct_text(float(x[1]) - lo)])
		lo = float(x[1])
	parts.append("Junk %s%%" % g.luck.pct_text(1.0 - lo))
	return " · ".join(parts)

func buy_box():
	if g.current_stall_index < 0 or g.current_stall_index >= g.stalls.size():
		return
	var stall = g.stalls[g.current_stall_index]
	if not stall.has("box") or stall["box"].get("bought", false):
		return
	var box = stall["box"]
	var price = float(box["price"])
	if g.cash < price:
		g.queue_popup("Not enough cash.")
		return
	if g.carry_used + 3 > int(g.effective_bag_capacity()):
		g.queue_popup("You need 3 carry space free for a box (%d/%d)." % [g.carry_used, g.effective_bag_capacity()])
		return
	if g.inventory_space_used() + 3 > g.storage_capacity():
		g.queue_popup("You need 3 storage space free for whatever's inside.")
		return
	box["bought"] = true
	g.cash -= price
	g.day_stats["buy_spend"] += price
	g.spend_time(3)
	var bands = box_bands(stall)
	var r = g.luck.roll("box", float(bands[bands.size() - 1][1]), "Taped-up box (%s)" % box["cat"])
	g.luck.tier_bands(r, bands, "junk: worth well under what you paid")
	r["label"] = "What's inside?"
	var tier = str(r["band"]) if r["hit"] else "Junk"
	var rng_v = BOX_TIERS[tier]
	var total = price * g.rng.randf_range(float(rng_v[0]), float(rng_v[1]))
	var n = 1 if tier == "Treasure" else g.rng.randi_range(1, 3)
	var names = []
	var cap_left = int(g.effective_bag_capacity()) - g.carry_used
	for i in range(n):
		var it = item_in_cat(stall["seller"], box["cat"], true)
		if g.size_units(it) > cap_left:
			continue
		cap_left -= g.size_units(it)
		var share = total / float(n) * g.rng.randf_range(0.85, 1.15)
		if tier == "Treasure":
			share = total
		retarget(it, share)
		it["paid"] = price / float(n)
		it["asking"] = it["paid"]
		it["source"] = "box"
		it["bought_from"] = stall.get("seller_full_name", stall["seller_display_name"])
		it["bought_day"] = g.day
		it["carried_day"] = g.day
		it["story"] = "Came out of a taped-up box on %s's stall." % stall["seller_display_name"]
		g.hist(it, "Found in a taped-up box (%s) bought for %s." % [tier.to_lower(), g.fmt_money(price)])
		g.inventory.append(it)
		g.register_collection(it)
		g.day_stats["items_bought"] += 1
		names.append(it["name"])
	var text = "%s: %s. Check them over at home." % [tier, ", ".join(names) if names.size() > 0 else "nothing you'd keep"]
	g.show_roll("TAPED-UP BOX", [r], text)
	if tier == "Treasure":
		g.add_journal("A taped-up box on %s's stall held treasure: %s." % [stall["seller_display_name"], ", ".join(names)], "good")
	g.play_sfx("buy")
	g.save_game()
	g.show_stall()

# =============================================================================
# The back room: the Fixer's weekly high-roller game
# =============================================================================
const HR_DEALERS = ["Lenny 'Two Vans'", "Mags from the antiques centre", "a quiet man in a camel coat", "Deano", "the Hendersons", "Big Sue"]

func hr_today():
	return g.day % 7 == 6 and g.current_time_minutes < 12 * 60

func hr_week():
	return int((g.day - 1) / 7)

func hr_played():
	return int(st().get("hr_week_played", -1)) == hr_week()

func hr_pot():
	# Three dealers' stakes, set once for the week.
	var d = st()
	if int(d.get("hr_pot_week", -1)) != hr_week():
		var target = clamp(g.business_value() * 0.05, 150.0, 2500.0)
		var pot = []
		var used = {}
		for i in range(3):
			var it = g.generate_item(["Collector", "Dealer", "Regular Seller"][i])
			retarget(it, target / 3.0 * g.rng.randf_range(0.7, 1.3))
			var who = HR_DEALERS[g.rng.randi_range(0, HR_DEALERS.size() - 1)]
			var tries = 0
			while used.has(who) and tries < 6:
				who = HR_DEALERS[g.rng.randi_range(0, HR_DEALERS.size() - 1)]
				tries += 1
			used[who] = true
			it["hr_dealer"] = who
			pot.append(it)
		d["hr_pot"] = pot
		d["hr_pot_week"] = hr_week()
	return d["hr_pot"]

func pot_value():
	var v = 0.0
	for it in hr_pot():
		v += round(g.true_market_value(it))
	return v

func pot_space():
	var n = 0
	for it in hr_pot():
		n += g.size_units(it)
	return n

func stake_value(it):
	# The table goes on what the sold prices say (you must have researched it).
	return round(g.perceived_center(it))

func stake_chance(it):
	var v = stake_value(it)
	return clamp(v / (v + pot_value()) * 0.9, 0.05, 0.7)

func stake_candidates():
	var out = []
	for i in range(g.inventory.size()):
		var it = g.inventory[i]
		if it["listed"] or it["auctioned"] or it.get("on_shop_floor", false) or it.get("consigned", false) or it.get("vaulted", false):
			continue
		if not it["basic_researched"] or it["auth_status"] == "Confirmed Counterfeit":
			continue
		if stake_value(it) < 40.0:
			continue
		out.append(i)
	out.sort_custom(func(a, b): return stake_value(g.inventory[a]) > stake_value(g.inventory[b]))
	return out.slice(0, 6)

func stake(index):
	if not hr_today() or hr_played():
		return
	if index < 0 or index >= g.inventory.size() or not stake_candidates().has(index):
		return
	var it = g.inventory[index]
	if g.inventory_space_used() - g.size_units(it) + pot_space() > g.storage_capacity():
		g.queue_popup("You'd need room for the whole pot if you win (%d space)." % pot_space())
		return
	st()["hr_week_played"] = hr_week()
	g.spend_time(15)
	var ch = stake_chance(it)
	var pv = pot_value()
	var r = g.luck.roll("backroom", ch, "Back room: staked the %s" % g.lc(it["name"]))
	r["label"] = "Your %s against the pot" % g.lc(it["name"])
	g.luck.tier_bands(r, [["Take the pot", ch, "gold", "the lot is yours, about %s" % g.fmt_money(pv)]], "you lose the %s" % g.lc(it["name"]))
	var text = ""
	if r["hit"]:
		var names = []
		for p in hr_pot():
			p["paid"] = 0.0
			p["asking"] = 0.0
			p["source"] = "backroom"
			p["bought_day"] = g.day
			p["story"] = "Won off %s in the Fixer's back room." % str(p.get("hr_dealer", "a dealer"))
			g.hist(p, "Won in the back room, against %s." % str(p.get("hr_dealer", "a dealer")))
			g.inventory.append(p)
			g.register_collection(p)
			names.append(p["name"])
		st()["hr_pot"] = []
		g.hist(it, "Staked in the back room, and kept.")
		text = "You take the pot: %s. And you keep your %s." % [", ".join(names), g.lc(it["name"])]
		g.add_journal("Took the pot in the Fixer's back room: %s." % ", ".join(names), "good")
		g.play_sfx("rare")
	else:
		g.hist(it, "Lost in the Fixer's back room.")
		g.inventory.remove_at(index)
		text = "The house takes it. Your %s is gone." % g.lc(it["name"])
		g.add_journal("Lost a %s in the Fixer's back room." % g.lc(it["name"]), "bad")
		g.play_sfx("fail")
	st()["hr_won" if r["hit"] else "hr_lost"] = int(st().get("hr_won" if r["hit"] else "hr_lost", 0)) + 1
	g.show_roll("THE BACK ROOM", [r], text)
	g.save_game()
	g.show_market()

# =============================================================================
# The scratch card on the night report
# =============================================================================
const SCRATCH = [["Jackpot", 0.01, "purple", "20× your stake"], ["Big win", 0.05, "gold", "5×"], ["Win", 0.20, "green", "2×"], ["Money back", 0.45, "blue", "your stake back"]]
const SCRATCH_PAY = {"Jackpot": 20.0, "Big win": 5.0, "Win": 2.0, "Money back": 1.0}

func scratch_price(profit):
	return clamp(round(float(profit) * 0.05), 2.0, 100.0)

func scratch_available(s):
	return float(s["stats"].get("sale_profit", 0.0)) >= 40.0 and int(st().get("scratch_day", -1)) != int(s["day"])

func scratch(s):
	if not scratch_available(s):
		return
	var price = scratch_price(s["stats"].get("sale_profit", 0.0))
	if g.cash < price:
		g.queue_popup("Not enough cash.")
		return
	st()["scratch_day"] = int(s["day"])
	g.cash -= price
	var r = g.luck.roll("scratch", float(SCRATCH[SCRATCH.size() - 1][1]), "Scratch card (%s)" % g.fmt_money(price))
	g.luck.tier_bands(r, SCRATCH, "nothing: better luck tomorrow")
	r["label"] = "Scratch card, %s" % g.fmt_money(price)
	var win = price * float(SCRATCH_PAY.get(str(r["band"]), 0.0)) if r["hit"] else 0.0
	g.cash += win
	s["end_cash"] = g.cash
	var text = ("%s! %s." % [r["band"], g.fmt_money(win)]) if win > price else (("Money back.") if win > 0.0 else "Nothing. It's only a bit of foil.")
	if str(r["band"]) == "Jackpot":
		g.add_journal("Scratch card jackpot: %s." % g.fmt_money(win), "good")
	g.show_roll("SCRATCH CARD", [r], text)
	g.save_game()
	if g.ui != null and not g.sim_mode:
		g.ui.show_day_summary(s)
