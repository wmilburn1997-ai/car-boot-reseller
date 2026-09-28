extends RefCounted
# The market hub, individual stalls, side deals and house clearances.

var ui
var g
var k

const ARCH_COLORS = {
	"Desperate Seller": Color(0.98, 0.64, 0.30),
	"House Clearance": Color(0.75, 0.62, 0.45),
	"Clueless Seller": Color(0.40, 0.85, 0.86),
	"Regular Seller": Color(0.72, 0.77, 0.84),
	"Collector": Color(0.74, 0.56, 0.98),
	"Dodgy Seller": Color(0.93, 0.50, 0.44),
	"Dealer": Color(0.95, 0.77, 0.33),
}

func _init(root):
	ui = root
	g = root.g
	k = root.k

func arch_color(a):
	return ARCH_COLORS.get(a, k.TEXT2)

# ---------------------------------------------------------------------------
# Market hub
# ---------------------------------------------------------------------------
func build_market(parent):
	var v = k.vbox(12)
	v.add_child(market_header())
	if g.current_time_minutes >= 12 * 60:
		v.add_child(closing_card())
	else:
		var leads = leads_card()
		if leads != null:
			v.add_child(leads)
		v.add_child(k.section("%d stalls today" % g.stalls.size()))
		var cols = 1 if ui.mobile else (3 if ui.logical.x < 1500 else 4)
		var gr = k.grid(cols, 10, 10)
		for i in range(g.stalls.size()):
			var c = stall_card(i)
			c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			gr.add_child(c)
		v.add_child(gr)
	var extras = k.grid(1 if ui.mobile else 3, 10, 10)
	var mb = mystery_card()
	if mb != null:
		extras.add_child(mb)
	extras.add_child(news_card())
	extras.add_child(fixer_card())
	v.add_child(k.section("Round the edges"))
	v.add_child(extras)
	v.add_child(k.section("The week ahead"))
	v.add_child(week_strip())
	v.add_child(k.spacer(0, 20))
	parent.add_child(ui.keyed_scroll("market", v))

func market_header():
	var p = k.panel("card2", 14)
	var h = k.hbox(14)
	p.add_child(h)
	var w = str(g.market_today.get("weather", "overcast"))
	var wg = k.glyph(k.weather_glyph(w), k.weather_color(w), 44 if not ui.mobile else 36)
	wg.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(wg)
	var tv = k.vbox(4)
	k.expand(tv)
	var mtype = str(g.market_today.get("type", "regular"))
	var tr = k.flow(8, 4)
	tr.add_child(k.label(str(g.market_today.get("venue", "The Car Boot")), "xl", k.TEXT))
	if mtype != "regular":
		tr.add_child(k.chip(g.market_name(mtype), k.GOLD, null, "s", "star"))
	tv.add_child(tr)
	var line = str(g.market_today.get("weather_line", ""))
	if line != "":
		tv.add_child(k.label("%s. %s" % [g.weather_name(w), line], "s", k.TEXT2, true))
	var intro = str(g.market_today.get("intro", ""))
	if intro != "" and mtype != "regular":
		tv.add_child(k.label(intro, "s", k.GOLD.lightened(0.2), true))
	var info = k.flow(8, 4)
	info.add_child(k.chip("Day %d" % g.day, k.TEXT2, null, "xs", "cal"))
	info.add_child(k.chip("%s, closes 12:00" % g.format_time(), k.GOLD, null, "xs", "clock"))
	info.add_child(k.chip("Pitch fee %s" % g.fmt_money(g.daily_expenses), k.TEXT3, null, "xs", "coin"))
	if g.market_today.get("rival_here", false):
		info.add_child(k.chip("%s is about" % g.rival.get("nickname", "The rival"), k.RED, null, "xs", "person"))
	tv.add_child(info)
	h.add_child(tv)
	return p

