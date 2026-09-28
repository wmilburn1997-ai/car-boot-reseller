extends SceneTree
# Validates scripts/data/world.gd flavour content.
# Usage: godot --headless --path . --script tools/check_world.gd

const CATEGORIES = ["Clothing","Games","Trading Cards","Vinyl","Cameras","Tools","Electronics","Collectables","Jewellery","Books","Home","Musical Instruments","Garden & Outdoor"]
const ARCHETYPES = ["Desperate Seller","House Clearance","Clueless Seller","Regular Seller","Collector","Dodgy Seller","Dealer"]
const LINE_COUNTS = {"greet_new": 4, "greet_regular": 4, "greet_friend": 3, "accept": 4, "reject": 4, "lowball": 3, "bought": 4, "chat": 4, "saved_item": 2, "tipoff": 2}
const WEATHERS = ["sunny","overcast","drizzle","downpour","heatwave","frost","windy"]
const DAYS = ["regular","early_bird","bank_holiday","collectors_fair","village_fete","christmas_market"]
const RIVAL_LINES = {"spotted": 5, "snatch": 5, "outbid": 4, "lost": 4, "taunt": 5, "respect": 3}
const BUYER = {"happy": 15, "missed": 8, "return": 10, "shop": 10}

var errors = 0

func err(msg):
	errors += 1
	print("ERROR: ", msg)

func check_str(s, maxlen, where):
	if typeof(s) != TYPE_STRING or s.strip_edges() == "":
		err(where + ": not a non-empty string")
		return
	if s.length() > maxlen:
		err("%s: %d chars > %d: %s" % [where, s.length(), maxlen, s])

func check_arr(a, n, maxlen, where, exact = true):
	if typeof(a) != TYPE_ARRAY:
		err(where + ": not an array")
		return
	if (exact and a.size() != n) or (not exact and a.size() < n):
		err("%s: size %d, expected %s%d" % [where, a.size(), "" if exact else ">=", n])
	for i in a.size():
		check_str(a[i], maxlen, "%s[%d]" % [where, i])

func check_cat(c, where):
	if not CATEGORIES.has(c):
		err(where + ": invalid category " + str(c))

