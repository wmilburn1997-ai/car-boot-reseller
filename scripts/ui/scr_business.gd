extends RefCounted
# Business (premises, vehicle, workshop, account, staff), Perks and Expertise screens.

var ui
var g
var k

func _init(root):
	ui = root
	g = root.g
	k = root.k

func art(kind, idx):
	var p = "res://art/%s_%d.png" % [kind, idx]
	if ResourceLoader.exists(p):
		return load(p)
	return null

func build(parent):
	var v = k.vbox(14)
	v.add_child(costs_bar())
	ui.coach(v, "business")
	var top = k.grid(1 if ui.mobile else 2, 12, 12)
	top.add_child(premises_card())
	top.add_child(vehicle_card())
	v.add_child(top)
	v.add_child(k.section("Workshop  %d/%d slots" % [g.workshop_slots_used(), g.workshop_slots()]))
	v.add_child(workshop())
	var bottom = k.grid(1 if ui.mobile else 2, 12, 12)
	bottom.add_child(account_card())
	bottom.add_child(staff_card())
	v.add_child(bottom)
	v.add_child(k.spacer(0, 20))
	parent.add_child(ui.keyed_scroll("business", v))

func costs_bar():
	var p = k.panel("card2", 12)
	var h = k.flow(18, 6)
	p.add_child(h)
	var rc = g.running_costs()
	h.add_child(k.label("Your business", "xl", k.TEXT))
	h.add_child(stat("Value", g.fmt_money(g.business_value()), k.GOLD))
	h.add_child(stat("Pitch fee today", g.fmt_money(g.daily_expenses), k.TEXT2))
	h.add_child(stat("Rent", g.fmt_money(rc["rent"]) + "/day", k.TEXT2))
	h.add_child(stat("Fuel", g.fmt_money(rc["fuel"]) + "/day", k.TEXT2))
	if float(rc["wages"]) > 0:
		h.add_child(stat("Wages", g.fmt_money(rc["wages"]) + "/day", k.TEXT2))
	h.add_child(stat("Every night", g.fmt_money(float(rc["total"]) + float(g.daily_expenses)), k.RED))
	return p

func stat(name, value, c):
	var b = k.vbox(0)
	b.add_child(k.label(name.to_upper(), "xs", k.TEXT3))
	b.add_child(k.label(value, "m", c))
	return b

func track(n, cur, names):
	var h = k.hbox(4)
	for i in range(n):
		var on = i <= cur
		var p = PanelContainer.new()
		p.add_theme_stylebox_override("panel", k.sbox(k.GOLD if i == cur else (k.GOLD_D if on else k.PANEL3), k.GOLD if i == cur else k.LINE, 3, 1, 0))
		p.custom_minimum_size = Vector2(0, 8)
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p.tooltip_text = names[i]
		p.mouse_filter = Control.MOUSE_FILTER_PASS
		h.add_child(p)
	return h

func premises_card():
	var cur = g.premises()
	var p = k.panel("card", 14)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v = k.vbox(10)
	p.add_child(v)
	var tex = art("premises", g.premises_level)
	if tex != null:
		var tr = k.tex_rect(tex, 0)
		tr.custom_minimum_size = Vector2(0, 150 if not ui.mobile else 120)
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.clip_contents = true
		v.add_child(tr)
	var names = []
	for pr in g.Biz.PREMISES:
		names.append(pr["name"])
	v.add_child(track(names.size(), g.premises_level, names))
	var h = k.hbox(8)
	h.add_child(k.glyph("home", k.GOLD, 20))
	h.add_child(k.label(cur["name"], "xl", k.GOLD))
	v.add_child(h)
	v.add_child(k.label(cur["desc"], "s", k.TEXT2, true))
	var f = k.flow(8, 4)
	f.add_child(k.chip("Storage %d" % g.storage_capacity(), k.ORANGE, null, "s", "box"))
	f.add_child(k.chip("Workshop slots %d" % int(cur["slots"]), k.BLUE, null, "s", "hammer"))
	f.add_child(k.chip("Listings %d" % g.listing_cap(), k.GREEN, null, "s", "tag"))
	if float(cur["rent"]) > 0:
		f.add_child(k.chip("Rent £%.0f/day" % float(cur["rent"]), k.RED, null, "s", "coin"))
	v.add_child(f)
	if g.can_buy_premises():
		var nxt = g.Biz.PREMISES[g.premises_level + 1]
		var np = k.panel("inset", 12)
		var nv = k.vbox(6)
		np.add_child(nv)
		var nh = k.hbox(8)
		nh.add_child(k.label("NEXT: " + nxt["name"].to_upper(), "s", k.TEXT))
		nh.add_child(k.spacer(0, 0, true))
		nh.add_child(k.label(g.fmt_money(nxt["cost"]), "l", k.GOLD))
		nv.add_child(nh)
		var lines = "Storage %d → %d · Slots %d → %d · Listings %d → %d · Rent £%.0f/day" % [int(cur["storage"]), int(nxt["storage"]), int(cur["slots"]), int(nxt["slots"]), int(cur["listings"]), int(nxt["listings"]), float(nxt["rent"])]
		nv.add_child(k.label(lines, "xs", k.TEXT2, true))
		for u in nxt.get("unlocks", []):
			nv.add_child(k.label("+ " + u, "xs", k.GREEN, true))
		var b = k.button("Move in  %s" % g.fmt_money(nxt["cost"]), "primary", func(): g.buy_premises(), "One-off fit-out and deposit. Rent is charged every night.", "m", 0, 46)
		b.disabled = g.cash < float(nxt["cost"])
		if g.cash < float(nxt["cost"]):
			b.text = "Save up: %s to go" % g.fmt_money(float(nxt["cost"]) - g.cash)
		nv.add_child(b)
		v.add_child(np)
	return p

