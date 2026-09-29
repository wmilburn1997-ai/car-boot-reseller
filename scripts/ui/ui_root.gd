extends RefCounted
# The UI shell: scaling, HUD, navigation, overlays (toasts, popups, floating numbers, sheets)
# and screen dispatch. Screens live in scr_*.gd; game state and rules live in main.gd (g).

const Kit = preload("res://scripts/ui/kit.gd")
const ScrMarket = preload("res://scripts/ui/scr_market.gd")
const ScrItem = preload("res://scripts/ui/scr_item.gd")
const ScrStock = preload("res://scripts/ui/scr_stock.gd")
const ScrBusiness = preload("res://scripts/ui/scr_business.gd")
const ScrJournal = preload("res://scripts/ui/scr_journal.gd")
const ScrMeta = preload("res://scripts/ui/scr_meta.gd")

var g
var k
var market
var item
var stock
var business
var journal
var meta

var mobile = false
var logical = Vector2(1600, 900)
var built_mode = ""
var root                  # full-rect Control under main
var shell                 # VBox/HBox holding HUD, nav and content
var content               # the current screen goes here
var hud_box
var nav_box
var overlay               # toasts, fx, popups
var sheet_layer
var toast_box
var popup_layer
var popup_queue = []
var popup_open = false
var current = "show_title_screen"
var current_args = []
var chrome_visible = true
var scroll_memory = {}
var sheet_open = false
var hud_cash_label
var hud_cash_value = 0.0
var hud_refs = {}
var category_icons = {}
var nav_buttons = {}
var font
var tutorial_index = 0

func setup(game):
	g = game
	k = Kit.new(g)
	market = ScrMarket.new(self)
	item = ScrItem.new(self)
	stock = ScrStock.new(self)
	business = ScrBusiness.new(self)
	journal = ScrJournal.new(self)
	meta = ScrMeta.new(self)
	load_assets()
	build_theme()
	adjust_scale()
	build_root()
	g.get_tree().root.size_changed.connect(_on_resize)

func load_assets():
	var files = {
		"Clothing": "cat_clothing", "Games": "cat_games", "Trading Cards": "cat_trading_cards",
		"Electronics": "cat_electronics", "Home": "cat_home", "Vinyl": "cat_vinyl", "Cameras": "cat_cameras",
		"Tools": "cat_tools", "Collectables": "cat_collectables", "Jewellery": "cat_jewellery", "Books": "cat_books",
		"Musical Instruments": "cat_musical_instruments", "Garden & Outdoor": "cat_garden_outdoor",
	}
	for cat in files:
		var p = "res://cat_icons/%s.png" % files[cat]
		if ResourceLoader.exists(p):
			category_icons[cat] = load(p)

func category_icon(cat):
	return category_icons.get(cat, null)

func tex(name):
	var p = "res://%s.png" % name
	if ResourceLoader.exists(p):
		return load(p)
	return null

func build_theme():
	var th = Theme.new()
	font = load("res://fonts/Jersey10-Regular.ttf")
	if font != null:
		if ResourceLoader.exists("res://fonts/Symbols.ttf"):
			var sym = load("res://fonts/Symbols.ttf")
			if sym != null:
				font.fallbacks = [sym]
		th.default_font = font
		for t in ["Label", "Button", "CheckButton", "CheckBox", "LineEdit", "TextEdit", "RichTextLabel", "SpinBox", "OptionButton", "TooltipLabel", "HSlider"]:
			th.set_font("font", t, font)
	th.default_font_size = 17
	var tip = k.sbox(Color(0.06, 0.07, 0.09, 0.98), k.LINE2, 6, 1, 8)
	th.set_stylebox("panel", "TooltipPanel", tip)
	th.set_color("font_color", "TooltipLabel", k.TEXT)
	th.set_font_size("font_size", "TooltipLabel", 16)
	var sb = k.sbox(Color(0.2, 0.25, 0.3, 0.6), null, 4, 0, 0)
	sb.content_margin_left = 3
	sb.content_margin_right = 3
	th.set_stylebox("grabber", "VScrollBar", k.sbox(Color(0.30, 0.36, 0.44), null, 4, 0, 0))
	th.set_stylebox("grabber_highlight", "VScrollBar", k.sbox(Color(0.40, 0.46, 0.55), null, 4, 0, 0))
	th.set_stylebox("grabber_pressed", "VScrollBar", k.sbox(Color(0.50, 0.56, 0.65), null, 4, 0, 0))
	th.set_stylebox("scroll", "VScrollBar", k.sbox(Color(0, 0, 0, 0.2), null, 4, 0, [3, 0, 3, 0]))
	var le = k.sbox(Color(0.04, 0.05, 0.07), k.LINE2, 6, 1, [8, 4, 8, 4])
	th.set_stylebox("normal", "LineEdit", le)
	th.set_stylebox("focus", "LineEdit", k.sbox(Color(0.04, 0.05, 0.07), k.GOLD, 6, 1, [8, 4, 8, 4]))
	th.set_color("font_color", "LineEdit", k.TEXT)
	g.theme = th

# --- scaling ---------------------------------------------------------------------

func css_size():
	var w = 0.0
	var h = 0.0
	if OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge"):
		var js = Engine.get_singleton("JavaScriptBridge")
		w = float(js.call("eval", "window.innerWidth"))
		h = float(js.call("eval", "window.innerHeight"))
	if w <= 0.0 or h <= 0.0:
		var ws = g.get_window().size
		w = float(ws.x)
		h = float(ws.y)
	return Vector2(max(w, 200.0), max(h, 200.0))

