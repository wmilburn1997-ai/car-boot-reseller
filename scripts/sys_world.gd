extends RefCounted
# The living world (0.12): Gaz as a real rival with an online shop you can raid,
# a weekly scoreboard, regulars who remember what actually happened, "find me…"
# commissions, big-find phone calls and headlines, the weekly Valuation Tent,
# and one odd thing per market day.
#
# All state lives in main.w2 (a plain dictionary) so it saves with the game.

const L = preload("res://scripts/data/lines_012.gd")

var g

func _init(main):
	g = main

func st():
	if typeof(g.w2) != TYPE_DICTIONARY:
		g.w2 = {}
	var d = g.w2
	for k in ["gaz_shop", "gaz_msgs", "commissions", "calls", "headlines", "offered_calls"]:
		if not d.has(k):
			d[k] = []
	if not d.has("week"):
		d["week"] = {"you": 0.0, "gaz": 0.0, "start": g.day}
	if not d.has("record"):
		d["record"] = {"wins": 0, "losses": 0, "streak": 0}
	if not d.has("next_cid"):
		d["next_cid"] = 1
	if not d.has("valued_week"):
		d["valued_week"] = -1
	return d

func nick():
	return str(g.rival.get("nickname", "Gaz"))

# =============================================================================
# Gaz
# =============================================================================
func gaz_took(item, stall, seen_by_player):
	# Gaz lists everything he buys on his online shop, "Gaz's Gems". He prices his own
	# categories properly; everything else he guesses from what the thing usually is,
	# so hidden gems end up underpriced and duds overpriced. That's the raid.
	var d = st()
	var knows = g.rival.get("cats", []).has(item["category"])
	var tm = g.true_market_value(item)
	var price = 0.0
	if knows:
		price = tm * g.rng.randf_range(1.05, 1.35)
	else:
		var fam = g.content.family(str(item["name"])) if g.content != null else null
		var mid = tm
		if fam != null:
			mid = (float(fam["value"][0]) + float(fam["value"][1])) * 0.5 * float(g.current_trends.get(item["category"], 1.0))
		price = mid * g.rng.randf_range(0.7, 1.45)
	price = max(float(item["asking"]) * 1.25, price)
	var title = g.fill_line(g.pick_line(L.RIVAL_LINES["shop_listing"]), {"item": str(item["name"]).to_upper()})
	item["gaz_title"] = title
	d["gaz_shop"].append({"item": item, "price": round(price), "day": g.day, "seen": seen_by_player, "paid": float(item["asking"]), "from": stall.get("seller_full_name", "")})
	if d["gaz_shop"].size() > 14:
		d["gaz_shop"].pop_front()

func gaz_night():
	# Gaz sells overnight; his week is his shop plus his other markets.
	var d = st()
	var keep = []
	var you_saw_best = null
	for e in d["gaz_shop"]:
		var it = e["item"]
		var tm = g.true_market_value(it)
		var ch = clamp(0.2 * tm / max(1.0, float(e["price"])), 0.03, 0.45)
		if g.day - int(e["day"]) > 12:
			ch = 0.6   # clears old stock at whatever it fetches
		if g.rng.randf() < ch:
			var profit = float(e["price"]) * 0.87 - float(e["paid"])
			d["week"]["gaz"] = float(d["week"]["gaz"]) + profit
			if e.get("seen", false) and profit >= 30.0 and tm >= float(e["paid"]) * 2.0:
				if you_saw_best == null or profit > float(you_saw_best["profit"]):
					you_saw_best = {"item": g.item_display_name(it), "name": it["name"], "price": e["price"], "profit": profit}
		else:
			keep.append(e)
	d["gaz_shop"] = keep
	if you_saw_best != null:
		var line = g.fill_line(g.pick_line(L.RIVAL_LINES["flipped_your_skip"]), {"item": "the " + g.lc(you_saw_best["name"]), "price": g.fmt_money(you_saw_best["price"])})
		d["gaz_msgs"].append(line)
		g.night_events.append({"kind": "missed", "text": "%s flipped one you walked past" % nick(), "sub": line})
		g.add_journal("%s sold %s for %s. You'd seen it on the table." % [nick(), you_saw_best["item"], g.fmt_money(you_saw_best["price"])], "bad")
	# His other markets: he keeps pace with you, roughly.
	# His other markets: he's getting better at this too, on his own schedule.
	var other = (14.0 + float(g.day) * 0.75) * g.rng.randf_range(0.6, 1.4)
	d["week"]["gaz"] = float(d["week"]["gaz"]) + other
	d["week"]["gaz_other"] = float(d["week"].get("gaz_other", 0.0)) + other