func closing_card():
	var p = k.panel("gold", 16)
	var v = k.vbox(10)
	p.add_child(v)
	v.add_child(k.label("The field's emptying out.", "xl", k.GOLD))
	v.add_child(k.label("Head home: test, research and list what you bought, then end the day to see what sells overnight.", "b", k.TEXT2, true))
	var row = k.hbox(10)
	row.add_child(k.button("Go to your stock", "action", func(): ui.show_inventory(true), "", "m", 200, 48))
	row.add_child(k.button("End day", "primary", func(): g.end_day(), "", "m", 160, 48))
	v.add_child(row)
	return p

func rel_dots(rel):
	return k.dots(g.rel_tier(rel), 3, k.GOLD if rel >= 0 else k.RED)

func stall_card(i):
	var stall = g.stalls[i]
	var banned = g.to_bool(stall.get("banned_today", false))
	var packed = g.current_time_minutes >= int(stall["packing_minute"])
	var here = i == g.current_stall_index and stall.get("visited", false)
	var b = Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var ac = arch_color(stall["seller"])
	var border = ac.darkened(0.45) if not (packed or banned) else k.LINE
	if here:
		border = k.GOLD
	b.add_theme_stylebox_override("normal", k.sbox(k.PANEL, border, 8, 2 if here else 1, 12))
	b.add_theme_stylebox_override("hover", k.sbox(k.PANEL2, ac.darkened(0.2), 8, 2 if here else 1, 12))
	b.add_theme_stylebox_override("pressed", k.sbox(k.PANEL, border, 8, 1, 12))
	b.add_theme_stylebox_override("disabled", k.sbox(Color(0.06, 0.07, 0.09), k.LINE, 8, 1, 12))
	b.add_theme_stylebox_override("focus", k.sbox(Color(0, 0, 0, 0), null, 8, 0, 0))
	b.custom_minimum_size = Vector2(0, 104 if not ui.mobile else 92)
	var v = k.vbox(4)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 12
	v.offset_right = -12
	v.offset_top = 10
	v.offset_bottom = -10
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top = k.hbox(8)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var nm = k.label("%d  %s" % [i + 1, stall.get("seller_full_name", stall["seller_display_name"])], "m", k.TEXT if not (packed or banned) else k.TEXT3)
	nm.clip_text = true
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(nm)
	var rid = int(stall.get("regular_id", -1))
	if rid >= 0:
		var r = g.regular_by_id(rid)
		if r != null and int(r["visits"]) > 0:
			top.add_child(rel_dots(float(r["rel"])))
	v.add_child(top)
	var chips = k.hbox(6)
	chips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chips.add_child(k.chip(stall["seller"], ac))
	var p = g.personality_of(stall)
	if p != null:
		chips.add_child(k.chip(p["name"], k.TEXT3))
	v.add_child(chips)
	var status = ""
	var sc = k.TEXT3
	if banned:
		status = "Thrown off for today"
		sc = k.RED
	elif packed:
		status = "Packed up and gone"
	else:
		status = "Packs up %s · seen %d/%d" % [g.minute_to_clock(stall["packing_minute"]), int(stall["revealed"]), stall["stock"].size()]
		sc = k.TEXT2
	var st = k.hbox(6)
	st.mouse_filter = Control.MOUSE_FILTER_IGNORE
	st.add_child(k.label(status, "xs", sc))
	if stall.get("rival_visited", false):
		st.add_child(k.chip("%s's been" % g.rival.get("nickname", "Rival"), k.RED))
	if stall.get("visited", false) and not packed:
		st.add_child(k.glyph("check", k.GREEN, 12))
	v.add_child(st)
	b.add_child(v)
	b.disabled = packed or banned
	b.pressed.connect(func():
		g.play_sfx("click")
		ui.sheet_open = false
		g.go_to_stall(i))
	return b

