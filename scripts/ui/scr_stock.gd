extends RefCounted
# Your stock: to-do / for sale / everything, with a detail panel for pricing and workshop actions.

var ui
var g
var k
var tab = "todo"
var sort_mode = "action"
var limit = 40

func _init(root):
	ui = root
	g = root.g
	k = root.k

func in_tab(it):
	var selling = it["listed"] or it["auctioned"] or it.get("on_shop_floor", false)
	match tab:
		"todo":
			return not selling
		"selling":
			return selling
	return true

func rank(it):
	if it["testable"] and not it["tested"]:
		return 0
	if g.is_unsorted_lot(it):
		return 1
	if it["auth_status"] in ["Confirmed Counterfeit", "Suspected Counterfeit"]:
		return 2
	if not (it["listed"] or it["auctioned"] or it.get("on_shop_floor", false)):
		return 3
	return 4

func sorted_indices():
	var idx = []
	for i in range(g.inventory.size()):
		if in_tab(g.inventory[i]):
			idx.append(i)
	var inv = g.inventory
	match sort_mode:
		"action":
			idx.sort_custom(func(a, b):
				var ra = rank(inv[a])
				var rb = rank(inv[b])
				if ra != rb:
					return ra < rb
				return int(inv[a]["uid"]) > int(inv[b]["uid"]))
		"newest":
			idx.sort_custom(func(a, b): return int(inv[a]["uid"]) > int(inv[b]["uid"]))
		"value":
			idx.sort_custom(func(a, b): return g.perceived_center(inv[a]) > g.perceived_center(inv[b]))
		"oldest":
			idx.sort_custom(func(a, b): return int(inv[a].get("days_owned", 0)) > int(inv[b].get("days_owned", 0)))
	return idx

func build(parent):
	var list = k.vbox(8)
	list.add_child(summary())
	ui.coach(list, "stock")
	list.add_child(tabs_row())
	var idx = sorted_indices()
	var sel = -1
	for i in idx:
		if int(g.inventory[i]["uid"]) == g.selected_inv_uid:
			sel = i
	if sel < 0 and not ui.mobile and idx.size() > 0:
		sel = idx[0]
		g.selected_inv_uid = int(g.inventory[sel]["uid"])
	if idx.size() == 0:
		list.add_child(empty_state())
	var shown = 0
	for i in idx:
		if shown >= limit:
			break
		shown += 1
		var it = g.inventory[i]
		list.add_child(ui.item.tile(it, "inv", i == sel and not ui.mobile, func():
			g.selected_inv_uid = int(it["uid"])
			ui.sheet_open = true
			ui.refresh()))
	if idx.size() > limit:
		list.add_child(k.button("Show %d more" % min(40, idx.size() - limit), "ghost", func():
			limit += 40
			ui.refresh(), "", "s"))
	list.add_child(k.spacer(0, 16))
	var detail = k.vbox(10)
	if sel >= 0:
		detail.add_child(ui.item.detail(g.inventory[sel], "inv", sel))
	else:
		detail.add_child(help_panel())
	ui.master_detail(parent, "stock_" + tab, list, detail, 1.0)
	if ui.mobile and ui.sheet_open and sel >= 0:
		ui.open_sheet(g.inventory[sel]["name"], ui.item.detail(g.inventory[sel], "inv", sel), null, func(): g.selected_inv_uid = -1)