func trailing_player_profit(days):
	var total = 0.0
	for s in g.sold_history:
		if int(s.get("day", 0)) > g.day - days:
			total += float(s.get("profit", 0.0))
	return total / float(max(1, min(days, g.day)))

func add_player_profit(p):
	var d = st()
	d["week"]["you"] = float(d["week"]["you"]) + float(p)

func week_rollover():
	# Called at the end of each 7th day: the scoreboard, and the market's move on the vault.
	g.gamble.vault_week()
	var d = st()
	var w = d["week"]
	var you = float(w["you"])
	var gaz = float(w["gaz"])
	var diff = abs(you - gaz)
	var line = ""
	var raw = ""
	if you >= gaz:
		d["record"]["wins"] = int(d["record"]["wins"]) + 1
		d["record"]["streak"] = max(1, int(d["record"]["streak"]) + 1)
		line = pick_not(L.RIVAL_LINES["week_win"], str(d.get("last_week", {}).get("line", "")))
		g.add_journal("You beat %s this week: %s to %s." % [nick(), g.fmt_money(you), g.fmt_money(gaz)], "good")
		g.add_xp(15)
	else:
		d["record"]["losses"] = int(d["record"]["losses"]) + 1
		d["record"]["streak"] = min(-1, int(d["record"]["streak"]) - 1)
		raw = pick_not(L.RIVAL_LINES["week_loss"], str(d.get("last_week", {}).get("raw", "")))
		line = g.fill_line(raw, {"amount": g.fmt_money(diff)})
		g.add_journal("%s beat you this week: %s to %s." % [nick(), g.fmt_money(gaz), g.fmt_money(you)], "bad")
	d["last_week"] = {"you": you, "gaz": gaz, "line": line, "raw": raw, "won": you >= gaz, "day": g.day}
	g.night_events.append({"kind": "info" if you >= gaz else "bad", "text": ("You beat %s this week" if you >= gaz else "%s won the week") % nick(), "sub": "%s  (You %s · %s %s)" % [line, g.fmt_money(you), nick(), g.fmt_money(gaz)]})
	d["week"] = {"you": 0.0, "gaz": 0.0, "start": g.day + 1}

func pick_not(arr, avoid):
	var c = []
	for l in arr:
		if str(l) != avoid:
			c.append(l)
	return g.pick_line(c if c.size() > 0 else arr)

func buy_from_gaz(idx):
	var d = st()
	if idx < 0 or idx >= d["gaz_shop"].size():
		return
	var e = d["gaz_shop"][idx]
	var it = e["item"]
	var cost = float(e["price"]) + 4.0
	if g.cash < cost:
		g.queue_popup("Not enough cash.")
		return
	if not g.can_store(it):
		g.queue_popup("No room at home for it.")
		return
	g.cash -= cost
	g.day_stats["buy_spend"] += cost
	g.day_stats["items_bought"] += 1
	it["paid"] = cost
	it["asking"] = float(e["price"])
	it["bought_day"] = g.day
	it["source"] = "gaz"
	it["listed"] = false
	it["on_shop_floor"] = false
	g.hist(it, "Bought off %s's online shop for %s (plus postage). His listing: %s" % [nick(), g.fmt_money(e["price"]), str(it.get("gaz_title", ""))])
	g.inventory.append(it)
	g.register_collection(it)
	d["gaz_shop"].remove_at(idx)
	d["week"]["gaz"] = float(d["week"]["gaz"]) + float(e["price"]) * 0.87 - float(e["paid"])
	g.add_toast("Bought from %s's Gems. It'll arrive with the post." % nick(), "success")
	g.play_sfx("buy")
	g.save_game()
	g.show_gaz_shop()