func leads_card():
	if not g.can_do_clearances() or g.clearance_leads.size() == 0:
		return null
	var p = k.panel("gold", 14)
	var v = k.vbox(10)
	p.add_child(v)
	var h = k.hbox(8)
	h.add_child(k.glyph("home", k.GOLD, 20))
	h.add_child(k.label("House clearance jobs", "l", k.GOLD))
	v.add_child(h)
	var early = g.current_time_minutes <= 7 * 60 + 30 + int(g.market_today.get("start_offset", 0))
	for lead in g.clearance_leads:
		var st = g.WorldData.CLEARANCE_STORIES[int(lead["story"])]
		var row = k.hbox(12)
		var tv = k.vbox(2)
		k.expand(tv)
		tv.add_child(k.label(st["title"], "m", k.TEXT, true))
		var src = ("Tip-off from %s" % lead["from"]) if lead.get("source", "") == "tip" else "Local paper"
		tv.add_child(k.label("%s · %s house · until day %d" % [src, str(lead["size"]).capitalize(), int(lead["expires"])], "xs", k.TEXT3))
		row.add_child(tv)
		var b = k.button("Do it today" if early else "Tomorrow, first thing", "primary" if early else "ghost", func(): g.start_clearance(lead["id"]), "A clearance takes your whole morning instead of the car boot.", "s")
		b.disabled = not early
		row.add_child(b)
		v.add_child(row)
	return p

func mystery_card():
	if g.mystery_packages_left <= 0:
		return null
	var p = k.panel("card", 12)
	var v = k.vbox(6)
	p.add_child(v)
	var h = k.hbox(8)
	h.add_child(k.glyph("box", k.PURPLE, 18))
	h.add_child(k.label("Mystery boxes", "m", k.TEXT))
	v.add_child(h)
	v.add_child(k.label("Sealed boxes, £30 each. One or two things inside. On average they're worth less than you pay.", "xs", k.TEXT3, true))
	var b = k.button("Buy one (%d left)" % g.mystery_packages_left, "special", func(): g.buy_mystery_package(), "", "s")
	b.disabled = g.cash < 30.0
	v.add_child(b)
	return p

func news_card():
	var p = k.panel("card", 12)
	var v = k.vbox(6)
	p.add_child(v)
	var h = k.hbox(8)
	h.add_child(k.glyph("news", k.TEAL, 18))
	h.add_child(k.label("This week's news", "m", k.TEXT))
	v.add_child(h)
	var t = str(g.week_news.get("text", "Quiet week."))
	v.add_child(k.label(t, "s", k.TEXT2, true))
	v.add_child(k.button("Trends & rumours", "ghost", func(): ui.show_news(), "", "s"))
	return p

func fixer_card():
	var p = k.panel("card", 12)
	var v = k.vbox(6)
	p.add_child(v)
	var h = k.hbox(8)
	h.add_child(k.glyph("coin", k.RED, 18))
	h.add_child(k.label("The Fixer", "m", k.TEXT))
	v.add_child(h)
	var done = g.fixer_uses_today >= g.fixer_max_uses()
	v.add_child(k.label("Round the back of the burger van. Double or nothing, 46%% odds. %s" % ("Done for today." if done else ""), "xs", k.TEXT3, true))
	var row = k.hbox(6)
	var wagers = [25, 75, 200]
	if g.player_level >= 5:
		wagers.append(350)
	for w in wagers:
		var b = k.button("£%d" % w, "danger", func(): g.fixer_gamble(w), "46%% chance to get £%d back." % (w * 2), "s")
		b.disabled = done or g.cash < w
		row.add_child(b)
	v.add_child(row)
	return p

func week_strip():
	var cols = 7 if not ui.mobile else 4
	var gr = k.grid(cols, 6, 6)
	g.ensure_week_plan()
	var shown = 0
	for e in g.week_plan:
		if shown >= (7 if not ui.mobile else 4):
			break
		shown += 1
		var p = k.panel("card" if int(e["day"]) != g.day else "gold", 8)
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var v = k.vbox(2)
		p.add_child(v)
		var h = k.hbox(6)
		h.add_child(k.glyph(k.weather_glyph(e["weather"]), k.weather_color(e["weather"]), 16))
		h.add_child(k.label("Day %d" % int(e["day"]), "s", k.TEXT if int(e["day"]) != g.day else k.GOLD))
		v.add_child(h)
		var special = str(e["type"]) != "regular"
		v.add_child(k.label(g.market_name(e["type"]) if special else g.weather_name(e["weather"]), "xs", k.GOLD if special else k.TEXT3, true))
		gr.add_child(p)
	return gr

