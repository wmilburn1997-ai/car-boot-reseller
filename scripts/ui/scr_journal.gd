extends RefCounted
# Journal (story, collection, discoveries, achievements, sales, logs) and the News/Trends screen.

var ui
var g
var k
var tab = "story"
var coll_cat = ""
var disc_cat = ""
var log_kind = "activity"

func _init(root):
	ui = root
	g = root.g
	k = root.k

func build(parent, want_tab = ""):
	if want_tab != "":
		tab = want_tab
	var v = k.vbox(12)
	var tabs = k.hbox(6)
	var names = [["story", "Story"], ["flips", "Best flips"], ["discoveries", "Discoveries"], ["collection", "Collection"], ["achievements", "Achievements"], ["sales", "Sales"]]
	if ui.mobile:
		names.insert(1, ["expertise", "Expertise"])
		names.insert(2, ["perks", "Perks"])
	for t in names:
		var id = t[0]
		tabs.add_child(k.button(t[1], "tab_on" if tab == id else "ghost", func():
			tab = id
			ui.refresh(), "", "s", 0, 40))
	if ui.mobile:
		var ts = ScrollContainer.new()
		ts.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		ts.custom_minimum_size = Vector2(0, 52)
		ts.add_child(tabs)
		v.add_child(ts)
	else:
		v.add_child(tabs)
	match tab:
		"story":
			story(v)
		"flips":
			flips(v)
		"discoveries":
			discoveries(v)
		"collection":
			collection(v)
		"achievements":
			achievements(v)
		"sales":
			sales(v)
		"logs":
			logs(v)
		"expertise":
			v.add_child(ui.business.knowledge_content())
		"perks":
			v.add_child(ui.business.perks_content())
	v.add_child(k.spacer(0, 20))
	parent.add_child(ui.keyed_scroll("journal_" + tab, ui.cap_width(v, 1250)))

func story(v):
	var p = k.panel("card2", 14)
	var hv = k.vbox(4)
	p.add_child(hv)
	hv.add_child(k.label("Your story so far", "xl", k.TEXT))
	var disc = 0
	for kk in g.discoveries_log:
		disc += int(g.discoveries_log[kk])
	hv.add_child(k.label("Day %d · %d sales · %s lifetime profit · %d discoveries · best business value %s" % [g.day, g.sold_history.size(), g.money_signed(g.total_lifetime_profit), disc, g.fmt_money(g.best_net_worth)], "s", k.TEXT3, true))
	v.add_child(p)
	if g.journal.size() == 0:
		v.add_child(k.label("Nothing written yet. Go and find something.", "b", k.TEXT3))
		return
	# One card per day: the headline, the good news, and the setbacks folded up.
	var days = {}
	var order = []
	for e in g.journal:
		var d = int(e["day"])
		if not days.has(d):
			days[d] = []
			order.append(d)
		days[d].append(e)
	order.reverse()
	var colors = {"good": k.GREEN, "bad": k.RED, "level": k.GOLD, "info": k.TEXT2}
	var glyphs = {"good": "spark", "bad": "cross", "level": "star", "info": "dots"}
	for d in order.slice(0, 20):
		var entries = days[d]
		var card = k.panel("card", 12)
		var cv = k.vbox(6)
		card.add_child(cv)
		var head = null
		for e in entries:
			if e["kind"] == "level":
				head = e
		if head == null:
			for e in entries:
				if e["kind"] == "good":
					head = e
					break
		var th = k.hbox(10)
		th.add_child(k.label("DAY %d" % d, "s", k.TEXT3))
		if head != null:
			th.add_child(k.label(head["text"], "m", colors.get(head["kind"], k.TEXT), true))
		cv.add_child(th)
		var bads = []
		for e in entries:
			if e == head:
				continue
			if e["kind"] == "bad":
				bads.append(e)
				continue
			var h = k.hbox(8)
			var gl = k.glyph(glyphs.get(e["kind"], "dots"), colors.get(e["kind"], k.TEXT2), 14)
			gl.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			h.add_child(gl)
			h.add_child(k.label(e["text"], "s", k.TEXT2, true))
			cv.add_child(h)
		if bads.size() > 0:
			var shown = bads.slice(0, 2)
			for e in shown:
				var h2 = k.hbox(8)
				var gl2 = k.glyph("cross", k.RED, 14)
				gl2.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
				h2.add_child(gl2)
				h2.add_child(k.label(e["text"], "s", k.RED.lerp(k.TEXT2, 0.5), true))
				cv.add_child(h2)
			if bads.size() > 2:
				cv.add_child(k.label("…and %d more setbacks." % (bads.size() - 2), "xs", k.TEXT3))
		v.add_child(card)

