extends SceneTree
# Expected value of house clearances, and of a sensible "look round, then decide" rule.
func _initialize():
	var g = load("res://main.gd").new()
	g.sim_mode = true
	g.rng.seed = 11
	g.init_new_run()
	g.vehicle_level = 4
	for c in ["Tools", "Books", "Collectables"]:
		g.expertise[c] = 250.0
	var ratios = []
	var taken = 0
	var taken_profit = 0.0
	var all_profit = 0.0
	var losses = 0
	for i in range(300):
		var lead = g.add_clearance_lead("paper")
		var c = g.build_clearance(lead)
		g.clearance = c
		g.energy = 100
		var net = 0.0
		for it in c["items"]:
			var v = g.true_market_value(it)
			var costs = g.selling_costs(it, v)
			net += v - costs["fee"] - costs["postage"] - costs["insurance"] - costs["packaging"]
		var price = float(c["price"])
		ratios.append(net / price)
		all_profit += net - price
		if net < price:
			losses += 1
		for r in range(c["rooms"].size()):
			if g.energy >= 8:
				g.clearance_look(r)
		var seen = 0.0
		var seen_n = 0
		for room in c["rooms"]:
			if room["looked"]:
				for idx in room["items"]:
					seen += g.perceived_center(c["items"][idx])
					seen_n += 1
		var est_total = seen / max(1, seen_n) * c["items"].size() * 0.72
		if est_total > price * 1.15:
			taken += 1
			taken_profit += net - price
		g.clearance_leads = []
	ratios.sort()
	print("median net/price %.2f p10 %.2f p90 %.2f  losing jobs %d/300  avg profit if take all £%.0f  rule takes %d, avg profit £%.0f" % [ratios[150], ratios[30], ratios[270], losses, all_profit / 300.0, taken, taken_profit / max(1, taken)])
	g.free()
	quit()
