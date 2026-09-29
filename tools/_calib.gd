extends SceneTree
func _initialize():
	var m = load("res://Main.tscn").instantiate()
	m.sim_mode = true
	get_root().add_child(m)
	m.start_new_game()
	var stages = {"none": [], "look": [], "cond": [], "res": []}
	var cover = {"none": 0, "look": 0, "cond": 0, "res": 0}
	var n = 0
	for d in range(25):
		m.generate_day()
		m.cash = 99999
		m.energy = 999
		for si in range(m.stalls.size()):
			var st = m.stalls[si]
			m.current_stall_index = si
			st["revealed"] = st["stock"].size()
			var items = st["stock"].duplicate()
			for it in items:
				var i = st["stock"].find(it)
				if i < 0: continue
				var tv = m.true_market_value(it)
				if tv <= 0.5: continue
				n += 1
				for stage in ["none", "look", "cond", "res"]:
					i = st["stock"].find(it)
					if i < 0: break
					if stage == "look": m.quick_look(i)
					if stage == "cond": m.check_condition(i)
					if stage == "res": m.prebuy_research(i)
					var pc = m.perceived_center(it)
					var u = m.estimate_uncertainty(it)
					stages[stage].append(pc / tv)
					if tv >= pc * (1 - u) and tv <= pc * (1 + u): cover[stage] += 1
				m.energy = 999
	for stage in ["none", "look", "cond", "res"]:
		var a = stages[stage]; a.sort()
		print("%s: n=%d median pc/true=%.2f p10=%.2f p90=%.2f coverage=%.0f%%" % [stage, a.size(), a[a.size()/2], a[int(a.size()*0.1)], a[int(a.size()*0.9)], 100.0*cover[stage]/a.size()])
	# asking vs true
	quit()