func discoveries(v):
	if disc_cat == "":
		var total_found = g.discoveries_log.size()
		var total = g.content.traits.size()
		var p = k.panel("card2", 14)
		var hv = k.vbox(6)
		p.add_child(hv)
		hv.add_child(k.label("Discoveries", "xl", k.TEXT))
		hv.add_child(k.label("Every hidden detail you've identified: editions, marks, variants, faults and fakes. %d of %d kinds found." % [total_found, total], "s", k.TEXT3, true))
		hv.add_child(k.bar(total_found, total, k.PURPLE, 8))
		v.add_child(p)
		var gr = k.grid(1 if ui.mobile else 2, 10, 10)
		for c in g.CATEGORIES:
			var found = 0
			var tot = 0
			for tid in g.content.traits:
				if g.content.traits[tid]["cats"].has(c):
					tot += 1
					if g.discoveries_log.has(tid):
						found += 1
			var cat = c
			var b = category_button(c, "%d/%d" % [found, tot], found, tot, k.PURPLE, func():
				disc_cat = cat
				ui.refresh())
			gr.add_child(b)
		v.add_child(gr)
		return
	v.add_child(k.button("‹ All categories", "ghost", func():
		disc_cat = ""
		ui.refresh(), "", "s"))
	v.add_child(k.label(disc_cat, "xl", k.TEXT))
	var unknown = 0
	var ids = []
	for tid in g.content.traits:
		if g.content.traits[tid]["cats"].has(disc_cat):
			ids.append(tid)
	ids.sort_custom(func(a, b): return float(g.content.traits[a]["mult"][1]) > float(g.content.traits[b]["mult"][1]))
	for tid in ids:
		var d = g.content.traits[tid]
		if not g.discoveries_log.has(tid):
			unknown += 1
			continue
		var p2 = k.panel("good" if d["kind"] in ["good", "hidden_item"] else ("warn" if d["kind"] == "fixable" else "bad"), 10)
		var h = k.hbox(10)
		h.add_child(k.glyph("spark" if d["kind"] in ["good", "hidden_item"] else "cross", k.trait_color(d["kind"]), 16))
		var tv = k.vbox(2)
		k.expand(tv)
		tv.add_child(k.label("%s  ×%d" % [d["name"], int(g.discoveries_log[tid])], "m", k.trait_color(d["kind"])))
		tv.add_child(k.label(d["found"], "s", k.TEXT2, true))
		h.add_child(tv)
		p2.add_child(h)
		v.add_child(p2)
	if unknown > 0:
		var p3 = k.panel("inset", 12)
		p3.add_child(k.label("??? — %d more to discover in %s" % [unknown, disc_cat], "m", k.TEXT3))
		v.add_child(p3)

func category_button(c, right_text, a, b, color, cb):
	var btn = Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	k.style_button(btn, "ghost", [10, 8, 10, 8])
	btn.custom_minimum_size = Vector2(0, 64)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h = k.hbox(10)
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 10
	h.offset_right = -10
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ic = k.cat_icon(c, 40)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	var v = k.vbox(4)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	k.expand(v)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var th = k.hbox(6)
	th.mouse_filter = Control.MOUSE_FILTER_IGNORE
	th.add_child(k.label(c, "m", k.TEXT))
	th.add_child(k.spacer(0, 0, true))
	th.add_child(k.label(right_text, "s", color))
	v.add_child(th)
	v.add_child(k.bar(a, max(1, b), color, 6))
	h.add_child(v)
	btn.add_child(h)
	btn.pressed.connect(cb)
	return btn

