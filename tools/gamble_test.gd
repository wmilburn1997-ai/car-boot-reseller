extends SceneTree
# Exercises the 0.14 gambles: vault, taped-up boxes, back room, scratch card.
var fails = 0
func check(c, msg):
	if not c:
		fails += 1
		print("FAIL: ", msg)

func _initialize():
	var g = load("res://main.gd").new()
	g.sim_mode = true
	g.rng.seed = 21
	g.init_new_run()
	g.cash = 20000.0
	g.premises_level = 3
	# --- vault
	check(not g.gamble.has_vault(), "no vault at start")
	g.gamble.buy_vault()
	check(g.gamble.vault_slots() == 6, "safe has 6 slots")
	for i in range(5):
		var it = g.generate_item("Collector")
		g.inventory.append(it)
	var used0 = g.inventory_space_used()
	var v0 = g.market_value(g.inventory[0])
	g.gamble.put_in_vault(0)
	check(g.inventory[0].get("vaulted", false), "vaulted")
	check(g.inventory_space_used() < used0, "vault frees storage")
	g.create_listing(0, 50.0)
	check(not g.inventory[0]["listed"], "can't list a vaulted item")
	var ups = 0
	var total = 0
	for w in range(60):
		g.night_events = []
		g.inventory[0]["vault_mult"] = 1.0
		g.gamble.vault_week()
		total += 1
		if float(g.inventory[0]["vault_mult"]) > 1.0:
			ups += 1
	print("vault: up %d/%d weeks" % [ups, total])
	check(ups > 12 and ups < 40, "vault odds plausible")
	g.inventory[0]["vault_mult"] = 1.25
	check(abs(g.market_value(g.inventory[0]) / v0 - 1.25) < 0.01, "vault mult applies to value")
	g.gamble.take_out(0)
	check(not g.inventory[0].get("vaulted", false), "taken out")
	print("upkeep ", g.running_costs()["vault"], " asset ", g.gamble.vault_asset_value())
	# --- box EV
	g.new_day() if g.has_method("new_day") else null
	var spent = 0.0
	var got = 0.0
	var n = 0
	for i in range(400):
		var stall = g.stalls[0] if g.stalls.size() > 0 else null
		if stall == null:
			break
		g.current_stall_index = 0
		stall["box"] = {"cat": stall["stock"][0]["category"], "price": 15.0, "hint": "x", "bought": false}
		var before = g.inventory.size()
		g.cash = 20000.0
		g.gamble.buy_box()
		for j in range(before, g.inventory.size()):
			got += g.true_market_value(g.inventory[j])
		spent += 15.0
		n += 1
		while g.inventory.size() > 5:
			g.inventory.pop_back()
	print("box: %d boxes, value/price %.2f" % [n, got / max(1.0, spent)])
	check(n > 0 and got / spent > 0.9 and got / spent < 2.0, "box EV in range")
	# --- back room
	g.day = 13
	g.current_time_minutes = 8 * 60
	check(g.gamble.hr_today(), "back room on day 13")
	var it2 = g.generate_item("Collector")
	g.gamble.retarget(it2, 200.0)
	it2["basic_researched"] = true
	it2["basic_comps"] = g.make_comps(it2, false)
	g.inventory.append(it2)
	var cands = g.gamble.stake_candidates()
	check(cands.size() > 0, "stake candidates")
	print("pot %s, stake %s, chance %.2f" % [g.gamble.pot_value(), g.gamble.stake_value(it2), g.gamble.stake_chance(it2)])
	var inv_before = g.inventory.size()
	g.gamble.stake(cands[0])
	check(g.gamble.hr_played(), "played this week")
	check(g.inventory.size() != inv_before, "stake resolved (won adds 3, lost removes 1)")
	# --- scratch
	var s = {"day": 13, "stats": {"sale_profit": 300.0}, "end_cash": g.cash}
	check(g.gamble.scratch_available(s), "scratch available")
	var c0 = g.cash
	var paid = 0.0
	var won = 0.0
	for i in range(3000):
		g.world.st()["scratch_day"] = -1
		var cb = g.cash
		g.gamble.scratch(s)
		paid += 15.0
		won += g.cash - cb + 15.0
	print("scratch return %.3f" % (won / paid))
	check(won / paid > 0.8 and won / paid < 1.1, "scratch EV just under 1")
	print("GAMBLE TESTS: %d failures" % fails)
	g.free()
	quit()
