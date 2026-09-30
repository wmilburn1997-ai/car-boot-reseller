extends RefCounted
# UI kit: palette, style builders, widget factories and a pixel glyph set.

# --- palette -------------------------------------------------------------
const BG = Color(0.035, 0.045, 0.06)
const PANEL = Color(0.075, 0.095, 0.125)
const PANEL2 = Color(0.095, 0.12, 0.155)
const PANEL3 = Color(0.12, 0.15, 0.19)
const LINE = Color(0.17, 0.215, 0.27)
const LINE2 = Color(0.24, 0.29, 0.36)
const TEXT = Color(0.93, 0.95, 0.98)
const TEXT2 = Color(0.72, 0.77, 0.84)
const TEXT3 = Color(0.50, 0.56, 0.64)
const GOLD = Color(0.95, 0.77, 0.33)
const GOLD_D = Color(0.36, 0.28, 0.10)
const GREEN = Color(0.44, 0.84, 0.54)
const GREEN_D = Color(0.10, 0.30, 0.18)
const RED = Color(0.93, 0.50, 0.44)
const RED_D = Color(0.33, 0.11, 0.10)
const BLUE = Color(0.42, 0.66, 1.0)
const BLUE_D = Color(0.10, 0.19, 0.35)
const PURPLE = Color(0.74, 0.56, 0.98)
const PURPLE_D = Color(0.22, 0.14, 0.34)
const ORANGE = Color(0.98, 0.64, 0.30)
const ORANGE_D = Color(0.33, 0.19, 0.07)
const TEAL = Color(0.40, 0.85, 0.86)

var g
var mobile = false
var glyph_cache = {}

func _init(game):
	g = game

# --- sizes ---------------------------------------------------------------
func fs(role):
	var m = {"xs": 13, "s": 15, "b": 17, "m": 19, "l": 23, "xl": 28, "xxl": 36, "hero": 46}
	if mobile:
		m = {"xs": 14, "s": 16, "b": 18, "m": 20, "l": 23, "xl": 27, "xxl": 33, "hero": 40}
	return int(m.get(role, 17))

# --- styles ----------------------------------------------------------------
func sbox(bg, border = null, radius = 6, bw = 0, pad: Variant = 10):
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	if border != null:
		s.border_color = border
		s.set_border_width_all(bw if bw > 0 else 1)
	s.set_corner_radius_all(radius)
	if typeof(pad) == TYPE_ARRAY:
		s.content_margin_left = pad[0]
		s.content_margin_top = pad[1]
		s.content_margin_right = pad[2]
		s.content_margin_bottom = pad[3]
	else:
		s.set_content_margin_all(pad)
	s.anti_aliasing = false
	return s

func panel(kind = "card", pad = 12):
	var p = PanelContainer.new()
	p.add_theme_stylebox_override("panel", panel_style(kind, pad))
	return p

func panel_style(kind = "card", pad = 12):
	match kind:
		"card":
			return sbox(PANEL, LINE, 8, 1, pad)
		"card2":
			return sbox(PANEL2, LINE, 8, 1, pad)
		"inset":
			return sbox(Color(0.05, 0.065, 0.085), LINE, 6, 1, pad)
		"flat":
			return sbox(Color(0, 0, 0, 0), null, 0, 0, pad)
		"gold":
			return sbox(Color(0.13, 0.11, 0.06), GOLD_D.lightened(0.25), 8, 2, pad)
		"good":
			return sbox(Color(0.07, 0.15, 0.10), GREEN_D.lightened(0.2), 8, 1, pad)
		"bad":
			return sbox(Color(0.16, 0.07, 0.07), RED_D.lightened(0.25), 8, 1, pad)
		"warn":
			return sbox(Color(0.16, 0.11, 0.05), ORANGE_D.lightened(0.3), 8, 1, pad)
		"purple":
			return sbox(Color(0.12, 0.08, 0.18), PURPLE_D.lightened(0.3), 8, 1, pad)
		"blue":
			return sbox(Color(0.07, 0.11, 0.19), BLUE_D.lightened(0.3), 8, 1, pad)
		"hud":
			return sbox(Color(0.055, 0.07, 0.095), LINE, 10, 1, pad)
		"modal":
			return sbox(Color(0.07, 0.09, 0.12), LINE2, 12, 2, pad)
	return sbox(PANEL, LINE, 8, 1, pad)

# --- containers ------------------------------------------------------------
func vbox(sep = 8):
	var b = VBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	return b