func collection(v):
	if coll_cat == "":
		var tot = g.total_families_discovered()
		var p = k.panel("card2", 14)
		var hv = k.vbox(6)
		p.add_child(hv)
		hv.add_child(k.label("Collection Log", "xl", k.TEXT))
		hv.add_child(k.label("Every kind of item, in every rarity. %d of %d found." % [tot[0], tot[1]], "s", k.TEXT3, true))
		hv.add_child(k.bar(tot[0], tot[1], k.GOLD, 8))
		v.add_child(p)
		var gr = k.grid(1 if ui.mobile else 2, 10, 10)
		for c in g.CATEGORIES:
			var cc = g.category_discovery_count(c)
			var cat = c
			gr.add_child(category_button(c, "%d/%d" % [cc[0], cc[1]], cc[0], cc[1], k.GOLD, func():
				coll_cat = cat
				ui.refresh()))
		v.add_child(gr)
		return
	v.add_child(k.button("‹ All categories", "ghost", func():
		coll_cat = ""
		ui.refresh(), "", "s"))
	v.add_child(k.label(coll_cat, "xl", k.TEXT))
	var gr2 = k.grid(1 if ui.mobile else 2, 8, 8)
	for fam in g.content.families_by_cat.get(coll_cat, []):
		var p2 = k.panel("card", 10)
		p2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var h = k.hbox(10)
		p2.add_child(h)
		var seen = g.family_stats.has(fam["name"])
		var tv = k.vbox(3)
		k.expand(tv)
		tv.add_child(k.label(fam["name"] if seen else "???", "b", k.TEXT if seen else k.TEXT3))
		var slots = k.hbox(3)
		for row in g.rarity_table:
			var key = coll_cat + "|" + fam["name"] + "|" + row["tier"]
			var has = g.discovered_log.has(key)
			var sp = PanelContainer.new()
			sp.custom_minimum_size = Vector2(22, 10)
			sp.add_theme_stylebox_override("panel", k.sbox(k.rarity_color(row["tier"]) if has else k.PANEL3, k.LINE, 2, 1, 0))
			sp.tooltip_text = "%s (1 in %d)%s" % [row["tier"], int(row["one_in"]), "" if has else ": not found yet"]
			sp.mouse_filter = Control.MOUSE_FILTER_PASS
			slots.add_child(sp)
		tv.add_child(slots)
		if seen:
			var fs = g.family_stats[fam["name"]]
			tv.add_child(k.label("Found %d · best sale %s" % [int(fs["times_found"]), g.fmt_money(fs["highest_sold"])], "xs", k.TEXT3))
		h.add_child(tv)
		gr2.add_child(p2)
	v.add_child(gr2)

func achievements(v):
	var n = 0
	for a in g.ALL_ACHIEVEMENTS:
		if g.achievements.has(a):
			n += 1
	v.add_child(k.label("Achievements  %d/%d" % [n, g.ALL_ACHIEVEMENTS.size()], "xl", k.TEXT))
	var gr = k.grid(1 if ui.mobile else 3, 8, 8)
	for a in g.ALL_ACHIEVEMENTS:
		var got = g.achievements.has(a)
		var p = k.panel("gold" if got else "inset", 10)
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var h = k.hbox(10)
		h.add_child(k.glyph("trophy" if got else "lock", k.GOLD if got else k.TEXT3, 20))
		var tv = k.vbox(2)
		k.expand(tv)
		tv.add_child(k.label(a, "m", k.GOLD if got else k.TEXT2))
		tv.add_child(k.label(g.ALL_ACHIEVEMENTS[a], "xs", k.TEXT3, true))
		h.add_child(tv)
		p.add_child(h)
		gr.add_child(p)
	v.add_child(gr)