func _initialize():
	var scr = load("res://scripts/data/world.gd")
	if scr == null:
		err("could not load world.gd")
		print("RESULT errors=", errors)
		quit(1)
		return
	var k = scr.get_script_constant_map()
	for name in ["FIRST_NAMES","SURNAMES","PERSONALITIES","STALL_DRESSING","WEATHER","MARKET_DAYS","RIVAL","CLEARANCE_STORIES","NEWS","RUMOUR_SOURCES","BUYER_MESSAGES","HINTS"]:
		if not k.has(name):
			err("missing const " + name)
	if errors > 0:
		print("RESULT errors=", errors)
		quit(1)
		return

	# Names
	check_arr(k.FIRST_NAMES, 80, 20, "FIRST_NAMES")
	check_arr(k.SURNAMES, 60, 20, "SURNAMES")
	for arr_name in ["FIRST_NAMES", "SURNAMES"]:
		var seen = {}
		for n in k[arr_name]:
			if seen.has(n):
				err(arr_name + ": duplicate " + n)
			seen[n] = true

	# Personalities
	var P = k.PERSONALITIES
	if P.size() < 22 or P.size() > 28:
		err("PERSONALITIES: %d entries" % P.size())
	var arch_cover = {}
	for id in P:
		var p = P[id]
		var w = "PERSONALITIES." + id
		check_str(p.get("name"), 22, w + ".name")
		check_str(p.get("blurb"), 90, w + ".blurb")
		var ar = p.get("archetypes", [])
		if ar.size() == 0:
			err(w + ": no archetypes")
		for a in ar:
			if not ARCHETYPES.has(a):
				err(w + ": bad archetype " + str(a))
			arch_cover[a] = true
		var cats = p.get("cats", [])
		if cats.size() < 2 or cats.size() > 4:
			err(w + ": cats size %d" % cats.size())
		for c in cats:
			check_cat(c, w + ".cats")
		var hm = p.get("haggle_mod", 99.0)
		var pm = p.get("price_mod", 99.0)
		var km = p.get("knowledge_mod", 99.0)
		if typeof(hm) != TYPE_FLOAT or hm < -0.12 or hm > 0.12:
			err(w + ": haggle_mod " + str(hm))
		if typeof(pm) != TYPE_FLOAT or pm < 0.85 or pm > 1.15:
			err(w + ": price_mod " + str(pm))
		if typeof(km) != TYPE_FLOAT or km < -0.15 or km > 0.15:
			err(w + ": knowledge_mod " + str(km))
		var lines = p.get("lines", {})
		for lk in LINE_COUNTS:
			check_arr(lines.get(lk), LINE_COUNTS[lk], 110, w + ".lines." + lk)
		for lk in lines:
			if not LINE_COUNTS.has(lk):
				err(w + ": unexpected lines key " + lk)
		for s in lines.get("saved_item", []):
			if not s.contains("{item}"):
				err(w + ".saved_item missing {item}: " + s)
	for a in ARCHETYPES:
		if not arch_cover.has(a):
			err("no personality covers archetype " + a)

	# Stall dressing
	check_arr(k.STALL_DRESSING, 40, 80, "STALL_DRESSING")

	# Weather
	for wk in WEATHERS:
		if not k.WEATHER.has(wk):
			err("WEATHER missing " + wk)
			continue
		check_str(k.WEATHER[wk].get("name"), 12, "WEATHER." + wk + ".name")
		check_arr(k.WEATHER[wk].get("lines"), 5, 90, "WEATHER." + wk + ".lines")

	# Market days
	for dk in DAYS:
		if not k.MARKET_DAYS.has(dk):
			err("MARKET_DAYS missing " + dk)
			continue
		var d = k.MARKET_DAYS[dk]
		check_str(d.get("name"), 28, "MARKET_DAYS." + dk + ".name")
		check_str(d.get("venue"), 60, "MARKET_DAYS." + dk + ".venue")
		check_arr(d.get("intro"), 3, 120, "MARKET_DAYS." + dk + ".intro")
	if k.MARKET_DAYS.has("regular"):
		check_arr(k.MARKET_DAYS.regular.get("venues"), 5, 60, "MARKET_DAYS.regular.venues")

	# Rival
	var R = k.RIVAL
	check_str(R.get("name"), 40, "RIVAL.name")
	check_str(R.get("nickname"), 16, "RIVAL.nickname")
	check_str(R.get("bio"), 160, "RIVAL.bio")
	for lk in RIVAL_LINES:
		check_arr(R.get("lines", {}).get(lk), RIVAL_LINES[lk], 110, "RIVAL.lines." + lk)

	# Clearances
	var C = k.CLEARANCE_STORIES
	if C.size() != 30:
		err("CLEARANCE_STORIES: %d entries" % C.size())
	var sizes = {}
	for i in C.size():
		var c = C[i]
		var w = "CLEARANCE_STORIES[%d]" % i
		check_str(c.get("title"), 40, w + ".title")
		check_str(c.get("owner"), 40, w + ".owner")
		check_str(c.get("story"), 200, w + ".story")
		var cats = c.get("cats", {})
		if cats.size() < 3 or cats.size() > 5:
			err(w + ": cats size %d" % cats.size())
		for cat in cats:
			check_cat(cat, w + ".cats")
			var wt = cats[cat]
			if typeof(wt) != TYPE_INT or wt < 1 or wt > 5:
				err(w + ": weight " + str(wt))
		var sz = c.get("size", "")
		if not ["small", "medium", "large"].has(sz):
			err(w + ": size " + str(sz))
		sizes[sz] = sizes.get(sz, 0) + 1

	# News
	var N = k.NEWS
	if N.size() != 60:
		err("NEWS: %d entries" % N.size())
	var per = {}
	for c in CATEGORIES:
		per[c] = {"up": 0, "down": 0}
	for i in N.size():
		var n = N[i]
		check_str(n.get("text"), 100, "NEWS[%d].text" % i)
		check_cat(n.get("cat"), "NEWS[%d]" % i)
		var dir = n.get("dir", "")
		if dir != "up" and dir != "down":
			err("NEWS[%d]: dir %s" % [i, dir])
		elif per.has(n.get("cat")):
			per[n.cat][dir] += 1
	for c in CATEGORIES:
		if per[c].up + per[c].down < 3 or per[c].up == 0 or per[c].down == 0:
			err("NEWS: category %s has up=%d down=%d" % [c, per[c].up, per[c].down])

	check_arr(k.RUMOUR_SOURCES, 20, 40, "RUMOUR_SOURCES")
	for bk in BUYER:
		check_arr(k.BUYER_MESSAGES.get(bk), BUYER[bk], 90, "BUYER_MESSAGES." + bk)
	check_arr(k.HINTS, 30, 120, "HINTS")

	print("FIRST_NAMES=%d SURNAMES=%d PERSONALITIES=%d STALL_DRESSING=%d WEATHER=%d MARKET_DAYS=%d" % [k.FIRST_NAMES.size(), k.SURNAMES.size(), P.size(), k.STALL_DRESSING.size(), k.WEATHER.size(), k.MARKET_DAYS.size()])
	print("CLEARANCE_STORIES=%d sizes=%s NEWS=%d RUMOUR_SOURCES=%d HINTS=%d" % [C.size(), str(sizes), N.size(), k.RUMOUR_SOURCES.size(), k.HINTS.size()])
	print("NEWS per category: ", per)
	print("RESULT errors=", errors)
	quit(0 if errors == 0 else 1)
