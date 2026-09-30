extends RefCounted
# Bigger games for bigger businesses (0.12):
#   The Saleroom    a weekly trade auction. Six to eight lots, sealed maximum bids,
#                   a 20% buyer's premium. The room knows what the auctioneer knows;
#                   you know what your expertise lets you see. That's the edge.
#   Bubbles         now and then a category gets hot: a rumour, a boom, a crash.
#   Estate sales    large house clearances go to sealed bids against Gaz and a dealer.
# State lives in main.w2 so it saves with the game.

var g

func _init(main):
	g = main

func st():
	var d = g.world.st()
	if not d.has("saleroom"):
		d["saleroom"] = {"day": -1, "lots": [], "results": []}
	if not d.has("bubble"):
		d["bubble"] = {}
	if not d.has("bubble_next"):
		d["bubble_next"] = 24
	return d

# =============================================================================
# The Saleroom
# =============================================================================
const SALE_WEEKDAY = 5   # day % 7
const PREMIUM = 0.20
const DEALER_NAMES = ["Harcourt & Lyle", "Mrs Ferrand (Ferrand Antiques)", "Two lads from Leeds", "A phone bidder", "A dealer from Ludlow", "The man in the tweed cap", "Pemberton-Hayes (Gaz)", "An online bidder", "A collector from Harrogate"]

func saleroom_unlocked():
	return g.player_level >= 6 or g.premises_level >= 1

func saleroom_today():
	return saleroom_unlocked() and g.day % 7 == SALE_WEEKDAY

func ensure_catalogue():
	var sr = st()["saleroom"]
	if int(sr["day"]) == g.day or not saleroom_today():
		return
	sr["day"] = g.day
	sr["lots"] = []
	var n = 6 + (2 if g.premises_level >= 2 else 0)
	var saved_seed = g.rng.seed
	var saved_state = g.rng.state
	g.rng.seed = hash([int(g.run_seed), g.day, "saleroom"])
	for i in range(n):
		var fam = pick_lot_family()
		if fam == null:
			continue
		var it = g.make_item_from_family(fam, "Dealer", {"rarity_boost": 2.2, "trait_bias": 0.03})
		it["source"] = "saleroom"
		# The auctioneer's catalogue: condition and anything obvious are disclosed.
		it["condition_checked"] = true
		it["quick_look_done"] = true
		if it["testable"]:
			it["tested"] = true
		g.reveal_traits_quiet(it, ["look", "condition", "test", "research"])
		var auction_view = g.known_value(it)
		var est = [round(auction_view * g.rng.randf_range(0.7, 0.85) / 5.0) * 5.0, round(auction_view * g.rng.randf_range(1.1, 1.3) / 5.0) * 5.0]
		est[0] = max(10.0, est[0])
		est[1] = max(est[0] + 10.0, est[1])
		# The room: dealers who know what the auctioneer knows, and sometimes one who knows more.
		var room = auction_view * g.rng.randf_range(0.72, 1.08)
		if g.rng.randf() < 0.3:
			room = max(room, g.true_market_value(it) * g.rng.randf_range(0.8, 0.98))
		var reserve = est[0] * 0.8
		sr["lots"].append({"lot": i + 1, "item": it, "est": est, "room": room, "reserve": reserve, "bid": 0.0, "bidder": DEALER_NAMES[g.rng.randi_range(0, DEALER_NAMES.size() - 1)]})
	g.rng.seed = saved_seed
	g.rng.state = saved_state
	# What *you* can see in the catalogue depends on what you know.
	for lot in sr["lots"]:
		your_read(lot["item"])

func pick_lot_family():
	var season = g.get_season_name()
	var cands = []
	for f in g.item_families:
		var fs = str(f.get("season", ""))
		if fs != "" and fs != season:
			continue
		if float(f["value"][1]) < 60.0:
			continue
		cands.append(f)
	if cands.size() == 0:
		return null
	return cands[g.rng.randi_range(0, cands.size() - 1)]

func your_read(it):
	var t = g.expertise_tier(it["category"])
	var methods = []
	if t >= 1:
		methods.append("eye")
	if t >= 2:
		methods.append("expert")
	if t >= 3:
		methods.append_array(["deep", "clean"])
	if t >= 4:
		methods.append("uv")
		if float(it["fake_chance"]) > 0.0:
			it["auth_status"] = "Confirmed Genuine" if it["authentic"] else "Confirmed Counterfeit"
			if not it["authentic"]:
				it["identified_mult"] = float(it["identified_mult"]) * 0.10
	g.reveal_traits_quiet(it, methods)
	it["basic_researched"] = true
	it["basic_comps"] = g.make_comps(it, t >= 3)
	if t >= 3:
		it["deep_researched"] = true