func gaz_at_stall_line(stall):
	return g.fill_line(g.pick_line(L.RIVAL_LINES["at_stall"]), {"seller": stall.get("seller_display_name", "someone")})

# =============================================================================
# Regulars who remember
# =============================================================================
func remember(reg_id, mem):
	var r = g.regular_by_id(int(reg_id))
	if r == null:
		return
	var ms = r.get("memories", [])
	if typeof(ms) != TYPE_ARRAY:
		ms = []
	# One memory per item: a sale replaces the purchase.
	var keep = []
	for m in ms:
		if str(m.get("item", "")) != str(mem.get("item", "")):
			keep.append(m)
	keep.append(mem)
	if keep.size() > 4:
		keep = keep.slice(keep.size() - 4)
	r["memories"] = keep

func memory_greeting(stall):
	var rid = int(stall.get("regular_id", -1))
	var r = g.regular_by_id(rid) if rid >= 0 else null
	if r == null:
		return ""
	var ms = r.get("memories", [])
	if typeof(ms) != TYPE_ARRAY or ms.size() == 0 or g.rng.randf() > 0.7:
		return ""
	var m = ms.pop_back()
	r["memories"] = ms
	var key = "memory_bought"
	if m.get("gem", false):
		key = "memory_gem"
	elif str(m.get("kind", "")) == "sold" and float(m.get("sold", 0)) > float(m.get("price", 0)) * 1.2:
		key = "memory_sold"
	return g.pers_line(stall, key, {"item": "the " + g.lc(m.get("item", "thing")), "price": g.fmt_money(m.get("price", 0)), "sold": g.fmt_money(m.get("sold", 0))})

# =============================================================================
# Commissions: "find me a…"
# =============================================================================
func max_commissions():
	return 2 if g.day < 15 else 3

func roll_commission():
	var d = st()
	var active = d["commissions"]
	if active.size() >= max_commissions() or g.day < 3 or g.rng.randf() > 0.4:
		return
	# Pick a family you could plausibly find: in season, not too rare a type.
	var season = g.get_season_name()
	var cands = []
	for f in g.item_families:
		var fs = str(f.get("season", ""))
		if fs != "" and fs != season:
			continue
		if float(f["value"][1]) > 450.0 or float(f["value"][0]) < 8.0:
			continue
		cands.append(f)
	if cands.size() == 0:
		return
	var fam = cands[g.rng.randi_range(0, cands.size() - 1)]
	var friends = []
	for r in g.regulars:
		if float(r["rel"]) >= 15.0 and int(r["visits"]) > 0:
			friends.append(r)
	var asker = null
	if friends.size() > 0 and g.rng.randf() < 0.5:
		asker = friends[g.rng.randi_range(0, friends.size() - 1)]
		var mine = []
		for f in cands:
			if asker.get("cats", []).has(f["category"]):
				mine.append(f)
		if mine.size() > 0:
			fam = mine[g.rng.randi_range(0, mine.size() - 1)]
		else:
			asker = null
	for c in active:
		if c["fam"] == fam["name"]:
			return
	var mult = snapped(g.rng.randf_range(1.25, 1.6), 0.05)
	var c = {"id": int(d["next_cid"]), "fam": fam["name"], "cat": fam["category"], "mult": mult, "expires": g.day + g.rng.randi_range(6, 11), "reg_id": -1, "from": ""}
	d["next_cid"] = int(d["next_cid"]) + 1
	# A regular who likes you, or a buyer from further afield.
	if asker != null:
		var r = asker
		c["reg_id"] = int(r["id"])
		c["from"] = str(r["name"])
		var arr = L.PERSONALITY_LINES.get(str(r["personality"]), {}).get("commission_ask", [])
		c["text"] = g.fill_line(g.pick_line(arr), {"item": g.a_an(g.lc(fam["name"]))}) if arr.size() > 0 else "Keep an eye out for %s for me?" % g.a_an(g.lc(fam["name"]))
	else:
		var buyer = pick_buyer(str(fam["category"]))
		c["from"] = buyer
		c["text"] = g.fill_line(g.pick_line(L.COMMISSION_ASKS), {"buyer": short_from(c), "item": g.a_an(g.lc(fam["name"]))})
	active.append(c)
	g.add_journal("WANTED: %s. %s pays %.1f× the going rate." % [g.a_an(fam["name"]), short_from(c), mult], "info")