# ---------------------------------------------------------------------------
# A stall
# ---------------------------------------------------------------------------
func visible_items(stall):
	var out = []
	for i in range(int(stall["revealed"])):
		if i >= stall["stock"].size():
			break
		var it = stall["stock"][i]
		if it["dismissed"]:
			continue
		out.append(i)
	return out

func selected_index(stall, vis):
	for i in vis:
		if int(stall["stock"][i]["uid"]) == g.selected_stall_uid:
			return i
	return -1

func build_stall(parent):
	var stall = g.stalls[g.current_stall_index]
	g.on_stall_visit(stall)
	var closed = g.current_time_minutes >= int(stall["packing_minute"]) or g.to_bool(stall.get("banned_today", false))
	var vis = visible_items(stall)
	var sel = selected_index(stall, vis)
	if sel < 0 and not ui.mobile and vis.size() > 0:
		sel = vis[0]
		g.selected_stall_uid = int(stall["stock"][sel]["uid"])
	var list = k.vbox(8)
	list.add_child(stall_header(stall, closed))
	if not closed:
		if vis.size() == 0:
			list.add_child(k.label("Nothing on the table takes your fancy. Dig deeper or move on.", "b", k.TEXT3, true))
		var new_from = int(stall.get("new_from", 999))
		for i in vis:
			var it = stall["stock"][i]
			var idx = i
			var t = ui.item.tile(it, "stall", i == sel and not ui.mobile, func():
				g.selected_stall_uid = int(it["uid"])
				ui.sheet_open = true
				ui.refresh(), {"new": i >= new_from})
			list.add_child(t)
		list.add_child(stall_buttons(stall))
	list.add_child(k.spacer(0, 16))
	var detail = k.vbox(10)
	if sel >= 0 and not closed:
		detail.add_child(ui.item.detail(stall["stock"][sel], "stall", sel, stall))
		if not ui.mobile:
			detail.add_child(k.spacer(0, 4))
			var bb = ui.item.buy_button(stall["stock"][sel], sel, stall)
			detail.add_child(bb)
			detail.add_child(dismiss_row(sel))
	else:
		detail.add_child(seller_detail(stall))
	ui.master_detail(parent, "stall%d" % g.current_stall_index, list, detail, 1.0)
	if ui.mobile and ui.sheet_open and sel >= 0 and not closed:
		var it2 = stall["stock"][sel]
		var body = ui.item.detail(it2, "stall", sel, stall)
		var foot = k.hbox(8)
		foot.add_child(ui.item.buy_button(it2, sel, stall))
		foot.add_child(k.icon_button("cross", func():
			g.dismiss_stall_item(sel)
			ui.sheet_open = false
			ui.refresh(), "Not interested: hide it", "ghost", 52))
		ui.open_sheet(it2["name"], body, foot, func(): g.selected_stall_uid = -1)
	if g.pending_special_offer != null:
		special_offer_modal()

func dismiss_row(sel):
	var h = k.hbox(8)
	h.add_child(k.spacer(0, 0, true))
	h.add_child(k.button("Not interested", "ghost", func():
		g.dismiss_stall_item(sel)
		g.selected_stall_uid = -1
		ui.refresh(), "Hide it from the list.", "s"))
	return h