func summary():
	var p = k.panel("card2", 12)
	var v = k.vbox(8)
	p.add_child(v)
	var h = k.hbox(10)
	h.add_child(k.label("Your stock", "xl", k.TEXT))
	h.add_child(k.label("at your %s" % g.premises()["name"].to_lower(), "s", k.TEXT3))
	v.add_child(h)
	var gr = k.grid(3 if not ui.mobile else 3, 12, 6)
	gr.add_child(meter("Storage", g.inventory_space_used(), g.storage_capacity(), k.ORANGE))
	gr.add_child(meter("Listings", g.active_listing_count(), g.listing_cap(), k.GREEN))
	if g.shop_floor_enabled():
		gr.add_child(meter("Shop floor", g.shop_floor_count(), g.shop_floor_cap(), k.TEAL))
	else:
		var est = g.inventory_estimated_net()
		var b = k.vbox(2)
		b.add_child(k.label("Est. worth", "xs", k.TEXT3))
		b.add_child(k.label(g.fmt_money(est), "m", k.TEAL))
		b.tooltip_text = "What you think your stock would clear after fees, by your own estimates."
		b.mouse_filter = Control.MOUSE_FILTER_PASS
		gr.add_child(b)
	v.add_child(gr)
	return p

func meter(name, v, m, c):
	var b = k.vbox(3)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h = k.hbox(6)
	h.add_child(k.label(name, "xs", k.TEXT3))
	h.add_child(k.spacer(0, 0, true))
	h.add_child(k.label("%d/%d" % [int(v), int(m)], "s", k.TEXT if float(v) < float(m) else k.RED))
	b.add_child(h)
	b.add_child(k.bar(v, m, c if float(v) < float(m) else k.RED, 6))
	return b

func tabs_row():
	var v = k.vbox(6)
	var h = k.hbox(4)
	var counts = {"todo": 0, "selling": 0, "all": g.inventory.size()}
	for it in g.inventory:
		if it["listed"] or it["auctioned"] or it.get("on_shop_floor", false):
			counts["selling"] += 1
		else:
			counts["todo"] += 1
	for t in [["todo", "To do"], ["selling", "For sale"], ["all", "All"]]:
		var id = t[0]
		var b = k.button("%s  %d" % [t[1], counts[id]], "tab_on" if tab == id else "ghost", func():
			tab = id
			limit = 40
			g.selected_inv_uid = -1
			ui.sheet_open = false
			ui.refresh(), "", "s", 0, 38)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(b)
	v.add_child(h)
	var h2 = k.hbox(6)
	var sort_names = {"action": "Needs action", "newest": "Newest", "value": "Most valuable", "oldest": "Held longest"}
	var sb = k.button("Sort: %s" % sort_names[sort_mode], "ghost", func():
		var order = ["action", "newest", "value", "oldest"]
		sort_mode = order[(order.find(sort_mode) + 1) % order.size()]
		ui.refresh(), "Change the sort order", "xs", 0, 32)
	h2.add_child(sb)
	h2.add_child(k.spacer(0, 0, true))
	var untested = 0
	for it in g.inventory:
		if it["testable"] and not it["tested"]:
			untested += 1
	if untested > 0:
		h2.add_child(k.button("Test all (%d)" % untested, "action", func(): g.bulk_test_all(), "Test every untested electrical.", "xs", 0, 32))
	if tab != "selling" and counts["todo"] > 0:
		h2.add_child(k.button("List all at estimate", "buy", func(): g.bulk_list_at_estimate(), "Lists everything tested at the middle of your estimate, skipping anything that would sell at a loss.", "xs", 0, 32))
	v.add_child(h2)
	return v

func empty_state():
	var p = k.panel("inset", 16)
	var v = k.vbox(8)
	p.add_child(v)
	if g.inventory.size() == 0:
		v.add_child(k.label("Nothing in stock yet.", "l", k.TEXT2))
		v.add_child(k.label("Buy things at the car boot, then come back here to test, research, fix and price them.", "s", k.TEXT3, true))
		v.add_child(k.button("Go to the market", "action", func(): ui.show_market(), "", "m"))
	else:
		v.add_child(k.label("Nothing in this list.", "m", k.TEXT3))
	return p

func help_panel():
	var v = k.vbox(10)
	v.add_child(k.label("Pick something to work on.", "l", k.TEXT2))
	v.add_child(k.label("Your estimate of each item's worth can be wrong. Checks narrow it down and can turn up hidden details, good and bad. Anything you never discover, a buyer will.", "s", k.TEXT3, true))
	return v