func vehicle_card():
	var cur = g.vehicle()
	var p = k.panel("card", 14)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v = k.vbox(10)
	p.add_child(v)
	var tex = art("vehicle", g.vehicle_level)
	if tex != null:
		var tr = k.tex_rect(tex, 0)
		tr.custom_minimum_size = Vector2(0, 150 if not ui.mobile else 120)
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.clip_contents = true
		v.add_child(tr)
	var names = []
	for vh in g.Biz.VEHICLES:
		names.append(vh["name"])
	v.add_child(track(names.size(), g.vehicle_level, names))
	var h = k.hbox(8)
	h.add_child(k.glyph("van", k.BLUE, 20))
	h.add_child(k.label(cur["name"], "xl", k.BLUE))
	v.add_child(h)
	v.add_child(k.label(cur["desc"], "s", k.TEXT2, true))
	var f = k.flow(8, 4)
	f.add_child(k.chip("Carry %d" % int(cur["carry"]), k.BLUE, null, "s", "bag"))
	if float(cur["fuel"]) > 0:
		f.add_child(k.chip("Fuel £%.0f/day" % float(cur["fuel"]), k.RED, null, "s", "coin"))
	if g.can_do_clearances():
		f.add_child(k.chip("House clearances", k.GOLD, null, "s", "home"))
	v.add_child(f)
	if g.vehicle_level < g.Biz.VEHICLES.size() - 1:
		var nxt = g.Biz.VEHICLES[g.vehicle_level + 1]
		var np = k.panel("inset", 12)
		var nv = k.vbox(6)
		np.add_child(nv)
		var nh = k.hbox(8)
		nh.add_child(k.label("NEXT: " + nxt["name"].to_upper(), "s", k.TEXT))
		nh.add_child(k.spacer(0, 0, true))
		nh.add_child(k.label(g.fmt_money(nxt["cost"]), "l", k.GOLD))
		nv.add_child(nh)
		nv.add_child(k.label("Carry %d → %d · Fuel £%.0f/day" % [int(cur["carry"]), int(nxt["carry"]), float(nxt["fuel"])], "xs", k.TEXT2, true))
		for u in nxt.get("unlocks", []):
			nv.add_child(k.label("+ " + u, "xs", k.GREEN, true))
		var b = k.button("Buy  %s" % g.fmt_money(nxt["cost"]), "primary", func(): g.buy_vehicle(), "", "m", 0, 46)
		b.disabled = g.cash < float(nxt["cost"])
		if g.cash < float(nxt["cost"]):
			b.text = "Save up: %s to go" % g.fmt_money(float(nxt["cost"]) - g.cash)
		nv.add_child(b)
		v.add_child(np)
	return p

const EQUIP_ORDER = ["cleaning", "repair", "test_rig", "photo", "auth", "parts", "packing", "library", "shelving"]

func workshop():
	var v = k.vbox(10)
	var cols = 1 if ui.mobile else (3 if ui.logical.x >= 1400 else 2)
	var gr = k.grid(cols, 10, 10)
	var installed = 0
	for id in EQUIP_ORDER:
		if g.equip_level(id) > 0:
			gr.add_child(equip_card(id, true))
			installed += 1
	for i in range(max(0, g.workshop_slots() - installed)):
		var p = k.panel("inset", 14)
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var h = k.hbox(8)
		h.add_child(k.glyph("gear", k.TEXT3, 18))
		h.add_child(k.label("Empty slot", "m", k.TEXT3))
		p.add_child(h)
		gr.add_child(p)
	v.add_child(gr)
	v.add_child(k.label("AVAILABLE", "xs", k.TEXT3))
	var gr2 = k.grid(cols, 10, 10)
	for id in EQUIP_ORDER:
		if g.equip_level(id) == 0:
			gr2.add_child(equip_card(id, false))
	v.add_child(gr2)
	return v

