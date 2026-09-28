extends SceneTree
# Save/load round-trip + legacy save migration checks, driving the real UI scene.
var fails = 0
func check(cond, msg):
	if not cond:
		fails += 1
		print("FAIL: ", msg)
	else:
		print("ok: ", msg)

func _initialize():
	_run()

func _run():
	var a = load("res://Main.tscn").instantiate()
	get_root().add_child(a)
	await process_frame
	a.start_new_game()
	a.tutorial_seen = true
	a.prebuy_research(0)
	a.buy_item(0)
	a.browse_stall()
	a.go_to_stall(2)
	a.save_game()
	var snap = {"cash": a.cash, "energy": a.energy, "time": a.current_time_minutes, "inv": a.inventory.size(), "stall": a.current_stall_index, "revealed": a.stalls[2]["revealed"], "stock0": a.stalls[0]["stock"].size(), "trend": a.current_trends.duplicate(), "challenges": a.daily_challenges.size()}
	a.queue_free()
	await process_frame
	var b = load("res://Main.tscn").instantiate()
	get_root().add_child(b)
	await process_frame
	check(b.has_save, "save detected on launch")
	check(abs(b.cash - snap["cash"]) < 0.01, "cash restored %.2f vs %.2f" % [b.cash, snap["cash"]])
	check(b.energy == snap["energy"], "energy restored (no free refill) %d" % b.energy)
	check(b.current_time_minutes == snap["time"], "clock restored")
	check(b.inventory.size() == snap["inv"], "inventory restored")
	check(b.current_stall_index == snap["stall"], "current stall restored")
	check(int(b.stalls[2]["revealed"]) == int(snap["revealed"]), "stall reveal state restored")
	check(b.stalls[0]["stock"].size() == snap["stock0"], "stall stock not re-rolled")
	check(b.daily_challenges.size() == snap["challenges"], "challenges not re-rolled")
	var same_trend = true
	for k in snap["trend"].keys():
		if abs(float(b.current_trends.get(k, 0)) - float(snap["trend"][k])) > 0.0001:
			same_trend = false
	check(same_trend, "trends not re-rolled")
	b.on_title_screen = false
	b.show_inventory()
	b.show_stall()
	await process_frame
	# Legacy save from the v0.9 web build era: old keys only, Pokemon category, no auction fields
	var legacy = {"cash": 512.5, "day": 9, "player_level": 3, "player_xp": 40,
		"inventory": [{"name": "Pokemon Card Tin", "category": "Pokemon", "condition": 7.0, "condition_checked": true, "size": "small", "testable": false, "true_value": 60.0, "asking": 20.0, "paid": 20.0, "authentic": true, "auth_status": "Unauthenticated", "fake_chance": 0.07, "fault": false, "fault_severity": "None", "rarity": "Common", "one_in": 1.0, "identified_mult": 1.0, "listing": 0.0, "listed": false, "extra_spend": 5.0}],
		"bag_level": 1.0, "storage_level": 0.0, "toolbox_level": 0.0, "eye_level": 0.0, "fee_level": 0.0,
		"achievements": {"First Flip": true}, "discovered_log": {"Pokemon|Pokemon Card Tin|Common": {"name": "Pokemon Card Tin", "category": "Pokemon", "rarity": "Common", "one_in": 1}},
		"family_stats": {}, "sold_history": [{"name": "Pokemon Deck Box", "price": 30.0, "day": 3, "condition": 6, "condition_checked": false, "paid": 10.0}],
		"skills_unlocked": {}, "tutorial_seen": true}
	var ok = b.apply_save_data(legacy)
	check(ok, "legacy save applied")
	check(b.inventory[0]["category"] == "Trading Cards" and b.inventory[0]["name"] == "Trading Card Tin", "legacy names migrated")
	check(b.inventory[0].has("auctioned") and b.inventory[0].has("est_noise"), "legacy item normalized")
	check(b.stalls.size() > 0, "fresh day generated for legacy save")
	check(b.discovered_log.has("Trading Cards|Trading Card Tin|Common"), "collection keys migrated")
	b.show_inventory()
	b.ui.show_journal("sales")
	b.ui.show_journal("collection")
	b.ui.show_journal("discoveries")
	b.show_business()
	b.end_day()
	await process_frame
	check(b.day == 10, "legacy save can end a day")
	# export/import code round trip
	var code = b.export_save_code()
	var cash_before = b.cash
	b.cash = 1.0
	check(b.import_save_code(code) and abs(b.cash - cash_before) < 0.01, "save code round trip")
	check(not b.import_save_code("nonsense!!"), "bad save code rejected")
	# Regression: actions must persist immediately (no reload re-rolls / duplication)
	var c = load("res://Main.tscn").instantiate()
	get_root().add_child(c)
	await process_frame
	c.start_new_game()
	c.cash = 2000.0
	c.buy_item(0)
	c.show_inventory()
	var it = c.inventory[0]
	if it["testable"]:
		c.test_item(0)
	c.deep_research(0)
	var dr_energy = c.energy
	# force an instant sale
	var le = LineEdit.new()
	le.text = "1"
	c.inventory[0]["instant_roll_day"] = -1
	var sold_before = c.sold_history.size()
	var tries = 0
	while c.sold_history.size() == sold_before and tries < 200 and c.inventory.size() > 0:
		c.inventory[0]["instant_roll_day"] = -1
		c.inventory[0]["listed"] = false
		c.create_listing(0, le)
		tries += 1
	c._debug_force_offer()
	c.accept_special_offer()
	var inv_now = c.inventory.size()
	var cash_now = c.cash
	c.queue_free()
	await process_frame
	var d = load("res://Main.tscn").instantiate()
	get_root().add_child(d)
	await process_frame
	check(d.inventory.size() == inv_now, "no item duplication after instant sale + side deal (%d vs %d)" % [d.inventory.size(), inv_now])
	check(abs(d.cash - cash_now) < 0.01, "cash matches after reload")
	check(d.pending_special_offer == null, "accepted offer not pending after reload")
	check(d.energy <= dr_energy, "deep research energy not refunded by reload")
	d.queue_free()
	await process_frame
	# 0.11 state round trip: business, expertise, regulars, rival, traits, mid-clearance
	var e = load("res://Main.tscn").instantiate()
	get_root().add_child(e)
	await process_frame
	e.start_new_game()
	e.cash = 9000.0
	e.buy_vehicle()
	e.buy_vehicle()
	e.buy_vehicle()
	e.buy_premises()
	e.buy_equipment("cleaning")
	e.expertise["Vinyl"] = 300.0
	e.regulars[0]["rel"] = 77.0
	var it2 = e.generate_item("Collector")
	it2["traits"] = [{"id": e.content.traits.keys()[0], "mult": 1.5, "known": true, "clue": true, "fixed": false}]
	e.inventory.append(it2)
	var uid2 = int(it2["uid"])
	var lead = e.add_clearance_lead("paper")
	e.start_clearance(lead["id"])
	e.clearance_look(0)
	var snap2 = {"veh": e.vehicle_level, "prem": e.premises_level, "eq": e.equip_level("cleaning"), "rel": e.regulars[0]["rel"], "rid": e.regulars[0]["id"], "rival": e.rival["name"], "clear_items": e.clearance["items"].size(), "looked": e.clearance["rooms"][0]["looked"], "cash": e.cash}
	e.save_game()
	e.queue_free()
	await process_frame
	var f = load("res://Main.tscn").instantiate()
	get_root().add_child(f)
	await process_frame
	check(f.vehicle_level == snap2["veh"] and f.premises_level == snap2["prem"] and f.equip_level("cleaning") == snap2["eq"], "business restored")
	check(f.expertise_tier("Vinyl") == 2, "expertise restored")
	check(abs(float(f.regulars[0]["rel"]) - float(snap2["rel"])) < 0.01 and int(f.regulars[0]["id"]) == int(snap2["rid"]), "regulars restored")
	check(f.rival["name"] == snap2["rival"], "rival restored")
	check(f.clearance != null and f.clearance["items"].size() == snap2["clear_items"] and f.to_bool(f.clearance["rooms"][0]["looked"]), "mid-clearance restored")
	var found = null
	for x in f.inventory:
		if int(x["uid"]) == uid2:
			found = x
	check(found != null and found["traits"].size() == 1 and found["traits"][0]["known"] == true, "item traits restored with uid")
	f.accept_clearance()
	check(f.clearance == null, "clearance can be completed after reload")
	f.end_day()
	await process_frame
	check(f.day == 2, "day ends after clearance")
	# 0.10 mid-game save (version 2) migration
	var old = {"save_version": 2, "cash": 1200.0, "day": 30, "player_level": 9, "player_xp": 10, "inventory": [], "bag_level": 3, "storage_level": 3, "toolbox_level": 2, "eye_level": 2, "fee_level": 1, "package_insight_level": 2, "persuasion_level": 1, "skills_unlocked": {"Keen Eye": true}, "category_knowledge": {"Vinyl": 25, "Games": 10}, "goals_done": 9, "tutorial_seen": true, "sold_history": [{"name": "Punk LP", "price": 40.0, "day": 3, "paid": 10.0, "category": "Vinyl"}]}
	f.apply_save_data(old)
	check(f.premises_level == 2 and f.equip_level("shelving") == 1 and f.equip_level("repair") == 2, "0.10 storage/toolbox migrated")
	check(f.vehicle_level == 2, "0.10 bag migrated to vehicle")
	check(f.skills_unlocked.size() == 0 and f.skill_points_available() == 8, "old skills refunded")
	check(abs(f.cash - (1200.0 + 50.0 + 64.0 + 50.0)) < 0.01, "retired upgrades refunded (%.0f)" % f.cash)
	check(f.expertise_tier("Vinyl") >= 1 and f.goals_done == 0, "knowledge -> expertise, goals re-checked")
	check(f.regulars.size() > 0 and f.rival.has("name") and f.stalls.size() > 0, "world created for old save")
	f.check_goals()
	check(f.goals_done > 0, "old save fast-forwards met goals")
	f.queue_free()
	print("SAVE TESTS: %d failures" % fails)
	quit()