func adjust_scale():
	var css = css_size()
	var win = Vector2(g.get_window().size)
	if win.x <= 0 or win.y <= 0:
		return
	var user = clamp(float(g.ui_scale), 0.7, 1.6)
	mobile = css.x < 820.0 or (css.y < 560.0 and css.x < 1000.0)
	var want_w = 0.0
	if mobile:
		want_w = css.x / user
		want_w = max(want_w, 340.0)
	else:
		want_w = css.x / (1.15 * user)
		want_w = clamp(want_w, 1020.0, 2400.0)
	var stretch = min(win.x / 1600.0, win.y / 900.0)
	if stretch <= 0.0:
		return
	var factor = (win.x / want_w) / stretch
	g.get_window().content_scale_factor = max(0.2, factor)
	logical = win / (stretch * factor)
	k.mobile = mobile

func _on_resize():
	var was = mobile
	adjust_scale()
	g.call_deferred("_ui_rerender")

func rerender():
	if built_mode != ("m" if mobile else "d"):
		build_root()
	refresh()

# --- shell ------------------------------------------------------------------------

func build_root():
	if root != null and is_instance_valid(root):
		g.remove_child(root)
		root.queue_free()
	built_mode = "m" if mobile else "d"
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.add_child(root)
	var bg = ColorRect.new()
	bg.color = k.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	root.add_child(make_pattern(22, 3, Color(0.55, 0.70, 0.95, 0.07)))
	root.add_child(make_pattern(64, 5, Color(0.55, 0.70, 0.95, 0.03)))
	var pad = 8 if mobile else 14
	if mobile:
		shell = k.vbox(6)
	else:
		shell = k.hbox(12)
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.offset_left = pad
	shell.offset_top = pad
	shell.offset_right = -pad
	shell.offset_bottom = -pad
	root.add_child(shell)
	nav_buttons = {}
	if mobile:
		hud_box = k.vbox(0)
		shell.add_child(hud_box)
		content = k.vbox(8)
		k.expand(content, true)
		shell.add_child(content)
		nav_box = k.hbox(4)
		shell.add_child(nav_box)
	else:
		nav_box = k.vbox(6)
		nav_box.custom_minimum_size = Vector2(210 if logical.x >= 1400 else 176, 0)
		shell.add_child(nav_box)
		var right = k.vbox(10)
		k.expand(right, true)
		shell.add_child(right)
		hud_box = k.vbox(0)
		right.add_child(hud_box)
		content = k.vbox(8)
		k.expand(content, true)
		right.add_child(content)
	sheet_layer = Control.new()
	sheet_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(sheet_layer)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(overlay)
	toast_box = k.vbox(6)
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(toast_box)
	position_toasts()
	popup_layer = Control.new()
	popup_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(popup_layer)
	popup_open = false
	build_nav()
	update_hud()
	set_chrome(chrome_visible)

func make_pattern(size, dot, color):
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for dx in range(dot):
		for dy in range(dot):
			img.set_pixel(3 + dx, 3 + dy, color)
	var r = TextureRect.new()
	r.texture = ImageTexture.create_from_image(img)
	r.stretch_mode = TextureRect.STRETCH_TILE
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

func position_toasts():
	if toast_box == null:
		return
	if mobile:
		toast_box.anchor_left = 0.0
		toast_box.anchor_right = 1.0
		toast_box.anchor_top = 1.0
		toast_box.anchor_bottom = 1.0
		toast_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
		toast_box.offset_left = 10
		toast_box.offset_right = -10
		toast_box.offset_top = -86
		toast_box.offset_bottom = -86
	else:
		toast_box.anchor_left = 1.0
		toast_box.anchor_right = 1.0
		toast_box.anchor_top = 0.0
		toast_box.anchor_bottom = 0.0
		toast_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		toast_box.grow_vertical = Control.GROW_DIRECTION_END
		toast_box.offset_left = -440
		toast_box.offset_right = -24
		toast_box.offset_top = 104
		toast_box.offset_bottom = 104

func set_chrome(v):
	chrome_visible = v
	if hud_box != null:
		hud_box.visible = v
	if nav_box != null:
		nav_box.visible = v

const NAV = [
	{"id": "market", "label": "Market", "glyph": "stall", "fn": "show_market", "key": "1"},
	{"id": "stock", "label": "Stock", "glyph": "box", "fn": "show_inventory", "key": "2"},
	{"id": "business", "label": "Business", "glyph": "shop", "fn": "show_business", "key": "3"},
	{"id": "knowledge", "label": "Expertise", "glyph": "star", "fn": "show_knowledge", "key": "4", "desktop": true},
	{"id": "perks", "label": "Perks", "glyph": "spark", "fn": "show_perks", "key": "5", "desktop": true},
	{"id": "news", "label": "News", "glyph": "news", "fn": "show_news", "key": "6", "desktop": true},
	{"id": "journal", "label": "Journal", "glyph": "book", "fn": "show_journal", "key": "7"},
	{"id": "more", "label": "More", "glyph": "menu", "fn": "show_more", "key": "8"},
]

func nav_active_id():
	match current:
		"show_market", "show_stall", "show_clearance":
			return "market"
		"show_inventory":
			return "stock"
		"show_business":
			return "business"
		"show_knowledge":
			return "knowledge" if not mobile else "journal"
		"show_perks":
			return "perks" if not mobile else "journal"
		"show_day_summary":
			return ""
		"show_news":
			return "news" if not mobile else "market"
		"show_journal":
			return "journal"
	return "more"

