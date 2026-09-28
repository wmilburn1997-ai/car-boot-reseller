extends SceneTree
func _initialize():
	var m = load("res://Main.tscn").instantiate()
	get_root().add_child(m)
	await process_frame
	m.start_new_game()
	for i in range(120):
		var it = m.generate_item("Regular Seller")
		it["paid"] = 10.0
		m.inventory.append(it)
	m.storage_level = 5
	for n in [1, 2, 3]:
		var t0 = Time.get_ticks_msec()
		m.show_inventory()
		await process_frame
		print("inventory 120 items render+frame ms: ", Time.get_ticks_msec() - t0)
	m.stalls[0]["stock"] = []
	for i in range(26):
		m.stalls[0]["stock"].append(m.generate_item("House Clearance"))
	m.stalls[0]["revealed"] = 26
	m.current_stall_index = 0
	for n in [1, 2]:
		var t2 = Time.get_ticks_msec()
		m.show_stall()
		await process_frame
		print("stall 26 items render+frame ms: ", Time.get_ticks_msec() - t2)
	var t1 = Time.get_ticks_msec()
	m.save_game()
	print("save ms: ", Time.get_ticks_msec() - t1)
	quit()