func equip_card(id, owned):
	var def = g.Biz.EQUIPMENT[id]
	var lvl = g.equip_level(id)
	var p = k.panel("card" if not owned else "blue", 12)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v = k.vbox(6)
	p.add_child(v)
	var h = k.hbox(8)
	var icon_for = {"shelf": "list", "clean": "brush", "repair": "hammer", "test": "bolt", "photo": "eye", "auth": "uv", "parts": "gear", "pack": "box", "book": "book"}
	h.add_child(k.glyph(icon_for.get(def["icon"], "gear"), k.BLUE if owned else k.TEXT2, 18))
	var name = def["levels"][max(0, lvl - 1)]["name"] if owned else def["levels"][0]["name"]
	var nl = k.label(name, "m", k.TEXT)
	k.expand(nl)
	h.add_child(nl)
	if def["levels"].size() > 1:
		h.add_child(k.chip("%d/%d" % [lvl, def["levels"].size()], k.TEXT3))
	v.add_child(h)
	var desc = def["levels"][max(0, lvl - 1)]["desc"] if owned else def["levels"][0]["desc"]
	v.add_child(k.label(desc, "xs", k.TEXT2, true))
	var row = k.hbox(6)
	if lvl < def["levels"].size():
		var nxt = def["levels"][lvl]
		var label = ("Upgrade: %s  %s" % [nxt["name"], g.fmt_money(nxt["cost"])]) if owned else ("Install  %s" % g.fmt_money(nxt["cost"]))
		var b = k.button(label, "action", func(): g.buy_equipment(id), nxt["desc"], "s")
		b.disabled = g.cash < float(nxt["cost"]) or (not owned and g.workshop_slots_used() >= g.workshop_slots())
		if not owned and g.workshop_slots_used() >= g.workshop_slots():
			b.text = "No free slot · %s" % g.fmt_money(nxt["cost"])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(b)
	if owned:
		row.add_child(k.button("Sell", "ghost", func(): g.remove_equipment(id), "Sell it for 40% of what you paid and free the slot.", "s"))
	v.add_child(row)
	return p

func account_card():
	var p = k.panel("card", 14)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v = k.vbox(8)
	p.add_child(v)
	var cur = g.account()
	var h = k.hbox(8)
	h.add_child(k.glyph("tag", k.GREEN, 18))
	h.add_child(k.label("Seller account", "l", k.TEXT))
	v.add_child(h)
	v.add_child(k.label("%s · fees %.1f%% of every sale" % [cur["name"], float(cur["fee"]) * 100.0], "m", k.GREEN))
	if g.fee_level < g.Biz.ACCOUNTS.size() - 1:
		var nxt = g.Biz.ACCOUNTS[g.fee_level + 1]
		var met = g.account_requirements_met(g.fee_level + 1)
		v.add_child(k.label("Next: %s (%.1f%% fees). Needs %d sales%s. You have %d%s." % [nxt["name"], float(nxt["fee"]) * 100.0, int(nxt["sales"]), (" and a %d%% rating" % int(nxt["rating"])) if int(nxt["rating"]) > 0 else "", g.sold_history.size(), (" and %d%%" % int(g.seller_rating)) if int(nxt["rating"]) > 0 else ""], "xs", k.TEXT2, true))
		var b = k.button("Upgrade  %s" % g.fmt_money(nxt["cost"]), "action", func(): g.buy_account(), "", "s")
		b.disabled = not met or g.cash < float(nxt["cost"])
		v.add_child(b)
	return p

func staff_card():
	var p = k.panel("card", 14)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v = k.vbox(8)
	p.add_child(v)
	var h = k.hbox(8)
	h.add_child(k.glyph("person", k.TEAL, 18))
	h.add_child(k.label("Staff", "l", k.TEXT))
	v.add_child(h)
	for id in ["assistant", "runner", "shopkeeper", "picker"]:
		var s = g.Biz.STAFF[id]
		var hired = g.staff.has(id)
		var allowed = g.staff_allowed(id)
		var row = k.hbox(10)
		var tv = k.vbox(2)
		k.expand(tv)
		tv.add_child(k.label("%s · £%.0f/day" % [s["name"], float(s["wage"])], "m", k.TEAL if hired else (k.TEXT if allowed else k.TEXT3)))
		tv.add_child(k.label(s["desc"] if allowed else "Needs a %s or bigger." % g.Biz.PREMISES[int(s["needs"])]["name"], "xs", k.TEXT3, true))
		row.add_child(tv)
		var b = k.button("Let go" if hired else "Hire", "ghost" if hired else "action", func(): g.toggle_staff(id), "", "s")
		b.disabled = not allowed and not hired
		row.add_child(b)
		v.add_child(row)
	return p

