extends SceneTree
func _initialize():
	var s = load("res://main.gd")
	print("LOADED" if s != null else "FAILED")
	quit()
