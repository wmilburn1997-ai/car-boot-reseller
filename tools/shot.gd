extends SceneTree
# Usage: godot --path . --script tools/shot.gd -- <outdir> <w> <h> <steps...>
var main
func _initialize():
	var args = OS.get_cmdline_user_args()
	var outdir = args[0]
	var w = int(args[1]); var h = int(args[2])
	get_root().size = Vector2i(w, h)
	DisplayServer.window_set_size(Vector2i(w, h))
	var scene = load("res://Main.tscn").instantiate()
	main = scene
	get_root().add_child(scene)
	_run(outdir, args.slice(3))

func _run(outdir, steps):
	for i in range(8):
		await process_frame
	var n = 0
	for step in steps:
		if step.begins_with("call:"):
			var parts = step.substr(5).split(",")
			var fn = parts[0]
			var cargs = []
			for p in parts.slice(1):
				cargs.append(int(p) if p.is_valid_int() else p)
			main.callv(fn, cargs)
			for i in range(4):
				await process_frame
		elif step.begins_with("set:"):
			var kv = step.substr(4).split("=")
			var v = kv[1]
			main.set(kv[0], int(v) if v.is_valid_int() else (float(v) if v.is_valid_float() else v))
		elif step.begins_with("press:"):
			var want = step.substr(6)
			var found = []
			_collect(main, found)
			var hit = null
			for b in found:
				if b.text.begins_with(want):
					hit = b
					break
			if hit == null:
				print("PRESS MISS: ", want)
			else:
				hit.pressed.emit()
			for i in range(4):
				await process_frame
		elif step.begins_with("shot:"):
			for i in range(6):
				await process_frame
			var img = get_root().get_texture().get_image()
			img.save_png("%s/%s.png" % [outdir, step.substr(5)])
			n += 1
	quit()

func _collect(node, out):
	if node is CanvasItem and not node.is_visible_in_tree():
		return
	if node is Button and not node.disabled:
		out.append(node)
	for c in node.get_children():
		_collect(c, out)
