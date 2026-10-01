extends RefCounted
# Chances you can see (0.13). Every gamble in the game shows its odds up front and the
# roll it actually hit afterwards: research digs, long shots on clues, repairs, cleaning,
# the Fixer, mystery boxes, coin tosses with chancers, and the tombola.
#
# Rolls go through roll() so the luck record (Journal → Luck) stays honest.

var g

func _init(main):
	g = main

func st():
	var d = g.world.st()
	if not d.has("luck"):
		d["luck"] = {"rolls": 0, "hits": 0, "expected": 0.0, "best": {}, "worst": {}, "by": {}}
	return d["luck"]

# =============================================================================
# The roll
# =============================================================================
func roll(kind, chance, label = ""):
	# One visible roll. Returns {chance, roll, hit, label}. Rolls are 1–100 for display.
	chance = clamp(float(chance), 0.0, 1.0)
	var r = g.rng.randf()
	if OS.has_environment("CBR_FORCE_ROLL"):
		# Test hook: screenshots of rare outcomes.
		r = clamp(float(OS.get_environment("CBR_FORCE_ROLL")), 0.0, 0.999)
	var hit = r < chance
	var L = st()
	L["rolls"] = int(L["rolls"]) + 1
	L["expected"] = float(L["expected"]) + chance
	if hit:
		L["hits"] = int(L["hits"]) + 1
	var by = L["by"]
	if not by.has(kind):
		by[kind] = {"rolls": 0, "hits": 0, "expected": 0.0}
	by[kind]["rolls"] = int(by[kind]["rolls"]) + 1
	by[kind]["expected"] = float(by[kind]["expected"]) + chance
	if hit:
		by[kind]["hits"] = int(by[kind]["hits"]) + 1
	var what = label if label != "" else kind
	# Luckiest hit = the least likely thing that came off; unluckiest miss = the surest thing that didn't.
	if hit and (L["best"].size() == 0 or chance < float(L["best"]["chance"])):
		L["best"] = {"chance": chance, "text": what, "day": g.day}
	if not hit and (L["worst"].size() == 0 or chance > float(L["worst"]["chance"])):
		L["worst"] = {"chance": chance, "text": what, "day": g.day}
	g.record_rng("%s | Under %s to hit | Rolled %s | %s" % [what, pct_text(chance), roll_text(r), "HIT" if hit else "miss"], false)
	return {"chance": chance, "roll": r, "hit": hit, "label": what}

func roll_display(r):
	return clamp(int(floor(float(r) * 100.0)) + 1, 1, 100)

func roll_text(r):
	# Rolls are shown as 0.0–99.9: lower is better. "Under 62" means 62% chance.
	return "%.1f" % clamp(float(r) * 100.0, 0.0, 99.9)

func pct_text(c):
	var v = float(c) * 100.0
	if abs(v - round(v)) < 0.05:
		return "%d" % int(round(v))
	return "%.1f" % v

func band_of(r, bands) -> Variant:
	# Bands run best-first, each [name, upto, colour, what you get]. Returns the band hit, or null.
	for b in bands:
		if float(r) < float(b[1]):
			return b
	return null

func tier_bands(e, bands, miss_text):
	# Attach outcome tiers to a roll entry so the card can show them before the marker lands.
	e["bands"] = bands
	e["miss_text"] = miss_text
	var b = band_of(e["roll"], bands)
	e["band"] = str(b[0]) if b != null else ""
	return e

# =============================================================================
# Digging: research and deep research as visible rolls
# =============================================================================
const LONG_SHOT = {"research": {"deep": 0.18, "expert": 0.12, "eye": 0.12, "uv": 0.06, "clean": 0.08, "test": 0.0, "condition": 0.0, "look": 0.0, "sort": 0.0},
	"deep": {"expert": 0.22, "eye": 0.22, "uv": 0.12, "clean": 0.15, "test": 0.0, "condition": 0.0, "look": 0.0, "sort": 0.0}}

func find_chance(item, method):
	# Chance this dig turns up the details it's built to find.
	var tier = float(g.expertise_tier(item["category"]))
	var lib = 0.08 if g.has_equip("library") else 0.0
	if method == "research":
		return clamp(0.62 + 0.07 * tier + lib, 0.05, 0.95)
	return clamp(0.68 + 0.06 * tier + lib, 0.05, 0.96)

