extends RefCounted
# Title, night report, settings, tutorial, "More" menu, bankruptcy and playtest notes.

var ui
var g
var k
var confirm_new = false
var save_code_text = ""

func _init(root):
	ui = root
	g = root.g
	k = root.k

# ---------------------------------------------------------------------------
# Title
# ---------------------------------------------------------------------------
func build_title(parent):
	var center = CenterContainer.new()
	k.expand(center, true)
	parent.add_child(center)
	var v = k.vbox(14)
	v.custom_minimum_size = Vector2(min(560, ui.logical.x - 32), 0)
	center.add_child(v)
	if ResourceLoader.exists("res://banner.png"):
		var tr = k.tex_rect(load("res://banner.png"), 0)
		tr.custom_minimum_size = Vector2(0, 280 if not ui.mobile else 160)
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		v.add_child(tr)
	else:
		v.add_child(k.label("CAR BOOT RESELLER", "hero", k.GOLD, false, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(k.label("Buy low at the boot sale. Find what everyone else missed. Build an empire.", "b", k.TEXT2, true, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(k.spacer(0, 6))
	if confirm_new:
		var p = k.panel("bad", 16)
		var pv = k.vbox(10)
		p.add_child(pv)
		pv.add_child(k.label("Start a new game?", "l", k.TEXT))
		pv.add_child(k.label("Your current business will be lost for good.", "s", k.TEXT2, true))
		var row = k.hbox(10)
		var yes = k.button("Yes, start again", "danger", func():
			confirm_new = false
			g.start_new_game(), "", "m", 0, 48)
		yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(yes)
		var no = k.button("Keep playing", "ghost", func():
			confirm_new = false
			ui.refresh(), "", "m", 0, 48)
		no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(no)
		pv.add_child(row)
		v.add_child(p)
		return
	var has_run = g.has_save and not g.game_over
	if has_run:
		var cb = k.button("Continue", "primary", func(): continue_game(), "", "xl", 0, 64)
		v.add_child(cb)
		v.add_child(k.label("Day %d · %s cash · %s · level %d" % [g.day, g.fmt_money(g.cash), g.premises()["name"], g.player_level], "s", k.TEXT3, false, HORIZONTAL_ALIGNMENT_CENTER))
	var nb = k.button("New game", "action" if has_run else "primary", func():
		if has_run:
			confirm_new = true
			ui.refresh()
		else:
			g.start_new_game(), "", "l", 0, 54)
	v.add_child(nb)
	var row2 = k.hbox(8)
	for t in [["How to play", func(): ui.show_tutorial()], ["Settings", func(): ui.show_settings()]]:
		var b = k.button(t[0], "ghost", t[1], "", "m", 0, 46)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row2.add_child(b)
	if not OS.has_feature("web"):
		var q = k.button("Quit", "ghost", func(): g.get_tree().quit(), "", "m", 0, 46)
		q.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row2.add_child(q)
	v.add_child(row2)
	v.add_child(k.label("v%s · playtest build" % g.GAME_VERSION, "xs", k.TEXT3, false, HORIZONTAL_ALIGNMENT_CENTER))

func continue_game():
	g.on_title_screen = false
	ui.sheet_open = false
	for n in g.pending_notices:
		ui.big_popup("WHAT'S NEW", n, "info")
	g.pending_notices = []
	if g.clearance != null:
		ui.show_clearance()
	elif g.current_time_minutes >= 12 * 60:
		ui.show_inventory(true)
	else:
		ui.show_market()

# ---------------------------------------------------------------------------
# Night report
# ---------------------------------------------------------------------------
func build_day_summary(parent, s):
	var v = k.vbox(12)
	var st = s["stats"]
	var worth_delta = float(s["end_worth"]) - float(s["start_worth"])
	var cash_delta = float(s["end_cash"]) - float(s["start_cash"])
	var head = k.panel("card2", 16)
	var hv = k.vbox(6)
	head.add_child(hv)
	hv.add_child(k.label("HOW DAY %d WENT" % int(s["day"]), "s", k.TEXT3))
	var profit = float(st.get("sale_profit", 0.0))
	var sold_n = int(st.get("items_sold", 0))
	var hh = k.hbox(22)
	var a = k.vbox(0)
	a.add_child(k.label("Profit on sales", "xs", k.TEXT3))
	if sold_n > 0:
		a.add_child(k.label(g.money_signed(profit), "hero", k.GREEN if profit >= 0 else k.RED))
		a.add_child(k.label("%d sold" % sold_n, "s", k.TEXT2))
	else:
		a.add_child(k.label("Nothing sold", "xl", k.TEXT3))
		a.add_child(k.label("some nights are like that", "s", k.TEXT3))
	hh.add_child(a)
	var b = k.vbox(0)
	b.add_child(k.label("Business value", "xs", k.TEXT3))
	b.add_child(k.label(g.money_signed(worth_delta), "xl", k.GREEN if worth_delta >= 0 else k.RED))
	b.add_child(k.label("now %s" % g.fmt_money(s["end_worth"]), "s", k.TEXT2))
	b.size_flags_vertical = Control.SIZE_SHRINK_END
	hh.add_child(b)
	if not ui.mobile:
		var c = k.vbox(0)
		c.add_child(k.label("Cash", "xs", k.TEXT3))
		c.add_child(k.label(g.fmt_money(s["end_cash"]), "xl", k.TEXT))
		var inv = float(st.get("buy_spend", 0.0))
		c.add_child(k.label(("%s invested in stock" % g.fmt_money(inv)) if inv > 0 else g.money_signed(cash_delta) + " today", "s", k.TEXT2))
		c.size_flags_vertical = Control.SIZE_SHRINK_END
		hh.add_child(c)
	hv.add_child(hh)
	if ui.mobile:
		var inv2 = float(st.get("buy_spend", 0.0))
		hv.add_child(k.label("Cash %s%s" % [g.fmt_money(s["end_cash"]), ("  ·  %s invested in stock" % g.fmt_money(inv2)) if inv2 > 0 else ""], "s", k.TEXT2))
	v.add_child(head)
	if int(s.get("streak", 0)) > 0:
		var w = k.panel("bad", 12)
		w.add_child(k.label("You're overdrawn: %d night%s in the red. Four in a row and the business goes under. Sell something, fast." % [int(s["streak"]), "" if int(s["streak"]) == 1 else "s"], "m", k.RED, true))
		v.add_child(w)
	# Overnight events, revealed one at a time
	v.add_child(k.section("Overnight"))
	var events = s.get("events", [])
	var ev_box = k.vbox(6)
	v.add_child(ev_box)
	if events.size() == 0:
		ev_box.add_child(k.label("A quiet night. Nothing sold.", "b", k.TEXT3))
	var delay = 0.15
	for e in events:
		var card = event_card(e)
		card.modulate = Color(1, 1, 1, 0)
		ev_box.add_child(card)
		var tw = card.create_tween()
		tw.tween_interval(delay)
		tw.tween_property(card, "modulate", Color(1, 1, 1, 1), 0.18)
		var kind = str(e.get("kind", "info"))
		tw.tween_callback(g.play_sfx.bind("coin" if kind == "sale" else ("fail" if kind == "return" else "reveal")))
		delay += 0.22 if events.size() < 10 else 0.08
	# Listings that didn't sell, and why
	var reps = s.get("listings", [])
	if reps.size() > 0:
		v.add_child(k.section("Still listed (%d)" % reps.size()))
		var lb = k.vbox(6)
		v.add_child(lb)
		var shown = 0
		for r in reps:
			if shown >= 6:
				lb.add_child(k.label("…and %d more in Stock." % (reps.size() - shown), "s", k.TEXT3))
				break
			lb.add_child(listing_card(r))
			shown += 1
	# Money
	var cols = k.grid(1 if ui.mobile else 2, 12, 12)
	var inp = k.panel("card", 12)
	inp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var iv = k.vbox(4)
	inp.add_child(iv)
	iv.add_child(k.label("MONEY IN", "xs", k.TEXT3))
	money_line(iv, "Sales", float(st.get("sales_revenue", 0)))
	if float(st.get("sales_revenue", 0)) == 0 and float(st.get("other_income", 0)) == 0:
		iv.add_child(k.label("Nothing today.", "s", k.TEXT3))
	if float(st.get("other_income", 0)) != 0:
		money_line(iv, "Other", float(st.get("other_income", 0)))
	cols.add_child(inp)
	var outp = k.panel("card", 12)
	outp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ov = k.vbox(4)
	outp.add_child(ov)
	ov.add_child(k.label("MONEY OUT", "xs", k.TEXT3))
	money_line(ov, "Buying stock", -float(st.get("buy_spend", 0)))
	money_line(ov, "Fees & postage", -(float(st.get("fees", 0)) + float(st.get("postage", 0))))
	money_line(ov, "Checks, repairs & auth", -(float(st.get("research", 0)) + float(st.get("repairs", 0)) + float(st.get("authentication", 0))))
	if float(st.get("business_spend", 0)) > 0:
		money_line(ov, "Business upgrades", -float(st.get("business_spend", 0)))
	money_line(ov, "Pitch fee", -float(s.get("pitch", 0)))
	var rc = s.get("running", {})
	if float(rc.get("total", 0)) > 0:
		money_line(ov, "Rent, fuel & wages", -float(rc.get("total", 0)))
	if float(st.get("interest", 0)) > 0:
		money_line(ov, "Overdraft interest", -float(st.get("interest", 0)))
	cols.add_child(outp)
	v.add_child(cols)
	# Day stats
	var f = k.flow(8, 6)
	f.add_child(k.chip("Bought %d" % int(st.get("items_bought", 0)), k.TEXT2, null, "s", "bag"))
	f.add_child(k.chip("Sold %d" % int(st.get("items_sold", 0)), k.GREEN, null, "s", "tag"))
	if int(st.get("returns", 0)) > 0:
		f.add_child(k.chip("Returns %d" % int(st.get("returns", 0)), k.RED, null, "s", "cross"))
	if int(st.get("discoveries", 0)) > 0:
		f.add_child(k.chip("Discoveries %d" % int(st.get("discoveries", 0)), k.PURPLE, null, "s", "spark"))
	f.add_child(k.chip("Challenges %d/%d" % [int(s.get("challenges_done", 0)), int(s.get("challenges_total", 0))], k.GOLD, null, "s", "trophy"))
	v.add_child(f)
	# Tomorrow
	v.add_child(k.section("Tomorrow"))
	var tp = k.panel("inset", 12)
	var th = k.hbox(12)
	tp.add_child(th)
	var w2 = str(g.market_today.get("weather", "overcast"))
	th.add_child(k.glyph(k.weather_glyph(w2), k.weather_color(w2), 36))
	var tv = k.vbox(2)
	k.expand(tv)
	var mt = str(g.market_today.get("type", "regular"))
	tv.add_child(k.label("Day %d: %s, %s" % [g.day, g.weather_name(w2), g.market_name(mt) if mt != "regular" else str(g.market_today.get("venue", ""))], "m", k.TEXT, true))
	tv.add_child(k.label(str(g.market_today.get("weather_line", "")), "s", k.TEXT3, true))
	if g.can_do_clearances() and g.clearance_leads.size() > 0:
		tv.add_child(k.label("%d house clearance job%s available." % [g.clearance_leads.size(), "" if g.clearance_leads.size() == 1 else "s"], "s", k.GOLD))
	th.add_child(tv)
	v.add_child(tp)
	var cont = k.button("Next morning  ›", "primary", func():
		g.play_sfx("confirm")
		ui.show_market(), "", "xl", 0, 60)
	v.add_child(k.spacer(0, 10))
	var outer = k.vbox(10)
	k.expand(outer, true)
	outer.add_child(ui.keyed_scroll("summary", ui.cap_width(v, 1100)))
	outer.add_child(ui.cap_width(cont, 1100))
	parent.add_child(outer)
	g.play_sfx("day_good" if cash_delta >= 0 else "day_bad")

func listing_card(r):
	var p = k.panel("card", 10)
	var h = k.hbox(10)
	p.add_child(h)
	var tv = k.vbox(2)
	k.expand(tv)
	var title = str(r.get("ident", "")) if str(r.get("ident", "")) != "" else str(r["name"])
	tv.add_child(k.label("%s · %s" % [title, g.fmt_money(r["price"])], "m", k.TEXT, true))
	var col = {"too_high": k.ORANGE, "unchecked": k.ORANGE, "slow_category": k.TEXT2, "watchers": k.GREEN, "fine": k.TEXT2}.get(str(r["key"]), k.TEXT2)
	tv.add_child(k.label(str(r["text"]), "s", col, true))
	tv.add_child(k.label("%d views · %d watching · night %d" % [int(r["views"]), int(r["watchers"]), int(r["days"])], "xs", k.TEXT3))
	h.add_child(tv)
	var uid = int(r["uid"])
	var drop_to = max(1.0, round(float(r["price"]) * 0.9))
	var btn = k.button("Drop to %s" % g.fmt_money(drop_to), "ghost", null, "Cut the price by 10%.", "s", 0, 40)
	btn.pressed.connect(func():
		var np = g.drop_listing_price(uid, 0.9)
		if np > 0.0:
			btn.text = "Now %s" % g.fmt_money(np)
			btn.disabled = true)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(btn)
	return p

func event_card(e):
	var kind = str(e.get("kind", "info"))
	var style = {"sale": "good", "return": "bad", "missed": "purple", "bad": "bad", "info": "card"}.get(kind, "card")
	if kind == "sale" and float(e.get("profit", 0.0)) < 0.0:
		style = "card"
	var p = k.panel(style, 10)
	var h = k.hbox(10)
	p.add_child(h)
	var gl = {"sale": "coin", "return": "cross", "missed": "q", "bad": "person", "info": "spark"}.get(kind, "spark")
	var col = {"sale": k.GREEN, "return": k.RED, "missed": k.PURPLE, "bad": k.RED, "info": k.TEXT2}.get(kind, k.TEXT2)
	if kind == "sale" and float(e.get("profit", 0.0)) < 0.0:
		col = k.TEXT2
	var gg = k.glyph(gl, col, 20)
	gg.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(gg)
	var tv = k.vbox(2)
	k.expand(tv)
	tv.add_child(k.label(str(e.get("text", "")), "m", k.TEXT, true))
	if str(e.get("sub", "")) != "":
		tv.add_child(k.label(str(e["sub"]), "s", k.TEXT3, true))
	h.add_child(tv)
	if e.has("profit"):
		h.add_child(k.label(g.money_signed(float(e["profit"])), "l", k.GREEN if float(e["profit"]) >= 0 else k.RED))
	return p

func money_line(parent, name, v):
	if abs(v) < 0.005:
		return
	var h = k.hbox(6)
	var l = k.label(name, "s", k.TEXT2)
	k.expand(l)
	h.add_child(l)
	h.add_child(k.label(g.money_signed(v), "s", k.GREEN if v >= 0 else k.RED))
	parent.add_child(h)

# ---------------------------------------------------------------------------
# More
# ---------------------------------------------------------------------------
func build_more(parent):
	var v = k.vbox(12)
	v.add_child(k.label("More", "xl", k.TEXT))
	var items = []
	if ui.mobile:
		items.append(["news", "Market news", "Trends, rumours and the week ahead", func(): ui.show_news()])
	items += [
		["trophy", "Achievements", "%d of %d unlocked" % [g.achievements.size(), g.ALL_ACHIEVEMENTS.size()], func(): ui.show_journal("achievements")],
		["gear", "Settings", "Sound, interface size, save codes", func(): ui.show_settings()],
		["q", "How to play", "The tutorial again", func(): ui.show_tutorial()],
		["list", "Playtest notes", "What's new, and a bug-report helper", func(): ui.show_notes()],
		["home", "Title screen", "Your game is saved", func():
			g.save_game()
			ui.show_title_screen()],
	]
	var gr = k.grid(1 if ui.mobile else 3, 10, 10)
	for it in items:
		var b = Button.new()
		b.focus_mode = Control.FOCUS_NONE
		k.style_button(b, "ghost", [12, 10, 12, 10])
		b.custom_minimum_size = Vector2(0, 72)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var h = k.hbox(12)
		h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		h.offset_left = 14
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var gl = k.glyph(it[0], k.GOLD, 24)
		gl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(gl)
		var tv = k.vbox(2)
		tv.alignment = BoxContainer.ALIGNMENT_CENTER
		tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tv.add_child(k.label(it[1], "m", k.TEXT))
		tv.add_child(k.label(it[2], "xs", k.TEXT3))
		h.add_child(tv)
		b.add_child(h)
		b.pressed.connect(it[3])
		gr.add_child(b)
	v.add_child(gr)
	v.add_child(k.section("Today's challenges"))
	for c in g.daily_challenges:
		var done = g.check_daily_challenge(c)
		var h2 = k.hbox(8)
		h2.add_child(k.glyph("check" if done else "dots", k.GREEN if done else k.TEXT3, 14))
		h2.add_child(k.label("%s  (%d/%d)" % [c["desc"], min(int(g.day_stats.get(c["type"], 0)), int(c["target"])), int(c["target"])], "s", k.GREEN if done else k.TEXT2, true))
		v.add_child(h2)
	v.add_child(k.spacer(0, 20))
	parent.add_child(ui.keyed_scroll("more", ui.cap_width(v, 1100)))

func challenges_line():
	return "%d of %d done today" % [g.daily_challenges_completed_count(), g.daily_challenges.size()]

# ---------------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------------
func build_settings(parent):
	var v = k.vbox(14)
	var back_title = g.on_title_screen or not g.has_save
	v.add_child(k.button("‹ Back", "ghost", func():
		if back_title:
			ui.show_title_screen()
		else:
			ui.show_more(), "", "s"))
	v.add_child(k.label("Settings", "xl", k.TEXT))
	v.add_child(slider_row("Master volume", g.master_volume, func(val):
		g.master_volume = val
		g.apply_settings()
		g.save_settings()))
	v.add_child(slider_row("Music", g.music_volume, func(val):
		g.music_volume = val
		g.apply_music_volume()
		g.save_settings()))
	v.add_child(toggle_row("Sound effects", g.sfx_enabled, func(on):
		g.sfx_enabled = on
		g.save_settings()))
	v.add_child(toggle_row("Show dice rolls as pop-ups", g.show_rng_toasts, func(on):
		g.show_rng_toasts = on
		g.save_settings()))
	var sz = k.hbox(8)
	sz.add_child(k.label("Interface size", "m", k.TEXT2))
	sz.add_child(k.spacer(0, 0, true))
	for s in [[0.85, "Small"], [1.0, "Normal"], [1.15, "Large"], [1.3, "Huge"]]:
		var val = s[0]
		sz.add_child(k.button(s[1], "tab_on" if abs(g.ui_scale - val) < 0.01 else "ghost", func():
			g.ui_scale = val
			g.save_settings()
			ui.adjust_scale()
			g.call_deferred("_ui_rerender"), "", "s"))
	v.add_child(sz)
	if not OS.has_feature("web"):
		v.add_child(toggle_row("Fullscreen", g.fullscreen, func(on):
			g.fullscreen = on
			g.save_settings()
			g.apply_settings()))
	v.add_child(k.section("Save codes"))
	v.add_child(k.label("Copy a code to back up your game or move it to another device.", "s", k.TEXT3, true))
	var te = TextEdit.new()
	te.custom_minimum_size = Vector2(0, 90)
	te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	te.text = save_code_text
	te.add_theme_font_size_override("font_size", 12)
	v.add_child(te)
	var row = k.flow(8, 8)
	row.add_child(k.button("Make a save code", "action", func():
		save_code_text = g.export_save_code()
		DisplayServer.clipboard_set(save_code_text)
		g.add_toast("Save code copied to the clipboard.", "success")
		ui.refresh(), "", "s"))
	row.add_child(k.button("Load this code", "danger", func():
		if g.import_save_code(te.text):
			g.has_save = true
			g.add_toast("Save loaded.", "success")
			ui.show_title_screen()
		else:
			g.add_toast("That code didn't work.", "error"), "Replaces your current game.", "s"))
	row.add_child(k.button("Reset first-time tips", "ghost", func():
		g.tips_seen = {}
		g.save_settings()
		g.add_toast("Tips will show again.", "info"), "", "s"))
	v.add_child(row)
	v.add_child(k.spacer(0, 20))
	var center = k.margin(v, 0 if ui.mobile else int(max(0.0, (ui.logical.x - 900.0) / 3.0)), 0)
	parent.add_child(ui.keyed_scroll("settings", center))

func slider_row(name, value, cb):
	var h = k.hbox(12)
	var l = k.label(name, "m", k.TEXT2)
	l.custom_minimum_size = Vector2(180 if not ui.mobile else 120, 0)
	h.add_child(l)
	var s = HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(0, 32)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.value_changed.connect(cb)
	h.add_child(s)
	return h

func toggle_row(name, on, cb):
	var h = k.hbox(12)
	var l = k.label(name, "m", k.TEXT2)
	k.expand(l)
	h.add_child(l)
	var c = CheckButton.new()
	c.button_pressed = on
	c.toggled.connect(cb)
	h.add_child(c)
	return h

# ---------------------------------------------------------------------------
# Tutorial
# ---------------------------------------------------------------------------
const SLIDES = [
	{"glyph": "stall", "title": "Welcome to the car boot", "body": "You've got £300, two hands and a spare room. Every morning you walk the car boot and buy things you think are worth more than the asking price. Then you sell them online.\n\nFour nights in the red with nothing you could sell to cover it, and you're finished."},
	{"glyph": "person", "title": "Know your sellers", "body": "Clueless sellers price at random. Dealers know what things are worth. Dodgy sellers are cheap for a reason.\n\nMany of them are regulars. Treat them well and they'll warm to you: better haggles, things put aside for you, tip-offs about house clearances."},
	{"glyph": "glass", "title": "Look before you buy", "body": "INSPECT is a quick glance, and it can be wrong. CHECK CONDITION gives the exact score and hidden damage. RESEARCH shows recent sold prices and your margin after fees.\n\nFees and postage eat cheap stuff. Only buy when there's a real gap."},
	{"glyph": "q", "title": "Everything has a story", "body": "Items hide details: a first pressing, a hallmark under the tarnish, a missing battery door, a signature that's printed, a gem buried in a box of junk.\n\nPurple clues tell you something's there. Checks, expertise and workshop kit identify it. Anything you miss, a buyer will spot, for better or worse."},
	{"glyph": "star", "title": "Become an expert", "body": "Selling and researching in a category builds your expertise. Enthusiasts see subtle tells. Specialists get a hands-on check at the stall (read the run-out, check the labels, loupe the hallmarks). Experts get a collector contact.\n\nPick a few categories you love."},
	{"glyph": "tag", "title": "Sell overnight", "body": "At home, test electricals, fix what you can and set a price. Buyers turn up overnight when you end the day. Price low to sell fast, high to earn more.\n\nUnchecked faults and fakes come back as returns, and that hurts your seller rating."},
	{"glyph": "shop", "title": "Build the business", "body": "Save up for a garage, then a lock-up, a shop and one day a warehouse. Fit out your workshop, get a van and do house clearances. Hire staff.\n\nGood luck. Don't go skint."},
]

func build_tutorial(parent):
	var idx = clamp(ui.tutorial_index, 0, SLIDES.size() - 1)
	var sl = SLIDES[idx]
	var center = CenterContainer.new()
	k.expand(center, true)
	parent.add_child(center)
	var p = k.panel("modal", 24)
	p.custom_minimum_size = Vector2(min(620, ui.logical.x - 24), 0)
	center.add_child(p)
	var v = k.vbox(14)
	p.add_child(v)
	var gl = k.glyph(sl["glyph"], k.GOLD, 56)
	gl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(gl)
	v.add_child(k.label(sl["title"], "xxl", k.GOLD, true, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(k.label(sl["body"], "b", k.TEXT, true))
	var dots = k.hbox(6)
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in range(SLIDES.size()):
		var d = PanelContainer.new()
		d.custom_minimum_size = Vector2(10, 10)
		d.add_theme_stylebox_override("panel", k.sbox(k.GOLD if i == idx else k.PANEL3, null, 5, 0, 0))
		dots.add_child(d)
	v.add_child(dots)
	var row = k.hbox(10)
	if idx > 0:
		row.add_child(k.button("Back", "ghost", func():
			ui.tutorial_index -= 1
			ui.refresh(), "", "m", 110, 48))
	else:
		row.add_child(k.button("Skip", "ghost", func(): finish_tutorial(), "", "m", 110, 48))
	row.add_child(k.spacer(0, 0, true))
	var last = idx >= SLIDES.size() - 1
	row.add_child(k.button("Let's go" if last else "Next", "primary", func():
		if last:
			finish_tutorial()
		else:
			ui.tutorial_index += 1
			ui.refresh(), "", "m", 150, 48))
	v.add_child(row)

func finish_tutorial():
	g.tutorial_seen = true
	ui.tutorial_index = 0
	g.save_game()
	if g.has_save and not g.game_over:
		continue_game()
	else:
		ui.show_title_screen()

# ---------------------------------------------------------------------------
# Bankruptcy & notes
# ---------------------------------------------------------------------------
func build_bankruptcy(parent):
	var center = CenterContainer.new()
	k.expand(center, true)
	parent.add_child(center)
	var p = k.panel("bad", 24)
	p.custom_minimum_size = Vector2(min(560, ui.logical.x - 24), 0)
	center.add_child(p)
	var v = k.vbox(12)
	p.add_child(v)
	v.add_child(k.label("GONE UNDER", "hero", k.RED, false, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(k.label("Four nights in the red. The bank's taken the keys.", "m", k.TEXT, true, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(k.label("You lasted %d days, sold %d things and hit a best business value of %s." % [g.day, g.sold_history.size(), g.fmt_money(g.best_net_worth)], "b", k.TEXT2, true, HORIZONTAL_ALIGNMENT_CENTER))
	var b = k.button("Start again", "primary", func(): g.start_new_game(), "", "l", 0, 56)
	v.add_child(b)
	v.add_child(k.button("Title screen", "ghost", func(): ui.show_title_screen(), "", "m"))

func build_notes(parent):
	var v = k.vbox(12)
	v.add_child(k.button("‹ Back", "ghost", func(): ui.show_more(), "", "s"))
	v.add_child(k.label("Playtest notes", "xl", k.TEXT))
	for sec in g.patch_notes:
		v.add_child(k.section(sec["version"]))
		for n in sec["notes"]:
			var h = k.hbox(8)
			h.add_child(k.glyph("spark", k.GOLD, 12))
			h.add_child(k.label(n, "s", k.TEXT2, true))
			v.add_child(h)
	v.add_child(k.section("Dice log"))
	v.add_child(k.label("Every roll is shown. Odds that would give away an item's hidden value stay hidden until the truth comes out.", "xs", k.TEXT3, true))
	var lp = k.panel("inset", 10)
	var lv = k.vbox(3)
	lp.add_child(lv)
	for i in range(g.rng_log.size() - 1, max(-1, g.rng_log.size() - 41), -1):
		lv.add_child(k.label(ui.item.strip_bb(g.rng_log[i]), "xs", k.TEXT2, true))
	v.add_child(lp)
	v.add_child(k.section("Found a bug?"))
	v.add_child(k.label("Copy this and paste it into your report. It includes a save code so we can see exactly what happened.", "s", k.TEXT3, true))
	v.add_child(k.button("Copy bug report info", "action", func():
		DisplayServer.clipboard_set(g.bug_report_text())
		g.add_toast("Copied.", "success"), "", "m"))
	v.add_child(k.spacer(0, 20))
	parent.add_child(ui.keyed_scroll("notes", v))
