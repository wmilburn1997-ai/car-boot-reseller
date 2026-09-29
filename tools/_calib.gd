extends SceneTree
func _initialize():
	var m = load("res://Main.tscn").instantiate()
	m.sim_mode = true
	get_root().add_child(m)
	m.start_new_game()
	var stages = {"none": [], "look": [], "cond": [], "res": []}
	var cover = {"none": 0, "look": 0, "cond": 0, "res": 0}
	var cover2 = {"none": 0, "look": 0, "cond": 0, "res": 0}
	var widths = {"none": [], "look": [], "cond": [], "res": []}
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
					var r = m.value_range(it)
					var kv = m.market_value(it) / max(0.01, m.item_unknown_trait_mult(it))
					stages[stage].append(pc / kv)
					if kv >= r[0] and kv <= r[1]: cover[stage] += 1
					if tv >= r[0] and tv <= r[1]: cover2[stage] += 1
					widths[stage].append(r[1] / r[0])
				m.energy = 999
	for stage in ["none", "look", "cond", "res"]:
		var a = stages[stage]; a.sort()
		var w = widths[stage]; w.sort()
		print("%s: n=%d median pc/known=%.2f p10=%.2f p90=%.2f | range covers known %.0f%%, covers truth %.0f%% | median width x%.2f" % [stage, a.size(), a[a.size()/2], a[int(a.size()*0.1)], a[int(a.size()*0.9)], 100.0*cover[stage]/a.size(), 100.0*cover2[stage]/a.size(), w[w.size()/2]])
	# asking vs true
	quit()