func stall_header(stall, closed):
	var p = k.panel("card2", 12)
	var v = k.vbox(8)
	p.add_child(v)
	var top = k.hbox(8)
	var back = k.icon_button("left", func():
		ui.sheet_open = false
		ui.show_market(), "Back to the market (Esc)", "ghost", 38)
	back.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top.add_child(back)
	var nv = k.vbox(2)
	k.expand(nv)
	var nm = k.label(stall.get("seller_full_name", stall["seller_display_name"]), "l", k.TEXT)
	nm.clip_text = true
	nv.add_child(nm)
	var chips = k.flow(6, 4)
	chips.add_child(k.chip(stall["seller"], arch_color(stall["seller"])))
	var pers = g.personality_of(stall)
	if pers != null:
		chips.add_child(k.chip(pers["name"], k.TEXT2))
	var rid = int(stall.get("regular_id", -1))
	var reg = g.regular_by_id(rid) if rid >= 0 else null
	if reg != null:
		chips.add_child(k.chip(g.rel_name(float(reg["rel"])), k.GOLD if float(reg["rel"]) >= 20 else k.TEXT3, null, "xs", "heart"))
	nv.add_child(chips)
	top.add_child(nv)
	var tv = k.vbox(0)
	tv.add_child(k.label("Stall %d/%d" % [g.current_stall_index + 1, g.stalls.size()], "xs", k.TEXT3, false, HORIZONTAL_ALIGNMENT_RIGHT))
	tv.add_child(k.label("packs up %s" % g.minute_to_clock(stall["packing_minute"]), "s", k.GOLD, false, HORIZONTAL_ALIGNMENT_RIGHT))
	top.add_child(tv)
	v.add_child(top)
	# What the seller's saying
	var line = ""
	for key in ["last_line", "saved_line", "tipoff_line", "greeting"]:
		if str(stall.get(key, "")) != "":
			line = str(stall[key])
			break
	if line != "":
		var bubble = k.panel("inset", 10)
		var bh = k.hbox(8)
		bh.add_child(k.glyph("person", arch_color(stall["seller"]), 16))
		bh.add_child(k.label("\"%s\"" % line.strip_edges().trim_prefix("\"").trim_suffix("\""), "s", k.TEXT, true))
		bubble.add_child(bh)
		v.add_child(bubble)
	if not ui.mobile:
		var about = "%s %s" % [g.seller_blurbs.get(stall["seller"], ""), (pers["blurb"] if pers != null else "")]
		v.add_child(k.label(about, "xs", k.TEXT3, true))
	var info = k.flow(8, 4)
	info.add_child(k.chip("Seen %d/%d" % [int(stall["revealed"]), stall["stock"].size()], k.TEXT2, null, "xs", "eye"))
	info.add_child(k.chip("Carry %d/%d" % [g.carry_used, g.effective_bag_capacity()], k.BLUE, null, "xs", "bag"))
	if g.special_event_profiles.has(stall["seller"]):
		info.add_child(k.chip("Might have more in the car", k.GOLD.darkened(0.1), null, "xs", "q"))
	var eta = int(stall.get("rival_eta", -1))
	if eta > 0 and not stall.get("rival_visited", false) and eta - g.current_time_minutes <= 20 and eta >= g.current_time_minutes:
		info.add_child(k.chip("%s is heading this way" % g.rival.get("nickname", "The rival"), k.RED, null, "xs", "person"))
	elif stall.get("rival_visited", false) and stall.get("rival_took", []).size() > 0:
		info.add_child(k.chip("%s took: %s" % [g.rival.get("nickname", "Rival"), ", ".join(stall["rival_took"])], k.RED, null, "xs", "person"))
	v.add_child(info)
	if closed:
		var msg = "You've been thrown off this stall for the day." if g.to_bool(stall.get("banned_today", false)) else "They've packed up and gone home."
		v.add_child(k.label(msg, "m", k.RED, true))
	return p

func stall_buttons(stall):
	var row = k.hbox(8)
	var left = stall["stock"].size() - int(stall["revealed"])
	var dig = k.action_tile("glass", "Dig deeper" if left > 0 else "Seen it all", "4 energy · 8m · %d more under the table" % left if left > 0 else "", "action", func(): g.browse_stall(), left <= 0 or g.energy < 4, "Rummage through the boxes under the table. (D)")
	row.add_child(dig)
	var nxt = k.action_tile("right", "Next stall", "5m walk", "ghost", func():
		ui.sheet_open = false
		g.next_stall(), false, "Walk to the next stall. (N)")
	row.add_child(nxt)
	return row