func build_nav():
	for c in nav_box.get_children():
		nav_box.remove_child(c)
		c.queue_free()
	nav_buttons = {}
	if mobile:
		for n in NAV:
			if n.get("desktop", false):
				continue
			var b = nav_tab_button(n, true)
			nav_box.add_child(b)
			nav_buttons[n["id"]] = b
		return
	# Desktop sidebar
	var brand = k.panel("hud", 12)
	var bb = k.vbox(0)
	bb.add_child(k.label("CAR BOOT", "xl", k.GOLD))
	bb.add_child(k.label("RESELLER", "m", k.TEXT2))
	brand.add_child(bb)
	nav_box.add_child(brand)
	var np = k.panel("hud", 8)
	var nv = k.vbox(3)
	np.add_child(nv)
	for n in NAV:
		var b = nav_tab_button(n, false)
		nv.add_child(b)
		nav_buttons[n["id"]] = b
	nav_box.add_child(np)
	var sp = k.spacer(0, 0)
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nav_box.add_child(sp)
	hud_refs["goal_box"] = k.vbox(4)
	var gp = k.panel("card", 10)
	gp.add_child(hud_refs["goal_box"])
	nav_box.add_child(gp)
	var end = k.button("End Day", "primary", func(): request_end_day(), "Go home for the night: pay the day's costs and see what sells. (E)", "l", 0, 56)
	hud_refs["end_day"] = end
	nav_box.add_child(end)

func nav_tab_button(n, compact):
	var b = Button.new()
	var on = nav_active_id() == n["id"]
	k.style_button(b, "tab_on" if on else "tab", [10, 6, 10, 6])
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.tooltip_text = "%s (%s)" % [n["label"], n["key"]] if not compact else ""
	var fg = k.GOLD if on else k.TEXT2
	if compact:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 58)
		var v = k.vbox(2)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var gl = k.glyph(n["glyph"], fg, 22)
		gl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(gl)
		v.add_child(k.label(n["label"], "xs", fg, false, HORIZONTAL_ALIGNMENT_CENTER))
		b.add_child(v)
	else:
		b.custom_minimum_size = Vector2(0, 40)
		var h = k.hbox(10)
		h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		h.offset_left = 12
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var gl2 = k.glyph(n["glyph"], fg, 18)
		gl2.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(gl2)
		var l = k.label(n["label"], "m", fg)
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(l)
		var badge = nav_badge(n["id"])
		if badge != "":
			h.add_child(k.spacer(0, 0, true))
			var c = k.chip(badge, k.GOLD, null, "xs")
			c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(c)
			h.add_child(k.spacer(8, 0))
		b.add_child(h)
	var fn = n["fn"]
	b.pressed.connect(func():
		g.play_sfx("page")
		sheet_open = false
		clear_toasts()
		if fn == "show_inventory":
			call("show_inventory", true)
		else:
			call(fn))
	return b

func nav_badge(id):
	match id:
		"stock":
			var n = 0
			for it in g.inventory:
				if not it["listed"] and not it["auctioned"] and not it.get("on_shop_floor", false):
					n += 1
			return str(n) if n > 0 else ""
		"perks":
			var p = g.skill_points_available()
			return "+%d" % p if p > 0 else ""
		"market":
			return str(g.clearance_leads.size()) + " job" if g.clearance_leads.size() > 0 and g.can_do_clearances() else ""
	return ""

# --- HUD -------------------------------------------------------------------------

func update_hud():
	if hud_box == null or not is_instance_valid(hud_box):
		return
	for c in hud_box.get_children():
		hud_box.remove_child(c)
		c.queue_free()
	if g.on_title_screen:
		return
	if mobile:
		build_hud_mobile()
	else:
		build_hud_desktop()
		refresh_goal_box()
	if abs(hud_cash_value - g.cash) >= 0.5:
		animate_cash()
	if nav_box != null and is_instance_valid(nav_box):
		for id in nav_buttons:
			pass

func refresh_goal_box():
	var gb = hud_refs.get("goal_box", null)
	if gb == null or not is_instance_valid(gb):
		return
	for c in gb.get_children():
		gb.remove_child(c)
		c.queue_free()
	gb.add_child(k.label("NEXT GOAL  %d/%d" % [min(g.goals_done + 1, g.business_goals.size()), g.business_goals.size()], "xs", k.TEXT3))
	gb.add_child(k.label(g.current_goal_text(), "s", k.GOLD, true))

