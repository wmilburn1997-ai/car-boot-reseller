extends SceneTree
# Plays N days with the bot, then opens every screen at a phone size and reports anything
# whose minimum width is wider than the screen (which would force sideways scrolling).
# Usage: xvfb-run -a godot --path . --rendering-driver opengl3 --script tools/width_check.gd -- 360 800 40
const Bot = preload("res://tools/bot.gd")
var m
var bad = 0
func _initialize():
	var a = OS.get_cmdline_user_args()
	var w = int(a[0]) if a.size() > 0 else 360
	var h = int(a[1]) if a.size() > 1 else 800
	get_root().size = Vector2i(w, h)
	DisplayServer.window_set_size(Vector2i(w, h))
	m = load("res://Main.tscn").instantiate()
	get_root().add_child(m)
	_go(int(a[2]) if a.size() > 2 else 40)

func _go(days):
	for i in range(3):
		await process_frame
	m.tutorial_seen = true
	for k in m.ui.COACH:
		m.tips_seen[k] = true
	m.start_new_game()
	var b = Bot.new(m, "tycoon")
	m.sim_mode = true
	for d in range(days):
		b.play_day()
		m.end_day()
		b.spend_upgrades()
	m.sim_mode = false
	var screens = [["market", func(): m.show_market()], ["stall", func(): m.go_to_stall(0)],
		["stock", func(): m.show_inventory()], ["business", func(): m.show_business()],
		["gaz", func(): m.show_gaz_shop()], ["saleroom", func(): m.show_saleroom()],
		["news", func(): m.ui.show_news()], ["expertise", func(): m.ui.show_journal("expertise")],
		["perks", func(): m.ui.show_journal("perks")], ["flips", func(): m.ui.show_journal("flips")],
		["discoveries", func(): m.ui.show_journal("discoveries")], ["collection", func(): m.ui.show_journal("collection")],
		["story", func(): m.ui.show_journal("story")], ["sales", func(): m.ui.show_journal("sales")], ["luck", func(): m.ui.show_journal("luck")]]
	for ev in m.world.EVENT_WEIGHTS.keys():
		screens.append(["event_" + ev, func():
			m.generate_day()
			m.world.apply_event(ev)
			m.show_market()])
	for sc in screens:
		sc[1].call()
		while m.ui.popup_open:
			m.ui._close_popup()
		for i in range(3):
			await process_frame
		var lim = m.ui.logical.x
		var over = _scan(m.ui.content, lim, [])
		over.append_array(_scan(m.ui.sheet_layer, lim, []))
		if over.size() > 0:
			bad += 1
			print("OVERFLOW ", sc[0], " (screen ", lim, "):")
			for o in over.slice(0, 6):
				print("   ", o)
	# an item sheet on the stall
	m.go_to_stall(0)
	var st = m.stalls[0]
	if st["stock"].size() > 0 and int(st["revealed"]) > 0:
		m.selected_stall_uid = int(st["stock"][0]["uid"])
		m.ui.sheet_open = true
		m.show_stall()
		for i in range(3):
			await process_frame
		var over2 = _scan(m.ui.sheet_layer, m.ui.logical.x, [])
		if over2.size() > 0:
			bad += 1
			print("OVERFLOW stall sheet:")
			for o in over2.slice(0, 6):
				print("   ", o)
	print("WIDTH CHECK: %d screen(s) overflow" % bad)
	quit()

func _scan(n, lim, out):
	# Report the deepest wide containers' children, so we see the culprit.
	for c in n.get_children():
		if c is Control and c.is_visible_in_tree():
			var w = c.get_combined_minimum_size().x
			if w > lim + 0.5:
				var deeper = _scan(c, lim, [])
				if deeper.size() == 0:
					var t = ""
					if "text" in c:
						t = str(c.text).substr(0, 50)
					out.append("%s minw %d %s | parent %s" % [c.get_class(), int(w), t, n.get_class()])
					# siblings summing up in a box
					if n is BoxContainer:
						for s in n.get_children():
							if s is Control:
								out.append("      sibling %s %d %s" % [s.get_class(), int(s.get_combined_minimum_size().x), (str(s.text).substr(0, 30) if "text" in s else "")])
				else:
					out.append_array(deeper)
			elif c is Container and w > 0:
				# a box whose children sum to more than the screen
				_scan(c, lim, out)
	return out