func seller_detail(stall):
	var v = k.vbox(12)
	var pers = g.personality_of(stall)
	v.add_child(k.label(stall.get("seller_full_name", stall["seller_display_name"]), "xl", k.TEXT))
	v.add_child(k.chip(stall["seller"], arch_color(stall["seller"]), null, "s"))
	v.add_child(k.label(g.seller_blurbs.get(stall["seller"], ""), "b", k.TEXT2, true))
	if pers != null:
		v.add_child(k.label("%s: %s" % [pers["name"], pers["blurb"]], "s", k.TEXT3, true))
	var d = int(stall.get("dressing", 0))
	if d >= 0 and d < g.WorldData.STALL_DRESSING.size():
		v.add_child(k.rich("[i]%s[/i]" % g.WorldData.STALL_DRESSING[d], "s", k.TEXT3))
	var rid = int(stall.get("regular_id", -1))
	var reg = g.regular_by_id(rid) if rid >= 0 else null
	if reg != null:
		v.add_child(k.section("You and %s" % reg["first"]))
		var rh = k.hbox(10)
		rh.add_child(rel_dots(float(reg["rel"])))
		rh.add_child(k.label(g.rel_name(float(reg["rel"])), "m", k.GOLD))
		v.add_child(rh)
		var facts = "Visits: %d · Bought from them: %d" % [int(reg["visits"]), int(reg["bought"])]
		if str(reg.get("last_item", "")) != "":
			facts += " · Last buy: %s" % reg["last_item"]
		v.add_child(k.label(facts, "s", k.TEXT2, true))
		v.add_child(k.label("Regulars warm to you when you buy and make fair offers. Friends put things aside for you and tip you off about house clearances.", "xs", k.TEXT3, true))
	return v

func special_offer_modal():
	var offer = g.pending_special_offer
	var it = offer["item"]
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	ui.sheet_layer.add_child(dim)
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.sheet_layer.add_child(center)
	var p = k.panel("gold", 18)
	p.custom_minimum_size = Vector2(min(520, ui.logical.x - 30), 0)
	center.add_child(p)
	var v = k.vbox(10)
	p.add_child(v)
	v.add_child(k.label("\"Actually mate, before you go...\"", "l", k.GOLD, true))
	v.add_child(k.label("%s: %s" % [offer["seller_display_name"], offer["title"]], "m", k.TEXT, true))
	v.add_child(k.label(str(offer["flavor"]).replace("\"", ""), "s", k.TEXT2, true))
	var h = k.hbox(10)
	h.add_child(k.cat_icon(it["category"], 44))
	var tv = k.vbox(2)
	k.expand(tv)
	tv.add_child(k.label(it["name"], "l", k.TEXT, true))
	var line = it["category"]
	if it["rarity"] != "Common":
		line += "  ·  %s 1/%d" % [it["rarity"], int(it["one_in"])]
	if float(it["fake_chance"]) >= 0.05:
		line += "  ·  fake risk %s" % g.fake_risk_label(float(it["fake_chance"])).to_lower()
	tv.add_child(k.label(line, "s", k.TEXT3, true))
	h.add_child(tv)
	h.add_child(k.label(g.fmt_money(it["asking"]), "xxl", k.GOLD))
	v.add_child(h)
	v.add_child(k.label("Straight out of the car: no inspecting, no research, no haggling. Take it or leave it.", "s", k.TEXT3, true))
	var row = k.hbox(10)
	var take = k.button("Take it  %s" % g.fmt_money(it["asking"]), "buy", func(): g.accept_special_offer(), "", "m", 0, 50)
	take.disabled = float(it["asking"]) > g.cash
	take.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(take)
	row.add_child(k.button("Walk away", "ghost", func(): g.decline_special_offer(), "", "m", 140, 50))
	v.add_child(row)