func build_hud_desktop():
	var compact = logical.x < 1560
	var p = k.panel("hud", 8)
	var row = k.hbox(10 if compact else 14)
	p.add_child(row)
	hud_box.add_child(p)
	# cash
	var cash_box = k.hbox(8)
	cash_box.custom_minimum_size = Vector2(150 if compact else 200, 0)
	var coin = k.glyph("coin", k.GOLD, 26)
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cash_box.add_child(coin)
	var cv = k.vbox(0)
	hud_cash_label = k.label(g.fmt_money(hud_cash_value), "xl", k.GREEN if g.cash >= 0 else k.RED)
	cv.add_child(hud_cash_label)
	cv.add_child(k.label("business %s" % g.fmt_money(g.business_value()), "xs", k.TEXT3))
	cash_box.add_child(cv)
	cash_box.tooltip_text = "Cash on hand. Business value adds your stock at cost and your kit at resale value."
	cash_box.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(cash_box)
	hud_refs["cash_anchor"] = cash_box
	row.add_child(vsep())
	# day & clock
	var dv = k.vbox(3)
	dv.custom_minimum_size = Vector2(120 if compact else 170, 0)
	var dh = k.hbox(6)
	dh.add_child(k.label("Day %d" % g.day, "m", k.TEXT))
	dh.add_child(k.label(g.format_time(), "m", k.GOLD))
	dv.add_child(dh)
	var start = 7 * 60 + int(g.market_today.get("start_offset", 0))
	dv.add_child(k.bar(g.current_time_minutes - start, 12 * 60 - start, k.GOLD, 6))
	dv.tooltip_text = "The car boot closes at 12:00. Stalls pack up earlier, from late morning."
	dv.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(dv)
	# weather
	var w = str(g.market_today.get("weather", "overcast"))
	var wb = k.hbox(6)
	var wg = k.glyph(k.weather_glyph(w), k.weather_color(w), 22)
	wg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	wb.add_child(wg)
	if not compact:
		var wv = k.vbox(0)
		wv.add_child(k.label(g.weather_name(w), "s", k.TEXT))
		wv.add_child(k.label(g.market_name(g.market_today.get("type", "regular")), "xs", k.TEXT3))
		wb.add_child(wv)
	wb.tooltip_text = "%s: %s" % [g.weather_name(w), str(g.market_today.get("weather_line", ""))]
	wb.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(wb)
	row.add_child(vsep())
	var mw = 72 if compact else 96
	row.add_child(meter("bolt", "Energy", g.energy, g.max_energy(), k.TEAL, "Energy for today. Most actions use some. Refills every morning.", mw))
	row.add_child(meter("bag", "Carry", g.carry_used, g.effective_bag_capacity(), k.BLUE, "Room left in your %s for today's buys. Selling or scrapping something bought today frees it; it empties overnight." % g.vehicle()["name"].to_lower(), mw))
	row.add_child(meter("box", "Storage", g.inventory_space_used(), g.storage_capacity(), k.ORANGE, "Space at your %s." % g.premises()["name"], mw))
	var gap = k.vbox(2)
	k.expand(gap)
	if logical.x >= 1500:
		gap.add_child(k.label("NEXT GOAL", "xs", k.TEXT3))
		var gl = k.label(g.current_goal_text(), "s", k.GOLD)
		gl.clip_text = true
		gap.add_child(gl)
	row.add_child(gap)
	# level
	var lv = k.vbox(3)
	lv.custom_minimum_size = Vector2(100 if compact else 130, 0)
	var lh = k.hbox(6)
	lh.add_child(k.glyph("star", k.PURPLE, 14))
	lh.add_child(k.label("Level %d" % g.player_level, "s", k.TEXT))
	var pts = g.skill_points_available()
	if pts > 0:
		lh.add_child(k.chip("+%d perk" % pts, k.GOLD))
	lv.add_child(lh)
	lv.add_child(k.bar(g.player_xp, g.xp_needed_for_level(g.player_level), k.PURPLE, 6))
	lv.tooltip_text = "%d / %d XP" % [g.player_xp, g.xp_needed_for_level(g.player_level)]
	lv.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(lv)
	var rt = k.vbox(0)
	rt.add_child(k.label("%d%%" % int(g.seller_rating), "m", k.GREEN if g.seller_rating >= 90 else (k.GOLD if g.seller_rating >= 70 else k.RED)))
	rt.add_child(k.label("rating", "xs", k.TEXT3))
	rt.visible = not compact or logical.x >= 1180
	rt.tooltip_text = "Seller rating. Returns lower it, and a low rating slows sales."
	rt.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(rt)

func vsep():
	var c = ColorRect.new()
	c.color = k.LINE
	c.custom_minimum_size = Vector2(1, 34)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

func meter(glyph_name, name, v, maxv, color, tip, w = 96):
	var b = k.vbox(3)
	b.custom_minimum_size = Vector2(w, 0)
	var h = k.hbox(5)
	h.add_child(k.glyph(glyph_name, color, 14))
	h.add_child(k.label("%d/%d" % [int(v), int(maxv)], "s", k.TEXT))
	if w >= 90:
		h.add_child(k.label(name.to_lower(), "xs", k.TEXT3))
	b.add_child(h)
	var over = float(v) / max(1.0, float(maxv))
	b.add_child(k.bar(v, maxv, color if over < 0.9 or glyph_name == "bolt" else k.RED, 6))
	b.tooltip_text = "%s: %s" % [name, tip]
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	return b

func build_hud_mobile():
	var p = k.panel("hud", 6)
	var row = k.hbox(8)
	p.add_child(row)
	hud_box.add_child(p)
	var cv = k.hbox(4)
	var coin = k.glyph("coin", k.GOLD, 18)
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cv.add_child(coin)
	hud_cash_label = k.label(g.fmt_money(hud_cash_value), "l", k.GREEN if g.cash >= 0 else k.RED)
	cv.add_child(hud_cash_label)
	row.add_child(cv)
	hud_refs["cash_anchor"] = cv
	var ev = k.vbox(2)
	ev.custom_minimum_size = Vector2(56, 0)
	var eh = k.hbox(3)
	eh.add_child(k.glyph("bolt", k.TEAL, 12))
	eh.add_child(k.label(str(g.energy), "s", k.TEXT))
	ev.add_child(eh)
	ev.add_child(k.bar(g.energy, g.max_energy(), k.TEAL, 4))
	ev.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(ev)
	var tv = k.vbox(2)
	tv.custom_minimum_size = Vector2(56, 0)
	var th = k.hbox(3)
	var w = str(g.market_today.get("weather", "overcast"))
	th.add_child(k.glyph(k.weather_glyph(w), k.weather_color(w), 12))
	th.add_child(k.label(g.format_time(), "s", k.GOLD))
	tv.add_child(th)
	var start = 7 * 60 + int(g.market_today.get("start_offset", 0))
	tv.add_child(k.bar(g.current_time_minutes - start, 12 * 60 - start, k.GOLD, 4))
	tv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(tv)
	row.add_child(k.spacer(0, 0, true))
	var late = g.current_time_minutes >= 11 * 60 or g.energy < 25 or g.clearance != null
	var end = k.button("End day", "primary" if late else "ghost", func(): request_end_day(), "", "s", 0, 40)
	row.add_child(end)
	hud_refs["end_day"] = end

