extends SceneTree
# Text-mode play harness: lets a human (or an agent) actually play the real game rules turn by turn.
# State persists in a named slot between invocations.
#
#   godot --headless --path . --script tools/play.gd -- <slot> <cmd> [; <cmd> ...]
#
# Commands (separate with ';'):
#   new [seed]          start a new game in this slot
#   st                  status          m   market overview       s N   go to stall N and show it
#   show                re-show current stall          inv   stock        biz   business
#   log [n]             last n activity lines (default 12)
#   it N / sit N        detail of stock item N / stall item N
#   call fn a b ...     call any main.gd function (ints/floats auto-converted; "it:N" = inventory[N], "sit:N" = stall item N)
#   end                 end the day, print the night report
#   bot N [strategy]    the bot plays N whole days for you (careful/tycoon/specialist/...), to reach mid/late game fast
#   shot path.png       screenshot (needs a real window: run under xvfb without --headless)
# Shortcuts at a stall: look N, cond N, res N, spec N, haggle N price, flaw N key, buy N, skip N, dig
# Shortcuts at home:    test N, clean N, repair N, deep N, auth N, uv N, sort N, parts N, list N [price], auction N,
#                       unlist N, scrap N, quick N, coll N, shop N price, icond N, ires N, trade
var m
var seen_log = 0

func _initialize():
	var a = OS.get_cmdline_user_args()
	var slot = a[0] if a.size() > 0 else "default"
	var line = " ".join(a.slice(1))
	var slot_path = "user://play_%s.json" % slot
	# The game reads CBR_SAVE when it's created, so each slot is its own save file.
	OS.set_environment("CBR_SAVE", slot_path)
	m = load("res://Main.tscn").instantiate()
	get_root().add_child(m)
	_run(line, slot_path)

func _run(line, slot_path):
	for i in range(3):
		await process_frame
	m.tutorial_seen = true
	for k in m.ui.COACH:
		m.tips_seen[k] = true
	if not line.begins_with("new"):
		if not m.load_game():
			print("No game in this slot. Use: new [seed]")
			quit()
			return
		m.on_title_screen = false
		m.has_save = true
		m.ui.meta.continue_game()
	_mark_log()
	for raw in line.split(";"):
		var cmd = raw.strip_edges()
		if cmd == "":
			continue
		print("\n> " + cmd)
		await _cmd(cmd)
		_flush_log()
	m.save_game()
	quit()

var last_line = ""

func _mark_log():
	seen_log = m.activity_log.size()
	last_line = str(m.activity_log[seen_log - 1]) if seen_log > 0 else ""

func _flush_log():
	# The activity log is capped (old lines drop off the front), so find the last line we printed.
	var n = m.activity_log.size()
	var start = n
	if last_line == "":
		start = seen_log if seen_log <= n else max(0, n - 6)
	else:
		for i in range(n - 1, -1, -1):
			if str(m.activity_log[i]) == last_line:
				start = i + 1
				break
			start = 0 if i == 0 else start
	for i in range(start, n):
		print("  · " + str(m.activity_log[i]).substr(str(m.activity_log[i]).find("  ") + 2))
	if n > 0:
		last_line = str(m.activity_log[n - 1])
	seen_log = n
	while m.ui.popup_open:
		m.ui._close_popup()

func _conv(s):
	if s.begins_with("it:"):
		return m.inventory[int(s.substr(3))]
	if s.begins_with("sit:"):
		return m.stalls[m.current_stall_index]["stock"][int(s.substr(4))]
	if s.is_valid_int():
		return int(s)
	if s.is_valid_float():
		return float(s)
	if s == "true":
		return true
	if s == "false":
		return false
	return s

