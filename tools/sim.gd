extends SceneTree
# Headless bot playtests that drive the real game code.
# Usage: godot --headless --path . --script tools/sim.gd -- <strategy> <runs> <days> [seed]
# Strategies: careful, casual_fee, naive, reckless, greedy, gambler, researcher, haggler, specialist, tycoon, hoarder
# Prints one JSON summary line per run, then an aggregate line.

var g
var strategy = "careful"
const Bot = preload("res://tools/bot.gd")
var bot

func _initialize():
	var args = OS.get_cmdline_user_args()
	strategy = args[0] if args.size() > 0 else "careful"
	var runs = int(args[1]) if args.size() > 1 else 20
	var days = int(args[2]) if args.size() > 2 else 40
	var seed_base = int(args[3]) if args.size() > 3 else 1000
	var finals = []
	var bankrupt = 0
	for r in range(runs):
		var res = run_one(seed_base + r, days)
		finals.append(res)
		if res["bankrupt_day"] > 0:
			bankrupt += 1
		print(JSON.stringify(res))
	var nw = []
	for f in finals:
		nw.append(f["net_worth"])
	nw.sort()
	var mean = 0.0
	for v in nw:
		mean += v
	mean /= max(1, nw.size())
	var agg = {"strategy": strategy, "runs": runs, "days": days, "bankrupt": bankrupt, "median_net_worth": nw[nw.size() / 2], "mean_net_worth": snapped(mean, 1), "p10": nw[int(nw.size() * 0.1)], "p90": nw[int(nw.size() * 0.9)]}
	for k in ["premises", "vehicle", "clearances", "discoveries", "missed", "returns", "max_tier", "level", "sold"]:
		var tot = 0.0
		for f in finals:
			tot += float(f.get(k, 0))
		agg["avg_" + k] = snapped(tot / max(1, finals.size()), 0.1)
	print("AGG " + JSON.stringify(agg))
	quit()

func new_game(seed):
	if g != null:
		g.free()
	g = load("res://main.gd").new()
	g.sim_mode = true
	g.forced_run_seed = seed
	seed(seed)
	g.init_new_run()
	bot = Bot.new(g, strategy)

func run_one(seed, days):
	new_game(seed)
	var curve = []
	var bankrupt_day = 0
	for d in range(days):
		bot.play_day()
		var before_day = g.day
		g.end_day()
		if g.game_over:
			bankrupt_day = before_day
			break
		bot.spend_upgrades()
		if d % 5 == 4:
			curve.append(int(g.business_value()))
	var missed = 0
	for s in g.sold_history:
		missed += s.get("missed", []).size()
	var disc = 0
	for k in g.discoveries_log:
		disc += int(g.discoveries_log[k])
	return {"seed": seed, "strategy": strategy, "day": g.day, "cash": snapped(g.cash, 1), "stock": g.inventory.size(),
		"net_worth": snapped(g.business_value(), 1), "bankrupt_day": bankrupt_day,
		"sold": g.sold_history.size(), "level": g.player_level, "profit": snapped(g.total_lifetime_profit, 1),
		"rating": snapped(g.seller_rating, 0.1), "premises": g.premises_level, "vehicle": g.vehicle_level,
		"equip": g.equipment.keys(), "clearances": bot.stats["clearances"], "discoveries": disc, "missed": missed,
		"max_tier": g.max_expertise_tier(), "goals": g.goals_done, "curve": curve}