# ---------------------------------------------------------------------------
# Perks
# ---------------------------------------------------------------------------
func build_perks(parent):
	parent.add_child(ui.keyed_scroll("perks", perks_content()))

func perks_content():
	var v = k.vbox(12)
	var head = k.panel("card2", 14)
	var hh = k.hbox(12)
	head.add_child(hh)
	hh.add_child(k.glyph("spark", k.GOLD, 28))
	var tv = k.vbox(2)
	k.expand(tv)
	tv.add_child(k.label("Perks", "xl", k.TEXT))
	tv.add_child(k.label("One point per level. Perks change how you play rather than nudging numbers.", "s", k.TEXT3, true))
	hh.add_child(tv)
	var pts = g.skill_points_available()
	var pv = k.vbox(2)
	pv.add_child(k.label("%d point%s" % [pts, "" if pts == 1 else "s"], "xl", k.GOLD if pts > 0 else k.TEXT3, false, HORIZONTAL_ALIGNMENT_RIGHT))
	if pts == 0:
		pv.add_child(k.label("Next point at level %d" % (g.player_level + 1), "xs", k.TEXT3, false, HORIZONTAL_ALIGNMENT_RIGHT))
		pv.add_child(k.bar(g.player_xp, g.xp_needed_for_level(g.player_level), k.PURPLE, 6))
	hh.add_child(pv)
	v.add_child(head)
	var cols = 1 if ui.mobile else 3
	var gr = k.grid(cols, 12, 12)
	for branch in ["Buying", "Knowing", "Selling"]:
		var col = k.vbox(8)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(k.section(branch))
		for pd in g.Biz.PERKS:
			if pd["branch"] == branch:
				col.add_child(perk_card(pd))
		gr.add_child(col)
	v.add_child(gr)
	v.add_child(k.spacer(0, 20))
	return v

func perk_card(pd):
	var owned = g.has_perk(pd["id"])
	var req_ok = pd["requires"] == "" or g.has_perk(pd["requires"])
	var afford = g.skill_points_available() >= int(pd["cost"])
	var p = k.panel("good" if owned else ("card" if req_ok else "inset"), 12)
	var v = k.vbox(4)
	p.add_child(v)
	var h = k.hbox(8)
	h.add_child(k.glyph("check" if owned else ("spark" if req_ok else "lock"), k.GREEN if owned else (k.GOLD if req_ok else k.TEXT3), 16))
	var nl = k.label(pd["name"], "m", k.TEXT if req_ok or owned else k.TEXT3)
	k.expand(nl)
	h.add_child(nl)
	h.add_child(k.chip("%d pt" % int(pd["cost"]), k.GOLD if not owned else k.GREEN))
	v.add_child(h)
	v.add_child(k.label(pd["desc"], "s", k.TEXT2, true))
	if not req_ok:
		v.add_child(k.label("Needs %s first." % g.perk_def(pd["requires"])["name"], "xs", k.TEXT3))
	elif not owned and afford:
		var b = k.button("Unlock", "primary", func(): g.buy_perk(pd["id"]), "", "s")
		v.add_child(b)
	return p

# ---------------------------------------------------------------------------
# Expertise
# ---------------------------------------------------------------------------
func build_knowledge(parent):
	parent.add_child(ui.keyed_scroll("knowledge", knowledge_content()))

