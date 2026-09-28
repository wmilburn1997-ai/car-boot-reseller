extends SceneTree
# Plays N days with a sensible bot through the REAL UI instance, then screenshots key screens.
# Usage: xvfb-run godot --path . --script tools/midgame.gd -- <outdir> <days> <seed>
var m
func _initialize():
	var a = OS.get_cmdline_user_args()
	get_root().size = Vector2i(1600, 900)
	m = load("res://Main.tscn").instantiate()
	get_root().add_child(m)
	_go(a[0], int(a[1]), int(a[2]))

func shot(outdir, name):
	for i in range(8):
		await process_frame
	get_root().get_texture().get_image().save_png("%s/%s.png" % [outdir, name])

func _go(outdir, days, s):
	await process_frame
	m.tutorial_seen = true
	m.start_new_game()
	m.rng.seed = s
	for d in range(days):
		for si in range(m.stalls.size()):
			if m.energy < 40 or m.current_time_minutes > 11 * 60 + 30:
				break
			m.go_to_stall(si)
			var st = m.stalls[si]
			var i = 0
			while i < int(st["revealed"]):
				var it = st["stock"][i]
				if float(it["asking"]) < m.cash * 0.5 and not it["basic_researched"] and m.energy > 40:
					m.prebuy_research(i)
				var med = m.comps_median_value(it)
				var before = st["stock"].size()
				if med > 0 and med * 0.78 > float(it["asking"]) * 1.25 and m.can_carry(it) and m.can_store(it) and float(it["asking"]) < m.cash * 0.5:
					m.buy_item(i)
				if st["stock"].size() == before:
					i += 1
				if m.pending_special_offer != null:
					m.decline_special_offer()
		m.show_inventory_fresh()
		m.bulk_test_all()
		m.bulk_list_at_estimate()
		if d == days - 1:
			break
		# spend like a sensible player
		if m.cash > 300 and m.bag_level == 0:
			m.buy_upgrade("bag")
		if m.cash > 500 and m.inventory_space_used() > 12 and m.storage_level == 0:
			m.buy_upgrade("storage")
		if m.cash > 400 and m.toolbox_level == 0:
			m.buy_upgrade("toolbox")
		if m.skill_points_available() > 0:
			for sk in ["Sharp Tongue", "Keen Eye", "Efficient Research", "Frugal Living", "Bulk Buyer"]:
				if not m.has_skill(sk):
					m.buy_skill(sk)
					break
		for idx in range(m.inventory.size() - 1, -1, -1):
			var it = m.inventory[idx]
			if m.player_level >= 6 and not it["listed"] and not it["auctioned"] and it["rarity"] != "Common":
				m.start_auction(idx)
			elif it["fault"] and m.fault_is_known(it) and m.toolbox_level > 0 and not it["repair_attempted"] and not it["listed"]:
				m.repair_item(idx)
			elif it["listed"] and m.day - int(it.get("listed_day", m.day)) >= 3:
				m.unlist_item(idx)
		m.end_day()
		while m.big_popup.visible:
			m._close_big_popup()
	m.clear_toasts()
	m.show_stall()
	await shot(outdir, "mid_stall")
	m.inventory_tab = "listed"
	m.show_inventory()
	await shot(outdir, "mid_inventory_listed")
	m.show_sold_history()
	await shot(outdir, "mid_sales")
	m.show_shop()
	await shot(outdir, "mid_shop")
	m.end_day()
	await shot(outdir, "mid_summary")
	while m.big_popup.visible:
		m._close_big_popup()
	m.show_log_screen("rng")
	await shot(outdir, "mid_rnglog")
	m.show_achievements()
	await shot(outdir, "mid_achievements")
	print("MIDGAME day=%d cash=%.2f stock=%d sold=%d level=%d" % [m.day, m.cash, m.inventory.size(), m.sold_history.size(), m.player_level])
	quit()