func hbox(sep = 8):
	var b = HBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	return b

func flow(hsep = 6, vsep = 6):
	var f = HFlowContainer.new()
	f.add_theme_constant_override("h_separation", hsep)
	f.add_theme_constant_override("v_separation", vsep)
	return f

func grid(cols, hsep = 8, vsep = 8):
	var gc = GridContainer.new()
	gc.columns = cols
	gc.add_theme_constant_override("h_separation", hsep)
	gc.add_theme_constant_override("v_separation", vsep)
	return gc

func spacer(w = 0, h = 0, expand = false):
	var c = Control.new()
	c.custom_minimum_size = Vector2(w, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if expand:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c

func expand(node, v = false):
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if v:
		node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return node

func margin(node, l, t = -1, r = -1, b = -1):
	var m = MarginContainer.new()
	if t < 0:
		t = l
	if r < 0:
		r = l
	if b < 0:
		b = t
	m.add_theme_constant_override("margin_left", l)
	m.add_theme_constant_override("margin_top", t)
	m.add_theme_constant_override("margin_right", r)
	m.add_theme_constant_override("margin_bottom", b)
	m.add_child(node)
	return m

func scroll(content_node = null):
	var sc = ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.scroll_deadzone = 60   # our own drag handler (ui_root.handle_pointer) takes over first
	if content_node != null:
		content_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sc.add_child(content_node)
	return sc

# --- text ------------------------------------------------------------------
func label(text, size = "b", color = TEXT, wrap = false, align = HORIZONTAL_ALIGNMENT_LEFT):
	var l = Label.new()
	l.text = str(text)
	l.add_theme_font_size_override("font_size", fs(size) if typeof(size) == TYPE_STRING else int(size))
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func rich(text, size = "b", color = TEXT2, align = ""):
	var r = RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sz = fs(size) if typeof(size) == TYPE_STRING else int(size)
	r.add_theme_font_size_override("normal_font_size", sz)
	r.add_theme_font_size_override("bold_font_size", sz)
	r.add_theme_font_size_override("italics_font_size", sz)
	r.add_theme_color_override("default_color", color)
	r.mouse_filter = Control.MOUSE_FILTER_PASS
	if align == "center":
		text = "[center]" + str(text) + "[/center]"
	elif align == "right":
		text = "[right]" + str(text) + "[/right]"
	r.text = str(text)
	return r

func hex(c):
	return "#" + c.to_html(false)

func col(text, c):
	return "[color=%s]%s[/color]" % [hex(c), str(text)]

func money(v):
	return g.fmt_money(v)

func title(text, size = "l", color = TEXT):
	return label(text, size, color)

func section(text, right = null):
	var row = hbox(8)
	var l = label(text.to_upper(), "s", TEXT3)
	row.add_child(l)
	var line = ColorRect.new()
	line.color = LINE
	line.custom_minimum_size = Vector2(0, 1)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(line)
	if right != null:
		row.add_child(right)
	return row

# --- chips, bars -------------------------------------------------------------
func chip(text, fg = TEXT2, bg = null, size = "xs", icon_name = ""):
	var p = PanelContainer.new()
	var bgc = bg if bg != null else Color(fg.r, fg.g, fg.b, 0.14)
	p.add_theme_stylebox_override("panel", sbox(bgc, Color(fg.r, fg.g, fg.b, 0.35), 4, 1, [6, 1, 6, 2]))
	var h = hbox(4)
	if icon_name != "":
		h.add_child(glyph(icon_name, fg, 12 if not mobile else 14))
	h.add_child(label(text, size, fg))
	p.add_child(h)
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	return p

func bar(value, maxv, color = GREEN, height = 8, bg = null):
	var pb = ProgressBar.new()
	pb.show_percentage = false
	pb.min_value = 0.0
	pb.max_value = max(0.001, float(maxv))
	pb.value = clamp(float(value), 0.0, float(maxv))
	pb.custom_minimum_size = Vector2(0, height)
	pb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pb.add_theme_stylebox_override("background", sbox(bg if bg != null else Color(0.03, 0.04, 0.05), LINE, 3, 1, 0))
	pb.add_theme_stylebox_override("fill", sbox(color, null, 3, 0, 0))
	pb.mouse_filter = Control.MOUSE_FILTER_PASS
	return pb

func dots(filled, total, color = GOLD, glyph_name = "heart"):
	var h = hbox(2)
	for i in range(total):
		h.add_child(glyph(glyph_name, color if i < filled else Color(0.25, 0.28, 0.33), 12 if not mobile else 14))
	return h

# --- buttons ---------------------------------------------------------------------
func button_style(kind):
	var base = PANEL3
	var border = LINE2
	var fg = TEXT
	match kind:
		"primary", "gold":
			base = Color(0.55, 0.42, 0.13)
			border = GOLD
			fg = Color(1, 0.97, 0.88)
		"buy":
			base = Color(0.13, 0.42, 0.24)
			border = GREEN
			fg = Color(0.92, 1, 0.94)
		"action":
			base = Color(0.11, 0.21, 0.38)
			border = Color(0.30, 0.48, 0.80)
			fg = Color(0.90, 0.95, 1)
		"special":
			base = Color(0.25, 0.15, 0.40)
			border = PURPLE
			fg = Color(0.97, 0.93, 1)
		"danger":
			base = Color(0.38, 0.13, 0.12)
			border = RED
			fg = Color(1, 0.93, 0.92)
		"ghost":
			base = Color(0.08, 0.10, 0.13)
			border = LINE2
			fg = TEXT2
		"tab":
			base = Color(0, 0, 0, 0)
			border = Color(0, 0, 0, 0)
			fg = TEXT2
		"tab_on":
			base = Color(0.16, 0.14, 0.08)
			border = GOLD_D.lightened(0.2)
			fg = GOLD
	return {"base": base, "border": border, "fg": fg}

func style_button(b, kind = "ghost", pad: Variant = [12, 6, 12, 7]):
	var st = button_style(kind)
	var base = st["base"]
	var border = st["border"]
	b.add_theme_stylebox_override("normal", sbox(base, border, 6, 1 if kind != "tab" else 0, pad))
	b.add_theme_stylebox_override("hover", sbox(base.lightened(0.10), border.lightened(0.2), 6, 1 if kind != "tab" else 0, pad))
	b.add_theme_stylebox_override("pressed", sbox(base.darkened(0.15), border, 6, 1 if kind != "tab" else 0, pad))
	b.add_theme_stylebox_override("focus", sbox(Color(0, 0, 0, 0), GOLD.darkened(0.2), 6, 1, pad))
	b.add_theme_stylebox_override("disabled", sbox(Color(0.07, 0.085, 0.10), Color(0.16, 0.18, 0.21), 6, 1, pad))
	b.add_theme_color_override("font_color", st["fg"])
	b.add_theme_color_override("font_hover_color", st["fg"].lightened(0.1))
	b.add_theme_color_override("font_pressed_color", st["fg"])
	b.add_theme_color_override("font_focus_color", st["fg"])
	b.add_theme_color_override("font_disabled_color", Color(0.40, 0.44, 0.50))

func button(text, kind = "ghost", cb = null, tooltip = "", size = "b", min_w = 0, min_h = 0):
	var b = Button.new()
	b.text = str(text)
	style_button(b, kind)
	b.add_theme_font_size_override("font_size", fs(size) if typeof(size) == TYPE_STRING else int(size))
	b.tooltip_text = tooltip
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var mh = min_h if min_h > 0 else (44 if mobile else 36)
	b.custom_minimum_size = Vector2(min_w, mh)
	if cb != null:
		b.pressed.connect(cb)
		b.pressed.connect(func(): g.play_sfx("click"))
	return b

func action_tile(icon, title_text, sub, kind = "action", cb = null, disabled = false, tooltip = "", done = false):
	# A two-line action button: icon, title, and a small cost/status line.
	var b = Button.new()
	style_button(b, kind if not done else "ghost", [10, 6, 10, 6])
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.tooltip_text = tooltip
	b.custom_minimum_size = Vector2(0, 58 if mobile else 46)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.disabled = disabled or done
	var h = hbox(8)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 10
	h.offset_right = -8
	var ic = null
	if typeof(icon) == TYPE_STRING and icon != "":
		ic = glyph(icon, TEXT if not (disabled or done) else TEXT3, 18 if not mobile else 20)
	elif icon is Texture2D:
		ic = tex_rect(icon, 22 if not mobile else 26)
		if disabled or done:
			ic.modulate = Color(1, 1, 1, 0.45)
	if ic != null:
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(ic)
	var v = vbox(0)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fg = button_style(kind)["fg"] if not (disabled or done) else TEXT3
	var tl = label(title_text, "s" if mobile else "b", fg)
	tl.clip_text = true
	v.add_child(tl)
	if str(sub) != "":
		var sl = label(sub, "xs", fg.darkened(0.25) if not done else GREEN.darkened(0.1))
		if mobile:
			sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		else:
			sl.clip_text = true
		v.add_child(sl)
	h.add_child(v)
	b.add_child(h)
	if cb != null and not disabled and not done:
		b.pressed.connect(cb)
	return b

func icon_button(glyph_name, cb, tooltip = "", kind = "ghost", size = 40):
	var b = Button.new()
	style_button(b, kind, [6, 6, 6, 6])
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = tooltip
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var s = size if not mobile else max(size, 44)
	b.custom_minimum_size = Vector2(s, s)
	var gl = glyph(glyph_name, button_style(kind)["fg"], 18 if not mobile else 20)
	gl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	gl.position = Vector2(-9, -9) if not mobile else Vector2(-10, -10)
	b.add_child(gl)
	if cb != null:
		b.pressed.connect(cb)
	return b

func tex_rect(tex, size = 24):
	var t = TextureRect.new()
	t.texture = tex
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(size, size)
	t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

const ItemArt = preload("res://scripts/data/item_art.gd")
var _item_tex = {}

func item_icon(name, category, size = 32):
	# The item family's own pixel sprite; falls back to the category icon.
	var path = ItemArt.ITEM_ART.get(str(name), "")
	if path != "":
		if not _item_tex.has(path):
			_item_tex[path] = load(path) if ResourceLoader.exists(path) else null
		var tex = _item_tex[path]
		if tex != null:
			var t = tex_rect(tex, size)
			t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			return t
	return cat_icon(category, size)

func cat_icon(category, size = 28):
	var tex = g.ui.category_icon(category)
	if tex != null:
		return tex_rect(tex, size)
	var p = PanelContainer.new()
	p.custom_minimum_size = Vector2(size, size)
	p.add_theme_stylebox_override("panel", sbox(PANEL3, LINE, 4, 1, 0))
	return p

# --- pixel glyphs ------------------------------------------------------------------
# 12x12 bitmaps. '#' = pixel.
const GLYPHS = {
	"sun": ["     #      ", "  #  #  #   ", "   #   #    ", "    ###     ", " # ##### #  ", "## ##### ## ", " # ##### #  ", "    ###     ", "   #   #    ", "  #  #  #   ", "     #      ", "            "],
	"cloud": ["            ", "            ", "    ###     ", "   #####    ", "  ####### # ", " ########## ", "############", "############", " ########## ", "            ", "            ", "            "],
	"rain": ["    ###     ", "   #####    ", " ########   ", "##########  ", "##########  ", " ########   ", "            ", "  #  #  #   ", " #  #  #    ", "            ", "   #  #  #  ", "  #  #  #   "],
	"storm": ["    ###     ", "   #####    ", " ########   ", "##########  ", "##########  ", " ###  ###   ", "    ##      ", "   ##  #  # ", "  ####  #   ", "    ##      ", "   ##    #  ", "  #     #   "],
	"snow": ["     #      ", "  #  #  #   ", "   # # #    ", "    ###     ", "#####*##### ", "    ###     ", "   # # #    ", "  #  #  #   ", "     #      ", "            ", "            ", "            "],
	"wind": ["            ", "      ##    ", "         #  ", "#########   ", "            ", "  ########  ", "          # ", "  ########  ", "            ", "######      ", "      #     ", "     #      "],
	"stall": ["############", "# # # # # ##", "############", " # # # # #  ", " #        # ", " #        # ", " #  #  #  # ", " # ### ## # ", "############", " #        # ", " #        # ", "            "],
	"box": ["            ", " ########## ", " #   ##   # ", " #   ##   # ", "############", "#          #", "#   ####   #", "#          #", "#          #", "#          #", "############", "            "],
	"shop": ["            ", "  ########  ", " #        # ", "############", "# # # # # # ", "############", "#          #", "# ##  #### #", "# ##  #  # #", "# ##  #  # #", "############", "            "],
	"book": ["            ", " ####  #### ", "#    ##    #", "# ## ## ## #", "#    ##    #", "# ## ## ## #", "#    ##    #", "# ## ## ## #", "#    ##    #", " ####  #### ", "     ##     ", "            "],
	"dots": ["            ", "            ", "            ", "            ", "            ", " ##  ##  ## ", " ##  ##  ## ", "            ", "            ", "            ", "            ", "            "],
	"star": ["     ##     ", "     ##     ", "    ####    ", "############", " ########## ", "  ########  ", "   ######   ", "  ###  ###  ", "  ##    ##  ", " ##      ## ", "            ", "            "],
	"heart": ["            ", " ###  ###   ", "##### ####  ", "##########  ", "##########  ", " ########   ", "  ######    ", "   ####     ", "    ##      ", "            ", "            ", "            "],
	"q": ["   ######   ", "  ##    ##  ", "  ##    ##  ", "       ##   ", "      ##    ", "     ##     ", "     ##     ", "            ", "     ##     ", "     ##     ", "            ", "            "],
	"spark": ["     #      ", "     #      ", "    ###     ", "  #######   ", "    ###     ", "     #    # ", "     #   ###", "          # ", "  #         ", " ###        ", "  #         ", "            "],
	"clock": ["   ######   ", "  #      #  ", " #   #    # ", "#    #     #", "#    #     #", "#    ####  #", "#          #", "#          #", " #        # ", "  #      #  ", "   ######   ", "            "],
	"bag": ["    ####    ", "   #    #   ", "   #    #   ", " ########## ", " #        # ", "#          #", "#   ####   #", "#          #", "#          #", "############", "            ", "            "],
	"bolt": ["      ###   ", "     ###    ", "    ###     ", "   ###      ", "  ########  ", "     ###    ", "    ###     ", "   ###      ", "  ##        ", " #          ", "            ", "            "],
	"coin": ["   ######   ", "  ##    ##  ", " ##  ##  ## ", " #  #  #  # ", " #  #     # ", " #   ##   # ", " #     #  # ", " #  #  #  # ", " ##  ##  ## ", "  ##    ##  ", "   ######   ", "            "],
	"right": ["            ", "     #      ", "     ##     ", "     ###    ", "##########  ", "########### ", "##########  ", "     ###    ", "     ##     ", "     #      ", "            ", "            "],
	"left": ["            ", "      #     ", "     ##     ", "    ###     ", "  ##########", " ###########", "  ##########", "    ###     ", "     ##     ", "      #     ", "            ", "            "],
	"check": ["            ", "          ##", "         ## ", "        ##  ", "       ##   ", "##    ##    ", " ##  ##     ", "  ####      ", "   ##       ", "            ", "            ", "            "],
	"cross": ["            ", " ##      ## ", "  ##    ##  ", "   ##  ##   ", "    ####    ", "     ##     ", "    ####    ", "   ##  ##   ", "  ##    ##  ", " ##      ## ", "            ", "            "],
	"lock": ["    ####    ", "   #    #   ", "   #    #   ", "   #    #   ", " ########## ", " #        # ", " #   ##   # ", " #   ##   # ", " #        # ", " ########## ", "            ", "            "],
	"eye": ["            ", "            ", "   ######   ", " ##      ## ", "#    ##    #", "#   ####   #", "#    ##    #", " ##      ## ", "   ######   ", "            ", "            ", "            "],
	"glass": ["  #####     ", " #     #    ", "#       #   ", "#       #   ", "#       #   ", "#       #   ", " #     #    ", "  ########  ", "        ### ", "         ###", "          ##", "            "],
	"hammer": [" ######     ", "########    ", "########    ", " ######     ", "    ##      ", "    ##      ", "    ##      ", "    ##      ", "    ##      ", "    ##      ", "   ####     ", "            "],
	"tag": ["######      ", "#     #     ", "# ##   #    ", "# ##    #   ", "#        #  ", " #        # ", "  #       # ", "   #     #  ", "    #   #   ", "     # #    ", "      #     ", "            "],
	"van": ["            ", "#######     ", "#     ###   ", "#     #  #  ", "#     #   # ", "############", "############", " ##     ##  ", "####   #### ", " ##     ##  ", "            ", "            "],
	"trophy": ["############", "# ######## #", "# ######## #", " # ###### # ", "  ########  ", "    ####    ", "     ##     ", "     ##     ", "   ######   ", "  ########  ", "            ", "            "],
	"gavel": ["   ####     ", "  ######    ", "   ######   ", "    #####   ", "    ## ##   ", "   ##       ", "  ##        ", " ##         ", "##    ######", "      ######", "            ", "            "],
	"brush": ["        ### ", "       #### ", "      ####  ", "     ####   ", "    ####    ", "   # ##     ", "  ####      ", " #####      ", "######      ", "####        ", "            ", "            "],
	"uv": ["  ########  ", "  #      #  ", "  ########  ", "    ####    ", "     ##     ", " #   ##   # ", "  #  ##  #  ", "     ##     ", "#    ##    #", "     ##     ", "  #      #  ", " #        # "],
	"gear": ["    ####    ", " ## #  # ## ", " #        # ", "   ######   ", "## #    # ##", "#  #    #  #", "#  #    #  #", "## #    # ##", "   ######   ", " #        # ", " ## #  # ## ", "    ####    "],
	"flame": ["     #      ", "    ##      ", "    ###     ", "   ####  #  ", "  ###### #  ", "  ######### ", " ########## ", " ###  ##### ", " ##    #### ", "  #    ###  ", "   ######   ", "            "],
	"up": ["     ##     ", "    ####    ", "   ######   ", "  ########  ", "     ##     ", "     ##     ", "     ##     ", "     ##     ", "     ##     ", "            ", "            ", "            "],
	"down": ["            ", "            ", "            ", "     ##     ", "     ##     ", "     ##     ", "     ##     ", "     ##     ", "  ########  ", "   ######   ", "    ####    ", "     ##     "],
	"person": ["    ####    ", "   ######   ", "   ######   ", "    ####    ", "            ", "  ########  ", " ########## ", " ########## ", " ########## ", " ########## ", "            ", "            "],
	"home": ["     ##     ", "    ####    ", "   ######   ", "  ########  ", " ########## ", "############", "  ##    ##  ", "  ##    ##  ", "  ## ## ##  ", "  ## ## ##  ", "  ########  ", "            "],
	"list": ["            ", "##  ########", "##  ########", "            ", "##  ########", "##  ########", "            ", "##  ########", "##  ########", "            ", "            ", "            "],
	"menu": ["            ", "            ", "############", "############", "            ", "############", "############", "            ", "############", "############", "            ", "            "],
	"cal": [" #  #  #  # ", "############", "#          #", "############", "# ## ## ## #", "# ## ## ## #", "#          #", "# ## ## ## #", "# ## ## ## #", "#          #", "############", "            "],
	"skull": ["   ######   ", "  ########  ", " ########## ", " ##  ##  ## ", " ##  ##  ## ", " ########## ", "  ###  ###  ", "   ######   ", "   # ## #   ", "            ", "            ", "            "],
	"news": ["##########  ", "#        #  ", "# ###### ## ", "#        # #", "# ## ### # #", "# ## ### # #", "#        # #", "# ###### # #", "#        # #", "############", "            ", "            "],
	"key": ["  ####      ", " #    #     ", " #    #     ", " #    #     ", "  ####      ", "    #       ", "    #       ", "    ####    ", "    #       ", "    ###     ", "    #       ", "            "],
}

func glyph_tex(name):
	if glyph_cache.has(name):
		return glyph_cache[name]
	var rows = GLYPHS.get(name, GLYPHS["q"])
	var img = Image.create(12, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(min(12, rows.size())):
		var row = rows[y]
		for x in range(min(12, row.length())):
			if row[x] != " ":
				img.set_pixel(x, y, Color(1, 1, 1, 1))
	var t = ImageTexture.create_from_image(img)
	glyph_cache[name] = t
	return t

func glyph(name, color = TEXT, size = 16):
	var t = TextureRect.new()
	t.texture = glyph_tex(name)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(size, size)
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.modulate = color
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

# --- colours for game concepts ------------------------------------------------------
func rarity_color(tier):
	match tier:
		"Uncommon":
			return Color(0.45, 0.85, 0.95)
		"Rare":
			return Color(0.50, 0.62, 1.0)
		"Very Rare":
			return Color(0.80, 0.52, 1.0)
		"Grail":
			return Color(1.0, 0.84, 0.35)
	return TEXT3

func trait_color(kind):
	match kind:
		"good", "hidden_item":
			return GREEN
		"fixable":
			return ORANGE
	return RED

func tier_color(t):
	return [TEXT3, TEAL, BLUE, PURPLE, GOLD][clamp(t, 0, 4)]

func weather_glyph(w):
	return {"sunny": "sun", "heatwave": "sun", "overcast": "cloud", "drizzle": "rain", "downpour": "storm", "frost": "snow", "windy": "wind"}.get(w, "cloud")

func weather_color(w):
	return {"sunny": GOLD, "heatwave": ORANGE, "overcast": TEXT2, "drizzle": BLUE, "downpour": BLUE.darkened(0.1), "frost": TEAL, "windy": TEXT2}.get(w, TEXT2)