func animate_cash():
	if hud_cash_label == null or not is_instance_valid(hud_cash_label):
		return
	var from = hud_cash_value
	var to = g.cash
	if abs(to - from) < 0.5 or abs(to - from) > 100000.0:
		hud_cash_value = to
		_set_cash_text(to)
		return
	hud_cash_value = to
	var tw = hud_cash_label.create_tween()
	tw.tween_method(_set_cash_text, from, to, 0.45)

func _set_cash_text(v):
	if hud_cash_label != null and is_instance_valid(hud_cash_label):
		hud_cash_label.text = g.fmt_money(v)

# --- screen dispatch --------------------------------------------------------------

func begin(name, args = []):
	# Remember scroll positions if we're re-rendering the same screen.
	if current == name:
		remember_scrolls(content)
	else:
		scroll_memory = {}
	current = name
	current_args = args
	fx_pending = []
	g.current_screen_name = name
	for c in content.get_children():
		content.remove_child(c)
		c.queue_free()
	for c in sheet_layer.get_children():
		sheet_layer.remove_child(c)
		c.queue_free()
	if name == "show_title_screen":
		g.on_title_screen = true
	elif not (name in ["show_settings", "show_tutorial"]):
		g.on_title_screen = false
	set_chrome(not g.on_title_screen and not (name in ["show_bankruptcy_screen", "show_tutorial"]))
	if chrome_visible:
		update_hud()
		build_nav()
		if not mobile:
			refresh_goal_box()
	var ed = hud_refs.get("end_day", null)
	if ed != null and is_instance_valid(ed):
		ed.visible = name != "show_day_summary"
	g.call_deferred("_ui_restore_scrolls")

func remember_scrolls(node):
	for c in node.get_children():
		if c is ScrollContainer and c.has_meta("key"):
			scroll_memory[c.get_meta("key")] = c.scroll_vertical
		remember_scrolls(c)

func restore_scrolls():
	_restore_in(content)
	_restore_in(sheet_layer)

func _restore_in(node):
	if node == null or not is_instance_valid(node):
		return
	for c in node.get_children():
		if c is ScrollContainer and c.has_meta("key") and scroll_memory.has(c.get_meta("key")):
			c.scroll_vertical = int(scroll_memory[c.get_meta("key")])
		_restore_in(c)

func keyed_scroll(key, inner):
	var sc = k.scroll(inner)
	sc.set_meta("key", key)
	return sc

func refresh():
	if current == "":
		return
	callv(current, current_args)

func after_frame():
	restore_scrolls()

# Screens (thin wrappers onto modules)
func show_title_screen():
	begin("show_title_screen")
	meta.build_title(content)

func show_market():
	if g.clearance != null:
		show_clearance()
		return
	begin("show_market")
	market.build_market(content)

func show_stall():
	if g.clearance != null:
		show_clearance()
		return
	if g.current_time_minutes >= 12 * 60 or g.stalls.size() == 0:
		show_market()
		return
	begin("show_stall")
	market.build_stall(content)

func show_clearance():
	if g.clearance == null:
		show_market()
		return
	begin("show_clearance")
	market.build_clearance(content)

func show_inventory(fresh = false):
	if fresh:
		sheet_open = false
	begin("show_inventory", [false])
	stock.build(content)

func show_business():
	begin("show_business")
	business.build(content)

func show_perks():
	begin("show_perks")
	business.build_perks(content)

func show_knowledge():
	begin("show_knowledge")
	business.build_knowledge(content)

func show_news():
	begin("show_news")
	journal.build_news(content)

func show_journal(tab = ""):
	begin("show_journal", [tab])
	journal.build(content, tab)

func show_more():
	begin("show_more")
	meta.build_more(content)

func show_settings():
	begin("show_settings")
	meta.build_settings(content)

func show_tutorial():
	begin("show_tutorial")
	meta.build_tutorial(content)

func show_day_summary(summary):
	begin("show_day_summary", [summary])
	meta.build_day_summary(content, summary)

func show_bankruptcy_screen():
	begin("show_bankruptcy_screen")
	meta.build_bankruptcy(content)

func show_notes():
	begin("show_notes")
	meta.build_notes(content)

# --- master/detail + sheets ---------------------------------------------------------

func master_detail(parent, list_key, list_node, detail_node, detail_ratio = 0.9, detail_footer = null):
	# Desktop: list and detail side by side. Mobile: only the list; detail goes in a sheet.
	if mobile:
		parent.add_child(keyed_scroll(list_key, list_node))
		return
	var row = k.hbox(12)
	k.expand(row, true)
	var ls = keyed_scroll(list_key, list_node)
	ls.size_flags_stretch_ratio = 1.0
	row.add_child(ls)
	var dp = k.panel("card", 14)
	dp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dp.size_flags_stretch_ratio = detail_ratio
	var ds = keyed_scroll(list_key + "_detail", detail_node)
	if detail_footer != null:
		var dv = k.vbox(10)
		dv.add_child(ds)
		dv.add_child(detail_footer)
		dp.add_child(dv)
	else:
		dp.add_child(ds)
	row.add_child(dp)
	parent.add_child(row)