# Which commission buyers plausibly want what (by COMMISSION_BUYERS order).
const BUYER_CATS = [["Collectables", "Games"], ["Home", "Garden & Outdoor"], ["Home", "Clothing", "Collectables", "Books"], ["Jewellery"], ["Musical Instruments"], ["Cameras"], ["Home", "Collectables", "Vinyl"], ["Games", "Electronics", "Trading Cards"], ["Clothing", "Jewellery"], ["Tools", "Electronics"]]

func pick_buyer(cat):
	var ok = []
	for i in range(L.COMMISSION_BUYERS.size()):
		if i < BUYER_CATS.size() and BUYER_CATS[i].has(cat):
			ok.append(L.COMMISSION_BUYERS[i])
	if ok.size() > 0:
		return ok[g.rng.randi_range(0, ok.size() - 1)]
	return "A %s collector in %s" % [cat.to_lower(), g.pick_line(g.Ident.POOLS["town"])]

func short_from(c):
	var f = str(c.get("from", "A buyer"))
	var cut = f.find(",")
	return f.substr(0, cut) if cut > 0 else f

func commission_for(item) -> Variant:
	for c in st()["commissions"]:
		if str(c["fam"]) == str(item["name"]) and int(c["expires"]) >= g.day:
			return c
	return null

func commission_quote(item, c):
	# What they'd pay for it as you've described it.
	return round(g.known_value(item) * float(c["mult"]))

func commission_pay(item, c):
	# They check it when it arrives: anything you didn't know about that makes it worse comes off.
	return round(min(g.known_value(item), g.true_market_value(item) * 1.1) * float(c["mult"]))

func commission_guess(c):
	var fam = g.content.family(str(c["fam"]))
	if fam == null:
		return [0, 0]
	var t = float(g.current_trends.get(c["cat"], 1.0))
	return [int(float(fam["value"][0]) * t * float(c["mult"])), int(float(fam["value"][1]) * t * float(c["mult"]))]

