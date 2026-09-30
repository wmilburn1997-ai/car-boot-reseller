extends RefCounted
# Item tiles (compact list rows) and the item detail panel, shared by stalls, stock and clearances.

var ui
var g
var k
var offer_values = {}   # uid -> haggle offer
var price_values = {}   # uid -> listing price
var footer_btn = null

func _init(root):
	ui = root
	g = root.g
	k = root.k

# ---------------------------------------------------------------------------
# Tiles
# ---------------------------------------------------------------------------
func tile(it, ctx, selected, on_press, extra = {}):
	var b = Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var border = k.LINE
	var bg = k.PANEL
	if it["rarity"] != "Common":
		border = k.rarity_color(it["rarity"]).darkened(0.35)
	if it.get("saved_for_player", false):
		border = k.GOLD.darkened(0.2)
	if selected:
		border = k.GOLD
		bg = Color(0.12, 0.13, 0.13)
	var dimmed = extra.get("dim", false)
	var st = k.sbox(bg, border, 8, 2 if selected else 1, [10, 8, 12, 8])
	b.add_theme_stylebox_override("normal", st)
	b.add_theme_stylebox_override("hover", k.sbox(bg.lightened(0.05), border.lightened(0.2), 8, 2 if selected else 1, [10, 8, 12, 8]))
	b.add_theme_stylebox_override("pressed", st)
	b.add_theme_stylebox_override("focus", k.sbox(Color(0, 0, 0, 0), null, 8, 0, 0))
	var has_ident = str(it.get("ident", "")) != ""
	b.custom_minimum_size = Vector2(0, (80 if k.mobile else 74) if has_ident else (64 if k.mobile else 58))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h = k.hbox(10)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 10
	h.offset_right = -12
	h.offset_top = 6
	h.offset_bottom = -6
	var ic = k.cat_icon(it["category"], 38 if k.mobile else 36)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if dimmed:
		ic.modulate = Color(1, 1, 1, 0.45)
	h.add_child(ic)
	var v = k.vbox(3)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_row = k.hbox(6)
	if extra.get("new", false):
		name_row.add_child(k.chip("NEW", Color(0.1, 0.1, 0.1), k.GOLD, "xs"))
	var nl = k.label(it["name"], "b", k.TEXT if not dimmed else k.TEXT3)
	nl.clip_text = true
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_row.add_child(nl)
	v.add_child(name_row)
	if str(it.get("ident", "")) != "":
		var il = k.label(str(it["ident"]), "xs", k.TEXT2 if not dimmed else k.TEXT3)
		il.clip_text = true
		il.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		il.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(il)
	v.add_child(status_row(it, ctx))
	h.add_child(v)
	var pv = k.vbox(0)
	pv.alignment = BoxContainer.ALIGNMENT_CENTER
	pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pv.custom_minimum_size = Vector2(76 if k.mobile else 90, 0)
	v.clip_contents = true
	var price_text = ""
	var price_color = k.TEXT
	var sub = ""
	var sub_color = k.TEXT3
	if ctx == "stall":
		price_text = g.fmt_money(it["asking"])
		price_color = k.GOLD if float(it["asking"]) <= g.cash else k.TEXT3
		var mg = stall_margin(it)
		if float(it["asking"]) > g.cash:
			sub = "can't afford"
			sub_color = k.TEXT3
		elif mg != null:
			sub = "%s margin" % g.money_signed(mg)
			sub_color = margin_color(mg, float(it["asking"]))
		if it["haggle_result"] == "accepted" and sub == "":
			sub = "haggled"
			sub_color = k.GREEN
		elif it["haggle_result"] == "refused":
			sub = "refused"
			sub_color = k.RED
		elif it["haggle_result"] == "countered":
			sub = "counter"
			sub_color = k.ORANGE
		elif it["haggle_result"] == "final":
			sub = "final price"
			sub_color = k.ORANGE
	elif ctx == "clearance":
		price_text = ""
	else:
		if it["listed"]:
			price_text = g.fmt_money(it["listing"])
			price_color = k.GREEN
			sub = "listed %dd" % max(0, g.day - int(it.get("listed_day", g.day)))
		elif it["auctioned"]:
			price_text = g.fmt_money(it["auction_current_bid"])
			price_color = k.PURPLE
			sub = "auction %dd" % int(it["auction_days_left"])
		elif it.get("on_shop_floor", false):
			price_text = g.fmt_money(it.get("shop_price", 0))
			price_color = k.TEAL
			sub = "in shop"
		else:
			var pot = g.estimate_identified_potential(it)
			price_text = "%s–%s" % [g.fmt_money(pot[0]), g.fmt_money(pot[1])]
			price_color = k.TEXT2
			sub = todo_hint(it)
			sub_color = k.ORANGE if sub != "ready to list" else k.GREEN
	if price_text != "":
		var pl = k.label(price_text, "m" if ctx == "stall" else "b", price_color, false, HORIZONTAL_ALIGNMENT_RIGHT)
		pv.add_child(pl)
	if sub != "":
		pv.add_child(k.label(sub, "xs", sub_color, false, HORIZONTAL_ALIGNMENT_RIGHT))
	h.add_child(pv)
	b.add_child(h)
	if on_press != null:
		b.pressed.connect(on_press)
		b.pressed.connect(func(): g.play_sfx("click"))
	return b

func todo_hint(it):
	if it["testable"] and not it["tested"]:
		return "needs test"
	if g.is_unsorted_lot(it):
		return "sort lot"
	if it["auth_status"] == "Confirmed Counterfeit":
		return "fake"
	for t in it.get("traits", []):
		if t.get("clue", false) and not t.get("known", false):
			return "clue"
	return "ready to list"

func stall_margin(it):
	# Your margin after fees at the middle of the sold prices, once researched.
	if not it["basic_researched"]:
		return null
	var med = g.comps_median_value(it)
	var costs = g.selling_costs(it, med)
	var net = med - float(costs["fee"]) - float(costs["postage"]) - float(costs["insurance"]) - float(costs["packaging"])
	return net - float(it["asking"])

func margin_color(margin, asking):
	if margin >= asking * 0.3 and margin >= 5.0:
		return k.GREEN
	if margin > 0.0:
		return k.GOLD
	return k.RED

