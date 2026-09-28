extends SceneTree
# Distribution of trait effects on generated stall items.
func _initialize():
	var g = load("res://main.gd").new()
	g.sim_mode = true
	g.rng.seed = 7
	g.init_new_run()
	var n = 0
	var prod_sum = 0.0
	var logsum = 0.0
	var counts = {"good": 0, "bad": 0, "fixable": 0, "hidden_item": 0}
	var ntr = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0}
	var ask_ratio = 0.0
	for arch in g.seller_profiles.keys():
		for i in range(400):
			var it = g.generate_item(arch)
			var p = 1.0
			for t in it["traits"]:
				p *= float(t["mult"])
				counts[g.trait_def(t)["kind"]] += 1
			ntr[it["traits"].size()] = ntr.get(it["traits"].size(), 0) + 1
			prod_sum += p
			logsum += log(p)
			ask_ratio += float(it["asking"]) / max(1.0, g.true_market_value(it))
			n += 1
	print("items %d mean trait product %.3f geo %.3f kinds %s ntraits %s mean ask/true %.3f" % [n, prod_sum / n, exp(logsum / n), str(counts), str(ntr), ask_ratio / n])
	g.free()
	quit()