func deliver_commission(index):
	if index < 0 or index >= g.inventory.size():
		return
	var item = g.inventory[index]
	var c = commission_for(item)
	if c == null:
		return
	if item["testable"] and not item["tested"]:
		g.queue_popup("Test it first: they want to know it works.")
		return
	if int(item.get("carried_day", -1)) == g.day:
		g.queue_popup("They'll collect it tomorrow. Get it home first.")
		return
	var quote = commission_quote(item, c)
	var pay = commission_pay(item, c)
	item["listed"] = false
	item["auctioned"] = false
	item["on_shop_floor"] = false
	g.cash += pay
	var profit = g.record_completed_sale(item, pay, {"fee": 0.0, "postage": 0.0, "insurance": 0.0, "packaging": 0.0}, "commission")
	g.inventory.remove_at(index)
	st()["commissions"].erase(c)
	var thanks = ""
	if int(c["reg_id"]) >= 0:
		var r = g.regular_by_id(int(c["reg_id"]))
		if r != null:
			r["rel"] = min(100.0, float(r["rel"]) + 12.0)
			var arr = L.PERSONALITY_LINES.get(str(r["personality"]), {}).get("commission_thanks", [])
			thanks = g.fill_line(g.pick_line(arr), {"item": "the " + g.lc(item["name"])})
	g.add_xp(12)
	g.add_expertise(item["category"], 6)
	g.add_journal("Found %s for %s. Paid %s." % [g.a_an(item["name"]), short_from(c), g.fmt_money(pay)], "good")
	var knocked = ("\n\nThey'd been quoted %s, but it wasn't quite as described, so they knocked it down." % g.fmt_money(quote)) if pay < quote - 1.0 else ""
	g.show_big_popup("COMMISSION DONE", "%s\n\n%s paid %s (%s profit).%s" % [("\"%s\"" % thanks) if thanks != "" else "They're pleased with it.", short_from(c), g.fmt_money(pay), g.money_signed(profit), knocked], "sale" if pay >= quote - 1.0 else "info")
	g.play_sfx("sale")
	g.fx_money(pay)
	g.save_game()
	g.refresh_after("inv")

func expire_commissions():
	var d = st()
	var keep = []
	for c in d["commissions"]:
		if int(c["expires"]) < g.day:
			g.add_journal("%s found %s elsewhere." % [short_from(c), g.a_an(c["fam"])], "info")
		else:
			keep.append(c)
	d["commissions"] = keep

# =============================================================================
# Big finds: the phone call and the headline
# =============================================================================
func check_big_finds():
	# After you've done your homework on something special, a specialist rings.
	var d = st()
	if g.day - int(d.get("last_call_day", -99)) < 10:
		return
	for it in g.inventory:
		if not it["basic_researched"]:
			continue
		var uid = int(it["uid"])
		if d["offered_calls"].has(uid):
			continue
		var pc = g.perceived_center(it)
		if pc < 400.0 or pc < float(it["paid"]) * 4.0:
			continue
		var special = it["rarity"] in ["Rare", "Very Rare", "Grail"]
		for t in g.known_traits(it):
			if float(t["mult"]) >= 1.5:
				special = true
		if not special:
			continue
		if not it["authentic"] and it["auth_status"] != "Confirmed Genuine":
			continue   # the specialists can smell a fake
		d["offered_calls"].append(uid)
		d["last_call_day"] = g.day
		var offer = round(g.true_market_value(it) * g.rng.randf_range(0.88, 1.05))
		var caller = g.pick_line(L.BIG_FIND["caller_names"])
		d["calls"].append({"uid": uid, "offer": offer, "caller": caller, "line": g.fill_line(g.pick_line(L.BIG_FIND["call"]), {"item": "your " + g.lc(it["name"]), "price": g.fmt_money(offer)}), "day": g.day})
		return

func pending_call() -> Variant:
	var d = st()
	for c in d["calls"]:
		for it in g.inventory:
			if int(it["uid"]) == int(c["uid"]):
				return c
	d["calls"] = []
	return null

func answer_call(accept):
	var d = st()
	var c = pending_call()
	if c == null:
		return
	d["calls"].erase(c)
	if not accept:
		g.add_journal("Turned down %s's offer of %s." % [c["caller"], g.fmt_money(c["offer"])], "info")
		g.refresh_after("inv")
		return
	for i in range(g.inventory.size()):
		var it = g.inventory[i]
		if int(it["uid"]) == int(c["uid"]):
			it["listed"] = false
			it["auctioned"] = false
			it["on_shop_floor"] = false
			g.cash += float(c["offer"])
			var profit = g.record_completed_sale(it, float(c["offer"]), {"fee": 0.0, "postage": 0.0, "insurance": 0.0, "packaging": 0.0}, "bigfind")
			g.inventory.remove_at(i)
			g.show_big_popup("SOLD TO A SPECIALIST", "%s\n\n%s paid %s. That's %s profit." % [g.item_display_name(it), str(c["caller"]).split(",")[0], g.fmt_money(c["offer"]), g.money_signed(profit)], "rare", {"item_name": it["name"], "icon": it["category"], "big": g.fmt_money(c["offer"])})
			g.play_sfx("rare")
			g.fx_money(float(c["offer"]))
			break
	g.save_game()
	g.refresh_after("inv")