func long_shot_chance(item, method, d):
	var rv = str(d.get("reveal", ""))
	var base = float(LONG_SHOT.get(method, {}).get(rv, 0.0))
	if base <= 0.0:
		return 0.0
	var tier = float(g.expertise_tier(item["category"]))
	return clamp(base + (0.03 if method == "research" else 0.05) * tier - 0.02 * max(0.0, float(d.get("tier", 1)) - 1.0), 0.02, 0.6)

func dig_targets(item, method):
	# Unknown details this method finds outright (on a hit).
	var out = []
	var methods = ["research"] if method == "research" else ["deep", "research"]
	for t in item.get("traits", []):
		if t.get("known", false):
			continue
		var d = g.trait_def(t)
		if d == null:
			continue
		for m in methods:
			if g.trait_can_reveal(item, d, m):
				out.append(t)
				break
	return out

func best_long_shot(item, method):
	# The open clue this dig has the best long-shot chance at: [trait, chance] or [null, 0].
	var best = null
	var bc = 0.0
	for t in item.get("traits", []):
		if t.get("known", false) or not t.get("clue", false):
			continue
		var d = g.trait_def(t)
		if d == null:
			continue
		if dig_targets(item, method).has(t):
			continue
		var c = long_shot_chance(item, method, d)
		if c > bc:
			bc = c
			best = t
	return [best, bc]

func dig_tries(item, method):
	return int(item.get("dig_" + method, 0))

func dig_cost(item, method):
	var n = dig_tries(item, method)
	if method == "research":
		return g.research_cost() + 2.0 * float(n)
	return round(g.deep_research_cost(item) * (1.0 + 0.5 * float(n)))

func dig_energy(method):
	return 2 if method == "research" else 10

func can_dig_again(item, method):
	# Worth another go if the main roll missed, or there's an open clue to take a long shot at.
	if method == "research" and not item["basic_researched"]:
		return false
	if method == "deep" and not item["deep_researched"]:
		return false
	if not item.get("dig_hit_" + method, false):
		return true
	return best_long_shot(item, method)[1] > 0.0

# Inside the find zone sit two rarer outcomes: the lower you roll, the better.
const DIG_RARE = 0.10
const DIG_JACKPOT = 0.02

func dig_bands(item, method, fc):
	var what = "what research can find" if method == "research" else "what the books can find"
	return [["Jackpot", DIG_JACKPOT, "purple", "every hidden detail on it, and your fee back"],
		["Rare find", DIG_RARE, "gold", "that, plus one more hidden detail (or your fee back)"],
		["Find", fc, "green", what]]

func do_dig(item, method, where, fee = 0.0):
	# The rolls for one dig. Returns the roll entries for the card and the traits found.
	var entries = []
	var found = []
	var bonus = ""
	item["dig_" + method] = dig_tries(item, method) + 1
	if not item.get("dig_hit_" + method, false):
		var fc = find_chance(item, method)
		var r = roll(method, fc, "%s: find what's there" % ("Research" if method == "research" else "Deep research"))
		r["label"] = "Find what's there"
		tier_bands(r, dig_bands(item, method, fc), "nothing this time")
		entries.append(r)
		if r["hit"]:
			item["dig_hit_" + method] = true
			for t in dig_targets(item, method):
				t["known"] = true
				t["clue"] = true
				found.append(t)
			if r["band"] == "Jackpot" or r["band"] == "Rare find":
				var extra = []
				for t in item.get("traits", []):
					if not t.get("known", false) and g.trait_def(t) != null:
						extra.append(t)
				if r["band"] == "Rare find" and extra.size() > 1:
					# Clues first: the thing you were wondering about.
					var pick = extra[g.rng.randi_range(0, extra.size() - 1)]
					for t in extra:
						if t.get("clue", false):
							pick = t
							break
					extra = [pick]
				for t in extra:
					t["known"] = true
					t["clue"] = true
					found.append(t)
				if (r["band"] == "Jackpot" or extra.size() == 0) and fee > 0.0:
					g.cash += fee
					item["extra_spend"] = max(0.0, float(item["extra_spend"]) - fee)
					g.day_stats["research"] = float(g.day_stats.get("research", 0.0)) - fee
					bonus = "Fee back (%s)." % g.fmt_money(fee)
				g.hist(item, "%s on the %s roll." % [r["band"], "research" if method == "research" else "deep research"])
		else:
			# You still notice there's something there, if there is.
			for t in dig_targets(item, method):
				var d = g.trait_def(t)
				if d != null and str(d.get("clue", "")) != "":
					t["clue"] = true
	var ls = best_long_shot(item, method)
	if ls[0] != null and float(ls[1]) > 0.0:
		var r2 = roll(method + "_long", float(ls[1]), "Long shot on a clue")
		r2["label"] = "Long shot on the clue"
		tier_bands(r2, [["Cracked it", float(ls[1]), "gold", "the clue gives up its secret"]], "the clue stays a mystery")
		entries.append(r2)
		if r2["hit"]:
			ls[0]["known"] = true
			found.append(ls[0])
	for t in found:
		g.on_trait_found(item, t, method)
	return {"entries": entries, "found": found, "bonus": bonus}

