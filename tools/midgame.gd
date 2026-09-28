extends SceneTree
# Plays N days with the careful bot inside the REAL game scene, then screenshots every major screen.
# Usage: xvfb-run -a godot --path . --rendering-driver opengl3 --script tools/midgame.gd -- <outdir> <days> <seed> [w] [h] [strategy]
const Bot = preload("res://tools/bot.gd")
var m

func _initialize():
	var a = OS.get_cmdline_user_args()
	var w = int(a[3]) if a.size() > 3 else 1600
	var h = int(a[4]) if a.size() > 4 else 900
	get_root().size = Vector2i(w, h)
	DisplayServer.window_set_size(Vector2i(w, h))
	m = load("res://Main.tscn").instantiate()
	get_root().add_child(m)
	_go(a[0], int(a[1]), int(a[2]), a[5] if a.size() > 5 else "tycoon")

func shot(outdir, name):
	for i in range(10):
		await process_frame
	get_root().get_texture().get_image().save_png("%s/%s.png" % [outdir, name])
	print("shot ", name)

func close_popups():
	while m.ui.popup_open:
		m.ui._close_popup()

func _go(outdir, days, s, strat):
	await process_frame
	m.tutorial_seen = true
	for k in m.ui.COACH:
		m.tips_seen[k] = true
	m.start_new_game()
	m.rng.seed = s
	var bot = Bot.new(m, strat)
	var summary = null
	for d in range(days):
		m.sim_mode = true
		bot.play_day()
		if d == days - 1:
			m.sim_mode = false
			break
		m.end_day()
		bot.spend_upgrades()
	m.sim_mode = false
	m.ui.popup_queue = []
	close_popups()
	m.ui.build_root()
	# Morning of the next day, fully rendered
	m.end_day()
	close_popups()
	await shot(outdir, "01_night_report")
	m.show_market()
	close_popups()
	await shot(outdir, "02_market")
	m.go_to_stall(0)
	close_popups()
	await shot(outdir, "03_stall")
	m.prebuy_research(0)
	m.quick_look(0)
	close_popups()
	await shot(outdir, "04_stall_checked")
	m.ui.show_inventory(true)
	close_popups()
	await shot(outdir, "05_stock")
	m.show_business()
	await shot(outdir, "06_business")
	m.ui.show_knowledge()
	await shot(outdir, "07_expertise")
	m.ui.show_perks()
	await shot(outdir, "08_perks")
	m.ui.show_journal("story")
	await shot(outdir, "09_journal_story")
	m.ui.show_journal("discoveries")
	await shot(outdir, "10_discoveries")
	m.ui.show_journal("sales")
	await shot(outdir, "11_sales")
	m.ui.show_news()
	await shot(outdir, "12_news")
	m.ui.show_more()
	await shot(outdir, "13_more")
	if m.can_do_clearances() or true:
		m.vehicle_level = max(m.vehicle_level, 3)
		m.current_time_minutes = 7 * 60
		if m.clearance_leads.size() == 0:
			m.add_clearance_lead("tip", "Doreen")
		m.start_clearance(m.clearance_leads[0]["id"])
		m.clearance_look(0)
		m.clearance_look(1)
		close_popups()
		await shot(outdir, "14_clearance")
	print("MIDGAME day=%d cash=%.0f level=%d premises=%d vehicle=%d" % [m.day, m.cash, m.player_level, m.premises_level, m.vehicle_level])
	quit()