func sales(v):
	var total = 0.0
	for sl in g.sold_history:
		total += g.sale_profit_of(sl)
	v.add_child(k.label("Sales  ·  %d sold  ·  %s profit" % [g.sold_history.size(), g.money_signed(total)], "xl", k.TEXT))
	if g.sold_history.size() == 0:
		v.add_child(k.label("Nothing sold yet.", "b", k.TEXT3))
		return
	if not ui.mobile:
		var hr = k.hbox(10)
		for col in [["Item", 0], ["Day", 60], ["Channel", 130], ["Paid", 80], ["Sold", 80], ["Profit", 90]]:
			var l = k.label(col[0].to_upper(), "xs", k.TEXT3, false, HORIZONTAL_ALIGNMENT_RIGHT if col[1] > 0 else HORIZONTAL_ALIGNMENT_LEFT)
			if col[1] > 0:
				l.custom_minimum_size = Vector2(col[1], 0)
			else:
				k.expand(l)
			hr.add_child(l)
		v.add_child(k.margin(hr, 12, 0, 12, 0))
	for i in range(g.sold_history.size() - 1, max(-1, g.sold_history.size() - 81), -1):
		var sl = g.sold_history[i]
		var prof = g.sale_profit_of(sl)
		var p = k.panel("card", 8)
		var h = k.hbox(10)
		p.add_child(h)
		h.add_child(k.cat_icon(sl.get("category", "Home"), 28))
		var tv = k.vbox(1)
		k.expand(tv)
		tv.add_child(k.label(sl["name"], "b", k.TEXT))
		var notes = []
		if sl.get("traits", []).size() > 0:
			notes.append("found " + ", ".join(sl["traits"]))
		if sl.get("missed", []).size() > 0:
			notes.append("missed " + ", ".join(sl["missed"]))
		if ui.mobile:
			notes.insert(0, "Day %d · %s · paid %s" % [int(sl["day"]), g.channel_name(sl.get("channel", "listing")), g.fmt_money(sl.get("paid", 0))])
		if notes.size() > 0:
			tv.add_child(k.label(" · ".join(notes), "xs", k.RED if sl.get("missed", []).size() > 0 else k.TEXT3, true))
		h.add_child(tv)
		if not ui.mobile:
			for c in [[str(int(sl["day"])), 60, k.TEXT3], [g.channel_name(sl.get("channel", "listing")), 130, k.TEXT2], [g.fmt_money(sl.get("paid", 0)), 80, k.TEXT2], [g.fmt_money(sl["price"]), 80, k.TEXT]]:
				var cl = k.label(c[0], "s", c[2], false, HORIZONTAL_ALIGNMENT_RIGHT)
				cl.custom_minimum_size = Vector2(c[1], 0)
				h.add_child(cl)
			var pl = k.label(g.money_signed(prof), "m", k.GREEN if prof >= 0 else k.RED, false, HORIZONTAL_ALIGNMENT_RIGHT)
			pl.custom_minimum_size = Vector2(90, 0)
			h.add_child(pl)
		else:
			var pv = k.vbox(0)
			pv.add_child(k.label(g.fmt_money(sl["price"]), "m", k.TEXT, false, HORIZONTAL_ALIGNMENT_RIGHT))
			pv.add_child(k.label(g.money_signed(prof), "s", k.GREEN if prof >= 0 else k.RED, false, HORIZONTAL_ALIGNMENT_RIGHT))
			h.add_child(pv)
		v.add_child(p)

func logs(v):
	var h = k.hbox(6)
	for t in [["activity", "Activity"], ["rng", "Dice rolls"]]:
		var id = t[0]
		h.add_child(k.button(t[1], "tab_on" if log_kind == id else "ghost", func():
			log_kind = id
			ui.refresh(), "", "s"))
	v.add_child(h)
	v.add_child(k.label("Every roll is shown. Odds that would give away an item's hidden value stay hidden until the truth comes out." if log_kind == "rng" else "What's happened recently.", "xs", k.TEXT3, true))
	var src = g.activity_log if log_kind == "activity" else g.rng_log
	var p = k.panel("inset", 10)
	var lv = k.vbox(4)
	p.add_child(lv)
	for i in range(src.size() - 1, max(-1, src.size() - 101), -1):
		lv.add_child(k.label(ui.item.strip_bb(src[i]), "xs", k.TEXT2, true))
	v.add_child(p)

# ---------------------------------------------------------------------------
# News & trends
# ---------------------------------------------------------------------------
func flips(v):
	# A scrapbook of your best deals, each with its whole story.
	var sold = []
	for e in g.sold_history:
		if e.has("profit"):
			sold.append(e)
	sold.sort_custom(func(a, b): return float(a["profit"]) > float(b["profit"]))
	if sold.size() == 0:
		v.add_child(k.label("Your best deals will be pinned here, with the whole story of each one.", "m", k.TEXT3, true))
		return
	var n = 0
	for e in sold:
		if n >= 12 or float(e["profit"]) <= 0.0:
			break
		n += 1
		var p = k.panel("good" if n <= 3 else "card", 12)
		var pv = k.vbox(4)
		p.add_child(pv)
		var h = k.hbox(10)
		h.add_child(k.item_icon(str(e.get("name", "")), str(e.get("category", "Home")), 40))
		var tv = k.vbox(1)
		k.expand(tv)
		var title = str(e.get("ident", "")) if str(e.get("ident", "")) != "" else str(e["name"])
		tv.add_child(k.label("%d. %s" % [n, title], "m", k.TEXT, true))
		tv.add_child(k.label("%s · paid %s · sold %s" % [e["name"], g.fmt_money(e.get("paid", 0)), g.fmt_money(e.get("price", 0))], "xs", k.TEXT3, true))
		h.add_child(tv)
		h.add_child(k.label(g.money_signed(float(e["profit"])), "l", k.GREEN))
		pv.add_child(h)
		for line in e.get("hist", []):
			pv.add_child(k.label("Day %d  ·  %s" % [int(line[0]), str(line[1])], "xs", k.TEXT2, true))
		v.add_child(p)

