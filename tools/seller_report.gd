extends "res://tools/sim.gd"
# Per-seller / per-channel profitability for a strategy.
func _initialize():
	var args = OS.get_cmdline_user_args()
	strategy = args[0] if args.size() > 0 else "careful"
	var by_seller = {}
	var by_channel = {}
	var by_rarity = {}
	var returns = 0
	for r in range(int(args[1]) if args.size() > 1 else 40):
		run_one(3000 + r, 30)
		for sale in g.sold_history:
			var p = g.sale_profit_of(sale)
			for pair in [[by_seller, sale.get("seller", "?") + "/" + sale.get("source", "?")], [by_channel, sale.get("channel", "?")], [by_rarity, sale.get("rarity", "?")]]:
				var d = pair[0]
				var k = pair[1]
				if not d.has(k):
					d[k] = [0, 0.0, 0]
				d[k][0] += 1
				d[k][1] += p
				if p > 0: d[k][2] += 1
	for d in [by_seller, by_channel, by_rarity]:
		for k in d.keys():
			print("%-32s n=%5d  avg profit £%6.2f  win %3d%%" % [k, d[k][0], d[k][1] / d[k][0], int(100.0 * d[k][2] / d[k][0])])
		print("")
	quit()