func open_sheet(title_text, body_node, footer_node = null, on_close = null):
	for c in sheet_layer.get_children():
		sheet_layer.remove_child(c)
		c.queue_free()
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	sheet_layer.add_child(dim)
	var p = PanelContainer.new()
	p.add_theme_stylebox_override("panel", k.sbox(Color(0.06, 0.075, 0.10), k.LINE2, 12, 1, 0))
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.offset_top = 6
	p.offset_left = 4
	p.offset_right = -4
	p.offset_bottom = -4
	sheet_layer.add_child(p)
	var v = k.vbox(0)
	p.add_child(v)
	var head = k.hbox(8)
	var back = k.icon_button("left", func():
		sheet_open = false
		if on_close != null:
			on_close.call()
		refresh(), "Back", "ghost", 44)
	head.add_child(back)
	var t = k.label(title_text, "m", k.TEXT)
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t.clip_text = true
	k.expand(t)
	head.add_child(t)
	v.add_child(k.margin(head, 8, 6, 8, 6))
	var line = ColorRect.new()
	line.color = k.LINE
	line.custom_minimum_size = Vector2(0, 1)
	v.add_child(line)
	var sc = keyed_scroll("sheet", k.margin(body_node, 12, 10, 12, 16))
	v.add_child(sc)
	if footer_node != null:
		var fp = PanelContainer.new()
		fp.add_theme_stylebox_override("panel", k.sbox(Color(0.08, 0.10, 0.13), k.LINE, 0, 1, 10))
		fp.add_child(footer_node)
		v.add_child(fp)
	sheet_open = true

# --- toasts, popups, fx ------------------------------------------------------------

func toast(text, kind = "info"):
	if toast_box == null or not is_instance_valid(toast_box):
		return
	var styles = {"success": "good", "error": "bad", "warn": "warn", "info": "card2", "rng": "purple"}
	var p = k.panel(styles.get(kind, "card2"), 10)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var colors = {"success": k.GREEN, "error": k.RED, "warn": k.ORANGE, "info": k.TEXT2, "rng": k.PURPLE}
	var h = k.hbox(8)
	var glyphs = {"success": "check", "error": "cross", "warn": "q", "info": "spark", "rng": "dots"}
	var gl = k.glyph(glyphs.get(kind, "spark"), colors.get(kind, k.TEXT2), 14)
	gl.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(gl)
	var clean = str(text)
	var r = k.rich(clean, "s", k.TEXT)
	r.custom_minimum_size = Vector2(0, 0)
	h.add_child(r)
	p.add_child(h)
	p.gui_input.connect(_toast_input.bind(p))
	toast_box.add_child(p)
	var maxn = 2 if mobile else 3
	while toast_box.get_child_count() > maxn:
		var old = toast_box.get_child(0)
		toast_box.remove_child(old)
		old.queue_free()
	p.modulate = Color(1, 1, 1, 0)
	var tw = p.create_tween()
	tw.tween_property(p, "modulate", Color(1, 1, 1, 1), 0.15)
	tw.tween_interval(3.2 if kind != "rng" else 2.2)
	tw.tween_property(p, "modulate", Color(1, 1, 1, 0), 0.35)
	tw.tween_callback(p.queue_free)

func _toast_input(ev, p):
	if ev is InputEventMouseButton and ev.pressed and is_instance_valid(p):
		p.queue_free()

func clear_toasts():
	if toast_box == null or not is_instance_valid(toast_box):
		return
	for c in toast_box.get_children():
		toast_box.remove_child(c)
		c.queue_free()

var fx_pending = []

func fx_money(amount):
	if not chrome_visible:
		return
	fx_pending.append(amount)
	g.get_tree().create_timer(0.06).timeout.connect(_fx_flush)

func _fx_flush():
	var list = fx_pending
	fx_pending = []
	var off = 0
	for a in list:
		_fx_spawn(a, off)
		off += 26

func _fx_spawn(amount, yoff):
	var anchor = hud_refs.get("cash_anchor", null)
	if anchor == null or not is_instance_valid(anchor) or not anchor.is_visible_in_tree():
		return
	var l = k.label(g.money_signed(amount), "l", k.GREEN if amount >= 0 else k.RED)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 4)
	overlay.add_child(l)
	var pos = anchor.global_position - root.global_position
	l.position = pos + (Vector2(10, 44 + yoff) if mobile else Vector2(40, 30 + yoff))
	var tw = l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position", l.position + Vector2(0, 36 if amount >= 0 else 46), 1.1).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate", Color(1, 1, 1, 0), 1.1).set_delay(0.4)
	tw.chain().tween_callback(l.queue_free)

func big_popup(title_text, body_text, kind = "info", extra = {}):
	popup_queue.append([title_text, body_text, kind, extra])
	if not popup_open:
		_next_popup()