func dig_result_text(item, method, res):
	var t0 = _dig_result_text(item, method, res)
	if str(res.get("bonus", "")) != "":
		t0 += (" " if t0.ends_with(".") else ". ") + str(res["bonus"])
	return t0

func _dig_result_text(item, method, res):
	var found = res["found"]
	if found.size() > 0:
		var names = []
		for t in found:
			var d = g.trait_def(t)
			if d != null:
				names.append("%s (%s%d%%)" % [d["name"], "+" if float(t["mult"]) >= 1.0 else "", g.trait_value_pct(t)])
		return "Found: " + ", ".join(names)
	var main_hit = false
	for e in res["entries"]:
		if e["label"] == "Find what's there" and e["hit"]:
			main_hit = true
	if main_hit:
		return "Nothing hidden that %s can turn up." % ("research" if method == "research" else "the books")
	if res["entries"].size() > 0 and res["entries"][0]["label"] == "Find what's there" and not res["entries"][0]["hit"]:
		return "Nothing turned up this time. Dig again?"
	return "No luck with the long shot."

func clue_odds_text(item):
	# For the item card: what each method gives you on the open clue.
	var out = []
	var r = best_long_shot(item, "research")
	var dd = best_long_shot(item, "deep")
	var direct_r = false
	var direct_d = false
	for t in item.get("traits", []):
		if t.get("clue", false) and not t.get("known", false):
			var d = g.trait_def(t)
			if d == null:
				continue
			if g.trait_can_reveal(item, d, "research"):
				direct_r = true
			if g.trait_can_reveal(item, d, "deep") or g.trait_can_reveal(item, d, "research"):
				direct_d = true
	if direct_r:
		out.append("Research %d%%" % int(round(find_chance(item, "research") * 100.0)))
	elif float(r[1]) > 0.0:
		out.append("Research %d%% (long shot)" % int(round(float(r[1]) * 100.0)))
	if direct_d:
		out.append("Deep research %d%%" % int(round(find_chance(item, "deep") * 100.0)))
	elif float(dd[1]) > 0.0:
		out.append("Deep research %d%% (long shot)" % int(round(float(dd[1]) * 100.0)))
	return ", ".join(out)

# =============================================================================
# Toss you for it
# =============================================================================
const CHANCERS = ["flash_lad", "wheeler_dealer", "chaos_gremlin", "ex_market_trader", "skint_student", "clearance_man"]
const TOSS_LINES = ["Tell you what. Toss you for it. Heads, half price. Tails, you pay a bit over.", "Fancy a flutter? Coin says half price, or you pay me extra. Go on.", "I'm a gambling man. Call it: half price or a quarter over."]

func can_toss(item, stall):
	return CHANCERS.has(str(stall.get("personality", ""))) and not stall.get("tossed_today", false) and g.haggle_open(item, stall) and float(item["asking"]) >= 6.0

