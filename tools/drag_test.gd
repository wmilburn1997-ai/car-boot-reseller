extends SceneTree
# Simulates a finger drag starting on a button and checks the list scrolls without clicking it.
var m
func _initialize():
	get_root().size = Vector2i(390, 844)
	DisplayServer.window_set_size(Vector2i(390, 844))
	m = load("res://Main.tscn").instantiate()
	get_root().add_child(m)
	_go()

func ev_touch(pressed, pos):
	var e = InputEventScreenTouch.new()
	e.index = 0
	e.pressed = pressed
	e.position = pos
	Input.parse_input_event(e)

func ev_drag(pos, rel):
	var e = InputEventScreenDrag.new()
	e.index = 0
	e.position = pos
	e.relative = rel
	Input.parse_input_event(e)

func _go():
	for i in range(5):
		await process_frame
	m.tutorial_seen = true
	for k in m.ui.COACH:
		m.tips_seen[k] = true
	m.start_new_game()
	for i in range(5):
		await process_frame
	var sc = m.ui.scroll_at(Vector2(200, 600) / 1.0)
	_dump(m.ui.content, 0)
	print("mouse emulation: ", ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch"))
	print("screen: ", m.current_screen_name, " scroll found: ", sc)
	var p0 = Vector2(200, 600)
	print("logical ", m.ui.logical, " window ", m.get_window().size, " found at p0: ", m.ui.scroll_at(p0))
	ev_touch(true, p0)
	await process_frame
	for i in range(1, 16):
		ev_drag(p0 - Vector2(0, i * 25), Vector2(0, -25))
		await process_frame
	ev_touch(false, p0 - Vector2(0, 375))
	for i in range(5):
		await process_frame
	print("after drag screen: ", m.current_screen_name, " scroll: ", sc.scroll_vertical if sc else -1, " dragging_state ", m.ui.dragging, " down ", m.ui.drag_down)
	quit()

func _dump(n, d):
	for c in n.get_children():
		if c is ScrollContainer:
			var vb = c.get_v_scroll_bar()
			print("SC rect ", c.get_global_rect(), " max ", vb.max_value, " page ", vb.page, " vis ", c.is_visible_in_tree())
		if c is Control:
			_dump(c, d + 1)