func _next_popup():
	if popup_queue.size() == 0:
		popup_open = false
		return
	if popup_layer == null or not is_instance_valid(popup_layer):
		return
	var entry = popup_queue.pop_front()
	popup_open = true
	var kind = entry[2]
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_layer.add_child(dim)
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup_layer.add_child(center)
	var colors = {"level": k.GOLD, "achievement": k.TEAL, "rare": k.PURPLE, "grail": k.GOLD, "bad": k.RED, "info": k.TEXT}
	var c = colors.get(kind, k.TEXT)
	var p = PanelContainer.new()
	var st = k.sbox(Color(0.06, 0.075, 0.10), c.darkened(0.2), 12, 2, 22)
	st.shadow_color = Color(c.r, c.g, c.b, 0.25)
	st.shadow_size = 18
	p.add_theme_stylebox_override("panel", st)
	p.custom_minimum_size = Vector2(min(460, logical.x - 40), 0)
	center.add_child(p)
	var v = k.vbox(12)
	p.add_child(v)
	var glyph_for = {"level": "star", "achievement": "trophy", "rare": "spark", "grail": "spark", "bad": "cross", "info": "spark"}
	var extra = entry[3] if entry.size() > 3 else {}
	if extra.has("icon"):
		var ic = k.cat_icon(extra["icon"], 72)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(ic)
	else:
		var gl = k.glyph(glyph_for.get(kind, "spark"), c, 40)
		gl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(gl)
	v.add_child(k.label(entry[0], "xl", c, true, HORIZONTAL_ALIGNMENT_CENTER))
	if extra.has("big"):
		var bl = k.label(str(extra["big"]), "hero", k.GREEN, false, HORIZONTAL_ALIGNMENT_CENTER)
		v.add_child(bl)
		bl.pivot_offset = Vector2(100, 20)
		var btw = bl.create_tween()
		btw.set_loops(3)
		btw.tween_property(bl, "modulate", Color(1.3, 1.3, 1.3, 1), 0.25)
		btw.tween_property(bl, "modulate", Color(1, 1, 1, 1), 0.25)
	v.add_child(k.rich(str(entry[1]), "b", k.TEXT2, "center"))
	var ok = k.button("Nice" if kind in ["level", "rare", "grail", "achievement"] else "OK", "primary" if kind != "bad" else "ghost", func(): _close_popup(), "", "m", 180, 46)
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ok)
	p.pivot_offset = p.custom_minimum_size / 2.0
	p.scale = Vector2(0.85, 0.85)
	p.modulate = Color(1, 1, 1, 0)
	var tw = p.create_tween()
	tw.set_parallel(true)
	tw.tween_property(p, "scale", Vector2(1, 1), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(p, "modulate", Color(1, 1, 1, 1), 0.15)
	if kind == "grail":
		g.play_sfx("grail")
	elif kind == "level":
		g.play_sfx("levelup")

func _close_popup():
	for c in popup_layer.get_children():
		popup_layer.remove_child(c)
		c.queue_free()
	popup_open = false
	_next_popup()

# --- input --------------------------------------------------------------------------

func handle_key(ev):
	if not (ev is InputEventKey) or not ev.pressed or ev.echo:
		return false
	if popup_open:
		if ev.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_SPACE, KEY_KP_ENTER]:
			_close_popup()
			return true
		return false
	var focus = g.get_viewport().gui_get_focus_owner()
	if focus is LineEdit:
		return false
	if ev.keycode == KEY_ESCAPE:
		if sheet_open:
			sheet_open = false
			g.selected_stall_uid = -1 if current == "show_stall" else g.selected_stall_uid
			refresh()
			return true
		if current in ["show_stall", "show_clearance"]:
			show_market()
			return true
		return false
	if g.on_title_screen or not chrome_visible:
		return false
	match ev.keycode:
		KEY_1:
			show_market()
		KEY_2:
			show_inventory(true)
		KEY_3:
			show_business()
		KEY_4:
			show_knowledge()
		KEY_5:
			show_perks()
		KEY_6:
			show_news()
		KEY_7:
			show_journal()
		KEY_8:
			show_more()
		KEY_E:
			request_end_day()
		KEY_N:
			if current == "show_stall":
				g.next_stall()
		KEY_D:
			if current == "show_stall":
				g.browse_stall()
		_:
			return false
	return true

# --- first-time coaching -----------------------------------------------------------
const COACH = {
	"market": "This is the morning's car boot. Every stall is a person: some are regulars who'll remember you. Stalls pack up from late morning and the field shuts at noon, so pick your route.",
	"stall": "Pick something off the table. Research shows what it really sells for after fees. Inspect is quick but can be wrong. You only get one offer per item.",
	"clue": "A purple ? is a clue: something about this item isn't what it seems. It could be good or bad. Checks, expertise and workshop kit identify it; anything you miss, a buyer will spot.",
	"stock": "Everything you own. Your estimate can be wrong until you check things properly. Electricals must be tested. Set a price and list it: buyers come overnight when you end the day.",
	"business": "Save up for bigger premises, a better vehicle and workshop kit. Each one changes what you can do, but premises and vehicles cost rent or fuel every night.",
	"clearance": "A whole house for one price. Look round the rooms you have energy for, then decide. Your expertise shows you more. Take it and you get everything; walk away and the morning's gone.",
}

func coach(parent, id):
	if g.tips_seen.has(id) or not COACH.has(id):
		return
	var p = k.panel("blue", 12)
	var h = k.hbox(10)
	p.add_child(h)
	var gl = k.glyph("spark", k.BLUE, 20)
	gl.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(gl)
	h.add_child(k.label(COACH[id], "s", k.TEXT, true))
	h.add_child(k.button("Got it", "action", func():
		g.tips_seen[id] = true
		g.save_settings()
		refresh(), "", "s"))
	parent.add_child(p)


func request_end_day():
	if current == "show_day_summary":
		return
	var early = g.current_time_minutes < 11 * 60 and g.energy >= 25 and g.clearance == null and g.stalls.size() > 0
	if early:
		confirm("End the day now?", "It's only %s and you've still got %d energy. The stalls are still open." % [g.format_time(), g.energy], "Go home", func(): g.end_day())
	else:
		g.end_day()

func confirm(title_text, body_text, yes_text, yes_cb):
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_layer.add_child(dim)
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup_layer.add_child(center)
	var p = k.panel("modal", 20)
	p.custom_minimum_size = Vector2(min(440, logical.x - 30), 0)
	center.add_child(p)
	var v = k.vbox(12)
	p.add_child(v)
	v.add_child(k.label(title_text, "l", k.TEXT, true))
	v.add_child(k.label(body_text, "b", k.TEXT2, true))
	var row = k.hbox(10)
	var close = func():
		for c in popup_layer.get_children():
			popup_layer.remove_child(c)
			c.queue_free()
		popup_open = false
	var yes = k.button(yes_text, "primary", func():
		close.call()
		yes_cb.call(), "", "m", 0, 46)
	yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var no = k.button("Not yet", "ghost", func(): close.call(), "", "m", 0, 46)
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(no)
	row.add_child(yes)
	v.add_child(row)
	popup_open = true