func build_news(parent):
	var v = k.vbox(12)
	var head = k.panel("card2", 14)
	var hv = k.vbox(6)
	head.add_child(hv)
	var hh = k.hbox(10)
	hh.add_child(k.glyph("news", k.TEAL, 24))
	var nl = k.label("Market news · week %d · %s" % [g.current_week, g.get_season_name()], "l" if ui.mobile else "xl", k.TEXT, ui.mobile)
	k.expand(nl)
	hh.add_child(nl)
	hv.add_child(hh)
	if g.week_news.size() > 0:
		var up = str(g.week_news.get("dir", "up")) == "up"
		hv.add_child(k.label(str(g.week_news["text"]), "l", k.GREEN if up else k.RED, true))
		hv.add_child(k.label("%s demand %s this week." % [g.week_news["cat"], "up" if up else "down"], "s", k.TEXT3))
	for line in g.trend_headlines:
		hv.add_child(k.label(line, "s", k.TEXT2, true))
	v.add_child(head)
	var d = g.world.st()
	var heads = d.get("headlines", [])
	var lw = d.get("last_week", {})
	if heads.size() > 0 or lw.size() > 0:
		v.add_child(k.section("In the local paper"))
		var pp = k.panel("inset", 12)
		var pv = k.vbox(6)
		pp.add_child(pv)
		for i in range(heads.size() - 1, max(-1, heads.size() - 5), -1):
			if g.day - int(heads[i].get("day", 0)) > 14:
				continue
			pv.add_child(k.label("\"%s\"  (day %d)" % [str(heads[i]["text"]), int(heads[i].get("day", 0))], "m", k.GOLD, true))
		if lw.size() > 0:
			pv.add_child(k.label("Boot-sale league, last week: you %s, %s %s. %s" % [g.fmt_money(lw["you"]), g.world.nick(), g.fmt_money(lw["gaz"]), str(lw.get("line", ""))], "s", k.TEXT2, true))
		v.add_child(pp)
	v.add_child(k.section("Demand by category"))
	var cats = g.CATEGORIES.duplicate()
	cats.sort_custom(func(a, b): return float(g.current_trends.get(a, 1.0)) > float(g.current_trends.get(b, 1.0)))
	var gr = k.grid(1 if ui.mobile else 2, 10, 8)
	for c in cats:
		var t = float(g.current_trends.get(c, 1.0))
		var p = k.panel("card", 10)
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var h = k.hbox(10)
		p.add_child(h)
		h.add_child(k.cat_icon(c, 32))
		var tv = k.vbox(4)
		k.expand(tv)
		var th = k.hbox(6)
		th.add_child(k.label(c, "b", k.TEXT))
		th.add_child(k.spacer(0, 0, true))
		var pct = int(round((t - 1.0) * 100.0))
		th.add_child(k.label(("+%d%%" % pct) if pct >= 0 else ("%d%%" % pct), "m", k.GREEN if pct >= 5 else (k.RED if pct <= -5 else k.TEXT2)))
		tv.add_child(th)
		tv.add_child(k.bar(t - 0.6, 0.8, k.GREEN if pct >= 5 else (k.RED if pct <= -5 else k.TEXT3), 6))
		h.add_child(tv)
		gr.add_child(p)
	v.add_child(gr)
	v.add_child(k.label("Demand changes what buyers pay. News moves one category each week; rumours come true about 70% of the time. Hold stock for a good week, or sell before a slump.", "xs", k.TEXT3, true))
	v.add_child(k.spacer(0, 20))
	parent.add_child(ui.keyed_scroll("news", v))