func _cmd(cmd):
	var p = cmd.split(" ", false)
	var c = p[0]
	var n = int(p[1]) if p.size() > 1 and p[1].is_valid_int() else -1
	match c:
		"new":
			if p.size() > 1:
				m.forced_run_seed = int(p[1])
			m.init_new_run()
			m.has_save = true
			m.on_title_screen = false
			_mark_log()
			status()
			market()
		"st": status()
		"m": market()
		"s":
			m.go_to_stall(n)
			stall()
		"show": stall()
		"inv": inv()
		"biz": biz()
		"log":
			var k = n if n > 0 else 12
			for i in range(max(0, m.activity_log.size() - k), m.activity_log.size()):
				print("  " + str(m.activity_log[i]))
		"it": item_detail(m.inventory[n], "home")
		"sit": item_detail(m.stalls[m.current_stall_index]["stock"][n], "stall")
		"look": m.quick_look(n); _after_stall(n)
		"cond": m.check_condition(n); _after_stall(n)
		"res": m.prebuy_research(n); _after_stall(n)
		"spec": m.specialist_check("stall", n); _after_stall(n)
		"haggle": m.haggle_item(n, float(p[2])); _after_stall(n)
		"flaw": m.point_out_flaw(n, p[2]); _after_stall(n)
		"buy": m.buy_item(n); stall()
		"skip": m.dismiss_stall_item(n)
		"dig": m.browse_stall(); stall()
		"next": m.next_stall(); stall()
		"test": m.test_item(n); _after_inv(n)
		"clean": m.clean_item(n); _after_inv(n)
		"repair": m.repair_item(n); _after_inv(n)
		"deep": m.deep_research(n); _after_inv(n)
		"auth": m.authenticate_item(n); _after_inv(n)
		"uv": m.uv_check(n); _after_inv(n)
		"sort": m.sort_lot(n); inv()
		"parts": m.parts_fix(n); _after_inv(n)
		"icond": m.inventory_check_condition(n); _after_inv(n)
		"ires": m.inventory_basic_research(n); _after_inv(n)
		"list":
			var price = float(p[2]) if p.size() > 2 else m.suggested_price(m.inventory[n])
			m.create_listing(n, price)
		"auction": m.start_auction(n)
		"unlist": m.unlist_item(n)
		"scrap": m.scrap_item(n)
		"quick": m.quick_sell_item(n)
		"coll": m.sell_to_collector(n)
		"shop": m.put_on_shop_floor(n, float(p[2]))
		"trade": m.trade_buyer_sale()
		"bot":
			# bot N [strategy]: let the scripted bot play N whole days (fast-forward to mid/late game)
			var Bot = load("res://tools/bot.gd")
			var b = Bot.new(m, p[2] if p.size() > 2 else "tycoon")
			var was = m.sim_mode
			m.sim_mode = true
			for d in range(max(1, n)):
				if m.game_over:
					break
				b.play_day()
				m.end_day()
				b.spend_upgrades()
			m.sim_mode = was
			_mark_log()
			status()
		"end":
			m.end_day()
			while m.ui.popup_open:
				m.ui._close_popup()
			night()
		"call":
			var args = []
			for i in range(2, p.size()):
				args.append(_conv(p[i]))
			var target = m
			var fn = p[1]
			if fn.find(".") > 0:
				target = m.get(fn.split(".")[0])
				fn = fn.split(".")[1]
			var r = target.callv(fn, args)
			print("  = ", _short(r))
		"view", "iview":
			# select a stall item (view N) or stock item (iview N) and show its screen, for screenshots
			if c == "view":
				m.selected_stall_uid = int(m.stalls[m.current_stall_index]["stock"][n]["uid"])
				m.show_stall()
			else:
				m.selected_inv_uid = int(m.inventory[n]["uid"])
				m.show_inventory()
		"screen":
			m.call(p[1])
		"world":
			var d = m.world.st()
			print("  week: you %s gaz %s | record %s" % [money(d["week"]["you"]), money(d["week"]["gaz"]), str(d["record"])])
			print("  last week: %s" % str(d.get("last_week", {})))
			print("  event today: %s" % str(m.market_today.get("event", {})))
			print("  valuation today: %s" % str(m.world.valuation_today()))
			for cm in d["commissions"]:
				print("  WANTED %s (%s) x%.2f until %d from %s: %s" % [cm["fam"], cm["cat"], cm["mult"], cm["expires"], cm["from"], cm.get("text", "")])
			for i in range(d["gaz_shop"].size()):
				var e = d["gaz_shop"][i]
				print("  GAZ[%d] %s | %s | price %s paid %s true %s seen %s" % [i, e["item"].get("gaz_title", ""), e["item"]["name"], money(e["price"]), money(e["paid"]), money(m.true_market_value(e["item"])), str(e["seen"])])
			for h in d["headlines"]:
				print("  HEADLINE %s" % h["text"])
			print("  calls: %s" % str(d["calls"]))
		"gazbuy": m.world.buy_from_gaz(n)
		"deliver": m.world.deliver_commission(n)
		"value": m.world.value_item(n)
		"sel":
			m.selected_stall_uid = int(m.stalls[m.current_stall_index]["stock"][n]["uid"])
			m.ui.sheet_open = true
			m.show_stall()
		"isel":
			m.selected_inv_uid = int(m.inventory[n]["uid"])
			m.ui.sheet_open = true
			m.show_inventory()
		"size":
			get_root().size = Vector2i(int(p[1]), int(p[2]))
			DisplayServer.window_set_size(Vector2i(int(p[1]), int(p[2])))
			for i in range(6):
				await process_frame
			m.ui.adjust_scale()
			m.ui.rerender() if m.ui.has_method("rerender") else null
		"clues":
			var stl = m.stalls[m.current_stall_index]
			for i in range(min(int(stl["revealed"]), stl["stock"].size())):
				var it = stl["stock"][i]
				for t in it["traits"]:
					if t.get("clue", false) and not t.get("known", false):
						print("  clue on (%d) %s: %s" % [i, it["name"], m.luck.clue_odds_text(it)])
		"sleep":
			await create_timer(float(p[1])).timeout
		"wait":
			for i in range(max(1, n)):
				await process_frame
		"redig": m.dig_again("stall", n, "research"); _after_stall(n)
		"idig": m.dig_again("inv", n, p[2] if p.size() > 2 else "research"); _after_inv(n)
		"toss": m.luck.toss(n); stall()
		"tombola": m.luck.play_tombola(n)
		"shot":
			for i in range(12):
				await process_frame
			get_root().get_texture().get_image().save_png(p[1])
			print("  saved ", p[1])
		_:
			print("  ?? unknown command")