func set_bid(lot_no, amount):
	var sr = st()["saleroom"]
	for lot in sr["lots"]:
		if int(lot["lot"]) == int(lot_no):
			lot["bid"] = max(0.0, round(float(amount)))
	g.save_game()

func bids_total():
	var t = 0.0
	for lot in st()["saleroom"]["lots"]:
		t += float(lot["bid"])
	return t * (1.0 + PREMIUM)

func bids_space():
	var n = 0
	for lot in st()["saleroom"]["lots"]:
		if float(lot["bid"]) > 0.0:
			n += g.size_units(lot["item"])
	return n

func resolve_saleroom():
	# The hammer falls overnight on sale day.
	var sr = st()["saleroom"]
	if int(sr["day"]) != g.day or sr["lots"].size() == 0:
		return
	var results = []
	var any_bid = false
	for lot in sr["lots"]:
		var it = lot["item"]
		var mine = float(lot["bid"])
		var room = float(lot["room"])
		var reserve = float(lot["reserve"])
		var line = {"lot": lot["lot"], "name": it["name"], "ident": g.item_display_name(it)}
		if mine > 0.0:
			any_bid = true
		var need = max(room, reserve)
		if mine >= need + 1.0 and g.can_store(it):
			var hammer = min(mine, round(max(reserve, room + max(1.0, room * 0.05))))
			var cost = round(hammer * (1.0 + PREMIUM))
			if g.cash >= cost:
				g.cash -= cost
				g.day_stats["buy_spend"] += cost
				g.day_stats["items_bought"] += 1
				it["paid"] = cost
				it["asking"] = hammer
				it["bought_day"] = g.day
				g.hist(it, "Won at the saleroom, lot %d: hammer %s, %s with premium." % [int(lot["lot"]), g.fmt_money(hammer), g.fmt_money(cost)])
				g.inventory.append(it)
				g.register_collection(it)
				line["won"] = true
				line["price"] = cost
				st()["saleroom_wins"] = int(st().get("saleroom_wins", 0)) + 1
				g.night_events.append({"kind": "info", "text": "Saleroom: you won lot %d, %s" % [int(lot["lot"]), g.item_display_name(it)], "sub": "Hammer %s, %s with the buyer's premium. It's in your stock." % [g.fmt_money(hammer), g.fmt_money(cost)]})
				results.append(line)
				continue
			line["reason"] = "you couldn't cover it"
		if room >= reserve:
			line["sold_to"] = lot["bidder"]
			line["price"] = round(room)
		else:
			line["unsold"] = true
		if mine > 0.0:
			g.night_events.append({"kind": "bad", "text": "Saleroom: lot %d went elsewhere" % int(lot["lot"]), "sub": "%s. Your bid %s; it made %s." % [g.item_display_name(it), g.fmt_money(mine), g.fmt_money(room)] if not line.has("unsold") else "%s didn't reach its reserve." % g.item_display_name(it)})
		results.append(line)
	sr["results"] = results
	sr["lots"] = []
	if any_bid:
		g.add_journal("Went to the saleroom.", "info")

func saleroom_card_info():
	var sr = st()["saleroom"]
	return {"lots": sr["lots"].size(), "bids": bids_total()}

# =============================================================================
# Bubbles
# =============================================================================
const BUBBLE_TEXT = {
	"rumour": ["Collectors are quietly buying up %s. Something's brewing.", "A dealer in Harrogate swears %s is about to go big. He's been right before. Once.", "Three separate people asked you about %s this week. Odd."],
	"boom": ["%s FEVER: prices through the roof. Everyone's an expert now.", "The papers have noticed %s. Buyers are paying silly money.", "%s is the hottest thing going. It can't last. Can it?"],
	"crash": ["The %s bubble has burst. Everyone's selling at once.", "%s prices have fallen off a cliff. Somebody always holds the parcel.", "Buyers have moved on from %s. Warehouses are full of the stuff."],
}
const BUBBLE_MULT = {"rumour": 1.08, "boom1": 1.35, "boom2": 1.6, "crash1": 0.66, "crash2": 0.82}
const BUBBLE_ORDER = ["rumour", "boom1", "boom2", "crash1", "crash2"]

func weekly_bubble():
	# Called when the weekly trends roll over.
	var d = st()
	var b = d["bubble"]
	if b.size() > 0:
		var i = BUBBLE_ORDER.find(str(b["phase"]))
		if i < 0 or i >= BUBBLE_ORDER.size() - 1:
			d["bubble"] = {}
			d["bubble_next"] = g.day + g.rng.randi_range(21, 42)
			return
		b["phase"] = BUBBLE_ORDER[i + 1]
		announce(b)
		return
	if g.day >= int(d["bubble_next"]) and g.rng.randf() < 0.6:
		var cat = g.CATEGORIES[g.rng.randi_range(0, g.CATEGORIES.size() - 1)]
		d["bubble"] = {"cat": cat, "phase": "rumour", "start": g.day}
		announce(d["bubble"])