func on_big_sale(item, price, profit):
	if profit < 250.0:
		return
	var d = st()
	var h = g.fill_line(g.pick_line(L.BIG_FIND["headline"]), {"item": g.item_display_name(item), "price": g.fmt_money(price)})
	d["headlines"].append({"text": h, "day": g.day})
	if d["headlines"].size() > 12:
		d["headlines"].pop_front()
	g.add_journal("In the paper: \"%s\"" % h, "good")

# =============================================================================
# The Valuation Tent (every seventh market day)
# =============================================================================
func valuation_today():
	return g.day % 7 == 3 and g.current_time_minutes < 12 * 60 and not g.market_today.get("clearance", false)

func can_value():
	return valuation_today() and int(st()["valued_week"]) != g.day

func value_item(index):
	if not can_value():
		return
	if index < 0 or index >= g.inventory.size():
		return
	if g.energy < 5:
		g.queue_popup("You need 5 energy.")
		return
	var it = g.inventory[index]
	st()["valued_week"] = g.day
	g.energy -= 5
	g.spend_time(20)
	var name = g.item_display_name(it)
	var lines = []
	lines.append(g.fill_line(g.pick_line(L.VALUATION["intro"]), {"item": name}))
	# Percival sees everything.
	var found = []
	for t in it.get("traits", []):
		if not t.get("known", false):
			t["known"] = true
			t["clue"] = true
			found.append(t)
			g.on_trait_found(it, t, "valuation")
	for t in found:
		var dd = g.trait_def(t)
		if dd != null:
			lines.append(g.fill_line(g.pick_line(L.VALUATION["clue"]), {"detail": g.first_lower(str(dd["found"]).trim_suffix("."))}))
	it["condition_checked"] = true
	if it["testable"]:
		it["tested"] = true
	if float(it["fake_chance"]) > 0.0:
		it["auth_status"] = "Confirmed Genuine" if it["authentic"] else "Confirmed Counterfeit"
		it["auth_attempted"] = true
		if not it["authentic"]:
			it["identified_mult"] = float(it["identified_mult"]) * 0.10
	if not it["basic_researched"]:
		it["basic_researched"] = true
		it["basic_comps"] = g.make_comps(it, true)
	if not it["deep_researched"]:
		it["deep_researched"] = true
		it["deep_comps"] = g.make_comps(it, true)
	var value = g.true_market_value(it)
	it["appraised"] = value
	var paid = float(it["paid"])
	var verdict = "fair"
	if not it["authentic"]:
		verdict = "fake"
	elif value >= max(paid * 2.5, 80.0):
		verdict = "high"
	elif value < paid * 0.8:
		verdict = "low"
	lines.append(g.fill_line(g.pick_line(L.VALUATION[verdict]), {"item": name, "value": g.fmt_money(value)}))
	g.hist(it, "Valued by Percival Dunmore at the tent: %s." % g.fmt_money(value))
	g.add_journal("Percival valued %s at %s." % [name, g.fmt_money(value)], "good" if verdict == "high" else "info")
	g.show_big_popup("THE VALUATION TENT", "\n\n".join(lines), "rare" if verdict == "high" else ("bad" if verdict in ["fake", "low"] else "info"), {"item_name": it["name"], "icon": it["category"], "big": g.fmt_money(value), "count_up": value})
	g.play_sfx("rare" if verdict == "high" else "reveal")
	g.save_game()
	g.show_market()