func _short(v):
	var s = str(v)
	return s if s.length() < 600 else s.substr(0, 600) + "…"

func _after_stall(n):
	var stl = m.stalls[m.current_stall_index]
	var st = stl["stock"]
	if n >= 0 and n < st.size():
		item_detail(st[n], "stall")
		var it = st[n]
		if str(it.get("haggle_note", "")) != "":
			print("     seller: %s" % it["haggle_note"])
		if m.haggle_open(it, stl):
			var fl = []
			for f in m.item_flaws(it):
				fl.append("%s=%s" % [f[0], f[1]])
			print("     haggle: ask %s | patience %d | offends under %s | 80%% ask chance %d%% | flaws: %s" % [money(it["asking"]), m.haggle_patience(it, stl), money(m.haggle_insult_below(it, stl)), int(m.haggle_chance_here(n, float(it["asking"]) * 0.8) * 100), ", ".join(fl)])
		else:
			print("     haggle closed (%s)" % str(it.get("haggle_result", "")))

func _after_inv(n):
	if n >= 0 and n < m.inventory.size():
		item_detail(m.inventory[n], "home")

func money(v):
	if typeof(v) in [TYPE_INT, TYPE_FLOAT]:
		return "£%.2f" % float(v)
	return str(v)

func status():
	print("DAY %d %s  %s  cash %s  energy %d/%d  lvl %d  rating %.0f" % [m.day, m.format_time(), m.weather_name(str(m.plan_for(m.day)["weather"])) + " / " + m.market_name(str(m.plan_for(m.day)["type"])), money(m.cash), m.energy, m.max_energy(), m.player_level, float(m.seller_rating)])
	print("  %s | %s | carry %d/%d | storage %d/%d | listings %d/%d | upkeep %s/day" % [m.premises()["name"], m.vehicle()["name"], m.carry_used, m.effective_bag_capacity(), m.inventory_space_used(), m.storage_capacity(), m.active_listing_count(), m.listing_cap(), money(m.running_costs()["total"])])
	var ex = []
	for c in m.CATEGORIES:
		var xp = m.expertise_xp(c)
		if xp > 0:
			ex.append("%s t%d(%d)" % [c, m.expertise_tier(c), xp])
	print("  expertise: ", ", ".join(ex))
	print("  goal: ", m.current_goal_text())
	print("  business value %s  stock book %s" % [money(m.business_value()), money(m.inventory_book_value())])

func market():
	print("MARKET: %s  (%s)" % [m.market_name(str(m.plan_for(m.day)["type"])), m.format_time()])
	for i in range(m.stalls.size()):
		var s = m.stalls[i]
		var hook = ""
		var extra = []
		if s.get("visited", false): extra.append("visited")
		if s.get("rival_visited", false): extra.append("RIVAL BEEN")
		var rg = m.regular_by_id(int(s.get("regular_id", -1))) if int(s.get("regular_id", -1)) >= 0 else null
		if rg != null: extra.append("REGULAR(%s, %d visits)" % [m.rel_name(float(rg.get("rel", 0))), int(rg.get("visits", 0))])
		print("  [%d] %s — %s, %s. packs %s. %d items (%d seen) %s" % [i, s.get("seller_full_name", s.get("seller_display_name", "?")), s.get("seller", "?"), s.get("personality", ""), m.minute_to_clock(int(s["packing_minute"])), s["stock"].size(), int(s["revealed"]), " ".join(extra)])
	if m.clearance_leads.size() > 0:
		for l in m.clearance_leads:
			print("  LEAD #%s: %s" % [str(l.get("id")), _short(l.get("title", l))])