func announce(b):
	var ph = str(b["phase"])
	var key = "rumour" if ph == "rumour" else ("boom" if ph.begins_with("boom") else "crash")
	var line = g.pick_line(BUBBLE_TEXT[key]) % str(b["cat"])
	b["text"] = line
	g.trend_headlines.push_front(line)
	g.add_journal(line, "info")

func bubble_mult(cat):
	var b = st()["bubble"]
	if b.size() == 0 or str(b.get("cat", "")) != cat:
		return 1.0
	return float(BUBBLE_MULT.get(str(b["phase"]), 1.0))

func bubble_label():
	var b = st()["bubble"]
	if b.size() == 0:
		return ""
	var ph = str(b["phase"])
	if ph == "rumour":
		return "Whispers about %s" % b["cat"]
	if ph.begins_with("boom"):
		return "%s boom" % b["cat"]
	return "%s crash" % b["cat"]

# =============================================================================
# Estate sales: sealed bids on the big houses
# =============================================================================
func is_estate(clr):
	return clr != null and str(clr["lead"].get("size", "")) == "large"

func estate_rivals(clr):
	# Two sealed bids against yours: Gaz and a dealer. They've had a look round too.
	if clr.has("rivals"):
		return clr["rivals"]
	var total = 0.0
	for it in clr["items"]:
		total += g.true_market_value(it)
	var saved_seed = g.rng.seed
	var saved_state = g.rng.state
	g.rng.seed = int(clr["lead"]["seed"]) + 17
	var dealer = DEALER_NAMES[g.rng.randi_range(0, DEALER_NAMES.size() - 3)]
	var rivals = [
		{"name": str(g.rival.get("nickname", "Gaz")), "bid": round(total * g.rng.randf_range(0.42, 0.82) / 5.0) * 5.0},
		{"name": dealer, "bid": round(total * g.rng.randf_range(0.38, 0.78) / 5.0) * 5.0},
	]
	g.rng.seed = saved_seed
	g.rng.state = saved_state
	clr["rivals"] = rivals
	return rivals

func submit_estate_bid(amount):
	var clr = g.clearance
	if clr == null or not is_estate(clr):
		return
	amount = round(float(amount))
	if amount < 50.0:
		g.queue_popup("The executor won't look at a bid under £50.")
		return
	if g.cash < amount:
		g.queue_popup("You haven't got %s." % g.fmt_money(amount))
		return
	var need = g.clearance_space_needed()
	if g.inventory_space_used() + need > g.storage_capacity():
		g.queue_popup("You need %d free storage space for the haul (you have %d)." % [need, g.storage_capacity() - g.inventory_space_used()])
		return
	var rivals = estate_rivals(clr)
	var best = rivals[0]
	for r in rivals:
		if float(r["bid"]) > float(best["bid"]):
			best = r
	if amount > float(best["bid"]):
		clr["price"] = amount
		var line = g.pick_line(g.Lines012.RIVAL_LINES["bid_win"])
		g.add_journal("Won the estate with a sealed bid of %s. Next best: %s at %s." % [g.fmt_money(amount), best["name"], g.fmt_money(best["bid"])], "good")
		g.show_big_popup("THE HOUSE IS YOURS", "Your bid: %s. Next best: %s, %s.\n\n%s" % [g.fmt_money(amount), best["name"], g.fmt_money(best["bid"]), line], "rare")
		g.unlock_achievement("House Call")
		st()["estates_won"] = int(st().get("estates_won", 0)) + 1
		g.accept_clearance()
	else:
		var line2 = g.fill_line(g.pick_line(g.Lines012.RIVAL_LINES["bid_loss"]), {"amount": g.fmt_money(best["bid"])})
		if best["name"] != str(g.rival.get("nickname", "Gaz")):
			line2 = "The executor went with %s's bid of %s." % [best["name"], g.fmt_money(best["bid"])]
		g.add_journal("Lost the estate: %s bid %s against your %s." % [best["name"], g.fmt_money(best["bid"]), g.fmt_money(amount)], "bad")
		g.show_big_popup("OUTBID", "Your bid: %s.\n\n%s" % [g.fmt_money(amount), line2], "bad")
		g.remove_lead(int(clr["lead"]["id"]))
		g.clearance = null
		g.save_game()
		g.show_market()