func cap_width(node, maxw = 1180):
	# Keep reading-heavy screens from stretching across ultra-wide windows.
	if mobile:
		return node
	var avail = logical.x - (240 if not mobile else 0)
	var side = int(max(0.0, (avail - maxw) / 2.0))
	return k.margin(node, side, 0, side, 0)


# --- drag to scroll -----------------------------------------------------------------
# Godot's ScrollContainer only drag-scrolls when the finger starts on empty space; nearly
# everything here is a button. So we watch every press: once it moves more than a few pixels
# vertically it becomes a scroll of whatever list is under the finger, and the button that
# was touched is told the press was cancelled instead of clicked.
const DRAG_THRESHOLD = 10.0
var drag_sc = null
var drag_down = false
var dragging = false
var drag_start = Vector2.ZERO
var drag_last = Vector2.ZERO
var drag_last_t = 0
var drag_vel = 0.0
var drag_fake = false
var drag_swallow_touch = false

func handle_pointer(ev):
	if drag_fake:
		return
	if ev is InputEventScreenDrag and dragging:
		g.get_viewport().set_input_as_handled()
		return
	if ev is InputEventScreenTouch and not ev.pressed and drag_swallow_touch:
		# The touch release that ends a drag must not reach the GUI either,
		# or the control now under the finger treats it as a tap.
		drag_swallow_touch = false
		var t = InputEventScreenTouch.new()
		t.index = ev.index
		t.pressed = false
		t.position = Vector2(-10000, -10000)
		_push_fake(t)
		g.get_viewport().set_input_as_handled()
		return
	if ev is InputEventMouseButton:
		if ev.button_index != MOUSE_BUTTON_LEFT:
			return
		var p = ev.position  # already in logical canvas space here
		if ev.pressed:
			drag_vel = 0.0
			dragging = false
			drag_swallow_touch = false
			drag_start = p
			drag_last = p
			drag_last_t = Time.get_ticks_msec()
			drag_sc = scroll_at(p)
			drag_down = drag_sc != null and not _over_text_field(p)
		else:
			drag_down = false
			if dragging:
				dragging = false
				drag_swallow_touch = true
				# Swallow the real release and hand the GUI one far off-screen, so the
				# pressed button resets without firing and nothing new gets tapped.
				var r = InputEventMouseButton.new()
				r.button_index = MOUSE_BUTTON_LEFT
				r.pressed = false
				r.position = Vector2(-10000, -10000)
				r.global_position = r.position
				_push_fake(r)
				g.get_viewport().set_input_as_handled()
	elif ev is InputEventMouseMotion and drag_down:
		if drag_sc == null or not is_instance_valid(drag_sc) or not drag_sc.is_inside_tree():
			drag_down = false
			return
		var p = ev.position  # already in logical canvas space here
		if not dragging:
			if abs(p.y - drag_start.y) >= DRAG_THRESHOLD and abs(p.y - drag_start.y) > abs(p.x - drag_start.x):
				dragging = true
				drag_last = p
				_cancel_press()
			else:
				return
		var dy = p.y - drag_last.y
		drag_sc.scroll_vertical = int(drag_sc.scroll_vertical - dy)
		var now = Time.get_ticks_msec()
		var dt = max(1, now - drag_last_t) / 1000.0
		drag_vel = lerp(drag_vel, -dy / dt, 0.5)
		drag_last = p
		drag_last_t = now
		g.get_viewport().set_input_as_handled()

func _cancel_press():
	# BaseButton only re-checks "is the pointer inside me" on motion, so send it
	# a motion far off-screen; its release then won't fire pressed.
	var away = InputEventMouseMotion.new()
	away.position = Vector2(-10000, -10000)
	away.global_position = away.position
	away.button_mask = MOUSE_BUTTON_MASK_LEFT
	_push_fake(away)

func _push_fake(e):
	drag_fake = true
	g.get_viewport().push_input(e)
	drag_fake = false

func process_scroll(delta):
	if drag_down or abs(drag_vel) < 20.0:
		return
	if drag_sc == null or not is_instance_valid(drag_sc) or not drag_sc.is_inside_tree():
		drag_vel = 0.0
		return
	var before = drag_sc.scroll_vertical
	drag_sc.scroll_vertical = int(before + drag_vel * delta)
	if drag_sc.scroll_vertical == before:
		drag_vel = 0.0
	drag_vel *= pow(0.04, delta)   # glide to a stop in about a second

func scroll_at(p):
	# The innermost vertically scrollable ScrollContainer under the point, sheets first.
	var roots = []
	if sheet_layer != null and sheet_layer.get_child_count() > 0:
		roots.append(sheet_layer)
	elif popup_open:
		return null
	else:
		roots.append(content)
	var best = null
	for r in roots:
		best = _find_scroll(r, p, best)
	return best

func _find_scroll(node, p, best):
	for c in node.get_children():
		if not (c is Control) or not c.is_visible_in_tree():
			continue
		if not c.get_global_rect().has_point(p):
			continue
		if c is ScrollContainer and c.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
			var vb = c.get_v_scroll_bar()
			if vb != null and vb.max_value > vb.page + 1.0:
				best = c
		best = _find_scroll(c, p, best)
	return best

func _over_text_field(p):
	var f = g.get_viewport().gui_get_hovered_control() if g.get_viewport().has_method("gui_get_hovered_control") else null
	return f is LineEdit or f is TextEdit or f is Slider