func stall():
	var s = m.stalls[m.current_stall_index]
	print("STALL %d: %s (%s) — %s" % [m.current_stall_index, s.get("seller_full_name", "?"), s.get("seller", "?"), m.format_time()])
	if s.has("greeting"):
		print("  \"%s\"" % str(s["greeting"]))
	for i in range(int(s["revealed"])):
		if i < s["stock"].size():
			item_line(i, s["stock"][i])
	if int(s["revealed"]) < s["stock"].size():
		print("  (%d more unseen — dig)" % (s["stock"].size() - int(s["revealed"])))

func est_text(it):
	# The same range the game shows the player.
	var r = m.estimate_identified_potential(it)
	return "worth £%d–£%d%s" % [int(r[0]), int(r[1]), "" if it["basic_researched"] else " (typical range, unresearched)"]

func item_line(i, it):
	var tags = []
	if it.get("quick_look_done", false): tags.append("looked")
	if it.get("condition_checked", false): tags.append("cond %d" % int(it["condition"]))
	elif it.get("quick_look_done", false): tags.append("looks %s" % str(it.get("perceived_condition", "?")))
	if it.get("basic_researched", false): tags.append("comps med %s" % money(m.comps_median_value(it)))
	for t in m.known_traits(it): tags.append("+" + str(t.get("name", t.get("id"))))
	if m.item_has_open_clue(it): tags.append("CLUE?")
	if it.get("haggle_result", "") != "": tags.append("haggle:" + str(it["haggle_result"]))
	if it.get("dismissed", false): tags.append("skipped")
	print("  (%d) %s [%s %s %s] ask %s | %s | %s" % [i, it["name"], it["category"], it.get("size", ""), it["rarity"], money(it["asking"]), est_text(it), ", ".join(tags)])

func item_detail(it, ctx):
	print("  ── %s (%s, %s, %s)" % [it["name"], it["category"], it["rarity"], it.get("size", "")])
	if it.has("desc") and str(it["desc"]) != "":
		print("     " + str(it["desc"]))
	print("     %s | paid %s | asking %s" % [est_text(it), money(it.get("paid", 0)), money(it.get("asking", 0))])
	var pot = m.estimate_identified_potential(it)
	print("     potential %s–%s  suggested list %s" % [money(pot[0]), money(pot[1]), money(m.suggested_price(it))])
	for t in it.get("traits", []):
		if t.get("known", false):
			var d = m.trait_def(t)
			print("     ✓ %s: %s (%+d%%)" % [d.get("name", t.get("id")), d.get("text", d.get("desc", "")), int(round((float(t.get("mult", d.get("mult", 1.0))) - 1.0) * 100))])
		elif t.get("clue", false):
			var d2 = m.trait_def(t)
			print("     ? clue: %s" % d2.get("clue", "something"))
	if it.get("basic_researched", false):
		print("     comps: ", it.get("comps_values", []))
	if it.get("fault", false) and m.fault_is_known(it):
		print("     fault: %s" % str(it.get("fault_severity", "")))

func inv():
	print("STOCK (%d items, storage %d/%d, listings %d/%d)" % [m.inventory.size(), m.inventory_space_used(), m.storage_capacity(), m.active_listing_count(), m.listing_cap()])
	for i in range(m.inventory.size()):
		var it = m.inventory[i]
		var state = ""
		if it.get("listed", false): state = "LISTED %s" % money(it["listing"])
		elif it.get("auctioned", false): state = "AUCTION bid %s" % money(it["auction_current_bid"])
		elif it.get("on_shop_floor", false): state = "SHOP %s" % money(it.get("shop_price", 0))
		var pot = m.estimate_identified_potential(it)
		var known = []
		for t in m.known_traits(it): known.append(str(t.get("id", "")))
		print("  (%d) %s [%s c%s] paid %s | pot %s–%s | %s %s %s" % [i, it["name"], it["category"], str(it["condition"]) if it.get("condition_checked", false) else "?", money(it.get("paid", 0)), money(pot[0]), money(pot[1]), state, ",".join(known), "CLUE?" if m.item_has_open_clue(it) else ""])

func biz():
	print("BUSINESS value %s" % money(m.business_value()))
	print("  premises: %s  vehicle: %s" % [m.premises()["name"], m.vehicle()["name"]])
	print("  skill points: %d" % m.skill_points_available())
	print("  equipment: ", m.equipment, "  staff: ", m.staff, "  perks: ", m.perks if m.get("perks") != null else "?")
	print("  account: ", m.account()["name"] if m.account() != null else "?")
	print("  trade buyer: ", m.trade_buyer_available())

func night():
	print("NIGHT → now DAY %d. cash %s, energy %d" % [m.day, money(m.cash), m.energy])
	var s = m.get("last_summary")
	if s != null:
		print("  ", _short(s))
