extends SceneTree
# Loads a save from an older version and plays ten days on it.
# Usage: godot --headless --path . --script tools/load_old_test.gd
# (copies tools/testdata/save_0.11.2_day71.json into a scratch save slot first)
func _initialize():
	var src = FileAccess.get_file_as_string("res://tools/testdata/save_0.11.2_day71.json")
	var f = FileAccess.open("user://old_fixture.json", FileAccess.WRITE)
	f.store_string(src)
	f.close()
	OS.set_environment("CBR_SAVE", "user://old_fixture.json")
	var m = load("res://Main.tscn").instantiate()
	get_root().add_child(m)
	_go(m)
func _go(m):
	for i in range(3):
		await process_frame
	var ok = m.load_game()
	m.on_title_screen = false
	m.has_save = true
	print("LOADED ", ok, " day ", m.day, " goals_done ", m.goals_done, " -> next: ", m.business_goals[min(m.goals_done, m.business_goals.size() - 1)]["text"])
	print("signatures ", m.signatures, " notes ", m.pending_notices)
	print("tiers ", m.CATEGORIES.map(func(c): return m.expertise_tier(c)))
	print("w2 keys ", m.w2.keys(), " gaz shop ", m.world.st()["gaz_shop"].size())
	m.ui.meta.continue_game()
	for i in range(3):
		await process_frame
	var Bot = load("res://tools/bot.gd")
	var b = Bot.new(m, "careful")
	m.sim_mode = true
	for d in range(10):
		b.play_day()
		m.end_day()
		b.spend_upgrades()
	m.sim_mode = false
	print("AFTER 10 days: day ", m.day, " worth ", m.business_value(), " goals ", m.goals_done, " record ", m.world.st()["record"])
	quit()