# =============================================================================
# One odd thing per market day
# =============================================================================
const EVENT_WEIGHTS = {"tv_crew": 1.0, "cloudburst": 0.8, "kids_stall": 1.0, "late_van": 1.0, "dealers_at_dawn": 0.9, "lost_dog": 0.8, "charity_stall": 1.0, "trading_standards": 0.6, "brass_band": 0.8, "heatwave_ices": 0.7, "retired_dealer": 0.7, "tombola": 1.0}

func roll_market_event():
	if g.day < 3 or g.rng.randf() > 0.5 or OS.get_environment("CBR_NO_EVENTS") != "":
		return
	var w = str(g.market_today.get("weather", "overcast"))
	var pool = []
	var total = 0.0
	for id in EVENT_WEIGHTS:
		if id == "cloudburst" and w in ["sunny", "heatwave", "frost"]:
			continue
		if id == "heatwave_ices" and w != "heatwave" and w != "sunny":
			continue
		pool.append(id)
		total += float(EVENT_WEIGHTS[id])
	var roll = g.rng.randf() * total
	var pick = pool[0]
	if OS.get_environment("CBR_EVENT") != "":
		apply_event(OS.get_environment("CBR_EVENT"))
		return
	for id in pool:
		roll -= float(EVENT_WEIGHTS[id])
		if roll <= 0.0:
			pick = id
			break
	apply_event(pick)

func apply_event(id):
	var ev = L.MARKET_EVENTS.get(id, null)
	if ev == null:
		return
	var vars = {}
	var fx = {}
	match id:
		"tv_crew":
			var cat = g.CATEGORIES[g.rng.randi_range(0, g.CATEGORIES.size() - 1)]
			vars["cat"] = cat
			fx["hype_cat"] = cat
			for s in g.stalls:
				for it in s["stock"]:
					if it["category"] == cat:
						it["asking"] = max(1.0, round(float(it["asking"]) * 1.3))
			g.current_trends[cat] = float(g.current_trends.get(cat, 1.0)) + 0.12
		"cloudburst":
			fx["haggle"] = 0.12
			fx["after"] = 10 * 60 + 30
			for s in g.stalls:
				s["packing_minute"] = min(int(s["packing_minute"]), g.rng.randi_range(10 * 60 + 40, 11 * 60 + 20))
		"kids_stall":
			var nm = g.pick_line(["Poppy", "Alfie", "Maisie", "Theo", "Ruby", "Ollie", "Freya", "Archie"])
			vars["name"] = nm
			var st = extra_stall("Clueless Seller", nm, "%s (aged 9)" % nm, ["Games", "Collectables", "Trading Cards", "Books"])
			st["no_haggle"] = true
			st["greeting"] = "Everything's priced. I've checked online. No haggling, please."
		"late_van":
			fx["late_van"] = 10 * 60
		"dealers_at_dawn":
			for s in g.stalls:
				var best = -1
				var bv = 0.0
				for j in range(min(int(s["revealed"]), s["stock"].size())):
					var r = float(s["stock"][j]["true_value"]) / max(1.0, float(s["stock"][j]["asking"]))
					if r > bv:
						bv = r
						best = j
				if best >= 0 and bv > 1.4:
					s["stock"].remove_at(best)
					s["revealed"] = max(0, int(s["revealed"]) - 1)
		"lost_dog":
			fx["lost_dog"] = true
		"charity_stall":
			var st2 = extra_stall("Clueless Seller", "Hospice", "The Hospice Stall", ["Books", "Home", "Clothing", "Collectables"])
			st2["no_haggle"] = true
			st2["charity"] = true
			st2["greeting"] = "Everything's a pound or two, love. It all goes to the hospice."
			# Donations are mostly bric-a-brac: nothing on this table is worth much, and it's all a pound or two.
			var cheap = []
			for it in st2["stock"]:
				if float(it["true_value"]) < 30.0 and cheap.size() < 8:
					cheap.append(it)
			st2["stock"] = cheap
			st2["revealed"] = min(int(st2["revealed"]), cheap.size())
			for it in cheap:
				it["asking"] = float(g.rng.randi_range(1, 3))
		"trading_standards":
			var keep = []
			for s in g.stalls:
				if s["seller"] != "Dodgy Seller":
					keep.append(s)
			if keep.size() >= 3:
				g.stalls.clear()
				for s in keep:
					g.stalls.append(s)
		"brass_band":
			fx["haggle"] = -0.04
			g.market_today["rival_here"] = true
		"heatwave_ices":
			fx["haggle"] = 0.06
		"retired_dealer":
			var st3 = extra_stall("Dealer", "Reg", "Reg Hollis (retiring)", ["Collectables", "Jewellery", "Cameras", "Books", "Home"], 2.4)
			st3["greeting"] = "Forty-one years. Last boot sale. Everything's got a story and a proper price."
	var text = g.fill_line(g.pick_line(ev["texts"]), vars)
	g.market_today["event"] = {"id": id, "title": ev["title"], "text": text, "fx": fx}

