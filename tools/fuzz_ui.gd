extends SceneTree
# Presses random visible, enabled buttons in the real UI and types into price fields.
# Usage: godot --headless --path . --script tools/fuzz_ui.gd -- <steps> <seed>
var main

func _initialize():
	var args = OS.get_cmdline_user_args()
	var steps = int(args[0]) if args.size() > 0 else 2000
	var s = int(args[1]) if args.size() > 1 else 1
	seed(s)
	if OS.get_environment("W") != "":
		var sz = Vector2i(int(OS.get_environment("W")), int(OS.get_environment("H")))
		get_root().size = sz
		DisplayServer.window_set_size(sz)
	main = load("res://Main.tscn").instantiate()
	get_root().add_child(main)
	_run(steps)

func collect(node, out):
	if node is CanvasItem and not node.is_visible_in_tree():
		return
	if node is BaseButton and not node.disabled:
		out.append(node)
	if node is LineEdit and node.editable:
		out.append(node)
	for c in node.get_children():
		collect(c, out)

func _run(steps):
	for i in range(5):
		await process_frame
	if OS.get_environment("RICH") != "":
		main.start_new_game()
		main.tutorial_seen = true
		main._debug_rich_state()
		main.cash = 20000.0
		main.vehicle_level = 4
		main.premises_level = 3
		main.add_clearance_lead("paper")
		main.add_clearance_lead("tip", "Doreen")
		main.expertise["Tools"] = 900.0
		main.skills_unlocked = {}
		main.player_level = 12
		main.ui.show_market()
	var presses = 0
	var days_seen = {}
	for step in range(steps):
		var targets = []
		# modal popup takes priority, like a real player
		if main.ui.popup_open:
			collect(main.ui.popup_layer, targets)
		elif main.ui.sheet_layer.get_child_count() > 0:
			collect(main.ui.sheet_layer, targets)
			if randf() < 0.3:
				collect(main.ui.hud_box, targets)
		else:
			collect(main, targets)
		if targets.size() == 0:
			await process_frame
			continue
		var t = targets[randi() % targets.size()]
		if t is LineEdit:
			t.text = str(randi() % 300)
			t.text_submitted.emit(t.text)
		else:
			var label = button_text(t)
			# don't quit the app / wipe the run constantly
			if label == "Quit":
				continue
			if label.begins_with("Yes, start again") and randf() < 0.9:
				continue
			if label.begins_with("Load this code"):
				continue
			if (label.begins_with("End day") or label.begins_with("End Day")) and randf() < 0.85:
				continue
			if label.begins_with("Title screen") and randf() < 0.8:
				continue
			t.pressed.emit()
			presses += 1
		days_seen[main.day] = true
		if step % 3 == 0:
			await process_frame
	for l in main.activity_log.slice(max(0, main.activity_log.size() - int(OS.get_environment("LOGN") if OS.get_environment("LOGN") != "" else "0")), main.activity_log.size()):
		print("  LOG ", l)
	print("FUZZ DONE presses=%d day=%d cash=%.2f screen=%s game_over=%s" % [presses, main.day, main.cash, main.current_screen_name, str(main.game_over)])
	quit()

func button_text(b):
	if not (b is Button):
		return ""
	if b.text != "":
		return b.text
	var labels = []
	_labels(b, labels)
	return labels[0] if labels.size() > 0 else ""

func _labels(node, out):
	for c in node.get_children():
		if c is Label:
			out.append(c.text)
		_labels(c, out)