func knowledge_content():
	var v = k.vbox(12)
	var head = k.panel("card2", 14)
	var hv = k.vbox(4)
	head.add_child(hv)
	hv.add_child(k.label("Expertise", "xl", k.TEXT))
	hv.add_child(k.label("You learn a category by selling, researching and discovering things in it. Every tier changes what you can see and do.", "s", k.TEXT3, true))
	var tiers = k.flow(8, 4)
	for t in range(1, 5):
		tiers.add_child(k.chip("%s at %d" % [g.EXPERTISE_TIER_NAMES[t], g.EXPERTISE_TIERS[t]], k.tier_color(t)))
	hv.add_child(tiers)
	hv.add_child(k.label("Enthusiast: subtler tells show up when you Inspect, and your estimates tighten. Specialist: a hands-on check for that category, at stalls and at home. Expert: a private collector contact. Authority: spot fakes at a glance.", "xs", k.TEXT2, true))
	var sp = k.panel("gold", 10)
	var sv = k.vbox(4)
	sp.add_child(sv)
	var sig_txt = ", ".join(g.signatures) if g.signatures.size() > 0 else "none yet"
	sv.add_child(k.label("Signatures (%d/%d): %s" % [g.signatures.size(), g.signature_slots(), sig_txt], "m", k.GOLD, true))
	sv.add_child(k.label("Only signature categories go beyond Specialist. It's what you're known for: pick them to suit how you like to deal. A High Street shop adds a third slot.", "xs", k.TEXT2, true))
	hv.add_child(sp)
	v.add_child(head)
	var cats = g.CATEGORIES.duplicate()
	cats.sort_custom(func(a, b):
		if g.is_signature(a) != g.is_signature(b):
			return g.is_signature(a)
		return g.expertise_xp(a) > g.expertise_xp(b))
	var cols = 1 if ui.mobile else 2
	var gr = k.grid(cols, 10, 10)
	for c in cats:
		gr.add_child(category_card(c))
	v.add_child(gr)
	v.add_child(k.spacer(0, 20))
	return v

func category_card(c):
	var t = g.expertise_tier(c)
	var p = k.panel("card", 12)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h = k.hbox(12)
	p.add_child(h)
	h.add_child(k.cat_icon(c, 44 if not ui.mobile else 30))
	var v = k.vbox(4)
	k.expand(v)
	var th = k.hbox(8)
	th.add_child(k.label(c, "m", k.TEXT))
	th.add_child(k.chip(g.EXPERTISE_TIER_NAMES[t], k.tier_color(t)))
	if g.is_signature(c):
		th.add_child(k.chip("SIGNATURE", k.GOLD, null, "xs", "star"))
	th.add_child(k.spacer(0, 0, true))
	var found = 0
	var total = 0
	for tid in g.content.traits:
		if g.content.traits[tid]["cats"].has(c):
			total += 1
			if g.discoveries_log.has(tid):
				found += 1
	th.add_child(k.label("%d/%d discoveries" % [found, total], "xs", k.PURPLE))
	v.add_child(th)
	var pr = g.expertise_progress(c)
	var capped = not g.is_signature(c) and g.raw_expertise_tier(c) >= 2
	if capped:
		var ch = k.hbox(8)
		var cl = k.label("Capped at Specialist%s." % (" (you know enough for %s)" % g.EXPERTISE_TIER_NAMES[g.raw_expertise_tier(c)] if g.raw_expertise_tier(c) > 2 else ""), "xs", k.TEXT3, true)
		k.expand(cl)
		ch.add_child(cl)
		var sb = k.button("Make signature", "gold", func(): g.set_signature(c), "Commit to %s: it can go all the way to Authority." % c, "s")
		sb.disabled = g.signatures.size() >= g.signature_slots()
		ch.add_child(sb)
		v.add_child(ch)
	elif float(pr[1]) > 0:
		var ph = k.hbox(8)
		var pb = k.bar(pr[0], pr[1], k.tier_color(t + 1), 7)
		k.expand(pb)
		ph.add_child(pb)
		ph.add_child(k.label("%d/%d → %s" % [int(pr[0]), int(pr[1]), g.EXPERTISE_TIER_NAMES[t + 1]], "xs", k.tier_color(t + 1)))
		v.add_child(ph)
		if t >= 1:
			v.add_child(k.label("Next: %s" % g.tier_unlock_text(c, t + 1), "xs", k.TEXT3, true))
	else:
		v.add_child(k.label("Mastered.", "xs", k.GOLD))
	if t >= 2:
		v.add_child(k.label("Specialist action: %s" % g.SPECIALIST_ACTIONS.get(c, ""), "xs", k.BLUE))
	if g.is_signature(c):
		var dr = k.hbox(8)
		dr.add_child(k.spacer(0, 0, true))
		dr.add_child(k.button("Drop signature", "ghost", func(): g.drop_signature(c), "Step back from %s (once a fortnight). You keep what you know, capped at Specialist." % c, "xs"))
		v.add_child(dr)
	elif g.raw_expertise_tier(c) < 2 and g.signatures.size() < g.signature_slots() and g.expertise_xp(c) >= 30:
		var dr2 = k.hbox(8)
		dr2.add_child(k.spacer(0, 0, true))
		dr2.add_child(k.button("Make signature", "ghost", func(): g.set_signature(c), "Commit to %s early." % c, "xs"))
		v.add_child(dr2)
	h.add_child(v)
	return p