func extra_stall(arch, first, full, cats, rarity = 1.0):
	var reg = g.make_regular(arch)
	reg["id"] = -1
	reg["first"] = first
	reg["name"] = full
	reg["cats"] = cats
	var mfx = g.MARKET_FX.get(str(g.market_today.get("type", "regular")), g.MARKET_FX["regular"]).duplicate()
	mfx["rarity"] = float(mfx["rarity"]) * rarity
	var wfx = g.WEATHER_FX.get(str(g.market_today.get("weather", "overcast")), g.WEATHER_FX["overcast"])
	var s = g.build_stall(reg, mfx, wfx)
	s["special"] = true
	g.stalls.append(s)
	return s

func event_tick():
	# Time-based event beats, called as the clock moves.
	var ev = g.market_today.get("event", {})
	if typeof(ev) != TYPE_DICTIONARY or ev.size() == 0:
		return
	var fx = ev.get("fx", {})
	if fx.has("late_van") and not fx.get("late_done", false) and g.current_time_minutes >= int(fx["late_van"]):
		fx["late_done"] = true
		var s = extra_stall("House Clearance", "Mick", "Mick's Clearance Van", ["Home", "Tools", "Books", "Vinyl", "Collectables"])
		s["packing_minute"] = 12 * 60
		s["greeting"] = "Just got here. Whole house in the back. Grab a box, make an offer."
		g.add_toast("A clearance van has just pulled onto the field.", "info")

func help_lost_dog():
	var ev = g.market_today.get("event", {})
	var fx = ev.get("fx", {})
	if not fx.get("lost_dog", false) or fx.get("dog_done", false):
		return
	if g.energy < 5:
		g.queue_popup("You need 5 energy.")
		return
	g.energy -= 5
	g.spend_time(15)
	fx["dog_done"] = true
	# The owner is one of the sellers here, and they won't forget it.
	var cands = []
	for s in g.stalls:
		if int(s.get("regular_id", -1)) >= 0 and g.current_time_minutes < int(s["packing_minute"]):
			cands.append(s)
	if cands.size() == 0:
		g.add_toast("You walk the dog round the whole field. A woman from the next village claims the dog, and gives you a tenner.", "success")
		g.cash += 10.0
	else:
		var s = cands[g.rng.randi_range(0, cands.size() - 1)]
		var r = g.regular_by_id(int(s["regular_id"]))
		if r != null:
			r["rel"] = min(100.0, float(r["rel"]) + 18.0)
		s["last_line"] = "You found Biscuit! Oh, thank you. Anything on the table, you get a friend's price. And I won't forget this."
		for it in s["stock"]:
			if not it.get("haggle_attempted", false):
				it["asking"] = max(1.0, round(float(it["asking"]) * 0.8))
		g.add_toast("The dog belongs to %s. They're overjoyed: 20%% off their whole stall today." % s["seller_display_name"], "success")
	g.play_sfx("confirm")
	g.show_market()
