extends SceneTree
# Loads every game script so parse errors show up without running the game.
func _initialize():
	var bad = 0
	for p in ["res://main.gd", "res://scripts/content.gd", "res://scripts/sys_world.gd", "res://scripts/sys_trade.gd"]:
		if load(p) == null:
			bad += 1
	for dir in ["res://scripts/ui/", "res://scripts/data/"]:
		var d = DirAccess.open(dir)
		for f in d.get_files():
			if f.ends_with(".gd"):
				if load(dir + f) == null:
					bad += 1
					print("FAILED ", dir + f)
	print("COMPILE %s" % ("OK" if bad == 0 else "FAILED %d" % bad))
	quit()