# ---------------------------------------------------------------------------
# House clearance
# ---------------------------------------------------------------------------
func build_clearance(parent):
	var c = g.clearance
	var lead = c["lead"]
	var st = g.WorldData.CLEARANCE_STORIES[int(lead["story"])]
	var v = k.vbox(12)
	var head = k.panel("gold", 16)
	var hv = k.vbox(8)
	head.add_child(hv)
	var th = k.hbox(10)
	th.add_child(k.glyph("home", k.GOLD, 28))
	var tt = k.vbox(2)
	k.expand(tt)
	tt.add_child(k.label(st["title"], "xl", k.GOLD, true))
	tt.add_child(k.label(st["owner"], "s", k.TEXT2, true))
	th.add_child(tt)
	hv.add_child(th)
	hv.add_child(k.label(st["story"], "b", k.TEXT, true))
	hv.add_child(k.label("The family want it all gone today, for one fixed price. Look round as much as your energy allows, then decide. Junk goes to the skip; you take the rest.", "s", k.TEXT3, true))
	v.add_child(head)
	# The deal
	var deal = k.panel("card2", 14)
	var dh = k.hbox(16)
	deal.add_child(dh)
	var seen_est = 0.0
	var seen_n = 0
	for room in c["rooms"]:
		if room["looked"]:
			for idx in room["items"]:
				seen_est += g.perceived_center(c["items"][idx])
				seen_n += 1
	var left = k.vbox(0)
	left.add_child(k.label("THEIR PRICE", "xs", k.TEXT3))
	left.add_child(k.label(g.fmt_money(c["price"]), "xxl", k.GOLD))
	left.add_child(k.label("for %d items (%d storage)" % [c["items"].size(), g.clearance_space_needed()], "xs", k.TEXT3))
	dh.add_child(left)
	var mid = k.vbox(0)
	k.expand(mid)
	mid.add_child(k.label("WHAT YOU'VE SEEN", "xs", k.TEXT3))
	mid.add_child(k.label("%d items, roughly %s" % [seen_n, g.fmt_money(seen_est)] if seen_n > 0 else "Nothing yet: have a look round", "l", k.TEAL))
	mid.add_child(k.label("Rough, before fees. The rooms you haven't seen could hold anything.", "xs", k.TEXT3, true))
	dh.add_child(mid)
	v.add_child(deal)
	var actions = k.hbox(10)
	var free = g.storage_capacity() - g.inventory_space_used()
	var take = k.button("Take the job  %s" % g.fmt_money(c["price"]), "buy", func(): g.accept_clearance(), "", "m", 0, 52)
	take.disabled = g.cash < float(c["price"]) or free < g.clearance_space_needed()
	if free < g.clearance_space_needed():
		take.text = "Not enough storage (%d free)" % free
	take.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(take)
	actions.add_child(k.button("Walk away", "ghost", func(): g.walk_away_clearance(), "", "m", 150, 52))
	v.add_child(actions)
	# Rooms
	v.add_child(k.section("The house"))
	var cols = 1 if ui.mobile else 2
	var gr = k.grid(cols, 10, 10)
	for ri in range(c["rooms"].size()):
		var room = c["rooms"][ri]
		var rp = k.panel("card", 12)
		rp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var rv = k.vbox(6)
		rp.add_child(rv)
		var rh = k.hbox(8)
		rh.add_child(k.label(room["name"], "l", k.TEXT))
		rh.add_child(k.label("%d things" % room["items"].size(), "s", k.TEXT3))
		rh.add_child(k.spacer(0, 0, true))
		if not room["looked"]:
			var lb = k.button("Look round", "action", func(): g.clearance_look(ri), "8 energy, 25 minutes. Your expertise shows you more.", "s")
			lb.disabled = g.energy < 8
			rh.add_child(lb)
		rv.add_child(rh)
		if room["looked"]:
			for idx in room["items"]:
				var it = c["items"][idx]
				rv.add_child(ui.item.tile(it, "clearance", false, null))
		else:
			rv.add_child(k.label("Boxes, bin bags and a lot of dust.", "s", k.TEXT3))
		gr.add_child(rp)
	v.add_child(gr)
	v.add_child(k.spacer(0, 20))
	parent.add_child(ui.keyed_scroll("clearance", v))