func toss(index):
	if not g.valid_stall_index(index):
		return
	var stall = g.stalls[g.current_stall_index]
	var item = stall["stock"][index]
	if not can_toss(item, stall):
		return
	var ask = float(item["asking"])
	var worst = round(ask * 1.25)
	if g.cash < worst:
		g.queue_popup("You'd need %s on you in case it's tails." % g.fmt_money(worst))
		return
	if not g.can_carry(item) or not g.can_store(item):
		g.queue_popup("You couldn't take it home if you won.")
		return
	stall["tossed_today"] = true
	g.spend_time(1)
	var r = roll("toss", 0.5, "Coin toss for the %s" % g.lc(item["name"]))
	r["label"] = "Heads or tails?"
	tier_bands(r, [["On its edge", 0.02, "purple", "he's so shocked he lets it go for a quid"], ["Heads", 0.5, "green", "half price (%s)" % g.fmt_money(round(ask * 0.5))]], "tails: you pay %s" % g.fmt_money(worst))
	var edge = r["band"] == "On its edge"
	var price = (1.0 if edge else round(ask * 0.5)) if r["hit"] else worst
	item["asking"] = max(1.0, price)
	item["haggle_result"] = "accepted"
	item["haggle_savings"] = ask - price
	item["haggle_note"] = "\"%s\"" % ("On its EDGE? I've never... take it. A quid." if edge else ("Heads! Fair's fair. Half price." if r["hit"] else "Tails. Unlucky, pal. Pay the man."))
	g.show_roll("TOSS YOU FOR IT", [r], ("It landed on its edge! %s for the %s." % [g.fmt_money(price), g.lc(item["name"])]) if edge else ("Heads! %s for the %s (was %s)." % [g.fmt_money(price), g.lc(item["name"]), g.fmt_money(ask)]) if r["hit"] else ("Tails. %s for the %s." % [g.fmt_money(price), g.lc(item["name"])]))
	g.buy_item(index)

# =============================================================================
# The tombola
# =============================================================================
const TOMBOLA_PRICE = 3.0
const TOMBOLA_WIN = 0.14
const TOMBOLA_STAR = 0.012

func tombola_here():
	var ev = g.market_today.get("event", {})
	return (typeof(ev) == TYPE_DICTIONARY and str(ev.get("id", "")) == "tombola") or str(g.market_today.get("type", "")) == "village_fete"

func tombola_left():
	return 10 - int(g.market_today.get("tombola_used", 0))

func play_tombola(tickets):
	if not tombola_here() or g.current_time_minutes >= 12 * 60:
		return
	tickets = min(tickets, tombola_left())
	if tickets <= 0:
		g.queue_popup("They've sold out of tickets.")
		return
	if g.cash < TOMBOLA_PRICE * tickets:
		g.queue_popup("Not enough cash.")
		return
	g.cash -= TOMBOLA_PRICE * tickets
	g.day_stats["other_income"] = float(g.day_stats.get("other_income", 0.0)) - TOMBOLA_PRICE * tickets
	g.market_today["tombola_used"] = int(g.market_today.get("tombola_used", 0)) + tickets
	var entries = []
	var prizes = []
	for i in range(tickets):
		var r = roll("tombola", TOMBOLA_WIN + TOMBOLA_STAR, "Tombola ticket")
		# Bands: star prize at the very bottom of the hit zone.
		tier_bands(r, [["Star prize", TOMBOLA_STAR, "gold", "something worth £120 or more"], ["Prize", TOMBOLA_WIN + TOMBOLA_STAR, "green", "a small prize (up to £45)"]], "a blank: it's for the hospice")
		r["label"] = "Ticket %d" % (i + 1)
		entries.append(r)
		if r["hit"]:
			var star = r["band"] == "Star prize"
			var it = tombola_prize(star)
			if it != null:
				prizes.append(it)
	var text = "No luck. It's for the hospice, at least."
	if prizes.size() > 0:
		var names = []
		for it in prizes:
			names.append(g.item_display_name(it) if str(it.get("ident", "")) != "" else it["name"])
		text = "You won: " + ", ".join(names) + ". It's in your stock."
	g.show_roll("THE TOMBOLA", entries, text)
	g.save_game()
	g.show_market()

func tombola_prize(star):
	var cands = []
	for f in g.item_families:
		var fs = str(f.get("season", ""))
		if fs != "" and fs != g.get_season_name():
			continue
		if star and float(f["value"][1]) >= 120.0:
			cands.append(f)
		elif not star and float(f["value"][1]) <= 45.0 and str(f.get("size", "small")) != "large":
			cands.append(f)
	if cands.size() == 0:
		return null
	var fam = cands[g.rng.randi_range(0, cands.size() - 1)]
	var it = g.make_item_from_family(fam, "Clueless Seller", {"rarity_boost": 6.0 if star else 1.0})
	it["paid"] = 0.0
	it["asking"] = 0.0
	it["source"] = "tombola"
	it["story"] = "Won on the tombola, ticket and all."
	g.hist(it, "Won on the tombola%s." % (" (the star prize!)" if star else ""))
	g.inventory.append(it)
	g.register_collection(it)
	return it