func status_row(it, ctx):
	var row = k.hbox(6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var entries = []   # [priority (lower first), node]
	if it["rarity"] != "Common":
		entries.append([1, k.label("%s 1/%d" % [it["rarity"].to_upper(), int(it["one_in"])], "xs", k.rarity_color(it["rarity"]))])
	if g.world.commission_for(it) != null:
		entries.append([0, k.label("WANTED", "xs", k.GOLD)])
	var good = 0
	var bad = 0
	var clue = 0
	for t in it.get("traits", []):
		var d = g.trait_def(t)
		if d == null:
			continue
		if t.get("known", false):
			if d["kind"] == "good" or d["kind"] == "hidden_item":
				good += 1
			else:
				bad += 1
		elif t.get("clue", false):
			clue += 1
	if it["auth_status"] == "Confirmed Genuine":
		entries.append([6, mini_stat("check", "genuine", k.GREEN)])
	elif it["auth_status"] in ["Confirmed Counterfeit", "Suspected Counterfeit"]:
		entries.append([0, mini_stat("skull", "fake", k.RED)])
	elif float(it["fake_chance"]) >= 0.10 and ctx != "clearance":
		entries.append([2, mini_stat("skull", "risk", k.ORANGE)])
	if clue > 0:
		entries.append([2, mini_stat("q", str(clue) if clue > 1 else "", k.PURPLE)])
	if good > 0:
		entries.append([3, mini_stat("spark", str(good) if good > 1 else "", k.GREEN)])
	if bad > 0:
		entries.append([3, mini_stat("cross", str(bad) if bad > 1 else "", k.RED)])
	if it["condition_checked"]:
		entries.append([4, mini_stat("eye", "%d/10" % int(it["condition"]), cond_color(int(it["condition"])))])
	elif it["quick_look_done"]:
		entries.append([5, mini_stat("eye", "~%d" % int(it.get("perceived_condition", 6)), k.TEXT3)])
	if it["testable"]:
		if it["tested"]:
			entries.append([4, mini_stat("bolt", "", k.GREEN if not it["fault"] else k.RED)])
		else:
			entries.append([5, mini_stat("bolt", "?", k.TEXT3)])
	if it["basic_researched"]:
		entries.append([7, mini_stat("glass", "", k.BLUE)])
	if it.get("saved_for_player", false):
		entries.append([1, mini_stat("heart", "saved" if k.mobile else "saved for you", k.GOLD)])
	var trend = float(g.current_trends.get(it["category"], 1.0))
	if trend >= 1.10:
		entries.append([6, mini_stat("up", "%d%%" % int(round((trend - 1.0) * 100)), k.PURPLE)])
	elif trend <= 0.90:
		entries.append([6, mini_stat("down", "%d%%" % int(round((1.0 - trend) * 100)), k.RED)])
	entries.sort_custom(func(a, b): return a[0] < b[0])
	var cap = 4 if k.mobile else 8
	for n in range(entries.size()):
		if n < cap:
			row.add_child(entries[n][1])
		else:
			entries[n][1].free()
	if entries.size() > cap:
		row.add_child(k.label("+%d" % (entries.size() - cap), "xs", k.TEXT3))
	return row

func mini_stat(glyph_name, text, color):
	var h = k.hbox(3)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gl = k.glyph(glyph_name, color, 14 if not k.mobile else 16)
	gl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(gl)
	if text != "":
		h.add_child(k.label(text, "xs", color))
	return h

func cond_color(c):
	if c >= 8:
		return k.GREEN
	if c >= 6:
		return k.TEXT2
	if c >= 4:
		return k.ORANGE
	return k.RED

# ---------------------------------------------------------------------------
# Detail
# ---------------------------------------------------------------------------
func detail(it, ctx, index, stall = null):
	var v = k.vbox(12)
	v.add_child(header(it, ctx))
	if ctx == "stall":
		v.add_child(stall_verdict(it, index, stall))
	elif ctx == "inv":
		v.add_child(inv_verdict(it))
	v.add_child(facts(it, ctx))
	var f = findings(it, ctx)
	if f != null:
		v.add_child(f)
	if ctx == "stall":
		v.add_child(k.section("Check it over"))
		v.add_child(stall_actions(it, index))
		if stall != null and g.haggle_open(it, stall):
			v.add_child(k.section("Make an offer"))
			v.add_child(haggle_panel(it, index, stall))
		elif str(it.get("haggle_result", "")) == "final":
			v.add_child(k.label("Final price. Take it or leave it.", "s", k.ORANGE))
		elif stall != null and g.to_bool(stall.get("no_haggle", false)):
			v.add_child(k.label("Fixed prices on this stall. No haggling.", "s", k.TEXT3))
	elif ctx == "inv":
		var acts = inv_actions(it, index)
		if acts.get_child_count() > 0:
			v.add_child(k.section("Workshop"))
			v.add_child(acts)
		v.add_child(k.section("Sell"))
		v.add_child(sell_panel(it, index))
		var hp = history_panel(it)
		if hp != null:
			v.add_child(k.section("Its story so far"))
			v.add_child(hp)
	return v

func to_bool_banned(stall):
	return stall != null and g.to_bool(stall.get("banned_today", false))

func header(it, ctx):
	var v = k.vbox(6)
	var h = k.hbox(12)
	var ic = k.cat_icon(it["category"], 56 if not k.mobile else 40)
	h.add_child(ic)
	var tv = k.vbox(4)
	k.expand(tv)
	if not k.mobile:
		var name_l = k.label(it["name"], "xl", k.TEXT, true)
		tv.add_child(name_l)
	var chips = k.flow(6, 4)
	var tier = g.expertise_tier(it["category"])
	chips.add_child(k.chip("%s · %s" % [it["category"], g.EXPERTISE_TIER_NAMES[tier]], k.tier_color(tier) if tier > 0 else k.TEXT2))
	if it["rarity"] != "Common":
		chips.add_child(k.chip("%s  1 in %s" % [it["rarity"], g.fmt_int(it["one_in"])], k.rarity_color(it["rarity"])))
	chips.add_child(k.chip(g.size_text(it), k.TEXT3))
	if it.get("saved_for_player", false):
		chips.add_child(k.chip("Saved for you", k.GOLD, null, "xs", "heart"))
	if str(it.get("found_in", "")) != "":
		chips.add_child(k.chip("Found in a %s" % it["found_in"], k.GREEN, null, "xs", "spark"))
	if str(it.get("ident", "")) != "":
		tv.add_child(k.label(str(it["ident"]), "m" if not k.mobile else "b", k.TEAL, true))
	tv.add_child(chips)
	h.add_child(tv)
	v.add_child(h)
	if str(it.get("blurb", "")) != "":
		v.add_child(k.rich("[i]%s[/i]" % it["blurb"], "s", k.TEXT3))
	if str(it.get("story", "")) != "" and ctx in ["stall", "clearance"]:
		v.add_child(k.rich("[color=#d9b45a]\u201c[/color]%s[color=#d9b45a]\u201d[/color]" % str(it["story"]), "s", k.TEXT2))
	return v

func history_panel(it):
	var h = it.get("hist", [])
	if typeof(h) != TYPE_ARRAY or h.size() == 0:
		return null
	var p = k.panel("inset", 10)
	var v = k.vbox(4)
	p.add_child(v)
	if str(it.get("story", "")) != "":
		v.add_child(k.rich("[i]%s[/i]" % str(it["story"]), "xs", k.TEXT3))
	for e in h:
		var row = k.hbox(8)
		var dl = k.label("Day %d" % int(e[0]), "xs", k.TEXT3)
		dl.custom_minimum_size = Vector2(52, 0)
		row.add_child(dl)
		var tl = k.label(str(e[1]), "xs", k.TEXT2, true)
		k.expand(tl)
		row.add_child(tl)
		v.add_child(row)
	return p

func stall_verdict(it, index, stall):
	var p = k.panel("inset", 12)
	var h = k.hbox(14)
	p.add_child(h)
	var left = k.vbox(0)
	left.add_child(k.label("ASKING", "xs", k.TEXT3))
	var asking = float(it["asking"])
	left.add_child(k.label(g.fmt_money(asking), "xxl", k.GOLD))
	if it["haggle_result"] == "accepted":
		left.add_child(k.label("haggled down %s" % g.fmt_money(it["haggle_savings"]), "xs", k.GREEN))
	elif it["haggle_result"] == "countered":
		left.add_child(k.label("their counter · was %s" % g.fmt_money(it.get("orig_asking", asking)), "xs", k.ORANGE))
	elif it["haggle_result"] == "final":
		left.add_child(k.label("final price · was %s" % g.fmt_money(it.get("orig_asking", asking)), "xs", k.ORANGE))
	h.add_child(left)
	var right = k.vbox(2)
	k.expand(right)
	var pot = g.estimate_identified_potential(it)
	if it["basic_researched"]:
		var med = g.comps_median_value(it)
		var costs = g.selling_costs(it, med)
		var net = med - float(costs["fee"]) - float(costs["postage"]) - float(costs["insurance"]) - float(costs["packaging"])
		var margin = net - asking
		var c = k.GREEN if margin >= asking * 0.3 and margin >= 5.0 else (k.GOLD if margin > 0.0 else k.RED)
		var conf = confidence(it)
		var th = k.hbox(8)
		th.add_child(k.label("WORTH", "xs", k.TEXT3))
		th.add_child(k.label(conf[0], "xs", conf[1]))
		right.add_child(th)
		var mh = k.hbox(8)
		mh.add_child(k.label("%s–%s" % [g.fmt_money(pot[0]), g.fmt_money(pot[1])], "xl", k.TEAL))
		var ml = k.label("%s after fees" % g.money_signed(margin), "m", c)
		ml.size_flags_vertical = Control.SIZE_SHRINK_END
		mh.add_child(ml)
		right.add_child(mh)
		right.add_child(k.label("Sold recently: %s" % g.comps_text(it), "xs", k.TEXT3, true))
	elif g.expertise_tier(it["category"]) >= 1:
		right.add_child(k.label("YOUR GUT SAYS", "xs", k.TEXT3))
		right.add_child(k.label("%s–%s" % [g.fmt_money(pot[0]), g.fmt_money(pot[1])], "l", k.TEAL))
		var rc0 = g.research_cost()
		var rb0 = k.button("Research  %s" % (g.fmt_money(rc0) if rc0 > 0 else "free"), "action", func(): g.prebuy_research(index), "Recent sold prices for ones like this, and your margin after fees. 2 energy, 4 minutes.", "s", 0, 36)
		rb0.disabled = g.cash < rc0 or g.energy < 2
		right.add_child(rb0)
	else:
		right.add_child(k.label("THESE USUALLY SELL FOR", "xs", k.TEXT3))
		right.add_child(k.label("%s–%s" % [g.fmt_money(pot[0]), g.fmt_money(pot[1])], "l", k.TEXT2))
		var rc = g.research_cost()
		var rb = k.button("Research  %s" % (g.fmt_money(rc) if rc > 0 else "free"), "action", func(): g.prebuy_research(index), "Recent sold prices for ones like this, and your margin after fees. 2 energy, 4 minutes.", "s", 0, 36)
		rb.disabled = g.cash < rc or g.energy < 2
		right.add_child(rb)
	h.add_child(right)
	var bd = breakdown(it)
	if bd != null:
		p.remove_child(h)
		var pv = k.vbox(8)
		pv.add_child(h)
		pv.add_child(bd)
		p.add_child(pv)
	return p

func breakdown(it):
	# "Why this range": typical example, then each thing you know that moves it.
	var parts = g.value_breakdown(it)
	if parts.size() <= 1:
		return null
	var f = k.flow(6, 4)
	for i in range(parts.size()):
		var e = parts[i]
		var col = k.TEXT2
		if i > 0:
			col = k.GREEN if float(e[1]) > 0.0 else k.RED
		var txt = str(e[0]) if i == 0 else "%s %+d%%" % [e[0], int(round(float(e[1]) * 100.0))]
		f.add_child(k.label(("" if i == 0 else "· ") + txt, "xs", col))
	return f

func inv_verdict(it):
	var p = k.panel("inset", 12)
	var h = k.hbox(14)
	p.add_child(h)
	var left = k.vbox(0)
	left.add_child(k.label("PAID", "xs", k.TEXT3))
	left.add_child(k.label(g.fmt_money(it["paid"]), "xl", k.TEXT))
	var extra = float(it.get("extra_spend", 0.0))
	if extra > 0.0:
		left.add_child(k.label("+%s on checks" % g.fmt_money(extra), "xs", k.TEXT3))
	h.add_child(left)
	var right = k.vbox(2)
	k.expand(right)
	var pot = g.estimate_identified_potential(it)
	right.add_child(k.label("YOUR ESTIMATE", "xs", k.TEXT3))
	var eh = k.hbox(8)
	eh.add_child(k.label("%s–%s" % [g.fmt_money(pot[0]), g.fmt_money(pot[1])], "xl", k.TEAL))
	var conf = confidence(it)
	var cl = k.label(conf[0], "s", conf[1])
	cl.size_flags_vertical = Control.SIZE_SHRINK_END
	eh.add_child(cl)
	right.add_child(eh)
	var mid = g.suggested_price(it)
	var prof = g.estimated_profit_at(it, mid)
	right.add_child(k.label("At %s you'd make about %s after fees." % [g.fmt_money(mid), g.money_signed(prof)], "xs", k.GREEN if prof >= 0 else k.RED, true))
	h.add_child(right)
	var bd = breakdown(it)
	if bd != null:
		p.remove_child(h)
		var pv = k.vbox(8)
		pv.add_child(h)
		pv.add_child(bd)
		p.add_child(pv)
	return p

func confidence(it):
	if not it["basic_researched"]:
		return ["guesswork", k.ORANGE]
	var u = g.estimate_uncertainty(it)
	if u <= 0.12:
		return ["very sure", k.GREEN]
	if u <= 0.20:
		return ["fairly sure", k.TEAL]
	if u <= 0.30:
		return ["rough idea", k.GOLD]
	return ["guesswork", k.ORANGE]

func facts(it, ctx):
	var f = k.flow(6, 6)
	var cond_text = "Condition ?"
	var cc = k.TEXT3
	if it["condition_checked"]:
		cond_text = "Condition %d/10" % int(it["condition"])
		cc = cond_color(int(it["condition"]))
	elif it["quick_look_done"]:
		cond_text = "Looks ~%d/10" % int(it.get("perceived_condition", 6))
		cc = k.TEXT2
	f.add_child(k.chip(cond_text, cc, null, "s", "eye"))
	if it["testable"]:
		if it["tested"]:
			f.add_child(k.chip("Works" if not it["fault"] else g.fault_label(it), k.GREEN if not it["fault"] else k.RED, null, "s", "bolt"))
		else:
			f.add_child(k.chip("Untested", k.ORANGE, null, "s", "bolt"))
	elif it["condition_checked"] and it["fault"]:
		f.add_child(k.chip(g.fault_label(it), k.RED, null, "s", "cross"))
	if float(it["fake_chance"]) >= 0.05 or it["auth_status"] != "Unauthenticated":
		var at = it["auth_status"]
		if at == "Unauthenticated":
			f.add_child(k.chip("Fake risk: %s" % g.fake_risk_label(float(it["fake_chance"])), k.ORANGE, null, "s", "skull"))
		elif at == "Confirmed Genuine":
			f.add_child(k.chip("Genuine", k.GREEN, null, "s", "check"))
		elif at == "Inconclusive":
			f.add_child(k.chip("Authentication inconclusive", k.GOLD, null, "s", "q"))
		else:
			f.add_child(k.chip(at, k.RED, null, "s", "skull"))
	var trend = float(g.current_trends.get(it["category"], 1.0))
	if trend >= 1.10:
		f.add_child(k.chip("Trending +%d%%" % int(round((trend - 1.0) * 100)), k.PURPLE, null, "s", "flame"))
	elif trend <= 0.90:
		f.add_child(k.chip("Weak demand %d%%" % int(round((trend - 1.0) * 100)), k.RED, null, "s", "down"))
	if ctx == "inv" and int(it.get("days_owned", 0)) > 0:
		f.add_child(k.chip("Owned %d day%s" % [int(it["days_owned"]), "" if int(it["days_owned"]) == 1 else "s"], k.TEXT3, null, "s", "clock"))
	return f

func reveal_hint(it, d):
	var rv = str(d.get("reveal", ""))
	var tier = int(d.get("tier", 1))
	var cat = it["category"]
	match rv:
		"look":
			return "A proper look would tell you."
		"eye":
			return "A %s %s would spot it at a glance." % [cat, g.EXPERTISE_TIER_NAMES[tier]]
		"condition":
			return "Checking condition would show it."
		"test":
			return "Testing it would show it."
		"research":
			return "Research would show it."
		"deep":
			return "Deep Research could pin it down."
		"expert":
			return "\"%s\" at %s %s level could identify it. Deep Research might too." % [g.SPECIALIST_ACTIONS.get(cat, "Specialist check"), cat, g.EXPERTISE_TIER_NAMES[tier]]
		"uv":
			return "A UV lamp (Authentication Kit) would show it."
		"clean":
			return "Cleaning it (Cleaning Station) might reveal it."
		"sort":
			return "Sort through the lot at home to find out."
	return "You'll find out eventually."

func findings(it, ctx):
	var v = k.vbox(6)
	var any = false
	# Discoveries and clues
	for t in it.get("traits", []):
		var d = g.trait_def(t)
		if d == null:
			continue
		if t.get("known", false):
			if d["kind"] == "hidden_item":
				continue
			v.add_child(trait_card(it, t, d))
			any = true
		elif t.get("clue", false):
			var p = k.panel("purple", 10)
			var h = k.hbox(10)
			var q = k.glyph("q", k.PURPLE, 20)
			q.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			h.add_child(q)
			var tv = k.vbox(2)
			k.expand(tv)
			var clue_text = str(d.get("clue", ""))
			if clue_text == "":
				clue_text = "There's something here you can't quite place."
			tv.add_child(k.label(clue_text, "b", k.TEXT, true))
			tv.add_child(k.label(reveal_hint(it, d), "xs", k.PURPLE.lightened(0.2), true))
			h.add_child(tv)
			p.add_child(h)
			v.add_child(p)
			any = true
	# Notes
	var notes = []
	if it["quick_look_done"] and str(it.get("quick_look_note", "")) != "" and not it["condition_checked"]:
		notes.append(["eye", "Inspect (%d%% reliable): %s" % [int(float(it["quick_look_accuracy"]) * 100.0), it["quick_look_note"]], k.TEXT2])
	if str(it.get("hunch", "")) != "":
		notes.append(["spark", it["hunch"], k.TEAL])
	if it["condition_checked"]:
		notes.append(["eye", strip_bb(it["condition_price_note"]), k.TEXT2])
	if str(it.get("expert_note", "")) != "":
		notes.append(["star", it["expert_note"], k.TEAL])
	if str(it.get("test_note", "")) != "":
		notes.append(["bolt", "Test: " + strip_bb(it["test_note"]), k.GREEN if not it["fault"] else k.RED])
	if str(it.get("research_note", "")) != "":
		notes.append(["book", "Deep Research: " + strip_bb(it["research_note"]), k.BLUE])
	if ctx == "inv" and it["basic_researched"] and it.get("comps_values", []).size() > 0:
		notes.append(["glass", "Sold recently (ones like yours): " + g.comps_text(it), k.BLUE])
	if str(it.get("auth_note", "")) != "":
		notes.append(["check", "Authentication: " + strip_bb(it["auth_note"]), k.TEXT2])
	if str(it.get("repair_note", "")) != "":
		notes.append(["hammer", "Repair: " + strip_bb(it["repair_note"]), k.TEXT2])
	if str(it.get("haggle_note", "")) != "" and ctx == "stall":
		notes.append(["person", it["haggle_note"], k.GOLD])
	for n in notes:
		if str(n[1]).strip_edges() == "":
			continue
		var h2 = k.hbox(8)
		var gl = k.glyph(n[0], n[2], 14)
		gl.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		h2.add_child(gl)
		h2.add_child(k.label(n[1], "s", n[2], true))
		v.add_child(h2)
		any = true
	if not any:
		return null
	var outer = k.vbox(8)
	outer.add_child(k.section("What you know"))
	for t in it.get("traits", []):
		if t.get("clue", false) and not t.get("known", false):
			ui.coach(outer, "clue")
			break
	outer.add_child(v)
	return outer

func strip_bb(s):
	var re = RegEx.new()
	re.compile("\\[/?[a-z]+(=[^\\]]*)?\\]")
	return re.sub(str(s), "", true)

func trait_card(it, t, d):
	var kind = str(d["kind"])
	var style = "good" if kind == "good" else ("warn" if kind == "fixable" and not t.get("fixed", false) else ("good" if t.get("fixed", false) else "bad"))
	var p = k.panel(style, 10)
	var h = k.hbox(10)
	var col = k.trait_color(kind) if not t.get("fixed", false) else k.GREEN
	var gl = k.glyph("spark" if kind == "good" else ("hammer" if kind == "fixable" else "cross"), col, 20)
	gl.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(gl)
	var tv = k.vbox(2)
	k.expand(tv)
	var th = k.hbox(8)
	var nl = k.label(d["name"], "m", col)
	th.add_child(nl)
	th.add_child(k.spacer(0, 0, true))
	var pct = int(round((float(t["mult"]) - 1.0) * 100.0))
	var pl = k.label(("+%d%%" % pct) if pct >= 0 else ("%d%%" % pct), "m", col)
	th.add_child(pl)
	tv.add_child(th)
	tv.add_child(k.label(d["found"], "s", k.TEXT2, true))
	if kind == "fixable" and not t.get("fixed", false):
		var how = {"clean": "Cleaning Station", "repair": "Repair Bench", "parts": "Parts Bin"}.get(str(d.get("fix", "")), "workshop")
		tv.add_child(k.label("Fixable with a %s (value back to about %d%%)." % [how, int(float(d.get("fix_mult", 0.95)) * 100.0)], "xs", k.ORANGE, true))
	elif t.get("fixed", false):
		tv.add_child(k.label("Fixed.", "xs", k.GREEN))
	h.add_child(tv)
	p.add_child(h)
	return p

# ---------------------------------------------------------------------------
# Actions
# ---------------------------------------------------------------------------
func time_cost(e, m, cash = 0.0):
	var parts = []
	if cash > 0.0:
		parts.append(g.fmt_money(cash) if cash >= 1.0 else "£%.2f" % cash)
	if e > 0:
		parts.append("%d energy" % e)
	if m > 0:
		parts.append("%dm" % m)
	return " · ".join(parts)

func stall_actions(it, index):
	var gcols = 2
	var gr = k.grid(gcols, 8, 8)
	var acc = int(g.inspect_accuracy(it) * 100.0)
	gr.add_child(k.action_tile(ui.tex("inspect_icon"), "Inspect" if not it["quick_look_done"] else "Inspected", ("%d%% reliable · 1 energy" % acc) if not it["quick_look_done"] else "read: %s" % str(it.get("quick_look_note", "")).to_lower(), "action", func(): g.quick_look(index), g.energy < 1, "A quick look at condition, and anything obvious. Only %d%% reliable: you won't know if the read was right until you check properly." % acc, it["quick_look_done"]))
	var cc = g.condition_cost()
	gr.add_child(k.action_tile(ui.tex("condition_icon"), "Check condition" if not it["condition_checked"] else "Condition %d/10" % int(it["condition"]), time_cost(4, 5, cc), "action", func(): g.check_condition(index), g.cash < cc or g.energy < 4, "The exact condition score, plus hidden wear and damage.", it["condition_checked"]))
	var rc = g.research_cost()
	gr.add_child(k.action_tile(ui.tex("research_icon"), "Research" if not it["basic_researched"] else "Researched", time_cost(2, 4, rc) if rc > 0 else time_cost(2, 4) + " · free", "action", func(): g.prebuy_research(index), g.cash < rc or g.energy < 2, "Recent sold prices for this kind of item, and your margin after fees.", it["basic_researched"]))
	var tier = g.expertise_tier(it["category"])
	var act = g.SPECIALIST_ACTIONS.get(it["category"], "Specialist check")
	if tier >= 2:
		gr.add_child(k.action_tile("star", act if not it.get("expert_checked", false) else "Checked", "3 energy · 3m", "special", func(): g.specialist_check("stall", index), g.energy < 3, "Your %s expertise: identify specialist details (editions, marks, variants, faults) at the stall." % it["category"], it.get("expert_checked", false)))
	else:
		gr.add_child(k.action_tile("lock", act, "Unlocks at %s Specialist" % it["category"], "ghost", null, true, "Become a %s Specialist (expertise tier 2) to use this at stalls." % it["category"]))
	return gr

func haggle_panel(it, index, stall):
	var v = k.vbox(8)
	var asking = float(it["asking"])
	var uid = int(it["uid"])
	if not offer_values.has(uid) or float(offer_values[uid]) >= asking:
		offer_values[uid] = max(1.0, round(asking * 0.8))
	var offer = clamp(float(offer_values[uid]), 1.0, max(1.0, asking - 1.0))
	# Seller's patience, shown as pips.
	var mood = k.hbox(6)
	var pat = g.haggle_patience(it, stall)
	var pmax = max(pat, g.haggle_patience_max(stall))
	mood.add_child(k.label("PATIENCE", "xs", k.TEXT3))
	mood.add_child(k.dots(pat, pmax, k.GOLD, "heart"))
	mood.add_child(k.spacer(0, 0, true))
	var insult = g.haggle_insult_below(it, stall)
	mood.add_child(k.label("under %s offends" % g.fmt_money(insult), "xs", k.TEXT3))
	v.add_child(mood)
	var row = k.hbox(6)
	var chance_l = k.label("", "m", k.PURPLE)
	var edit = LineEdit.new()
	edit.text = str(int(offer))
	edit.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	edit.custom_minimum_size = Vector2(80, 40 if not k.mobile else 44)
	edit.add_theme_font_size_override("font_size", k.fs("m"))
	var update = func():
		var val = clamp(g._parse_price(edit.text), 1.0, max(1.0, asking - 1.0))
		offer_values[uid] = val
		var ch = g.haggle_chance_here(index, val)
		var word = "Sure thing" if ch >= 0.95 else ("Likely" if ch >= 0.65 else ("Maybe" if ch >= 0.35 else ("Unlikely" if ch > 0.02 else "No chance")))
		if val < insult:
			chance_l.text = "Insulting. They may refuse you"
			chance_l.add_theme_color_override("font_color", k.RED)
		else:
			chance_l.text = "%s · %d%%" % [word, int(round(ch * 100.0))]
			chance_l.add_theme_color_override("font_color", k.GREEN if ch >= 0.65 else (k.PURPLE if ch >= 0.35 else k.ORANGE))
	var step = max(1.0, round(asking * 0.05))
	row.add_child(k.button("-", "ghost", func():
		edit.text = str(int(max(1.0, g._parse_price(edit.text) - step)))
		update.call(), "", "l", 44))
	row.add_child(k.label("£", "m", k.TEXT2))
	row.add_child(edit)
	row.add_child(k.button("+", "ghost", func():
		edit.text = str(int(min(asking - 1.0, g._parse_price(edit.text) + step)))
		update.call(), "", "l", 44))
	var offer_b = k.button("Offer", "action", func():
		update.call()
		g.haggle_item(index, float(offer_values[uid])), "Make an offer. They'll take it, counter, or name a final price when their patience runs out. Very low offers offend.", "m", 90)
	offer_b.disabled = g.energy < 1
	row.add_child(k.spacer(4, 0))
	row.add_child(offer_b)
	edit.text_changed.connect(func(_t): update.call())
	v.add_child(row)
	update.call()
	var ch_row = k.hbox(8)
	ch_row.add_child(chance_l)
	ch_row.add_child(k.spacer(0, 0, true))
	ch_row.add_child(k.label("1 energy per offer", "xs", k.TEXT3))
	v.add_child(ch_row)
	var flaws = g.item_flaws(it)
	if flaws.size() > 0:
		var fl = k.flow(6, 6)
		fl.add_child(k.label("Point out:", "xs", k.TEXT2))
		for f in flaws:
			var key = f[0]
			fl.add_child(k.button(str(f[3]), "ghost", func(): g.point_out_flaw(index, key), "Raise this with the seller. If they hadn't priced it in, the price comes down.", "s"))
		v.add_child(fl)
	return v

func buy_button(it, index, stall, big = true):
	var asking = float(it["asking"])
	var b = null
	if it["haggle_result"] == "refused" or it.get("seller_refuses", false):
		b = k.button("Won't sell to you", "ghost", null, "", "m", 0, 52 if big else 44)
		b.disabled = true
	elif to_bool_banned(stall):
		b = k.button("Banned from this stall", "ghost", null, "", "m", 0, 52 if big else 44)
		b.disabled = true
	elif asking > g.cash:
		b = k.button("Can't afford %s" % g.fmt_money(asking), "ghost", null, "", "m", 0, 52 if big else 44)
		b.disabled = true
	elif not g.can_carry(it):
		b = k.button("Can't carry any more", "ghost", null, "Your %s carries %d. Get a bigger vehicle in Business." % [g.vehicle()["name"], g.effective_bag_capacity()], "m", 0, 52 if big else 44)
		b.disabled = true
	elif not g.can_store(it):
		b = k.button("No room at home", "ghost", null, "Storage full. Sell stock, add shelving or move premises.", "m", 0, 52 if big else 44)
		b.disabled = true
	else:
		var mg = stall_margin(it)
		var style = "action"
		var txt = "BUY  %s" % g.fmt_money(asking)
		if mg != null:
			if margin_color(mg, asking) == k.GREEN:
				style = "buy"
			elif mg <= 0.0:
				style = "ghost"
				txt = "Buy anyway  %s" % g.fmt_money(asking)
		b = k.button(txt, style, func(): g.buy_item(index), "Pay the asking price. Anything you haven't checked is a gamble.", "l" if big else "m", 0, 52 if big else 44)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return b

# --- inventory actions ---------------------------------------------------------------
func inv_actions(it, index):
	var gr = k.grid(2, 8, 8)
	if g.is_unsorted_lot(it):
		gr.add_child(k.action_tile("box", "Sort through the lot", "6 energy · 20m", "special", func(): g.sort_lot(index), g.energy < 6, "Empty it out and go through everything. Lots sometimes hide something worth more than the whole box."))
	if it["testable"]:
		gr.add_child(k.action_tile(ui.tex("test_icon"), "Test it" if not it["tested"] else ("Works" if not it["fault"] else "Faulty"), time_cost(g.test_energy(), 5 if g.has_equip("test_rig") else 10, g.test_cost()) if not it["tested"] else "tested", "action", func(): g.test_item(index), g.cash < g.test_cost() or g.energy < g.test_energy(), "Plug it in. You can't sell electricals untested.", it["tested"]))
	if not it["condition_checked"]:
		gr.add_child(k.action_tile(ui.tex("condition_icon"), "Check condition", time_cost(4, 5, g.condition_cost()), "action", func(): g.inventory_check_condition(index), g.cash < g.condition_cost() or g.energy < 4, "Exact condition score and hidden wear."))
	if not it["basic_researched"]:
		var rc = g.research_cost()
		gr.add_child(k.action_tile(ui.tex("research_icon"), "Research", time_cost(2, 4, rc) if rc > 0 else time_cost(2, 4), "action", func(): g.inventory_basic_research(index), g.cash < rc or g.energy < 2, "Recent sold prices."))
	var drc = g.deep_research_cost(it)
	gr.add_child(k.action_tile(ui.tex("deep_research_icon"), "Deep Research" if not it["deep_researched"] else "Deep researched", time_cost(10, 20, drc), "action", func(): g.deep_research(index), g.cash < drc or g.energy < 10, "Dig into editions, provenance and variants. Identifies research-level details outright, and may place specialist ones.", it["deep_researched"]))
	var tier = g.expertise_tier(it["category"])
	if tier >= 2:
		gr.add_child(k.action_tile("star", g.SPECIALIST_ACTIONS.get(it["category"], "Specialist check") if not it.get("expert_checked", false) else "Checked", "3 energy · 3m", "special", func(): g.specialist_check("inv", index), g.energy < 3, "Your %s expertise at work." % it["category"], it.get("expert_checked", false)))
	if g.has_equip("cleaning"):
		gr.add_child(k.action_tile("brush", "Clean it" if not it.get("cleaned", false) else "Cleaned", time_cost(4, 12, 1.0), "action", func(): g.clean_item(index), g.cash < 1 or g.energy < 4, "Grime off: fixes dirt and tarnish, can reveal marks, sometimes lifts condition.", it.get("cleaned", false)))
	if g.has_equip("auth"):
		gr.add_child(k.action_tile("uv", "UV lamp" if not it.get("uv_checked", false) else "UV checked", "2 energy · 3m", "action", func(): g.uv_check(index), g.energy < 2, "Repaints, restorations and touched-up signatures glow under UV.", it.get("uv_checked", false)))
	var parts = g.known_fixable(it, "parts")
	if g.has_equip("parts") and parts.size() > 0:
		gr.add_child(k.action_tile("gear", "Fit parts", time_cost(3, 10, 4.0 * parts.size()), "action", func(): g.parts_fix(index), g.cash < 4.0 * parts.size() or g.energy < 3, "Replace the missing bits from your parts bin."))
	if g.can_repair(it) or (g.has_equip("repair") and it["repair_attempted"]):
		var cost = g.repair_cost(it) if (it["fault"] and g.fault_is_known(it)) else 6.0
		gr.add_child(k.action_tile("hammer", "Repair" if not it["repair_attempted"] else "Repair tried", time_cost(10, 30, cost), "action", func(): g.repair_item(index), g.cash < cost or g.energy < 10, "One attempt at fixing known faults and broken parts. Better benches, better odds.", it["repair_attempted"]))
	if float(it["fake_chance"]) > 0.0 or it["auth_status"] != "Unauthenticated":
		var ac = g.authentication_cost(it)
		gr.add_child(k.action_tile(ui.tex("authenticate_icon"), "Authenticate" if not it["auth_attempted"] else it["auth_status"], time_cost(6, 15, ac), "action", func(): g.authenticate_item(index), g.cash < ac or g.energy < 6, "Find out if it's genuine. Selling an unchecked fake usually ends in a return and a hit to your rating.", it["auth_attempted"]))
	return gr

func sell_panel(it, index):
	var v = k.vbox(10)
	var uid = int(it["uid"])
	if it["auth_status"] == "Confirmed Counterfeit":
		v.add_child(k.label("It's a fake. You can't sell it honestly, but you can scrap it for parts.", "s", k.RED, true))
		v.add_child(k.button("Scrap for parts", "danger", func(): g.scrap_item(index), "", "m"))
		return v
	var com = g.world.commission_for(it)
	if com != null:
		var cp = k.panel("gold", 10)
		var ch = k.hbox(10)
		cp.add_child(ch)
		ch.add_child(k.glyph("heart", k.GOLD, 20))
		var ctv = k.vbox(2)
		k.expand(ctv)
		ctv.add_child(k.label("%s wants one" % g.world.short_from(com), "m", k.GOLD, true))
		ctv.add_child(k.label("Pays %.1f× what it's really worth. No fees, no postage. Until day %d." % [float(com["mult"]), int(com["expires"])], "xs", k.TEXT2, true))
		ch.add_child(ctv)
		ch.add_child(k.button("Deliver", "gold", func(): g.world.deliver_commission(index), "Hand it over. They judge the real thing: hidden flaws lower the price.", "m", 110, 44))
		v.add_child(cp)
	if it["listed"]:
		var p = k.panel("good", 10)
		var h = k.hbox(10)
		h.add_child(k.glyph("tag", k.GREEN, 20))
		var tv = k.vbox(2)
		k.expand(tv)
		tv.add_child(k.label("Listed at %s" % g.fmt_money(it["listing"]), "m", k.GREEN))
		tv.add_child(k.label("Expected interest: %s. Buyers look overnight." % g.buyer_interest_label(it, float(it["listing"])).to_lower(), "xs", k.TEXT2, true))
		h.add_child(tv)
		h.add_child(k.button("Unlist", "ghost", func(): g.unlist_item(index), "", "s"))
		p.add_child(h)
		v.add_child(p)
		return v
	if it["auctioned"]:
		var p2 = k.panel("purple", 10)
		var tv2 = k.vbox(2)
		tv2.add_child(k.label("At auction: current bid %s" % g.fmt_money(it["auction_current_bid"]), "m", k.PURPLE))
		tv2.add_child(k.label("Ends in %d day%s. The final price is a surprise." % [int(it["auction_days_left"]), "" if int(it["auction_days_left"]) == 1 else "s"], "xs", k.TEXT2))
		p2.add_child(tv2)
		v.add_child(p2)
		return v
	if it.get("on_shop_floor", false):
		var p3 = k.panel("blue", 10)
		var h3 = k.hbox(10)
		var tv3 = k.vbox(2)
		k.expand(tv3)
		tv3.add_child(k.label("On the shop floor at %s" % g.fmt_money(it.get("shop_price", 0)), "m", k.TEAL))
		tv3.add_child(k.label("Walk-in customers pay the ticket price. No fees, no postage.", "xs", k.TEXT2, true))
		h3.add_child(tv3)
		h3.add_child(k.button("Take off", "ghost", func(): g.put_on_shop_floor(index, 0), "", "s"))
		p3.add_child(h3)
		v.add_child(p3)
		return v
	if it["testable"] and not it["tested"]:
		v.add_child(k.label("Test it before you can sell it.", "s", k.ORANGE, true))
	var pot = g.estimate_identified_potential(it)
	if not price_values.has(uid):
		price_values[uid] = g.suggested_price(it)
	var price = max(1.0, float(price_values[uid]))
	var info = k.label("", "s", k.TEXT2, true)
	var profit_l = k.label("", "m", k.GREEN)
	var edit = LineEdit.new()
	edit.text = str(int(price))
	edit.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	edit.custom_minimum_size = Vector2(96, 44)
	edit.add_theme_font_size_override("font_size", k.fs("l"))
	var update = func():
		var p = max(1.0, g._parse_price(edit.text))
		price_values[uid] = p
		var prof = g.estimated_profit_at(it, p)
		profit_l.text = "%s profit" % g.money_signed(prof)
		profit_l.add_theme_color_override("font_color", k.GREEN if prof >= 0 else k.RED)
		var lbl = g.buyer_interest_label(it, p)
		info.text = "Expected interest: %s" % lbl.to_lower()
		if footer_btn != null and is_instance_valid(footer_btn) and not footer_btn.disabled:
			footer_btn.text = "List at %s  (%s)" % [g.fmt_money(p), g.money_signed(prof)]
	var row = k.hbox(6)
	var step = max(1.0, round(price * 0.05))
	row.add_child(k.button("-", "ghost", func():
		edit.text = str(int(max(1.0, g._parse_price(edit.text) - step)))
		update.call(), "", "l", 44))
	row.add_child(k.label("£", "l", k.TEXT2))
	row.add_child(edit)
	row.add_child(k.button("+", "ghost", func():
		edit.text = str(int(g._parse_price(edit.text) + step))
		update.call(), "", "l", 44))
	row.add_child(k.spacer(6, 0))
	row.add_child(profit_l)
	v.add_child(row)
	var presets = k.hbox(6)
	for pr in [["Quick", round(float(pot[0]) * 0.95)], ["Fair", g.suggested_price(it)], ["Ambitious", round(float(pot[1]) * 1.05)]]:
		var val = pr[1]
		presets.add_child(k.button("%s %s" % [pr[0], g.fmt_money(val)], "ghost", func():
			edit.text = str(int(val))
			update.call(), "", "xs", 0, 34))
	v.add_child(presets)
	v.add_child(info)
	edit.text_changed.connect(func(_t): update.call())
	update.call()
	var can_sell = not (it["testable"] and not it["tested"])
	var cap_full = g.active_listing_count() >= g.listing_cap()
	var list_b = k.button("List online", "buy", func():
		update.call()
		g.create_listing(index, float(price_values[uid])), "Put it up for sale. One shot at a buyer today, then a roll every night.", "m", 0, 48)
	list_b.disabled = not can_sell or cap_full
	if cap_full:
		list_b.text = "Listings full (%d)" % g.listing_cap()
	list_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var main_row = k.hbox(8)
	main_row.add_child(list_b)
	if g.shop_floor_enabled():
		var sb = k.button("Shop floor", "action", func():
			update.call()
			g.put_on_shop_floor(index, float(price_values[uid])), "Put it on a shelf in your shop at this price.", "m", 0, 48)
		sb.disabled = not can_sell or g.shop_floor_count() >= g.shop_floor_cap()
		sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		main_row.add_child(sb)
	v.add_child(main_row)
	var alt = k.flow(6, 6)
	if g.auctions_unlocked():
		var ab = k.button("Auction (3 days)", "special", func(): g.start_auction(index), "Let bidders decide. Rare and trending things can spark a bidding war; common things can go cheap.", "s")
		ab.disabled = not can_sell or cap_full
		alt.add_child(ab)
	if g.collector_contact_available(it):
		var offer = g.collector_offer_for(it)
		alt.add_child(k.button("Collector pays %s" % g.fmt_money(offer), "gold", func(): g.sell_to_collector(index), "Your %s collector contact makes one private offer a day. No fees, no postage." % it["category"], "s"))
	var tr_lo = 0.45 if g.has_perk("trade_contacts") else 0.35
	var tr_hi = 0.60 if g.has_perk("trade_contacts") else 0.50
	alt.add_child(k.button("Sell to a trader", "ghost", func(): g.quick_sell_item(index), "Instant cash: a trader pays %d–%d%% of what it's really worth." % [int(tr_lo * 100), int(tr_hi * 100)], "s"))
	alt.add_child(k.button("Scrap", "ghost", func(): g.scrap_item(index), "Parts value only.", "s"))
	v.add_child(alt)
	return v


func inv_footer(it, index):
	# Mobile sheet footer: the sell decision, always visible.
	if it["listed"] or it["auctioned"] or it.get("on_shop_floor", false) or it["auth_status"] == "Confirmed Counterfeit":
		return null
	var uid = int(it["uid"])
	if not price_values.has(uid):
		price_values[uid] = g.suggested_price(it)
	var price = float(price_values[uid])
	var h = k.hbox(8)
	var can_sell = not (it["testable"] and not it["tested"])
	var cap_full = g.active_listing_count() >= g.listing_cap()
	var prof = g.estimated_profit_at(it, price)
	var b = k.button("List at %s  (%s)" % [g.fmt_money(price), g.money_signed(prof)], "buy" if prof >= 0 else "action", func(): g.create_listing(index, float(price_values[uid])), "", "m", 0, 50)
	if not can_sell:
		b.text = "Test it before selling"
	elif cap_full:
		b.text = "Listings full (%d)" % g.listing_cap()
	b.disabled = not can_sell or cap_full
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(b)
	footer_btn = b
	return h
