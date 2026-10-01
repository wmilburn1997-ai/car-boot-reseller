extends Control
# Car Boot Reseller — game state and rules. The UI lives in scripts/ui/.

var rng = RandomNumberGenerator.new()
# Each run has a seed. Nights and markets draw from a per-day stream derived from it,
# and the live RNG state is saved, so reloading a save can't reroll outcomes.
var run_seed = 0
var forced_run_seed = -1   # tools set this for reproducible runs

const GAME_VERSION = "0.14.0-playtest"
const STARTING_CASH = 300.0
const SAVE_PATH = "user://savegame.json"
# Tools can point the game at another save file (CBR_SAVE=user://x.json) so parallel test runs don't collide.
var save_path = OS.get_environment("CBR_SAVE") if OS.get_environment("CBR_SAVE") != "" else SAVE_PATH
const CATEGORIES = ["Clothing","Games","Trading Cards","Vinyl","Cameras","Tools","Electronics","Collectables","Jewellery","Books","Home","Musical Instruments","Garden & Outdoor"]
const ContentScript = preload("res://scripts/content.gd")
const Biz = preload("res://scripts/data/business.gd")
const Lines012 = preload("res://scripts/data/lines_012.gd")
const Ident = preload("res://scripts/data/identity.gd")
const WorldSys = preload("res://scripts/sys_world.gd")
const TradeSys = preload("res://scripts/sys_trade.gd")
const LuckSys = preload("res://scripts/sys_luck.gd")
const GambleSys = preload("res://scripts/sys_gamble.gd")
var w2 = {}
var world = WorldSys.new(self)
var trade = TradeSys.new(self)
var luck = LuckSys.new(self)
var gamble = GambleSys.new(self)
const WorldData = preload("res://scripts/data/world.gd")
const UIRoot = preload("res://scripts/ui/ui_root.gd")
static var _content_cache = null

var content = null
var ui = null
var sim_mode = false

# --- run state
var has_save = false
var game_over = false
var on_title_screen = false
var in_end_day = false
var seller_rating = 100.0
var rng_log = []
var activity_log = []
var best_net_worth = STARTING_CASH
var day = 1
var cash = STARTING_CASH
var energy = 100
var player_level = 1
var player_xp = 0
var current_time_minutes = 7 * 60
var daily_expenses = 6.50
var current_stall_index = 0
var stalls = []
var inventory = []
var sold_history = []
var discovered_log = {}
var family_stats = {}
var achievements = {}
var day_stats = {}
var last_rng_line = "No RNG rolls yet."
var category_knowledge = {}   # legacy 0.10 (5..25), migration only
var expertise = {}            # category -> xp
# What's in the car from today's buys. Worked out from stock, so scrapping or
# selling something you bought today frees the space again.
var carry_used:
	get:
		var used = 0
		for it in inventory:
			if int(it.get("carried_day", -1)) == day:
				used += size_units(it)
		return used
	set(_v):
		pass
var mystery_packages_left = 0
var current_trends = {}
var trend_headlines = []
var current_week = 1
var negative_days_streak = 0
var total_haggled_savings = 0.0
var total_lifetime_profit = 0.0
var fixer_uses_today = 0
var daily_challenges = []
var daily_challenge_bonus_given = false
var lifetime_challenges_completed = 0
var lifetime_fixer_wins = 0
var last_save_time = ""
var skills_unlocked = {}
var pending_special_offer = null
var current_screen_name = "show_stall"
var selected_stall_uid = -1
var selected_inv_uid = -1
var bulk_mode = false
var cash_last_shown = -999999.0
# Legacy 0.10 upgrade levels: kept for migration and a few legacy bonuses.
var bag_level = 0
var storage_level = 0
var toolbox_level = 0
var eye_level = 0
var fee_level = 0            # 0.11: seller account tier

var item_families = []        # from Content

var seller_profiles = {
	"Desperate Seller": {"knowledge":0.45, "haggle":0.23, "pricing":0.88, "fault":1.15, "fake":1.05, "side":0.010, "depth":18, "rarity_boost":0.80, "trait_bias":0.00, "categories":["Clothing","Games","Trading Cards","Electronics","Home","Garden & Outdoor"]},
	"House Clearance": {"knowledge":0.35, "haggle":0.34, "pricing":0.90, "fault":1.30, "fake":0.90, "side":0.018, "depth":26, "rarity_boost":0.70, "trait_bias":0.00, "categories":["Home","Vinyl","Cameras","Tools","Books","Collectables","Jewellery","Musical Instruments","Garden & Outdoor"]},
	"Clueless Seller": {"knowledge":0.40, "haggle":0.38, "pricing":0.84, "fault":0.95, "fake":0.85, "side":0.002, "depth":15, "rarity_boost":0.55, "trait_bias":0.02, "categories":["Games","Trading Cards","Clothing","Books","Home","Collectables","Garden & Outdoor"]},
	"Regular Seller": {"knowledge":0.60, "haggle":0.56, "pricing":0.98, "fault":1.00, "fake":1.00, "side":0.0015, "depth":14, "rarity_boost":1.00, "trait_bias":0.00, "categories":["Clothing","Games","Tools","Home","Electronics","Books","Musical Instruments","Garden & Outdoor"]},
	"Collector": {"knowledge":0.86, "haggle":0.78, "pricing":1.06, "fault":0.70, "fake":0.45, "side":0.008, "depth":10, "rarity_boost":1.60, "trait_bias":0.08, "categories":["Vinyl","Cameras","Collectables","Jewellery","Games","Trading Cards","Musical Instruments"]},
	"Dodgy Seller": {"knowledge":0.48, "haggle":0.36, "pricing":0.82, "fault":1.55, "fake":2.40, "side":0.022, "depth":13, "rarity_boost":0.95, "trait_bias":-0.10, "categories":["Clothing","Trading Cards","Electronics","Games","Jewellery"]},
	"Dealer": {"knowledge":0.90, "haggle":0.84, "pricing":1.10, "fault":0.65, "fake":0.55, "side":0.001, "depth":8, "rarity_boost":1.85, "trait_bias":0.06, "categories":["Clothing","Games","Cameras","Vinyl","Collectables","Jewellery","Musical Instruments"]}
}
# Chances match the "1 in N" shown to the player exactly (before a seller's rarity modifier).
var rarity_table = [
	{"tier":"Common","one_in":1,"chance":1.0 - (1.0/25.0 + 1.0/125.0 + 1.0/750.0 + 1.0/5000.0)},
	{"tier":"Uncommon","one_in":25,"chance":1.0/25.0},
	{"tier":"Rare","one_in":125,"chance":1.0/125.0},
	{"tier":"Very Rare","one_in":750,"chance":1.0/750.0},
	{"tier":"Grail","one_in":5000,"chance":1.0/5000.0}
]

var package_table = [
	{"tier":"Poor","chance":0.55},
	{"tier":"Average","chance":0.25},
	{"tier":"Good","chance":0.14},
	{"tier":"Excellent","chance":0.05},
	{"tier":"Jackpot","chance":0.009},
	{"tier":"Grail","chance":0.001}
]

var special_event_profiles = {
	"Desperate Seller": {"title":"Something in the Car","flavor":"\"Look, I need this gone today. I've got more of this in the car if you want first look.\"","price_mult":[0.55,0.80],"value_mult":[0.85,1.15],"fault_bonus":0.10},
	"House Clearance": {"title":"More in the Van","flavor":"\"There's a lot more of this back in the van, actually. Take it or leave it.\"","price_mult":[0.75,1.00],"value_mult":[0.90,1.30],"fault_bonus":0.05},
	"Collector": {"title":"From My Personal Collection","flavor":"\"I don't usually let this go... but from my personal collection, if you're serious.\"","price_mult":[0.60,0.95],"value_mult":[1.30,2.20],"fault_bonus":-0.05},
	"Dodgy Seller": {"title":"Bit of a Grey Area","flavor":"\"Between you and me, this one's a bit of a grey area — no questions asked, cash only.\"","price_mult":[0.45,0.70],"value_mult":[1.00,1.80],"fault_bonus":0.08,"fake_bonus":0.35}
}
var tutorial_seen = false
var tutorial_slide_index = 0
var tutorial_slides = [
	{"title": "Welcome to the car boot", "body": "You've got £300, a bag for life and a spare room. Every morning you walk a British car boot sale looking for things worth more than the asking price. Every evening, buyers look at what you've listed.\n\nSomewhere in these fields there's a first pressing, a signed guitar and a hallmark under the tarnish. Most of it is junk. Your job is telling the difference."},
	{"title": "Every item hides something", "body": "INSPECT is a quick glance. CHECK CONDITION gives the real score. RESEARCH shows what these actually sell for, after fees.\n\nPurple \"?\" clues mean there's more to find: a mark, a variant, a fault. Checks and expertise reveal it. Anything you miss, a buyer will spot."},
	{"title": "Sellers are people", "body": "Make an offer and they'll take it, counter, or name a final price when their patience runs out. Found a flaw? Point it out. Research in front of a sharp dealer and the price might go up.\n\nRegulars remember you. Gaz, your rival, is out there too, buying what you walk past."},
	{"title": "Sell, then grow", "body": "At home: test, clean, repair, price, list. Buyers arrive overnight, and the night report tells you why things aren't selling.\n\nPut profit into a garage, a van, a shop. Pick signature categories to master, chase Wanted requests, bid at the Saleroom. Just don't let cash stay in the red for four nights."},
]

func fixer_max_uses():
	return 2 if player_level >= 15 else 1

func unlock_check_high_roller():
	if lifetime_fixer_wins >= 5:
		unlock_achievement("High Roller")

func fixer_gamble(amount):
	if fixer_uses_today >= fixer_max_uses():
		queue_popup("The Fixer is done dealing for today. Come back tomorrow.")
		return
	if cash < amount:
		queue_popup("Not enough cash.")
		return
	fixer_uses_today += 1
	cash -= amount
	day_stats["other_income"] = float(day_stats.get("other_income", 0.0)) - amount
	var fr = luck.roll("fixer", 0.44, "The Fixer: £%d double or nothing" % int(amount))
	fr["label"] = "Your £%d, double or nothing" % int(amount)
	luck.tier_bands(fr, [["Treble", 0.05, "gold", "£%d becomes £%d" % [int(amount), int(amount * 3.0)]], ["Double", 0.44, "green", "£%d becomes £%d" % [int(amount), int(amount * 2.0)]]], "you lose the £%d" % int(amount))
	var won = fr["hit"]
	if won:
		var mult = 3.0 if fr["band"] == "Treble" else 2.0
		cash += amount * mult
		day_stats["other_income"] = float(day_stats.get("other_income", 0.0)) + amount * mult
		lifetime_fixer_wins += 1
		show_roll("THE FIXER", [fr], "%s! £%.0f becomes £%.0f." % ["Treble" if mult > 2.0 else "Won", amount, amount * mult])
		play_sfx("rare")
		unlock_check_high_roller()
	else:
		show_roll("THE FIXER", [fr], "Lost £%.0f. The Fixer shrugs." % amount)
		play_sfx("fail")
	save_game()
	show_stall_list()

const SAVE_VERSION = 4

func get_save_data():
	return {
		"save_version": SAVE_VERSION,
		"game_version": GAME_VERSION,
		"run_seed": str(run_seed),
		"w2": w2,
		"signatures": signatures,
		"signature_changed_day": signature_changed_day,
		"signature_nagged": signature_nagged,
		"rng_seed": str(rng.seed),
		"rng_state": str(rng.state),
		"energy": energy,
		"current_time_minutes": current_time_minutes,
		"daily_expenses": daily_expenses,
		"stalls": stalls,
		"current_stall_index": current_stall_index,
		"carry_used": carry_used,
		"fixer_uses_today": fixer_uses_today,
		"mystery_packages_left": mystery_packages_left,
		"daily_challenges": daily_challenges,
		"daily_challenge_bonus_given": daily_challenge_bonus_given,
		"current_trends": current_trends,
		"trend_random": trend_random,
		"trend_rumour": trend_rumour,
		"trend_headlines": trend_headlines,
		"week_news": week_news,
		"current_week": current_week,
		"pending_special_offer": pending_special_offer,
		"day_stats": day_stats,
		"category_knowledge": category_knowledge,
		"expertise": expertise,
		"discoveries_log": discoveries_log,
		"journal": journal,
		"game_over": game_over,
		"seller_rating": seller_rating,
		"rng_log": rng_log,
		"activity_log": activity_log,
		"best_net_worth": best_net_worth,
		"goals_done": goals_done,
		"cash": cash,
		"day": day,
		"player_level": player_level,
		"player_xp": player_xp,
		"inventory": inventory,
		"bag_level": bag_level,
		"storage_level": storage_level,
		"toolbox_level": toolbox_level,
		"eye_level": eye_level,
		"fee_level": fee_level,
		"premises_level": premises_level,
		"vehicle_level": vehicle_level,
		"equipment": equipment,
		"staff": staff,
		"achievements": achievements,
		"discovered_log": discovered_log,
		"family_stats": family_stats,
		"sold_history": sold_history,
		"total_haggled_savings": total_haggled_savings,
		"total_lifetime_profit": total_lifetime_profit,
		"lifetime_challenges_completed": lifetime_challenges_completed,
		"lifetime_fixer_wins": lifetime_fixer_wins,
		"skills_unlocked": skills_unlocked,
		"tutorial_seen": tutorial_seen,
		"negative_days_streak": negative_days_streak,
		"market_today": market_today,
		"week_plan": week_plan,
		"home_venue": home_venue,
		"regulars": regulars,
		"next_regular_id": next_regular_id,
		"rival": rival,
		"rival_route": rival_route,
		"clearance_leads": clearance_leads,
		"next_lead_id": next_lead_id,
		"clearance": clearance,
		"next_item_uid": next_item_uid,
		"collector_used_today": collector_used_today,
		"collector_offers": collector_offers,
		"fixed_count": fixed_count,
		"trade_buyer_day": trade_buyer_day,
		"save_time": Time.get_datetime_string_from_system(false, true),
	}

func save_game():
	if sim_mode:
		return
	var data = get_save_data()
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data))
	file.close()
	last_save_time = str(data["save_time"])

const LEGACY_RENAMES = [
	["Polaroid Instant Camera", "Instant Film Camera"],
	["PS2 Game Bundle", "Console Game Bundle"],
	["N64 Cartridge Bundle", "Retro Cartridge Bundle"],
	["GameCube Controller", "Retro Console Controller"],
	["Nintendo DS Lite", "Dual-Screen Handheld"],
	["Game Boy Advance", "Retro Handheld Console"],
	["Pokemon Card Binder", "Trading Card Binder"],
	["Pokemon Card Tin", "Trading Card Tin"],
	["Pokemon Deck Box", "Card Game Deck Box"],
	["Pokemon Plush Lot", "Monster Plush Lot"],
	["Pokemon Promo Poster", "Anime Promo Poster"],
	["\"Pokemon\"", "\"Trading Cards\""],
	["Pokemon|", "Trading Cards|"],
]

func migrate_legacy_names(parsed):
	var text = JSON.stringify(parsed)
	for pair in LEGACY_RENAMES:
		text = text.replace(pair[0], pair[1])
	var again = JSON.parse_string(text)
	return again if typeof(again) == TYPE_DICTIONARY else parsed

func apply_save_data(parsed):
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		return false
	parsed = migrate_legacy_names(parsed)
	var version = int(parsed.get("save_version", 1))
	init_new_run_state_only()
	# 64-bit RNG values are stored as strings; JSON numbers would lose precision.
	if parsed.has("run_seed"):
		run_seed = int(str(parsed["run_seed"]))
	else:
		run_seed = hash([str(parsed.get("save_time", "")), int(parsed.get("day", 1)), float(parsed.get("cash", 0))])
	if parsed.has("rng_state"):
		rng.seed = int(str(parsed.get("rng_seed", "0")))
		rng.state = int(str(parsed["rng_state"]))
	else:
		rng.seed = hash([run_seed, "live", int(parsed.get("day", 1))])
	cash = float(parsed.get("cash", cash))
	day = int(parsed.get("day", day))
	w2 = parsed.get("w2", {}) if typeof(parsed.get("w2", {})) == TYPE_DICTIONARY else {}
	signature_changed_day = int(parsed.get("signature_changed_day", -99))
	signature_nagged = parsed.get("signature_nagged", {}) if typeof(parsed.get("signature_nagged", {})) == TYPE_DICTIONARY else {}
	signatures = []
	for c in parsed.get("signatures", []):
		signatures.append(str(c))
	for e in w2.get("gaz_shop", []):
		e["item"] = normalize_item(e["item"])
	player_level = int(parsed.get("player_level", player_level))
	player_xp = int(parsed.get("player_xp", player_xp))
	next_item_uid = int(parsed.get("next_item_uid", 1))
	inventory = parsed.get("inventory", [])
	bag_level = int(parsed.get("bag_level", 0))
	storage_level = int(parsed.get("storage_level", 0))
	toolbox_level = int(parsed.get("toolbox_level", 0))
	eye_level = int(parsed.get("eye_level", 0))
	fee_level = int(parsed.get("fee_level", 0))
	achievements = parsed.get("achievements", {})
	discovered_log = parsed.get("discovered_log", {})
	family_stats = parsed.get("family_stats", {})
	sold_history = parsed.get("sold_history", [])
	total_haggled_savings = float(parsed.get("total_haggled_savings", 0.0))
	total_lifetime_profit = float(parsed.get("total_lifetime_profit", 0.0))
	lifetime_challenges_completed = int(parsed.get("lifetime_challenges_completed", 0))
	lifetime_fixer_wins = int(parsed.get("lifetime_fixer_wins", 0))
	skills_unlocked = parsed.get("skills_unlocked", {})
	tutorial_seen = to_bool(parsed.get("tutorial_seen", tutorial_seen))
	negative_days_streak = int(parsed.get("negative_days_streak", 0))
	last_save_time = str(parsed.get("save_time", ""))
	game_over = to_bool(parsed.get("game_over", false))
	seller_rating = float(parsed.get("seller_rating", 100.0))
	rng_log = parsed.get("rng_log", [])
	activity_log = parsed.get("activity_log", [])
	best_net_worth = float(parsed.get("best_net_worth", 0.0))
	goals_done = int(parsed.get("goals_done", 0))
	if version < 4 and goals_done > 0:
		# Goals were re-ordered in 0.12: carry progress over by goal, not position.
		var last_id = OLD_GOAL_IDS[clamp(goals_done - 1, 0, OLD_GOAL_IDS.size() - 1)]
		goals_done = max(0, goal_index(last_id) + 1)
	var ck = parsed.get("category_knowledge", null)
	category_knowledge = ck if typeof(ck) == TYPE_DICTIONARY else {}
	var migrated_notes = []
	if version < 3:
		migrated_notes = migrate_from_0_10(parsed)
	else:
		expertise = parsed.get("expertise", {})
		discoveries_log = parsed.get("discoveries_log", {})
		journal = parsed.get("journal", [])
		premises_level = int(parsed.get("premises_level", 0))
		vehicle_level = int(parsed.get("vehicle_level", 0))
		equipment = parsed.get("equipment", {})
		staff = parsed.get("staff", {})
		regulars = parsed.get("regulars", [])
		next_regular_id = int(parsed.get("next_regular_id", 1))
		rival = parsed.get("rival", {})
		clearance_leads = parsed.get("clearance_leads", [])
		next_lead_id = int(parsed.get("next_lead_id", 1))
		home_venue = str(parsed.get("home_venue", ""))
		week_plan = parsed.get("week_plan", [])
		fixed_count = int(parsed.get("fixed_count", 0))
		trade_buyer_day = int(parsed.get("trade_buyer_day", -1))
		var cl = parsed.get("clearance", null)
		clearance = cl if typeof(cl) == TYPE_DICTIONARY else null
		if clearance != null:
			for i in range(clearance["items"].size()):
				clearance["items"][i] = normalize_item(clearance["items"][i])
	for k in equipment.keys():
		equipment[k] = int(equipment[k])
	if regulars.size() == 0:
		init_regulars()
	if typeof(rival) != TYPE_DICTIONARY or not rival.has("name"):
		init_rival()
	if home_venue == "":
		home_venue = pick_line(WorldData.MARKET_DAYS.get("regular", {}).get("venues", ["The Top Field"]))
	for i in range(inventory.size()):
		inventory[i] = normalize_item(inventory[i])
	# Full mid-day state (save_version 2+). Older saves fall back to a fresh day.
	var restored_day = false
	if version >= 3 and typeof(parsed.get("stalls", null)) == TYPE_ARRAY and parsed["stalls"].size() > 0:
		energy = int(parsed.get("energy", 100))
		current_time_minutes = int(parsed.get("current_time_minutes", 7 * 60))
		daily_expenses = float(parsed.get("daily_expenses", daily_expenses))
		stalls = parsed["stalls"]
		for stall in stalls:
			stall["revealed"] = int(stall.get("revealed", 0))
			stall["packing_minute"] = int(stall.get("packing_minute", 12 * 60))
			stall["regular_id"] = int(stall.get("regular_id", -1))
			var stock = stall.get("stock", [])
			for j in range(stock.size()):
				stock[j] = normalize_item(stock[j])
			stall["stock"] = stock
		current_stall_index = clamp(int(parsed.get("current_stall_index", 0)), 0, stalls.size() - 1)
		# Saves from before 0.11.2 only kept a running total; tag today's buys instead.
		for it in inventory:
			if not it.has("carried_day") and int(it.get("bought_day", -1)) == day:
				it["carried_day"] = day
		fixer_uses_today = int(parsed.get("fixer_uses_today", 0))
		mystery_packages_left = int(parsed.get("mystery_packages_left", 0))
		daily_challenges = parsed.get("daily_challenges", [])
		daily_challenge_bonus_given = to_bool(parsed.get("daily_challenge_bonus_given", false))
		var offer = parsed.get("pending_special_offer", null)
		if typeof(offer) == TYPE_DICTIONARY and offer.has("item"):
			offer["item"] = normalize_item(offer["item"])
			pending_special_offer = offer
		else:
			pending_special_offer = null
		var ds = parsed.get("day_stats", null)
		if typeof(ds) == TYPE_DICTIONARY:
			reset_day_stats()
			for k in ds.keys():
				day_stats[k] = ds[k]
		var mt = parsed.get("market_today", null)
		if typeof(mt) == TYPE_DICTIONARY and mt.size() > 0:
			market_today = mt
		else:
			market_today = {"type": "regular", "weather": "overcast", "venue": home_venue, "entry_fee": 0.0, "clearance": false, "start_offset": 0}
		var rr = parsed.get("rival_route", [])
		rival_route = rr if typeof(rr) == TYPE_ARRAY else []
		var cu = parsed.get("collector_used_today", {})
		collector_used_today = cu if typeof(cu) == TYPE_DICTIONARY else {}
		var co = parsed.get("collector_offers", {})
		collector_offers = co if typeof(co) == TYPE_DICTIONARY else {}
		restored_day = true
	var trends = parsed.get("current_trends", null)
	if typeof(trends) == TYPE_DICTIONARY and trends.size() > 0:
		current_trends = trends
		trend_random = parsed.get("trend_random", trends.duplicate())
		trend_rumour = parsed.get("trend_rumour", {})
		trend_headlines = parsed.get("trend_headlines", [])
		var wn = parsed.get("week_news", {})
		week_news = wn if typeof(wn) == TYPE_DICTIONARY else {}
		current_week = int(parsed.get("current_week", current_week))
	else:
		generate_weekly_trends()
	if not restored_day:
		pending_special_offer = null
		reset_day_stats()
		generate_day_seeded()
	ensure_week_plan()
	if not parsed.has("signatures"):
		# 0.12 introduces signatures. Keep your two strongest categories at full strength.
		var strong = []
		for c in CATEGORIES:
			if raw_expertise_tier(c) >= 3:
				strong.append(c)
		strong.sort_custom(func(a, b): return expertise_xp(a) > expertise_xp(b))
		for i in range(min(signature_slots(), strong.size())):
			signatures.append(strong[i])
		migrated_notes.append("Expertise now has Signatures: only the categories you commit to go beyond Specialist. %s" % (("Your strongest, %s, %s been made your signature%s." % [" and ".join(signatures), "has" if signatures.size() == 1 else "have", "" if signatures.size() == 1 else "s"]) if signatures.size() > 0 else "Choose yours from the Expertise screen when you're ready."))
		if strong.size() > signatures.size():
			migrated_notes.append("%s %s now capped at Specialist. You keep the knowledge; make one a signature any time a slot frees up." % [", ".join(strong.slice(signatures.size())), "is" if strong.size() - signatures.size() == 1 else "are"])
	for c in CATEGORIES:
		if not is_signature(c) and expertise_xp(c) > NON_SIGNATURE_XP_CAP:
			expertise[c] = NON_SIGNATURE_XP_CAP
	for n in migrated_notes:
		pending_notices.append(n)
	if version < 3:
		var popups_ui = ui
		ui = null
		check_goals()
		ui = popups_ui
	return true

func item_template():
	return {
		"name": "Unknown Item", "category": "Home", "condition": 5, "condition_checked": false,
		"quick_look_done": false, "quick_look_note": "", "quick_look_accuracy": 0.0, "quick_look_roll": 0.0,
		"size": "small", "testable": false, "seller": "Regular Seller", "true_value": 10.0, "asking": 10.0,
		"paid": 0.0, "authentic": true, "auth_status": "Unauthenticated", "auth_attempted": false,
		"fake_chance": 0.0, "fault": false, "fault_chance": 0.0, "fault_roll": 1.0, "fault_severity": "None",
		"tested": false, "test_note": "", "basic_researched": false, "basic_comps": "", "deep_researched": false,
		"research_note": "", "rare_variant_hit": false, "rare_variant_roll_pct": 0.0, "rare_variant_tier": "",
		"rare_variant_mult": 1.0, "hidden_special": "", "special_discovered": false, "special_genuine": true,
		"rarity": "Common", "one_in": 1, "identified_mult": 1.0, "listing": 0.0, "listed": false,
		"auctioned": false, "auction_days_left": 0, "auction_current_bid": 0.0, "auction_final_price": 0.0,
		"auction_tier": "", "repair_attempted": false, "haggle_attempted": false, "seller_refuses": false,
		"haggle_result": "", "haggle_savings": 0.0, "extra_spend": 0.0, "condition_price_note": "",
		"auth_note": "", "haggle_note": "", "repair_note": "", "buy_block_note": "", "listing_block_note": "",
		"action_order": [], "highlight_action": "", "highlight_color": "yellow", "basic_comps_max": 0.0,
		"locked_gamble_hint": 0.10, "dismissed": false, "est_noise": 0.0, "instant_roll_day": -1,
		"days_owned": 0, "listed_day": -1, "source": "stall", "perceived_condition": 6,
		"special_premium": 1.0, "channel": "", "traits": [], "blurb": "", "expert_checked": false,
		"uv_checked": false, "cleaned": false, "sorted": false, "on_shop_floor": false, "shop_price": 0.0,
		"expert_note": "", "hunch": "", "counter_offer": 0.0, "saved_for_player": false, "uid": 0,
	}

func normalize_item(item):
	if typeof(item) != TYPE_DICTIONARY:
		item = {}
	var tpl = item_template()
	for k in tpl.keys():
		if not item.has(k):
			item[k] = tpl[k]
	# JSON round-trips ints as floats; keep the fields used as ints tidy.
	for k in ["condition", "one_in", "auction_days_left", "instant_roll_day", "days_owned", "listed_day", "uid", "perceived_condition"]:
		item[k] = int(item[k])
	for k in ["listed", "auctioned", "tested", "testable", "fault", "authentic", "condition_checked", "quick_look_done", "basic_researched", "deep_researched", "haggle_attempted", "seller_refuses", "dismissed", "repair_attempted", "auth_attempted", "special_discovered", "special_genuine", "expert_checked", "uv_checked", "cleaned", "sorted", "on_shop_floor", "saved_for_player"]:
		item[k] = to_bool(item[k])
	if not item.has("est_noise_set"):
		item["est_noise"] = rng.randfn(0.0, 1.0)
		item["est_noise_set"] = true
	if int(item["uid"]) <= 0:
		item["uid"] = next_item_uid
		next_item_uid += 1
	if str(item["blurb"]) == "" and content != null:
		var fam = content.family(str(item["name"]))
		if fam != null:
			item["blurb"] = str(fam.get("blurb", ""))
	if typeof(item["traits"]) != TYPE_ARRAY:
		item["traits"] = []
	for t in item["traits"]:
		t["known"] = to_bool(t.get("known", false))
		t["clue"] = to_bool(t.get("clue", false))
		t["fixed"] = to_bool(t.get("fixed", false))
		t["mult"] = float(t.get("mult", 1.0))
	return item

func load_game():
	if sim_mode:
		return false
	if not FileAccess.file_exists(save_path):
		return false
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return false
	var text = file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	return apply_save_data(parsed)

func export_save_code():
	var data = get_save_data()
	var json_text = JSON.stringify(data)
	var raw_bytes = json_text.to_utf8_buffer()
	var compressed_bytes = raw_bytes.compress(FileAccess.COMPRESSION_GZIP)
	return Marshalls.raw_to_base64(compressed_bytes)

func import_save_code(code):
	var cleaned = code.strip_edges()
	if cleaned == "":
		return false
	var compressed_bytes = Marshalls.base64_to_raw(cleaned)
	if compressed_bytes.size() == 0:
		return false
	var raw_bytes = compressed_bytes.decompress_dynamic(5000000, FileAccess.COMPRESSION_GZIP)
	if raw_bytes.size() == 0:
		return false
	var json_text = raw_bytes.get_string_from_utf8()
	if json_text == "":
		return false
	var parsed = JSON.parse_string(json_text)
	var applied = apply_save_data(parsed)
	if applied:
		save_game()
	return applied

func generate_daily_challenges():
	var templates = [
		{"desc_fmt": "Buy %d items today", "type": "items_bought", "min": 2, "max": 5},
		{"desc_fmt": "Sell %d items today", "type": "items_sold", "min": 2, "max": 4},
		{"desc_fmt": "Earn £%d in sales revenue today", "type": "sales_revenue", "min": 50, "max": 200},
		{"desc_fmt": "Check Condition on %d items today", "type": "condition_checks", "min": 2, "max": 4},
		{"desc_fmt": "Research %d items today", "type": "researches_done", "min": 2, "max": 4},
		{"desc_fmt": "Deep Research %d items today", "type": "deep_researches_done", "min": 1, "max": 2},
		{"desc_fmt": "Authenticate %d items today", "type": "authentications_done", "min": 1, "max": 2},
		{"desc_fmt": "Repair %d items today", "type": "repairs_done", "min": 1, "max": 2},
		{"desc_fmt": "Make %d profitable sales today", "type": "profitable_sales", "min": 1, "max": 3},
		{"desc_fmt": "Successfully haggle %d times today", "type": "successful_haggles", "min": 1, "max": 3},
		{"desc_fmt": "Find something at least 1-in-%d rare today", "type": "rarest_one_in", "min": 20, "max": 80},
	]
	templates.shuffle()
	var count = rng.randi_range(3, 5)
	daily_challenges.clear()
	var added = 0
	for t in templates:
		if added >= count:
			break
		if t["type"] == "repairs_done" and toolbox_level <= 0:
			continue
		var target = rng.randi_range(t["min"], t["max"])
		daily_challenges.append({"desc": t["desc_fmt"] % target, "type": t["type"], "target": target, "reward_cash": 8, "reward_xp": 8, "reward_given": false})
		added += 1
	daily_challenge_bonus_given = false

func check_daily_challenge(challenge):
	return float(day_stats.get(challenge["type"], 0)) >= float(challenge["target"])

func daily_challenges_completed_count():
	var count = 0
	for c in daily_challenges:
		if check_daily_challenge(c):
			count += 1
	return count

func check_daily_challenge_rewards():
	var done = []
	var total = 0.0
	for c in daily_challenges:
		if not c["reward_given"] and check_daily_challenge(c):
			c["reward_given"] = true
			cash += float(c["reward_cash"])
			total += float(c["reward_cash"])
			day_stats["other_income"] = float(day_stats.get("other_income", 0.0)) + float(c["reward_cash"])
			add_xp(int(c["reward_xp"]))
			lifetime_challenges_completed += 1
			done.append(c["desc"])
	if done.size() == 1:
		add_toast("Challenge done: %s (+£%d)" % [done[0], int(total)], "success")
	elif done.size() > 1:
		add_toast("%d challenges done (+£%d)" % [done.size(), int(total)], "success")

func check_milestone_achievements():
	if player_level >= 10:
		unlock_achievement("Level Headed")
	if lifetime_challenges_completed >= 30:
		unlock_achievement("Challenge Crusher")
	if lifetime_fixer_wins >= 5:
		unlock_achievement("High Roller")

func check_daily_challenge_bonus():
	if daily_challenge_bonus_given or daily_challenges.size() == 0:
		return
	if daily_challenges_completed_count() >= daily_challenges.size():
		daily_challenge_bonus_given = true
		cash += 40.0
		day_stats["other_income"] = float(day_stats.get("other_income", 0.0)) + 40.0
		add_xp(30)
		queue_popup("ALL DAILY CHALLENGES COMPLETE! +£40 and +30 XP!", "success")

func condition_cost():
	return 5.0

func research_cost():
	return 0.0 if has_equip("library") else 1.0

func xp_needed_for_level(level):
	return int(80 + (level - 1) * 40)

func add_xp(amount):
	player_xp += int(amount)
	while player_xp >= xp_needed_for_level(player_level):
		player_xp -= xp_needed_for_level(player_level)
		player_level += 1
		var unlock_text = ""
		for tier in level_unlock_tiers:
			if int(tier["level"]) == player_level:
				unlock_text = "\n\nUnlocked: " + tier["desc"]
		add_journal("Reached level %d." % player_level, "level")
		show_big_popup("LEVEL %d" % player_level, "+1 Perk point. Spend it on the Perks page.%s" % unlock_text, "level")
		check_milestone_achievements()

var level_unlock_tiers = [
	{"level": 3, "desc": "+1 Mystery Package available each day"},
		{"level": 5, "desc": "The Fixer's Gamble unlocks a bigger £350 stake"},
	{"level": 6, "desc": "Online auctions"},
	{"level": 8, "desc": "Dig Deeper reveals 1 extra item each time"},
	{"level": 15, "desc": "The Fixer's Gamble can be used twice a day"},
]


func format_time():
	var h = int(current_time_minutes / 60)
	var m = current_time_minutes % 60
	return "%02d:%02d" % [h, m]

func minute_to_clock(minute):
	var h = int(minute / 60)
	var m = minute % 60
	return "%02d:%02d" % [h, m]

func reset_day_stats():
	day_stats = {
		"start_cash": cash, "start_worth": business_value(),
		"buy_spend": 0.0, "sales_revenue": 0.0, "fees": 0.0, "postage": 0.0, "research": 0.0,
		"authentication": 0.0, "repairs": 0.0, "expenses": 0.0, "rent": 0.0, "upkeep": 0.0,
		"interest": 0.0, "refunds": 0.0, "other_income": 0.0, "business_spend": 0.0,
		"items_bought": 0, "items_sold": 0, "items_scrapped": 0, "returns": 0, "collection_adds": 0,
		"rarest_one_in": 1, "condition_checks": 0, "researches_done": 0, "deep_researches_done": 0,
		"authentications_done": 0, "repairs_done": 0, "profitable_sales": 0, "successful_haggles": 0,
		"discoveries": 0, "rng_events": [], "sale_profit": 0.0
	}

var trend_random = {}
var trend_rumour = {}
var week_news = {}

func season_factor(category, season):
	var f = 1.0
	if season == "Winter" and category == "Clothing":
		f *= 1.10
	if season == "Winter" and (category == "Games" or category == "Trading Cards"):
		f *= 1.06
	if season == "Summer" and (category == "Garden & Outdoor" or category == "Cameras"):
		f *= 1.08
	if season == "Summer" and category == "Clothing":
		f *= 0.95
	if season == "Spring" and (category == "Garden & Outdoor" or category == "Tools"):
		f *= 1.06
	if season == "Autumn" and (category == "Books" or category == "Vinyl"):
		f *= 1.05
	return f

func generate_weekly_trends():
	current_week = int((day - 1) / 7) + 1
	trend_headlines.clear()
	var categories = CATEGORIES.duplicate()
	var season = get_season_name()
	for category in categories:
		var prev = float(trend_random.get(category, 1.0))
		# Momentum with mean reversion: this week partly echoes last week.
		trend_random[category] = clamp(lerp(1.0, prev, 0.55) * rng.randf_range(0.93, 1.07), 0.72, 1.32)
	# Last week's rumour comes good (or doesn't).
	if trend_rumour.has("cat") and categories.has(trend_rumour["cat"]):
		var rc = trend_rumour["cat"]
		var came_true = to_bool(trend_rumour.get("true", false))
		if came_true:
			if trend_rumour["dir"] == "up":
				trend_random[rc] = clamp(float(trend_random[rc]) * rng.randf_range(1.12, 1.22), 0.72, 1.35)
			else:
				trend_random[rc] = clamp(float(trend_random[rc]) * rng.randf_range(0.80, 0.90), 0.70, 1.32)
		record_rng("Rumour check: %s %s — %s" % [rc, "up" if trend_rumour["dir"] == "up" else "down", "CAME TRUE" if came_true else "was nonsense"], false)
	# This week's news moves one category.
	var news = WorldData.NEWS[rng.randi_range(0, WorldData.NEWS.size() - 1)]
	if categories.has(news["cat"]):
		var up = str(news["dir"]) == "up"
		trend_random[news["cat"]] = clamp(float(trend_random[news["cat"]]) * (rng.randf_range(1.10, 1.20) if up else rng.randf_range(0.84, 0.92)), 0.70, 1.35)
		week_news = {"text": news["text"], "cat": news["cat"], "dir": news["dir"]}
	trade.weekly_bubble()
	for category in categories:
		current_trends[category] = clamp(float(trend_random[category]) * season_factor(category, season) * trade.bubble_mult(category), 0.55, 2.0)
	var sorted = categories.duplicate()
	sorted.sort_custom(func(a, b): return float(current_trends[a]) > float(current_trends[b]))
	trend_headlines.append("%s is attracting the most buyers this week." % sorted[0])
	trend_headlines.append("%s demand looks softest right now." % sorted[sorted.size() - 1])
	var rumour_cat = categories[rng.randi_range(0, categories.size() - 1)]
	var rumour_dir = "up" if rng.randf() < 0.55 else "down"
	trend_rumour = {"cat": rumour_cat, "dir": rumour_dir, "true": rng.randf() < 0.70, "src": pick_line(WorldData.RUMOUR_SOURCES)}
	trend_headlines.append("Word from %s: %s prices could %s next week. (Rumours are right about 70%% of the time.)" % [trend_rumour["src"], rumour_cat, "jump" if rumour_dir == "up" else "slump"])

func get_season_name():
	var week_of_year = ((current_week - 1) % 52) + 1
	if week_of_year <= 8 or week_of_year >= 48:
		return "Winter"
	if week_of_year <= 21:
		return "Spring"
	if week_of_year <= 34:
		return "Summer"
	return "Autumn"

func generate_day():
	stalls.clear()
	carry_used = 0
	fixer_uses_today = 0
	collector_offers = {}
	rival_route = []
	selected_stall_uid = -1
	generate_daily_challenges()
	ensure_week_plan()
	var plan = plan_for(day)
	var mtype = str(plan["type"])
	var weather = str(plan["weather"])
	var mfx = MARKET_FX.get(mtype, MARKET_FX["regular"])
	var wfx = WEATHER_FX.get(weather, WEATHER_FX["overcast"])
	var md = WorldData.MARKET_DAYS.get(mtype, {})
	var venue = home_venue if mtype == "regular" else str(md.get("venue", ""))
	var start_offset = int(wfx["start"]) - int(mfx["early"]) - (30 if has_perk("early_bird") else 0)
	market_today = {"type": mtype, "weather": weather, "venue": venue, "entry_fee": float(mfx["fee"]),
		"intro": pick_line(md.get("intro", [])), "weather_line": pick_line(WorldData.WEATHER.get(weather, {}).get("lines", [])),
		"clearance": false, "start_offset": start_offset}
	current_time_minutes = 7 * 60 + start_offset
	energy = max_energy() + int(wfx["energy"])
	mystery_packages_left = rng.randi_range(0, 2) + (1 if player_level >= 3 else 0)
	if mtype == "collectors_fair" or mtype == "village_fete":
		mystery_packages_left = 0
	daily_expenses = pitch_fee()
	var count = clamp(rng.randi_range(int(mfx["stalls"][0]), int(mfx["stalls"][1])) + int(wfx["stalls"]), 3, 16)
	var archetypes = mfx["archetypes"] if mfx["archetypes"].size() > 0 else seller_profiles.keys()
	var used_regulars = {}
	var used_first = {}
	for i in range(count):
		var arch = archetypes[rng.randi_range(0, archetypes.size() - 1)]
		if weather == "downpour" and rng.randf() < 0.35:
			arch = "Desperate Seller"
		var reg = null
		if rng.randf() < 0.68:
			var pool = []
			var total = 0.0
			for r in regulars:
				if used_regulars.has(r["id"]) or used_first.has(r["first"]):
					continue
				if not archetypes.has(r["archetype"]):
					continue
				if int(r.get("banned_until", -1)) >= day:
					continue
				var w = 1.0 + max(0.0, float(r["rel"])) / 40.0
				pool.append([r, w])
				total += w
			if pool.size() > 0:
				var roll = rng.randf() * total
				for pr in pool:
					roll -= pr[1]
					if roll <= 0.0:
						reg = pr[0]
						break
				if reg == null:
					reg = pool[pool.size() - 1][0]
		if reg == null:
			reg = make_regular(arch)
			var gpool = WorldData.FIRST_NAMES
			var gg = str(WorldData.PERSONALITY_GENDER.get(str(reg["personality"]), ""))
			if gg == "f":
				gpool = WorldData.FEMALE_NAMES
			elif gg == "m":
				gpool = WorldData.MALE_NAMES
			while used_first.has(reg["first"]):
				reg["first"] = pick_line(gpool)
				reg["name"] = reg["first"] + " " + pick_line(WorldData.SURNAMES)
			reg["id"] = -1
		used_regulars[reg["id"]] = true
		used_first[reg["first"]] = true
		stalls.append(build_stall(reg, mfx, wfx))
	plan_rival_route()
	world.st()
	world.roll_market_event()
	world.expire_commissions()
	world.roll_commission()
	trade.ensure_catalogue()
	lines_used_today = {}
	current_stall_index = 0

var home_venue = ""

func build_stall(reg, mfx, wfx):
	var seller = reg["archetype"]
	var profile = seller_profiles[seller]
	var pers = WorldData.PERSONALITIES.get(reg["personality"], {})
	var stall = {
		"seller": seller,
		"seller_display_name": reg["first"],
		"seller_full_name": reg["name"],
		"regular_id": int(reg["id"]),
		"personality": reg["personality"],
		"dressing": int(reg.get("dressing", 0)),
		"stock": [],
		"revealed": 0,
		"packing_minute": rng.randi_range(10 * 60 + 45, 12 * 60),
		"crowd": clamp(rng.randf_range(0.10, 0.45) + float(wfx["crowd"]), 0.02, 0.8),
		"banned_today": false,
		"visited": false,
		"rival_eta": -1,
		"rival_visited": false,
		"tipoff": false,
	}
	var rate = 0.9 if (has_perk("regulars_rate") and float(reg.get("rel", 0.0)) >= 35.0) else 1.0
	var ctx = {"cats": reg.get("cats", []), "rarity_boost": float(mfx["rarity"]),
		"price_mult": float(pers.get("price_mod", 1.0)) * float(wfx["price"]) * rate,
		"knowledge_mod": float(pers.get("knowledge_mod", 0.0))}
	var stock_count = rng.randi_range(max(6, int(profile["depth"] * 0.65)), profile["depth"])
	var seen_names = {}
	for j in range(stock_count):
		var it = generate_item(seller, ctx)
		var tries = 0
		while seen_names.has(it["name"]) and tries < 4:
			it = generate_item(seller, ctx)
			tries += 1
		seen_names[it["name"]] = true
		stall["stock"].append(it)
	# Friends keep something back for you, in the thing you know best.
	if int(reg["id"]) >= 0 and float(reg["rel"]) >= 65.0 and rng.randf() < 0.5:
		var best_cat = top_expertise_category()
		var fams = content.families_by_cat.get(best_cat, [])
		if fams.size() > 0:
			var fam = fams[rng.randi_range(0, fams.size() - 1)]
			var it = make_item_from_family(fam, seller, {"trait_bias": 0.18, "rarity_boost": 1.5})
			it["asking"] = max(1.0, round(true_market_value(it) * rng.randf_range(0.55, 0.8)))
			it["saved_for_player"] = true
			stall["stock"].insert(0, it)
	if int(reg["id"]) >= 0 and float(reg["rel"]) >= 35.0 and can_do_clearances() and clearance_leads.size() < 3 and rng.randf() < 0.14:
		stall["tipoff"] = true
	stall["revealed"] = min(rng.randi_range(5, 7) + (2 if staff.has("picker") else 0), stall["stock"].size())
	gamble.maybe_add_box(stall)
	return stall

func top_expertise_category():
	var best = CATEGORIES[rng.randi_range(0, CATEGORIES.size() - 1)]
	var bx = -1.0
	for c in CATEGORIES:
		if expertise_xp(c) > bx:
			bx = expertise_xp(c)
			best = c
	return best

func on_stall_visit(stall):
	# First visit of the day: greeting, relationship memory, tip-offs.
	if stall.get("visited", false):
		return
	stall["visited"] = true
	var r = regular_by_id(int(stall.get("regular_id", -1))) if int(stall.get("regular_id", -1)) >= 0 else null
	if r != null:
		r["visits"] = int(r["visits"]) + 1
		r["last_seen"] = day
		if float(r["rel"]) < 20.0:
			r["rel"] = float(r["rel"]) + 1.5   # turning up counts for something
	stall["greeting"] = stall_greeting(stall)
	if stall.get("tipoff", false) and r != null:
		var lead = add_clearance_lead("tip", r["first"])
		var place = WorldData.CLEARANCE_STORIES[int(lead["story"])]["title"]
		stall["tipoff_line"] = stall_line(stall, "tipoff", {"place": place})
	if stall_has_saved_item(stall):
		var it = stall["stock"][0]
		stall["saved_line"] = stall_line(stall, "saved_item", {"item": it["name"]})

func stall_has_saved_item(stall):
	return stall["stock"].size() > 0 and stall["stock"][0].get("saved_for_player", false)

func generate_item(seller, ctx = {}):
	var profile = seller_profiles[seller]
	var season = get_season_name()
	var pref = ctx.get("cats", [])
	var cats = profile["categories"]
	if pref.size() > 0 and rng.randf() < 0.55:
		cats = pref
	var candidates = []
	for family in item_families:
		if cats.has(family["category"]):
			var fs = str(family.get("season", ""))
			if fs != "" and fs != season:
				continue
			candidates.append(family)
	if candidates.size() == 0:
		for family in item_families:
			var fs = str(family.get("season", ""))
			if fs == "" or fs == season:
				candidates.append(family)
	var base = candidates[rng.randi_range(0, candidates.size() - 1)]
	return make_item_from_family(base, seller, ctx)

func roll_rarity(boost):
	var weights = []
	var total = 0.0
	for i in range(rarity_table.size()):
		var w = float(rarity_table[i]["chance"])
		if i > 0:
			w *= boost
		weights.append(w)
		total += w
	var roll = rng.randf() * total
	for i in range(rarity_table.size()):
		roll -= weights[i]
		if roll <= 0.0:
			return rarity_table[i]
	return rarity_table[0]

func rarity_mult_for(tier):
	match tier:
		"Uncommon":
			return rng.randf_range(1.15, 1.45)
		"Rare":
			return rng.randf_range(1.5, 2.2)
		"Very Rare":
			return rng.randf_range(2.4, 4.0)
		"Grail":
			return rng.randf_range(5.0, 12.0)
	return 1.0

func roll_fault_severity():
	var r = rng.randf()
	if r < 0.45:
		return "Minor"
	if r < 0.75:
		return "Moderate"
	if r < 0.93:
		return "Major"
	return "Dead"

func make_item_from_family(base, seller, ctx = {}):
	var profile = seller_profiles.get(seller, seller_profiles["Regular Seller"])
	var rarity = roll_rarity(float(profile.get("rarity_boost", 1.0)) * float(ctx.get("rarity_boost", 1.0)))
	var rmult = rarity_mult_for(rarity["tier"])
	var condition = rng.randi_range(3, 10)
	var base_value = rng.randf_range(float(base["value"][0]), float(base["value"][1])) * rmult
	var fake_chance = clamp(float(base["fake"]) * float(profile["fake"]), 0.0, 0.60)
	var fault_chance = get_fault_chance(base["name"], base["category"], condition, float(profile["fault"]))
	var fault_roll = rng.randf()
	var fault = fault_roll < fault_chance
	var item = normalize_item({
		"name": base["name"], "category": base["category"], "condition": condition,
		"size": base["size"], "testable": base["testable"], "seller": seller,
		"true_value": base_value, "authentic": rng.randf() > fake_chance, "fake_chance": fake_chance,
		"fault": fault, "fault_chance": fault_chance, "fault_roll": fault_roll,
		"fault_severity": roll_fault_severity() if fault else "None",
		"rarity": rarity["tier"], "one_in": rarity["one_in"], "blurb": str(base.get("blurb", "")),
		"traits": [],
	})
	roll_item_traits(item, base, profile, rarity["tier"], ctx)
	cap_condition_for_damage(item)
	item["ident"] = make_ident(str(base["name"]))
	item["story"] = pick_line(Ident.SELLER_STORIES.get(str(base["category"]), []))
	var knowledge = clamp(float(profile["knowledge"]) + float(ctx.get("knowledge_mod", 0.0)), 0.05, 0.98)
	var seller_value = base_value * seller_known_trait_mult(item, knowledge)
	var random_ask = rng.randf_range(float(base["ask"][0]), float(base["ask"][1]))
	var marketish = seller_value * float(profile["pricing"]) * rng.randf_range(0.55, 1.35)
	var asking = lerp(random_ask, marketish, knowledge) * float(ctx.get("price_mult", 1.0))
	item["asking"] = max(1.0, round(asking))
	return item

func cap_condition_for_damage(item):
	# Physical damage and a 10/10 condition can't both be true.
	var cap = 10
	for t in item.get("traits", []):
		var d = trait_def(t)
		if d == null or str(d.get("kind", "")) not in ["bad", "fixable"] or d.has("group"):
			continue
		if str(d.get("reveal", "")) in ["condition", "look", "clean"] or str(d.get("kind", "")) == "fixable":
			cap = min(cap, 7 if float(t["mult"]) >= 0.72 else 5)
	if int(item["condition"]) > cap:
		item["condition"] = rng.randi_range(max(3, cap - 2), cap)

func get_fault_chance(name, category, condition, seller_mult):
	var base = 0.15
	if name == "Dual-Screen Handheld":
		base = 0.24
	elif name == "Retro Handheld Console":
		base = 0.18
	elif name == "Digital Compact Camera":
		base = 0.28
	elif name == "35mm Film Camera":
		base = 0.21
	elif name == "Vintage SLR Camera":
		base = 0.20
	elif name == "35mm Lens":
		base = 0.16
	elif name == "Mini Hi-Fi":
		base = 0.33
	elif name == "Portable CD Player":
		base = 0.30
	elif name == "Cordless Drill":
		base = 0.22
	elif name == "Vintage Wristwatch" or name == "Pocket Watch":
		base = 0.20
	elif name == "Old Mobile Phone" or name == "Tablet (unknown model)":
		base = 0.34
	elif name == "Personal Cassette Player":
		base = 0.38
	elif name == "Lawnmower" or name == "Stand Mixer":
		base = 0.24
	elif category == "Games":
		base = 0.17
	elif category == "Electronics":
		base = 0.28
	var condition_mod = float(7 - condition) * 0.018
	return clamp((base + condition_mod) * seller_mult, 0.02, 0.70)

func size_units(item):
	if item["size"] == "large":
		return 4
	if item["size"] == "medium":
		return 2
	return 1

func inventory_space_used():
	var used = 0
	for item in inventory:
		if item.get("vaulted", false):
			continue   # the vault has its own room
		used += size_units(item)
	return used

var seller_blurbs = {
	"Desperate Seller": "Needs cash today. Prices low-ish and gives in to haggling easily. Stock is hit and miss.",
	"House Clearance": "Clearing a whole house — has no idea what most of it is worth. Lots of stock, more faults.",
	"Clueless Seller": "Prices almost at random. Real bargains hide next to overpriced junk — research pays here.",
	"Regular Seller": "Knows roughly what things are worth. Fair prices, the odd bargain.",
	"Collector": "Knows their stuff and prices accordingly, but stocks rarer pieces. Hard to haggle.",
	"Dodgy Seller": "Cheap, but fakes and faults are common. Authenticate anything that matters.",
	"Dealer": "Prices close to market and barely haggles — but the best odds of something genuinely rare.",
}

func rarity_color(tier):
	match tier:
		"Uncommon":
			return Color(0.45,0.85,0.95,1.0)
		"Rare":
			return Color(0.45,0.55,1.0,1.0)
		"Very Rare":
			return Color(0.80,0.50,1.0,1.0)
		"Grail":
			return Color(1.0,0.84,0.35,1.0)
	return Color(0.75,0.78,0.82,1.0)

func first_day_hint_needed():
	return day <= 2 and inventory.size() == 0 and sold_history.size() == 0

func fake_risk_label(p):
	if p >= 0.30:
		return "Very High"
	if p >= 0.18:
		return "High"
	if p >= 0.10:
		return "Moderate"
	if p >= 0.05:
		return "Low"
	return "Very Low"

func size_text(item):
	var u = size_units(item)
	return "%s (%d bag space)" % [str(item["size"]).capitalize(), u]

func quick_look(index):
	if not valid_stall_index(index):
		return
	var item = stalls[current_stall_index]["stock"][index]
	if item["quick_look_done"]:
		return
	if energy < 1:
		queue_popup("Not enough energy. It refills tomorrow morning.")
		return
	energy -= 1
	spend_time(1)
	item["quick_look_done"] = true
	var accuracy = inspect_accuracy(item)
	var roll = rng.randf()
	var accurate = roll < accuracy
	var perceived_condition = int(item["condition"])
	if not accurate:
		var error = rng.randi_range(2, 4)
		if rng.randf() < 0.5:
			error = -error
		perceived_condition = clamp(perceived_condition + error, 1, 10)
	item["quick_look_accuracy"] = accuracy
	item["quick_look_roll"] = roll
	item["perceived_condition"] = perceived_condition
	item["quick_look_note"] = inspect_clue_text(perceived_condition)
	var found = reveal_traits(item, "look")
	if has_perk("hunch"):
		var hidden = 0
		for t in item.get("traits", []):
			if not t.get("known", false):
				hidden += 1
		item["hunch"] = "Your gut says there's more to this one." if hidden > 0 else "Your gut says what you see is what you get."
	play_sfx("reveal")
	show_stall()

func check_condition(index):
	do_check_condition("stall", index)

func prebuy_research(index):
	do_research("stall", index)

func comps_median_value(item):
	var v = comps_now(item)
	if v.size() == 0:
		return 0.0
	var s = v.duplicate()
	s.sort()
	return float(s[s.size() / 2])

func comps_after_fees_text(item):
	var med = comps_median_value(item)
	if med <= 0.0:
		return ""
	var costs = selling_costs(item, med)
	var net = med - float(costs["fee"]) - float(costs["postage"]) - float(costs["insurance"]) - float(costs["packaging"])
	var margin = net - float(item["asking"])
	var col = "#8cd98f" if margin >= float(item["asking"]) * 0.3 and margin >= 5.0 else ("#e0c96e" if margin > 0.0 else "#e88c7a")
	return "Middle sale £%.0f -> after fees & postage ~£%.0f  ->  [color=%s]%s£%.0f vs the £%.0f asking[/color]" % [med, net, col, "+" if margin >= 0.0 else "-", abs(margin), float(item["asking"])]

func reveal_inspect_roll(item):
	if item["quick_look_done"] and not item.get("inspect_roll_revealed", false):
		item["inspect_roll_revealed"] = true
		var acc = float(item["quick_look_accuracy"])
		var roll = float(item["quick_look_roll"])
		record_rng("Earlier Inspect: reliability %.0f%% | Rolled %.2f%% | Result: %s" % [acc * 100.0, roll * 100.0, "ACCURATE" if roll < acc else "MISLEADING"])

func condition_reveal_note(item):
	reveal_inspect_roll(item)
	var c = int(item["condition"])
	var f = condition_factor(c)
	var words = "average"
	if c >= 9:
		words = "excellent"
	elif c >= 7:
		words = "good"
	elif c <= 4:
		words = "poor"
	var note = "Condition [b]%d/10[/b] (%s) — examples like this typically sell for [color=%s]%+d%%[/color] vs an average one." % [c, words, "#8cd98f" if f >= 1.0 else "#e88c7a", int(round((f - 1.0) * 100.0))]
	if item["quick_look_done"]:
		var pc = int(item.get("perceived_condition", c))
		var agreed = abs(pc - c) <= 1
		note += "\nYour Inspect read was %s." % ("[color=#8cd98f]about right[/color]" if agreed else "[color=#e88c7a]off[/color]")
	return note

func all_trait_mult(item):
	var m = 1.0
	for t in item.get("traits", []):
		m *= float(t["mult"])
	return m

func known_basis(item):
	# How THIS example compares with a typical one, as far as you know:
	# condition, identified traits, known faults, test and authentication results.
	var b = float(item.get("identified_mult", 1.0)) * float(item.get("documented", 1.0)) * float(item.get("vault_mult", 1.0))
	if item["condition_checked"]:
		b *= condition_factor(int(item["condition"]))
	elif item["quick_look_done"]:
		b *= condition_factor(int(item.get("perceived_condition", 6)))
	for t in item.get("traits", []):
		if t.get("known", false):
			b *= float(t["mult"])
	if item["fault"] and fault_is_known(item):
		b *= fault_multiplier(item["fault_severity"])
	if item["testable"] and item["tested"] and not item["fault"]:
		b *= 1.12
	if item["auth_status"] == "Confirmed Genuine" and float(item["fake_chance"]) >= 0.05:
		b *= 1.08
	elif item["auth_status"] == "Suspected Counterfeit":
		b *= 0.3
	if item["hidden_special"] != "" and item["special_discovered"]:
		b *= max(1.0, float(item.get("special_premium", 1.0)))
	return max(0.01, b)

func typical_value(item):
	# The hidden value of a typical example of this item (no traits, average condition).
	var v = float(item["true_value"]) * float(current_trends.get(item["category"], 1.0)) / max(0.01, all_trait_mult(item))
	if item["hidden_special"] != "":
		v /= max(1.0, float(item.get("special_premium", 1.0)))
	return v

func make_comps(item, deep):
	# Recent sold prices for examples like the one you *think* you have. They follow what you know:
	# check the condition or find a flaw later and the comps you're shown move with it.
	var values = []
	var count = 6 if deep else 5
	var basis = known_basis(item)
	var comp_base = typical_value(item) * basis
	for i in range(count):
		var spread = rng.randf_range(0.70, 1.30) if deep else rng.randf_range(0.45, 1.60)
		values.append(max(1, int(comp_base * spread)))
	values.sort()
	item["comps_values"] = values
	item["comps_basis"] = basis
	item["basic_comps_max"] = float(values[-1])
	return comps_text(item)

func comps_now(item):
	# Comps rescaled to what you know right now.
	var v = item.get("comps_values", [])
	if v.size() == 0:
		return []
	var basis_then = float(item.get("comps_basis", 0.0))
	if basis_then <= 0.0:
		return v
	var f = known_basis(item) / basis_then
	var out = []
	for x in v:
		out.append(max(1, int(round(float(x) * f))))
	return out

func comps_text(item):
	var text = ""
	var values = comps_now(item)
	for i in range(values.size()):
		if i > 0:
			text += ", "
		text += "£" + str(values[i])
	return text

# --- Negotiation -----------------------------------------------------------------
# Every seller has a hidden lowest price for each item (their "floor") and a limited
# patience. Offer at or above the floor and they take it. Below it, they counter and
# lose a little patience; when patience runs out they name a final price. Very low
# offers offend. Flaws you've found are arguments: point one out and, if the seller
# hadn't priced it in, the floor drops.
const HAGGLE_FLEX = {"Desperate Seller": 0.25, "House Clearance": 0.21, "Clueless Seller": 0.18, "Regular Seller": 0.12, "Collector": 0.07, "Dodgy Seller": 0.17, "Dealer": 0.06}
const HAGGLE_PATIENCE = {"Desperate Seller": 3, "House Clearance": 3, "Clueless Seller": 3, "Regular Seller": 2, "Collector": 2, "Dodgy Seller": 3, "Dealer": 2}
const HAGGLE_SPREAD = 0.07
const INSULT_FRACTION = 0.62   # an offer under this share of the (expected) floor is an insult
# Sharp sellers notice you pricing something up in front of them and add a bit on.
const NOTICE_CHANCE = {"Dealer": 0.45, "Collector": 0.40, "Dodgy Seller": 0.25, "Regular Seller": 0.15, "House Clearance": 0.08, "Desperate Seller": 0.05, "Clueless Seller": 0.0}

func haggle_flex_mean(item, stall):
	var f = float(HAGGLE_FLEX.get(stall["seller"], 0.18))
	f += stall_haggle_bonus(stall) * 0.7
	if current_time_minutes >= int(stall.get("packing_minute", 12 * 60)) - 45:
		f += 0.07   # they want to go home
	f += (1.0 - float(current_trends.get(item["category"], 1.0))) * 0.25
	f += float(market_event_fx("haggle", 0.0))
	if item.get("saved_for_player", false):
		f *= 0.35
	if item.get("noticed", false):
		f *= 0.5   # they know you want it now
	return clamp(f, 0.03, 0.55)

func haggle_base_ask(item):
	if float(item.get("orig_asking", 0.0)) <= 0.0:
		item["orig_asking"] = float(item["asking"])
	return float(item["orig_asking"])

func haggle_floor(item, stall):
	# The real lowest price, fixed per item once you start talking.
	if not item.has("haggle_noise"):
		item["haggle_noise"] = rng.randf_range(-1.0, 1.0)
	var flex = clamp(haggle_flex_mean(item, stall) + float(item["haggle_noise"]) * HAGGLE_SPREAD, 0.02, 0.60)
	var fl = haggle_base_ask(item) * (1.0 - flex) * (1.0 - float(item.get("flaw_leverage", 0.0)))
	return max(1.0, round(fl))

func haggle_floor_guess(item, stall):
	# What you can reasonably expect, without knowing this seller's mind: [low, high] of the floor.
	var base = haggle_base_ask(item) * (1.0 - float(item.get("flaw_leverage", 0.0)))
	var m = haggle_flex_mean(item, stall)
	var lo = base * (1.0 - clamp(m + HAGGLE_SPREAD, 0.02, 0.60))
	var hi = base * (1.0 - clamp(m - HAGGLE_SPREAD, 0.02, 0.60))
	return [lo, min(hi, float(item["asking"]))]

func compute_haggle_chance(item, seller, target_price, stall = null):
	# The chance shown to the player: how likely this offer clears the seller's floor, from what you can see.
	if stall == null:
		return 0.5
	if float(target_price) >= float(item["asking"]):
		return 1.0
	var g2 = haggle_floor_guess(item, stall)
	if g2[1] <= g2[0]:
		return 1.0 if float(target_price) >= g2[0] else 0.0
	return clamp((float(target_price) - g2[0]) / (g2[1] - g2[0]), 0.0, 1.0)

func haggle_insult_below(item, stall):
	var g2 = haggle_floor_guess(item, stall)
	return round((g2[0] + g2[1]) * 0.5 * INSULT_FRACTION)

func haggle_patience_max(stall):
	var p = int(HAGGLE_PATIENCE.get(stall["seller"], 2))
	var pers = personality_of(stall)
	if pers != null and float(pers.get("haggle_mod", 0.0)) < -0.03:
		p -= 1
	if has_perk("silver_tongue"):
		p += 1
	return max(2, p)

func haggle_patience(item, stall):
	if not item.has("patience"):
		item["patience"] = haggle_patience_max(stall)
	return int(item["patience"])

func haggle_open(item, stall):
	if to_bool(stall.get("no_haggle", false)):
		return false
	return not to_bool(item.get("seller_refuses", false)) and not to_bool(stall.get("banned_today", false)) and not to_bool(item.get("haggle_closed", false)) and item["haggle_result"] != "accepted"

func item_flaws(item):
	# Known problems you can raise with the seller: [key, label, mult].
	var out = []
	for t in item.get("traits", []):
		if t.get("known", false) and float(t["mult"]) < 0.97:
			var d = trait_def(t)
			var nm = str(d["name"]) if d != null else "A flaw"
			out.append(["t:" + str(t.get("id", "")), nm.to_lower(), float(t["mult"]), nm])
	if item["fault"] and fault_is_known(item):
		out.append(["fault", "the %s" % ("fault" if item["testable"] else "damage"), fault_multiplier(item["fault_severity"]), fault_label(item)])
	var has_damage = item["fault"] and fault_is_known(item) and not item["testable"]
	if item["condition_checked"] and int(item["condition"]) <= 5 and not has_damage:
		out.append(["cond", "the wear on it", condition_factor(int(item["condition"])) / max(0.01, condition_factor(7)), "Condition %d/10" % int(item["condition"])])
	var used = item.get("flaws_used", [])
	var avail = []
	for f in out:
		if not used.has(f[0]):
			avail.append(f)
	return avail

func seller_knew_flaw(item, stall, key):
	var knowledge = float(seller_profiles.get(stall["seller"], {"knowledge": 0.5})["knowledge"])
	var pers = personality_of(stall)
	if pers != null:
		knowledge += float(pers.get("knowledge_mod", 0.0))
	if key.begins_with("t:"):
		for t in item.get("traits", []):
			if "t:" + str(t.get("id", "")) == key:
				if t.has("seller_knew"):
					return to_bool(t["seller_knew"])
				var d = trait_def(t)
				return d != null and knowledge > trait_difficulty(d)
		return false
	# Faults and condition: the better they know their stuff, the likelier it's already in the price.
	var h = float(abs(hash([int(item["uid"]), key]))) / 2147483647.0
	return fmod(h, 1.0) < knowledge * 0.8

func point_out_flaw(index, key):
	if not valid_stall_index(index):
		return
	var stall = stalls[current_stall_index]
	var item = stall["stock"][index]
	if not haggle_open(item, stall):
		return
	var f = null
	for x in item_flaws(item):
		if x[0] == key:
			f = x
	if f == null:
		return
	haggle_base_ask(item)
	haggle_floor(item, stall)
	var used = item.get("flaws_used", [])
	used.append(key)
	item["flaws_used"] = used
	spend_time(1)
	var vars = {"flaw": f[1], "item": item_display_name(item)}
	var cap = 0.40 if has_perk("silver_tongue") else 0.30
	if seller_knew_flaw(item, stall, key) or float(item.get("flaw_leverage", 0.0)) >= cap - 0.01:
		var line = pers_line(stall, "flaw_knew", vars)
		item["haggle_note"] = "\"%s\"" % (line if line != "" else "I know. It's in the price.")
		# Lecturing someone about a flaw they already knew costs goodwill.
		item["patience"] = max(1, haggle_patience(item, stall) - 1)
		add_toast("They'd already priced that in, and they didn't love being told.", "info")
	else:
		var hit = clamp((1.0 - float(f[2])) * (0.75 if has_perk("silver_tongue") else 0.5), 0.03, 0.40)
		var lev = min(cap, 1.0 - (1.0 - float(item.get("flaw_leverage", 0.0))) * (1.0 - hit))
		hit = 1.0 - (1.0 - lev) / max(0.01, 1.0 - float(item.get("flaw_leverage", 0.0)))
		item["flaw_leverage"] = lev
		var new_ask = max(haggle_floor(item, stall), max(round(float(item["asking"]) * (1.0 - hit)), round(haggle_base_ask(item) * (1.0 - lev))))
		if item.get("flaws_used", []).size() >= 2:
			item["patience"] = max(1, haggle_patience(item, stall) - 1)   # nobody likes a list of complaints
		var was = float(item["asking"])
		item["asking"] = min(was, new_ask)
		var line2 = pers_line(stall, "flaw_concede", vars)
		item["haggle_note"] = "\"%s\"" % (line2 if line2 != "" else "Oh. I hadn't seen that. Less, then.")
		item["haggle_result"] = "countered"
		add_toast("Price down to %s (was %s)." % [fmt_money(item["asking"]), fmt_money(was)], "success")
		play_sfx("haggle_ok")
	show_stall()

func seller_notices(stall, item):
	# Called when you research or specialist-check an item in front of its seller.
	if has_perk("poker_face") or item.get("noticed", false) or not haggle_open(item, stall):
		return
	if float(item["asking"]) < 15.0 or int(stall.get("noticed_count", 0)) >= 2 or OS.get_environment("CBR_NO_NOTICE") != "":
		return
	var ch = float(NOTICE_CHANCE.get(stall["seller"], 0.1))
	var pers = personality_of(stall)
	if pers != null:
		ch += float(pers.get("knowledge_mod", 0.0)) * 0.8
	if rng.randf() >= ch:
		return
	item["noticed"] = true
	stall["noticed_count"] = int(stall.get("noticed_count", 0)) + 1
	haggle_base_ask(item)
	var up = rng.randf_range(0.08, 0.18)
	var was = float(item["asking"])
	item["asking"] = max(was + 1.0, round(was * (1.0 + up)))
	item["orig_asking"] = float(item["asking"])
	var line = pers_line(stall, "noticed", {"item": item_display_name(item)})
	item["haggle_note"] = "\"%s\"" % (line if line != "" else "Oh, you like that one? It's gone up.")
	add_toast("%s saw you checking. Now %s (was %s)." % [stall["seller_display_name"], fmt_money(item["asking"]), fmt_money(was)], "warn")

func valid_stall_index(index):
	if stalls.size() == 0 or current_stall_index < 0 or current_stall_index >= stalls.size():
		return false
	var stock = stalls[current_stall_index]["stock"]
	return index >= 0 and index < stock.size() and index < int(stalls[current_stall_index]["revealed"])

func dismiss_stall_item(index):
	var stall = stalls[current_stall_index]
	if index >= stall["stock"].size():
		return
	stall["stock"][index]["dismissed"] = true
	show_stall()

var seller_voice = {
	"accepted": {
		"Desperate Seller": ["Go on then, I need the money.", "Fine — just take it.", "Yeah, alright. Cash is cash."],
		"House Clearance": ["It's all got to go. Deal.", "Whatever, one less thing in the van.", "Done. Next!"],
		"Clueless Seller": ["Oh! Is that a good price? Lovely.", "Ooh, alright then.", "My husband said to take what I'm offered."],
		"Regular Seller": ["Fair enough, deal.", "Go on, you've twisted my arm.", "Alright mate, shake on it."],
		"Collector": ["...Fine. Look after it.", "I'll allow it. Just this once.", "You know what you're doing. Deal."],
		"Dodgy Seller": ["Cash, no receipt. Sorted.", "Quick, before I change my mind.", "Pleasure doing business, pal."],
		"Dealer": ["Tight, but alright.", "Only because it's early.", "Don't tell anyone I did that."],
	},
	"rejected": {
		"Desperate Seller": ["I can't go that low, sorry.", "Please, I've got bills to pay."],
		"House Clearance": ["Nah, not for that.", "I'll take my chances with the next bloke."],
		"Clueless Seller": ["Hmm, no, I don't think so, dear.", "Oh — that seems a bit low?"],
		"Regular Seller": ["Nah, price is the price.", "Can't do that one, mate."],
		"Collector": ["No. It's worth what I'm asking.", "Absolutely not."],
		"Dodgy Seller": ["Do I look soft to you?", "Nah. Walk on."],
		"Dealer": ["I know what it's worth.", "Price is firm."],
	},
	"refused": {
		"_": ["You're having a laugh. Not selling it to you now.", "Are you being serious? No chance.", "That's an insult. It's not for you."],
	},
	"kicked": {
		"_": ["Right, get away from my stall.", "Go on, clear off. I'm not dealing with you.", "Out. Now. Waste of my morning."],
	},
}

func seller_line(kind, seller):
	var table = seller_voice.get(kind, {})
	var lines = table.get(seller, table.get("_", [""]))
	return lines[rng.randi_range(0, lines.size() - 1)]

func haggle_item(index, offer):
	if not valid_stall_index(index):
		return
	if typeof(offer) == TYPE_OBJECT:
		offer = _parse_price(offer.text) if is_instance_valid(offer) else 0.0
	var stall = stalls[current_stall_index]
	var item = stall["stock"][index]
	var seller = stall["seller"]
	var seller_display = stall["seller_display_name"]
	if not haggle_open(item, stall):
		return
	if energy < 1:
		queue_popup("You need 1 energy to make an offer.")
		return
	var asking = float(item["asking"])
	haggle_base_ask(item)
	var target_price = clamp(round(float(offer)), 1.0, max(1.0, asking - 1.0))
	# A deal is a deal: make sure you could actually take it home before you shake on it.
	if cash < target_price:
		queue_popup("You haven't got %s on you." % fmt_money(target_price))
		return
	if not can_carry(item):
		queue_popup("You can't carry it (%d/%d). A bigger vehicle carries more." % [carry_used, effective_bag_capacity()])
		return
	if not can_store(item):
		queue_popup("No room at home for it (storage %d/%d)." % [inventory_space_used(), storage_capacity()])
		return
	var floor_p = haggle_floor(item, stall)
	var insult = haggle_insult_below(item, stall)
	var patience = haggle_patience(item, stall)
	energy -= 1
	spend_time(1)
	item["haggle_attempted"] = true
	item["offers"] = int(item.get("offers", 0)) + 1
	var goodwill = 1.0 if not has_perk("poker_face") else 0.5
	var money = {"price": "£%d" % int(target_price)}
	if target_price >= floor_p:
		var savings = haggle_base_ask(item) - target_price
		item["asking"] = target_price
		item["haggle_result"] = "accepted"
		item["haggle_savings"] = max(0.0, savings)
		if savings >= haggle_base_ask(item) * 0.05:
			day_stats["successful_haggles"] += 1
		change_rel(stall, 1.0)
		var line = stall_line(stall, "accept", money)
		if line == "":
			line = seller_line("accepted", seller)
		item["haggle_note"] = "\"%s\"" % line
		add_toast("Deal: %s (was %s). It's yours." % [fmt_money(target_price), fmt_money(haggle_base_ask(item))], "success")
		play_sfx("haggle_ok")
		buy_item(index)
		return
	play_sfx("haggle_no")
	if target_price < insult:
		# An insult: patience drains fast, and a proud seller may refuse you the item.
		patience -= 2
		change_rel(stall, -4.0 * goodwill)
		stall["insults"] = int(stall.get("insults", 0)) + 1
		var l1 = stall_line(stall, "lowball")
		if patience <= 0:
			item["patience"] = 0
			if int(stall["insults"]) >= 3 and not has_perk("poker_face"):
				stall["banned_today"] = true
				change_rel(stall, -12.0)
				item["haggle_note"] = "\"%s\"" % seller_line("kicked", seller)
				add_toast("%s has had enough of you for today." % seller_display, "error")
			else:
				item["seller_refuses"] = true
				item["haggle_result"] = "refused"
				item["haggle_note"] = "\"%s\"" % (l1 if l1 != "" else seller_line("refused", seller))
				add_toast("Too low. They won't sell you this one now.", "error")
			show_stall()
			return
		item["patience"] = patience
		item["haggle_note"] = "\"%s\"" % (l1 if l1 != "" else seller_line("rejected", seller))
		item["haggle_result"] = "rejected"
		add_toast("That offended them. Careful.", "warn")
		show_stall()
		return
	patience -= 1
	item["patience"] = max(0, patience)
	change_rel(stall, -0.5 * goodwill)
	if patience <= 0:
		# Final answer: somewhere just above their floor.
		var final_p = min(asking, max(floor_p, round(floor_p * rng.randf_range(1.0, 1.06))))
		item["asking"] = final_p
		item["haggle_closed"] = true
		item["haggle_result"] = "final"
		var lf = pers_line(stall, "final", {"price": fmt_money(final_p)})
		item["haggle_note"] = "\"%s\"" % (lf if lf != "" else "%s. Final offer." % fmt_money(final_p))
		show_stall()
		return
	# Counter: meet you part of the way, never below their floor.
	var give = rng.randf_range(0.30, 0.50)
	var counter = max(floor_p, round(asking - (asking - target_price) * give))
	counter = min(counter, asking)
	if counter >= asking:
		counter = max(floor_p, asking - max(1.0, round(asking * 0.03)))
	item["asking"] = counter
	item["haggle_result"] = "countered"
	var mid = (asking + target_price) * 0.5
	var lc = ""
	var pid = str(stall.get("personality", ""))
	var carr = Lines012.PERSONALITY_LINES.get(pid, {}).get("counter", [])
	if abs(counter - mid) > asking * 0.12:
		var filt = []
		for l in carr:
			if str(l).findn("split") < 0 and str(l).findn("meet") < 0 and str(l).findn("middle") < 0:
				filt.append(l)
		carr = filt
	if carr.size() > 0:
		lc = fill_line(unique_line(carr), {"price": fmt_money(counter)})
	if lc == "":
		lc = stall_line(stall, "reject")
		if lc == "":
			lc = seller_line("rejected", seller)
		lc += " %s?" % fmt_money(counter)
	item["haggle_note"] = "\"%s\"" % lc
	show_stall()

func make_ident(fam_name):
	var pats = Ident.PATTERNS.get(fam_name, [])
	if typeof(pats) != TYPE_ARRAY or pats.size() == 0:
		return ""
	var out = fill_pools(str(pats[rng.randi_range(0, pats.size() - 1)]), 0)
	if out.length() > 0 and out.substr(0, 1) != "'":
		out = out.substr(0, 1).to_upper() + out.substr(1)
	return out

func fill_pools(t, depth):
	var out = ""
	var i = 0
	while true:
		var a = t.find("{", i)
		if a < 0:
			out += t.substr(i)
			break
		var b = t.find("}", a)
		if b < 0:
			out += t.substr(i)
			break
		out += t.substr(i, a - i)
		var key = t.substr(a + 1, b - a - 1)
		var pool = Ident.POOLS.get(key, null)
		if typeof(pool) == TYPE_ARRAY and pool.size() > 0:
			var rep = str(pool[rng.randi_range(0, pool.size() - 1)])
			if rep.find("{") >= 0 and depth < 3:
				rep = fill_pools(rep, depth + 1)
			out += rep
		else:
			out += key
		i = b + 1
	return out

func buyer_message(item, price):
	# What the buyer says should fit what they actually got.
	if price < true_market_value(item) * 0.6 and item_unknown_trait_mult(item) > 1.25:
		return pick_line(WorldData.BUYER_MESSAGES.get("missed", [""]))
	var flawed = (item["fault"] and fault_is_known(item)) or int(item["condition"]) <= 4
	if flawed:
		return pick_line(["As described. Fine for what I need it for.", "Arrived. Honest listing, flaws and all. Thanks.", "It's rough, but you said so. No complaints.", "Spares or repair, as advertised. Cheers.", "Exactly the state you said. Fair price for it."])
	var cands = []
	for l in WorldData.BUYER_MESSAGES.get("happy", []):
		var t = str(l)
		if t.findn("working") >= 0 and not item["testable"]:
			continue
		if t.findn("perfect condition") >= 0 and int(item["condition"]) < 8:
			continue
		if t.findn("loft") >= 0 and int(item["condition"]) >= 8:
			continue
		if t.findn("photos") >= 0 and not has_equip("photo"):
			continue
		cands.append(t)
	return pick_line(cands)

func sale_buyer_phrase(channel):
	var town = pick_line(Ident.POOLS["town"])
	match channel:
		"listing", "instant":
			return "online to a buyer in %s" % town
		"auction":
			return "at auction, to a bidder in %s" % town
		"shop":
			return "in the shop, to someone from %s" % town
		"collector":
			return "to your collector contact"
		"trader", "trade":
			return "to the trade"
		"bigfind":
			return "to a specialist buyer"
	return "to a buyer in %s" % town

func hist(item, text):
	# The item's biography: a short dated timeline that follows it from the stall to the buyer.
	var h = item.get("hist", [])
	if typeof(h) != TYPE_ARRAY:
		h = []
	h.append([day, str(text)])
	if h.size() > 14:
		h = h.slice(h.size() - 14)
	item["hist"] = h

func first_lower(t):
	var s2 = str(t)
	if s2.length() > 1 and s2.substr(1, 1) == s2.substr(1, 1).to_upper() and s2.substr(1, 1) != s2.substr(1, 1).to_lower():
		return s2   # starts with an acronym
	return s2.substr(0, 1).to_lower() + s2.substr(1) if s2.length() > 0 else s2

func lc(name):
	# Lower-case a name for use mid-sentence, keeping acronyms (VHS, LP, SLR, 35mm) intact.
	var out = []
	for w in str(name).split(" "):
		var letters = w.strip_edges()
		if letters.length() > 1 and letters == letters.to_upper() and letters != letters.to_lower():
			out.append(w)
		elif letters.length() > 0 and letters.substr(0, 1).is_valid_int():
			out.append(w)
		else:
			out.append(w.to_lower())
	return " ".join(out)

func a_an(word):
	var w = str(word)
	return ("an " if w.length() > 0 and "aeiou".find(w.substr(0, 1).to_lower()) >= 0 else "a ") + w

func item_display_name(item):
	# The specific name if the item has one ("Iron Parish – Harvest of Rust"), else its kind.
	var n = str(item.get("ident", ""))
	return n if n != "" else str(item["name"])

func market_event_fx(key, default):
	# Today's odd thing at the market can tweak a rule.
	var ev = market_today.get("event", {})
	if typeof(ev) != TYPE_DICTIONARY:
		return default
	var fx = ev.get("fx", {})
	if fx.has("after") and current_time_minutes < int(fx["after"]):
		return default
	return fx.get(key, default)

func pers_line(stall, key, vars = {}):
	# Lines from the 0.12 dialogue set, falling back to the base personality lines.
	var pid = str(stall.get("personality", ""))
	var t = Lines012.PERSONALITY_LINES.get(pid, {})
	var arr = t.get(key, [])
	if typeof(arr) != TYPE_ARRAY or arr.size() == 0:
		var p = personality_of(stall)
		arr = p["lines"].get(key, []) if p != null else []
	return fill_line(unique_line(arr), vars)

func browse_stall():
	var stall = stalls[current_stall_index]
	if stall["revealed"] >= stall["stock"].size():
		return
	if energy < 4:
		queue_popup("Not enough energy. It refills tomorrow morning.")
		return
	energy -= 4
	stall["new_from"] = int(stall["revealed"])
	stall["revealed"] = min(stall["stock"].size(), stall["revealed"] + rng.randi_range(2, 4) + (1 if player_level >= 8 else 0))
	spend_time(8)
	play_sfx("reveal")
	show_stall()

func next_stall():
	go_to_stall((current_stall_index + 1) % max(1, stalls.size()))

func go_to_stall(index):
	if index < 0 or index >= stalls.size():
		return
	if index != current_stall_index:
		stalls[current_stall_index]["new_from"] = 999
		current_stall_index = index
		selected_stall_uid = -1
		spend_time(5)
	on_stall_visit(stalls[current_stall_index])
	show_stall()

func can_carry(item):
	return carry_used + size_units(item) <= int(effective_bag_capacity())

func can_store(item):
	return inventory_space_used() + size_units(item) <= storage_capacity()

func buy_item(index):
	if not valid_stall_index(index):
		return
	var stall = stalls[current_stall_index]
	if to_bool(stall.get("banned_today", false)):
		return
	var item = stall["stock"][index]
	if to_bool(item.get("seller_refuses", false)):
		return
	if cash < item["asking"]:
		queue_popup("Not enough cash.")
		return
	if not can_carry(item):
		queue_popup("You can't carry any more of today's buys (%d/%d). Selling or scrapping something you bought today frees the space, and it all empties overnight. A bigger vehicle carries more." % [carry_used, effective_bag_capacity()])
		return
	if not can_store(item):
		queue_popup("No room at home (storage %d/%d). Sell stock, or get bigger premises." % [inventory_space_used(), storage_capacity()])
		return
	cash -= item["asking"]
	day_stats["buy_spend"] += item["asking"]
	day_stats["items_bought"] += 1
	item["paid"] = item["asking"]
	if item["haggle_result"] == "accepted":
		total_haggled_savings += float(item["haggle_savings"])
	item["bought_from"] = stall.get("seller_full_name", stall["seller_display_name"])
	item["bought_day"] = day
	var pn = personality_of(stall)
	item["from_reg"] = int(stall.get("regular_id", -1))
	if market_today.get("rival_here", false) and not stall.get("rival_visited", false) and int(stall.get("rival_eta", -1)) > current_time_minutes and rival.get("cats", []).has(item["category"]) and float(item["true_value"]) >= float(item["asking"]) * 1.8:
		stall["beat_gaz_item"] = item["name"]
	if int(stall.get("regular_id", -1)) >= 0:
		world.remember(int(stall["regular_id"]), {"kind": "bought", "item": item["name"], "price": float(item["asking"])})
	hist(item, "Bought from %s%s for %s%s." % [item["bought_from"], "", fmt_money(item["asking"]), (" (asked %s)" % fmt_money(item.get("orig_asking", item["asking"]))) if float(item.get("orig_asking", 0.0)) > float(item["asking"]) + 0.5 else ""])
	item["carried_day"] = day
	inventory.append(item)
	stall["stock"].remove_at(index)
	stall["revealed"] = clamp(int(stall["revealed"]) - 1, 0, stall["stock"].size())
	register_collection(item)
	change_rel(stall, 6.0 if item["haggle_result"] != "accepted" else 4.0)
	var r = regular_by_id(int(stall.get("regular_id", -1))) if int(stall.get("regular_id", -1)) >= 0 else null
	if r != null:
		r["bought"] = int(r["bought"]) + 1
		r["last_item"] = item["name"]
	stall["last_line"] = stall_line(stall, "bought", {"item": item["name"]})
	if item.get("saved_for_player", false):
		unlock_achievement("Saved For You")
	check_side_deal(stall["seller"], stall["seller_display_name"])
	add_xp(3)
	add_toast("Bought %s for £%.0f." % [item["name"], item["paid"]], "success")
	fx_money(-float(item["paid"]))
	play_sfx("buy")
	selected_stall_uid = -1
	save_game()
	show_stall()

func update_family_condition(item):
	if family_stats.has(item["name"]):
		var fs = family_stats[item["name"]]
		if int(item["condition"]) > int(fs["best_condition"]):
			fs["best_condition"] = item["condition"]

func register_collection(item):
	day_stats["rarest_one_in"] = max(int(day_stats["rarest_one_in"]), int(item["one_in"]))
	var key = item["category"] + "|" + item["name"] + "|" + item["rarity"]
	if not discovered_log.has(key):
		discovered_log[key] = {"name":item["name"], "category":item["category"], "rarity":item["rarity"], "one_in":item["one_in"]}
		day_stats["collection_adds"] += 1
		if int(item["one_in"]) >= 100:
			unlock_achievement("Against the Odds")
		if item["rarity"] == "Grail":
			unlock_achievement("Grail Hunter")
			show_big_popup("GRAIL FIND", "%s — a 1 in %d find.\nNew Collection Log entry.\n\nMost players never see one of these." % [item["name"], int(item["one_in"])], "grail")
		elif int(item["one_in"]) >= 100:
			show_big_popup("%s FIND" % item["rarity"].to_upper(), "%s — 1 in %d.\nNew Collection Log entry." % [item["name"], int(item["one_in"])], "rare")
		elif int(item["one_in"]) >= 20:
			add_toast("New Collection Log entry: %s (%s 1/%d)" % [item["name"], item["rarity"], int(item["one_in"])], "success")
	if not family_stats.has(item["name"]):
		family_stats[item["name"]] = {"category":item["category"], "times_found":0, "best_condition":0, "cheapest_bought":-1.0, "highest_sold":0.0, "lifetime_profit":0.0, "specials_found":{}, "highest_rarity":"Common", "highest_one_in":1}
	var fs = family_stats[item["name"]]
	fs["times_found"] += 1
	if fs["cheapest_bought"] < 0.0 or float(item["asking"]) < fs["cheapest_bought"]:
		fs["cheapest_bought"] = float(item["asking"])
	if item["one_in"] > int(fs["highest_one_in"]):
		fs["highest_one_in"] = item["one_in"]
		fs["highest_rarity"] = item["rarity"]

func check_side_deal(seller, display_name):
	if not special_event_profiles.has(seller):
		return
	if pending_special_offer != null:
		return
	var chance = float(seller_profiles[seller]["side"])
	var roll = rng.randf()
	var result = roll < chance
	record_rng("Side deal chance: %s | Rolled: %.2f%% | Result: %s" % [chance_text(chance), roll * 100.0, "TRIGGERED" if result else "MISS"], result)
	if result:
		pending_special_offer = generate_special_offer(seller, display_name)
		add_toast("%s has something else for you..." % display_name, "warn")
		play_sfx("rare")
		unlock_achievement("Actually Mate...")

func generate_special_offer(seller, display_name):
	var profile = special_event_profiles[seller]
	var item = generate_item(seller)
	var value_mult = rng.randf_range(float(profile["value_mult"][0]), float(profile["value_mult"][1]))
	item["true_value"] = max(1.0, float(item["true_value"]) * value_mult)
	var price_mult = rng.randf_range(float(profile["price_mult"][0]), float(profile["price_mult"][1]))
	item["asking"] = max(1.0, round(float(item["true_value"]) * price_mult))
	item["fault_chance"] = clamp(float(item["fault_chance"]) + float(profile["fault_bonus"]), 0.02, 0.85)
	item["fault_roll"] = rng.randf()
	item["fault"] = item["fault_roll"] < item["fault_chance"]
	if item["fault"]:
		var severity_roll = rng.randf()
		if severity_roll < 0.45:
			item["fault_severity"] = "Minor"
		elif severity_roll < 0.75:
			item["fault_severity"] = "Moderate"
		elif severity_roll < 0.93:
			item["fault_severity"] = "Major"
		else:
			item["fault_severity"] = "Dead"
	else:
		item["fault_severity"] = "None"
	if profile.has("fake_bonus"):
		item["fake_chance"] = clamp(float(item["fake_chance"]) + float(profile["fake_bonus"]), 0.0, 0.85)
		item["authentic"] = rng.randf() > item["fake_chance"]
	return {"seller":seller, "seller_display_name":display_name, "title":profile["title"], "flavor":profile["flavor"], "item":item}

func accept_special_offer():
	if pending_special_offer == null:
		return
	var item = pending_special_offer["item"]
	if cash < item["asking"]:
		set_status("You don't have enough cash for this offer.")
		return
	if not can_carry(item):
		set_status("BAG FULL — you can't carry this offer right now.")
		return
	if not can_store(item):
		set_status("HOME STORAGE FULL — you can't take this offer right now.")
		return
	cash -= item["asking"]
	day_stats["buy_spend"] += item["asking"]
	day_stats["items_bought"] += 1
	item["paid"] = item["asking"]
	item["carried_day"] = day
	hist(item, "Side deal from %s for %s." % [pending_special_offer.get("seller_display_name", "a seller"), fmt_money(item["asking"])])
	inventory.append(item)
	register_collection(item)
	add_xp(2)
	add_toast("Took the side deal: %s for £%.2f." % [item["name"], item["paid"]], "success")
	play_sfx("buy")
	pending_special_offer = null
	save_game()
	show_stall()

func decline_special_offer():
	add_toast("You walked away from the offer.", "info")
	pending_special_offer = null
	save_game()
	show_stall()

func confidence_label(item):
	var u = estimate_uncertainty(item)
	if u <= 0.10:
		return "[color=#8cd98f]Very confident[/color]"
	if u <= 0.17:
		return "[color=#b8e08f]Confident[/color]"
	if u <= 0.25:
		return "[color=#e0c96e]Rough idea[/color]"
	return "[color=#e88c7a]Guesswork[/color]"

const INVENTORY_PAGE_SIZE = 15
var inventory_page = 0
var inventory_sort = "needs_action"

func inventory_action_rank(item):
	if item["testable"] and not item["tested"]:
		return 0
	if item["auth_status"] == "Confirmed Counterfeit" or item["auth_status"] == "Suspected Counterfeit":
		return 1
	if not item["listed"] and not item["auctioned"]:
		return 2
	return 3

func function_status(item):
	if not item["testable"]:
		return "N/A"
	if not item["tested"]:
		return "TEST REQUIRED"
	if item["fault"]:
		return fault_label(item)
	return "Working"

func _parse_price(text):
	var cleaned = text.strip_edges()
	if cleaned == "" or not cleaned.is_valid_float():
		return 0.0
	return float(cleaned)

func quick_sell_item(index):
	if index < 0 or index >= inventory.size():
		return
	var item = inventory[index]
	if item.get("vaulted", false):
		return
	if item["auth_status"] == "Confirmed Counterfeit":
		queue_popup("Confirmed counterfeits can't be sold. Scrap it for parts.")
		return
	var qs_roll = rng.randf_range(0.45, 0.60) if has_perk("trade_contacts") else rng.randf_range(0.35, 0.50)
	var quick_price = max(1.0, round(true_market_value(item) * qs_roll))
	record_rng("Trader offer: %.0f%% of market value | Result: £%.0f" % [qs_roll * 100.0, quick_price])
	cash += quick_price
	spend_time(2)
	var profit = record_completed_sale(item, quick_price, {"fee":0.0, "postage":0.0, "insurance":0.0, "packaging":0.0}, "trader")
	inventory.remove_at(index)
	add_toast("Sold to a trader: %s for £%.0f (profit %s)." % [item["name"], quick_price, money_signed(profit)], "success" if profit >= 0.0 else "warn")
	fx_money(quick_price)
	play_sfx("coin")
	save_game()
	show_inventory()


func money_signed(v):
	var r = round(float(v))
	return ("+" if r >= 0.0 else "-") + "£" + fmt_int(abs(r))

# =====================================================================
# UI BRIDGE — logic calls these; in sim mode they do nothing.
# =====================================================================

func format_sale_summary(item, price):
	var costs = selling_costs(item, price)
	var insurance_pack = float(costs["insurance"]) + float(costs["packaging"])
	var total_costs = float(costs["fee"]) + float(costs["postage"]) + insurance_pack
	var net = price - total_costs
	var extra_spend = float(item.get("extra_spend", 0.0))
	var profit = net - float(item["paid"]) - extra_spend
	var profit_color = "#8cd98f" if profit >= 0.0 else "#e88c7a"
	return "Profit if it sells at this price: [color=%s]%s[/color]" % [profit_color, money_signed(profit)]

func format_sale_breakdown(item, price):
	var costs = selling_costs(item, price)
	var insurance_pack = float(costs["insurance"]) + float(costs["packaging"])
	var total_costs = float(costs["fee"]) + float(costs["postage"]) + insurance_pack
	var net = price - total_costs
	var extra_spend = float(item.get("extra_spend", 0.0))
	var profit = net - float(item["paid"]) - extra_spend
	var profit_color = "#8cd98f" if profit >= 0.0 else "#e88c7a"
	var extra_line = ""
	if extra_spend > 0.0:
		extra_line = "  ->  Research/Test/Auth spend -£%.2f" % extra_spend
	return "£%.2f  ->  fee £%.2f, postage £%.2f, packaging/insurance £%.2f  ->  you get £%.2f%s  ->  profit [color=%s][b]%s[/b][/color]" % [price, costs["fee"], costs["postage"], insurance_pack, net, extra_line.replace("  ->  Research/Test/Auth spend -", ", less £").replace("££", "£") + (" already spent on checks" if extra_line != "" else ""), profit_color, money_signed(profit)]

func buyer_interest_color(label_text):
	label_text = str(label_text).split(" (")[0]
	if label_text == "VERY HIGH" or label_text == "HIGH":
		return "#8cd98f"
	elif label_text == "AVERAGE":
		return "#e0c96e"
	else:
		return "#e88c7a"

func format_sale_estimate(item, price):
	var chance = daily_sale_chance(buyer_interest_score(item, price, true))
	var expected_days = max(1, int(round(1.0 / chance)))
	return "Estimate: ~%d%% chance of a buyer each night (about %d day%s) — if your estimate of its value is right. The real odds stay hidden until it sells." % [int(round(chance * 100.0)), expected_days, "" if expected_days == 1 else "s"]

func fault_is_known(item):
	if item["testable"]:
		return item["tested"]
	return item["condition_checked"]

func gamble_hint_chance(item):
	var potential = estimate_identified_potential(item)
	var center = (float(potential[0]) + float(potential[1])) / 2.0
	var value_ratio = clamp(float(item["asking"]) / max(1.0, center), 0.3, 2.5)
	return clamp(0.06 + (value_ratio - 0.8) * 0.20, 0.04, 0.32)

func condition_factor(condition):
	return lerp(0.62, 1.38, clamp(float(condition - 3) / 7.0, 0.0, 1.0))

func market_value(item):
	# The hidden truth: what buyers will actually pay for this exact item right now.
	var v = float(item["true_value"]) * float(item["identified_mult"]) * float(current_trends.get(item["category"], 1.0))
	v *= float(item.get("documented", 1.0)) * float(item.get("vault_mult", 1.0))
	v *= condition_factor(int(item["condition"]))
	if item["fault"] and fault_is_known(item):
		v *= fault_multiplier(item["fault_severity"])
	if item["testable"] and item["tested"] and not item["fault"]:
		v *= 1.12
	if item["auth_status"] == "Confirmed Genuine" and float(item["fake_chance"]) >= 0.05:
		v *= 1.08
	return max(1.0, v)

func true_market_value(item):
	# What a buyer who inspects the item in hand would pay: every fault counts, fakes are nearly worthless.
	var v = market_value(item)
	if item["fault"] and not fault_is_known(item):
		v *= fault_multiplier(item["fault_severity"])
	if not item["authentic"] and item["auth_status"] != "Confirmed Counterfeit":
		v *= 0.15
	return max(1.0, v)

func estimate_uncertainty(item):
	# Relative half-width of your value range (~80% of the time the known-version value lands inside).
	if not item["basic_researched"] or item.get("comps_values", []).size() == 0:
		var u = 0.40
		if item["quick_look_done"]:
			u -= 0.02
		if item["condition_checked"]:
			u -= 0.07
		u -= 0.02 * float(expertise_tier(item["category"]))
		return clamp(u, 0.12, 0.40)
	# Researched: the spread of a median of real sold prices, plus whatever condition you haven't pinned down.
	var ev = 0.14 if item["deep_researched"] else 0.29
	ev *= 1.0 - 0.08 * float(expertise_tier(item["category"]))
	if item.get("expert_checked", false):
		ev *= 0.9
	var c = 0.0
	if not item["condition_checked"]:
		c = 0.10 if item["quick_look_done"] else 0.18
	return clamp(sqrt(ev * ev + c * c), 0.05, 0.40)

func known_value(item):
	# The value of the item as you understand it (unknown traits, unknown faults and unchecked condition left out).
	return max(1.0, typical_value(item) * known_basis(item))

func perceived_center(item):
	# The player's belief. Once researched, it's what the sold prices say about examples like yours;
	# before that, a guess from what this *kind* of thing usually fetches, sharpened by expertise.
	if item["basic_researched"] and item.get("comps_values", []).size() > 0:
		var ev = comps_median_value(item)
		var tier = float(expertise_tier(item["category"]))
		if tier > 0.0:
			# Experts read the comps better: a little pull toward the real thing.
			ev = exp(lerp(log(max(1.0, ev)), log(known_value(item)), 0.08 * tier))
		return max(1.0, ev)
	var v = market_value(item)
	if not item["condition_checked"]:
		v /= condition_factor(int(item["condition"]))
		if item["quick_look_done"]:
			v *= condition_factor(int(item.get("perceived_condition", 6)))
	if item["hidden_special"] != "" and not item["special_discovered"]:
		v /= max(1.0, float(item.get("special_premium", 1.0)))
	v /= max(0.05, item_unknown_trait_mult(item))
	var w = knowledge_weight(item)
	if w < 0.999:
		var prior = family_prior(item)
		if prior > 0.0:
			v = exp(w * log(max(1.0, v)) + (1.0 - w) * log(max(1.0, prior)))
	var u = estimate_uncertainty(item)
	var bias = exp(clamp(float(item.get("est_noise", 0.0)), -2.2, 2.2) * u * 0.62)
	return max(1.0, v * bias)

func value_breakdown(item):
	# [[label, pct]] explaining the estimate: first entry is the typical example, then each known adjustment.
	var out = []
	if item["basic_researched"] and item.get("comps_values", []).size() > 0:
		out.append(["Typical one ~%s" % fmt_money(comps_median_value(item) / known_basis(item)), 0.0])
	else:
		out.append(["Before research", 0.0])
	var cf = 1.0
	var clabel = ""
	if item["condition_checked"]:
		cf = condition_factor(int(item["condition"]))
		clabel = "Condition %d/10" % int(item["condition"])
	elif item["quick_look_done"]:
		cf = condition_factor(int(item.get("perceived_condition", 6)))
		clabel = "Looks ~%d/10" % int(item.get("perceived_condition", 6))
	if clabel != "" and abs(cf - 1.0) >= 0.02:
		out.append([clabel, cf - 1.0])
	for t in item.get("traits", []):
		if t.get("known", false) and abs(float(t["mult"]) - 1.0) >= 0.02:
			var d = trait_def(t)
			out.append([str(d["name"]) if d != null else "Detail", float(t["mult"]) - 1.0])
	if item["fault"] and fault_is_known(item):
		out.append([fault_label(item), fault_multiplier(item["fault_severity"]) - 1.0])
	if item["testable"] and item["tested"] and not item["fault"]:
		out.append(["Tested working", 0.12])
	if item["auth_status"] == "Confirmed Genuine" and float(item["fake_chance"]) >= 0.05:
		out.append(["Authenticated", 0.08])
	if float(item.get("identified_mult", 1.0)) != 1.0 and abs(float(item["identified_mult"]) - 1.0) >= 0.02:
		out.append(["Identified", float(item["identified_mult"]) - 1.0])
	if float(item.get("documented", 1.0)) > 1.0:
		out.append(["Provenance documented" if float(item["documented"]) < 1.08 else "Full provenance", float(item["documented"]) - 1.0])
	if abs(float(item.get("vault_mult", 1.0)) - 1.0) >= 0.01:
		out.append(["Market moves in the vault", float(item["vault_mult"]) - 1.0])
	return out

func family_range(item):
	# What examples of this kind usually go for, adjusted for what you already know about this one.
	var fam = content.family(str(item["name"])) if content != null else null
	if fam == null:
		var c = perceived_center(item)
		return [c * 0.5, c * 1.6]
	var adj = float(RARITY_EXPECT.get(item["rarity"], 1.0)) * float(current_trends.get(item["category"], 1.0)) * known_basis(item)
	return [max(1.0, float(fam["value"][0]) * adj), max(2.0, float(fam["value"][1]) * adj)]

func value_range(item):
	# The range shown to the player. Honest by construction: before research it's the family range
	# (narrowed by expertise), after research it's the comps median ± a calibrated spread.
	if item["basic_researched"] and item.get("comps_values", []).size() > 0:
		var c = perceived_center(item)
		var u = estimate_uncertainty(item)
		return [max(1.0, c * (1.0 - u)), max(2.0, c * (1.0 + u))]
	var fr = family_range(item)
	var tier = float(expertise_tier(item["category"]))
	if tier <= 0.0:
		return fr
	var kv = known_value(item)
	var t = clamp(0.2 * tier, 0.0, 0.8)
	var lo = exp(lerp(log(fr[0]), log(max(1.0, kv * 0.72)), t))
	var hi = exp(lerp(log(fr[1]), log(max(2.0, kv * 1.35)), t))
	return [min(lo, hi - 1.0), max(hi, lo + 1.0)]

const RARITY_EXPECT = {"Common": 1.0, "Uncommon": 1.3, "Rare": 1.85, "Very Rare": 3.2, "Grail": 8.5}

func knowledge_weight(item):
	# How much of your estimate comes from evidence about THIS item rather than its type.
	# Research (real sold prices) is the big one; an unresearched item is mostly a guess from its type.
	var w = 0.0
	if item["quick_look_done"]:
		w += 0.05
	if item["basic_researched"]:
		w += 0.80
	if item["condition_checked"]:
		w += 0.08
	if item["deep_researched"]:
		w += 0.15
	if item["testable"] and item["tested"]:
		w += 0.03
	if item.get("expert_checked", false):
		w += 0.08
	w += 0.05 * float(expertise_tier(item["category"]))
	return clamp(w, 0.0, 0.98)

func family_prior(item):
	var fam = content.family(str(item["name"])) if content != null else null
	if fam == null:
		return -1.0
	var p = (float(fam["value"][0]) + float(fam["value"][1])) * 0.5
	p *= float(RARITY_EXPECT.get(item["rarity"], 1.0))
	p *= float(current_trends.get(item["category"], 1.0))
	var c = 6
	if item["condition_checked"]:
		c = int(item["condition"])
	elif item["quick_look_done"]:
		c = int(item.get("perceived_condition", 6))
	p *= condition_factor(c)
	for t in item.get("traits", []):
		if t.get("known", false):
			p *= float(t["mult"])
	p *= float(item.get("identified_mult", 1.0)) * float(item.get("documented", 1.0)) * float(item.get("vault_mult", 1.0))
	if item["fault"] and fault_is_known(item):
		p *= fault_multiplier(item["fault_severity"])
	return max(1.0, p)

func estimate_identified_potential(item):
	var r = value_range(item)
	var low = int(max(1.0, round(r[0])))
	var high = int(max(float(low) + 1.0, round(r[1])))
	return [low, high]

func inventory_check_condition(index):
	do_check_condition("inv", index)

func inventory_basic_research(index):
	do_research("inv", index)

func deep_research(index):
	if index < 0 or index >= inventory.size():
		return
	var item = inventory[index]
	if item["deep_researched"]:
		return
	var dr_cost = deep_research_cost(item)
	if cash < dr_cost or energy < 10:
		queue_popup("Deep Research needs £%d and 10 energy." % int(dr_cost))
		return
	var before = estimate_identified_potential(item)
	cash -= dr_cost
	item["extra_spend"] += dr_cost
	energy -= 10
	spend_time(20)
	day_stats["research"] += dr_cost
	day_stats["deep_researches_done"] += 1
	item["deep_researched"] = true
	item["action_order"].append("deep_research")
	add_expertise(item["category"], 3 if not has_equip("library") else 5)
	var tier = expertise_tier(item["category"])
	var reason = ""
	if item.has("traits") and item.get("hidden_special", "") == "":
		# Deep Research rolls to find deep- and research-level details, with a long shot at specialist clues.
		var res = luck.do_dig(item, "deep", "inv", dr_cost)
		reason = luck.dig_result_text(item, "deep", res)
		show_roll("DEEP RESEARCH", res["entries"], reason)
	else:
		# Legacy (0.10) items keep their old behaviour.
		var knowledge = float(category_knowledge.get(item["category"], 5))
		var chance = clamp(0.28 + knowledge / 180.0, 0.28, 0.78)
		var roll = rng.randf()
		var success = roll < chance
		record_rng("Deep research discovery chance: %.1f%% | Rolled: %.2f%% | Result: %s" % [chance * 100.0, roll * 100.0, "DISCOVERY" if success else "NO MAJOR DISCOVERY"])
		reason = "No new info."
		if success and item["hidden_special"] != "" and not item["special_discovered"]:
			item["special_discovered"] = true
			if item["special_genuine"]:
				item["identified_mult"] *= 1.55
			else:
				item["identified_mult"] *= 0.92
			reason = "Possible hidden special: %s." % item["hidden_special"]
	item["basic_comps"] = make_comps(item, true)
	var after = estimate_identified_potential(item)
	item["deep_note"] = "%s Your estimate £%d–£%d → £%d–£%d." % [reason, before[0], before[1], after[0], after[1]]
	play_sfx("reveal")
	refresh_after("inv")

func deep_research_cost(item):
	var c = max(3.0, round(max(float(item["paid"]), 1.0) * 0.18))
	if item.get("source", "") in ["found", "clearance"]:
		c = max(3.0, round(perceived_center(item) * 0.08))
	if has_equip("library"):
		c = max(2.0, round(c * 0.7))
	return c

func test_item(index):
	if index < 0 or index >= inventory.size():
		return
	var item = inventory[index]
	if item["tested"] or not item["testable"]:
		return
	var tc = test_cost()
	if cash < tc or energy < test_energy():
		queue_popup("Testing needs £%d and %d energy." % [int(tc), test_energy()])
		return
	var before = estimate_identified_potential(item)
	cash -= tc
	item["extra_spend"] += tc
	energy -= test_energy()
	spend_time(5 if has_equip("test_rig") else 10)
	day_stats["research"] += tc
	item["tested"] = true
	item["action_order"].append("test")
	var result_text = "WORKING"
	if item["fault"]:
		result_text = "FAULT: " + fault_label(item)
	record_rng("Fault chance: %.1f%% | Rolled: %.2f%% | Result: %s" % [item["fault_chance"] * 100.0, item["fault_roll"] * 100.0, result_text])
	var found = reveal_traits(item, "test")
	for t in found:
		var td = trait_def(t)
		if td != null and float(t["mult"]) <= 0.6 and str(td["kind"]) != "good":
			result_text = "FAULT: " + str(td["name"])
	hist(item, "Tested: %s." % ("works" if result_text == "WORKING" else result_text.to_lower()))
	var after = estimate_identified_potential(item)
	item["test_note"] = "%s. Your estimate £%d–£%d → £%d–£%d." % [result_text.capitalize() if not item["fault"] else result_text, before[0], before[1], after[0], after[1]]
	if not bulk_mode:
		add_toast("Test: %s" % result_text, "success" if not item["fault"] else "warn")
		play_sfx("reveal" if not item["fault"] else "fail")
	refresh_after("inv")

func fault_label(item):
	var s = str(item["fault_severity"])
	if item["testable"]:
		return {"Minor":"Minor fault", "Moderate":"Moderate fault", "Major":"Major fault", "Dead":"Dead — doesn't work"}.get(s, s)
	return {"Minor":"Minor wear or flaw", "Moderate":"Noticeable damage", "Major":"Heavy damage", "Dead":"Badly broken / for parts"}.get(s, s)

func fault_multiplier(severity):
	if severity == "Minor":
		return 0.85
	if severity == "Moderate":
		return 0.64
	if severity == "Major":
		return 0.42
	if severity == "Dead":
		return 0.24
	return 1.0

func authentication_cost(item):
	if has_equip("auth"):
		return 2.0
	var cost = 12.0
	if float(item["paid"]) > 60.0:
		cost = 22.0
	if float(item["paid"]) > 150.0:
		cost = 32.0
	return cost

func authentication_accuracy(item):
	var accuracy = 0.80
	if has_equip("auth"):
		accuracy = 0.78 + 0.05 * float(expertise_tier(item["category"]))
	else:
		var cost = authentication_cost(item)
		if cost >= 22.0:
			accuracy = 0.87
		if cost >= 32.0:
			accuracy = 0.92
	return clamp(accuracy, 0.5, 0.97)

func authenticate_item(index):
	if index < 0 or index >= inventory.size():
		return
	var item = inventory[index]
	if item["auth_attempted"]:
		return
	var cost = authentication_cost(item)
	if cash < cost or energy < 6:
		queue_popup("Authentication needs £%.0f and 6 energy." % cost)
		return
	cash -= cost
	item["extra_spend"] += cost
	energy -= 6
	spend_time(15)
	day_stats["authentication"] += cost
	day_stats["authentications_done"] += 1
	item["auth_attempted"] = true
	item["action_order"].append("authenticate")
	var accuracy = authentication_accuracy(item)
	var roll = rng.randf()
	var success = roll < accuracy
	record_rng("Authentication accuracy: %.0f%% | Rolled: %.2f%% | Result: %s" % [accuracy * 100.0, roll * 100.0, "CONCLUSIVE" if success else "INCONCLUSIVE"])
	if success:
		if item["authentic"]:
			item["auth_status"] = "Confirmed Genuine"
		else:
			item["auth_status"] = "Confirmed Counterfeit"
			item["identified_mult"] *= 0.10
			if item["listed"] or item["auctioned"] or item.get("on_shop_floor", false):
				item["listed"] = false
				item["auctioned"] = false
				item["on_shop_floor"] = false
				item["listing"] = 0.0
				add_toast("Listing pulled: you can't knowingly sell a counterfeit.", "warn")
			play_sfx("fail")
			unlock_achievement("Should've Known Better")
			add_journal("A %s turned out to be a fake." % item["name"], "bad")
	else:
		item["auth_status"] = "Inconclusive"
	if has_equip("auth") and not item.get("uv_checked", false):
		item["uv_checked"] = true
		reveal_traits(item, "uv")
	item["auth_note"] = item["auth_status"]
	add_xp(3)
	add_toast("Authentication: %s." % item["auth_status"], "success" if item["auth_status"] == "Confirmed Genuine" else ("error" if item["auth_status"] == "Confirmed Counterfeit" else "info"))
	refresh_after("inv")

func repair_fault_chance(item):
	var base_chance = {"Minor": 0.62, "Moderate": 0.48, "Major": 0.30, "Dead": 0.16}.get(item["fault_severity"], 0.3)
	if item["testable"] and equip_level("repair") >= 2:
		base_chance += 0.06
	return clamp(base_chance + repair_bonus(), 0.05, 0.92)

func repair_trait_chance():
	return clamp(0.55 + repair_bonus(), 0.1, 0.95)

func repair_odds_text(item):
	var parts = []
	if item["fault"] and fault_is_known(item):
		parts.append("%d%%" % int(round(repair_fault_chance(item) * 100.0)))
	if known_fixable(item, "repair").size() > 0:
		parts.append("%d%%" % int(round(repair_trait_chance() * 100.0)))
	return " / ".join(parts)

func repair_cost(item):
	if item["fault_severity"] == "Minor":
		return 5.0
	if item["fault_severity"] == "Moderate":
		return 10.0
	if item["fault_severity"] == "Major":
		return 18.0
	return 25.0

func repair_item(index):
	if index < 0 or index >= inventory.size():
		return
	var item = inventory[index]
	if not has_equip("repair"):
		queue_popup("You need a Repair Bench in your workshop.")
		return
	if not can_repair(item):
		return
	var cost = repair_cost(item) if (item["fault"] and fault_is_known(item)) else 6.0
	if cash < cost or energy < 10:
		queue_popup("Repairing needs £%.0f and 10 energy." % cost)
		return
	cash -= cost
	item["extra_spend"] += cost
	energy -= 10
	spend_time(30)
	day_stats["repairs"] += cost
	day_stats["repairs_done"] += 1
	item["repair_attempted"] = true
	var notes = []
	var entries = []
	if item["fault"] and fault_is_known(item):
		var chance = repair_fault_chance(item)
		var rr = luck.roll("repair", chance, "Repair: %s" % fault_label(item).to_lower())
		rr["label"] = "Fix the %s" % fault_label(item).to_lower()
		var fix_desc = "fault gone" if item["fault_severity"] in ["Minor", "Moderate"] else ("eased to minor" if item["fault_severity"] == "Major" else "brought back to moderate")
		luck.tier_bands(rr, [["Perfect fix", min(0.08, chance * 0.5), "gold", "fault gone completely, and condition +1"], ["Fixed", chance, "green", fix_desc]], "the fault beats you")
		entries.append(rr)
		var success = rr["hit"]
		if success and rr["band"] == "Perfect fix":
			item["fault"] = false
			item["fault_severity"] = "None"
			item["condition"] = min(10, int(item["condition"]) + 1)
			notes.append("a perfect repair: fault gone and condition up to %d/10" % int(item["condition"]))
		elif success:
			if item["fault_severity"] in ["Minor", "Moderate"]:
				item["fault"] = false
				item["fault_severity"] = "None"
			elif item["fault_severity"] == "Major":
				item["fault_severity"] = "Minor"
			else:
				item["fault_severity"] = "Moderate"
			notes.append("fault repaired" if not item["fault"] else "fault improved to %s" % item["fault_severity"])
		else:
			notes.append("the fault beat you")
	for t in known_fixable(item, "repair"):
		var ch = repair_trait_chance()
		var r2r = luck.roll("repair", ch, "Repair: %s" % trait_def(t)["name"])
		r2r["label"] = "Fix: %s" % trait_def(t)["name"]
		luck.tier_bands(r2r, [["Restored", 0.08, "gold", "fixed, and condition +1"], ["Fixed", ch, "green", "fixed"]], "still broken")
		entries.append(r2r)
		if r2r["hit"]:
			fix_trait(item, t)
			if r2r["band"] == "Restored":
				item["condition"] = min(10, int(item["condition"]) + 1)
				notes.append("%s restored (condition %d/10)" % [trait_def(t)["name"], int(item["condition"])])
			else:
				notes.append("%s fixed" % trait_def(t)["name"])
		else:
			notes.append("couldn't fix the %s" % trait_def(t)["name"].to_lower())
	item["repair_note"] = ", ".join(notes).capitalize()
	hist(item, "On the bench: %s." % ", ".join(notes))
	show_roll("ON THE BENCH", entries, item["repair_note"] + ".")
	add_xp(3)
	if not show_rolls or entries.size() == 0:
		add_toast("Repair: %s." % ", ".join(notes), "success" if "fixed" in item["repair_note"].to_lower() or "repaired" in item["repair_note"].to_lower() else "warn")
	refresh_after("inv")

func buyer_interest_score(item, price, perceived = false, reference_override = -1.0):
	# perceived=true: what the player expects, based on their own estimate.
	# perceived=false: the real figure used by the sale roll.
	var reference = perceived_center(item) if perceived else market_value(item)
	if reference_override > 0.0:
		reference = reference_override
	var r = float(price) / max(1.0, reference)
	var score = 0.93 - (r - 0.70) * 1.18
	score *= lerp(1.0, float(current_trends.get(item["category"], 1.0)), 0.5)
	if item["auth_status"] == "Confirmed Genuine":
		score *= 1.10
	elif item["auth_status"] == "Suspected Counterfeit":
		score *= 0.55
	elif float(item["fake_chance"]) >= 0.08:
		score *= 0.88
	if int(item["one_in"]) >= 500:
		score *= 1.08
	var checks_done = 0
	if item["condition_checked"]:
		checks_done += 1
	if item["basic_researched"]:
		checks_done += 1
	if item["deep_researched"]:
		checks_done += 1
	score *= lerp(0.92, 1.10, float(checks_done) / 3.0)
	score *= lerp(0.70, 1.04, clamp(seller_rating / 100.0, 0.0, 1.0))
	score *= listing_appeal_mult()
	return clamp(score, 0.0, 0.98)

func daily_sale_chance(score):
	return clamp(0.02 + score * 0.47, 0.0, 0.50) if score > 0.0 else 0.0

func buyer_interest_label(item, price):
	var lbl = buyer_interest_label_raw(item, price)
	var u = estimate_uncertainty(item)
	if u > 0.24:
		return lbl + " (wild guess)"
	if u > 0.15:
		return lbl + " (rough guess)"
	return lbl

func buyer_interest_label_raw(item, price):
	var score = buyer_interest_score(item, price, true)
	if score >= 0.78:
		return "VERY HIGH"
	if score >= 0.60:
		return "HIGH"
	if score >= 0.42:
		return "AVERAGE"
	if score >= 0.24:
		return "LOW"
	return "VERY LOW"

func auction_flavor_text(tier, sniped):
	if sniped:
		return "A late bid snuck in right at the buzzer."
	if tier == "big_war":
		return "A proper bidding war broke out for it."
	if tier == "war":
		return "A collector recognized what you'd found."
	if tier == "weak":
		return "Sold to the only bidder in the room."
	return "A fair price, no drama."

func auction_hype(item):
	var hype = 0.0
	if item["one_in"] >= 25:
		hype += 0.15
	if item["one_in"] >= 125:
		hype += 0.15
	if item["one_in"] >= 750:
		hype += 0.15
	if item["one_in"] >= 5000:
		hype += 0.15
	for t in known_traits(item):
		if float(t["mult"]) >= 1.6:
			hype += 0.1
	if float(current_trends.get(item["category"], 1.0)) >= 1.10:
		hype += 0.15
	return clamp(hype, 0.0, 0.6)

func auction_bands(item):
	# Cumulative [tier, upto] from worst to best; a roll lands in one.
	var hype = auction_hype(item)
	var w = {"flop": 0.12, "weak": 0.33, "normal": 0.42, "war": 0.10 * (1.0 + hype * 1.5), "big_war": 0.03 * (1.0 + hype * 2.5)}
	var tot = 0.0
	for v in w.values():
		tot += v
	var out = []
	var cum = 0.0
	for key in ["flop", "weak", "normal", "war", "big_war"]:
		cum += w[key] / tot
		out.append([key, cum])
	return out

func auction_odds_text(item):
	var b = auction_bands(item)
	return "%d%% flop · %d%% bidding war" % [int(round(float(b[0][1]) * 100.0)), int(round((1.0 - float(b[2][1])) * 100.0))]

func start_auction(index):
	if index < 0 or index >= inventory.size():
		return
	var item = inventory[index]
	if item.get("vaulted", false):
		return
	if not auctions_unlocked():
		queue_popup("Auctions unlock at level 6 (or with the Auctioneer perk).")
		return
	if item["auth_status"] == "Confirmed Counterfeit":
		queue_popup("You can't knowingly sell a counterfeit.")
		return
	if item["testable"] and not item["tested"]:
		queue_popup("Test it first.")
		return
	if not item["listed"] and active_listing_count() >= listing_cap():
		queue_popup("You're at your listing limit (%d)." % listing_cap())
		return
	var center = true_market_value(item)
	# Bidders only half-believe in what you haven't found yourself: unknown upside is discounted.
	var unk_good = 1.0
	for t in item.get("traits", []):
		if not t.get("known", false) and float(t["mult"]) > 1.0:
			unk_good *= float(t["mult"])
	center /= sqrt(unk_good)
	item["auction_center"] = center
	var hype = 0.0
	if item["one_in"] >= 25:
		hype += 0.15
	if item["one_in"] >= 125:
		hype += 0.15
	if item["one_in"] >= 750:
		hype += 0.15
	if item["one_in"] >= 5000:
		hype += 0.15
	for t in known_traits(item):
		if float(t["mult"]) >= 1.6:
			hype += 0.1
	if float(current_trends.get(item["category"], 1.0)) >= 1.10:
		hype += 0.15
	hype = clamp(hype, 0.0, 0.6)
	var bands = auction_bands(item)
	var ar = luck.roll("auction", 1.0 - float(bands[0][1]), "Auction: %s" % item["name"])
	var tier = "big_war"
	for b in bands:
		if float(ar["roll"]) < float(b[1]):
			tier = str(b[0])
			break
	item["auction_roll"] = luck.roll_display(ar["roll"])
	var final_mult = {"flop": 0.0, "weak": rng.randf_range(0.55, 0.85), "normal": rng.randf_range(0.80, 1.05), "war": rng.randf_range(1.10, 1.40), "big_war": rng.randf_range(1.45, 2.00)}[tier]
	record_rng("Auction started for %s: interest boost %.0f%%. The final price stays hidden until it ends." % [item["name"], hype * 100.0], false)
	item["auctioned"] = true
	item["listed"] = false
	item["on_shop_floor"] = false
	item["auction_days_left"] = 3
	item["auction_final_price"] = max(1.0, round(center * final_mult))
	item["auction_tier"] = tier
	item["auction_current_bid"] = round(center * rng.randf_range(0.25, 0.60))
	add_toast("Auction started for %s. Ends in 3 days." % item["name"], "success")
	save_game()
	show_inventory()

func process_auctions():
	var to_remove = []
	for i in range(inventory.size()):
		var item = inventory[i]
		if not item["auctioned"]:
			continue
		item["auction_days_left"] -= 1
		if item["auction_days_left"] <= 0 and str(item["auction_tier"]) == "flop":
			# Reserve not met: nobody bid enough. Back in stock, listing fee lost.
			item["auctioned"] = false
			item["auction_days_left"] = 0
			cash -= 2.0
			day_stats["fees"] += 2.0
			night_events.append({"kind": "bad", "text": "Auction flop: %s" % item["name"], "sub": "The bids never reached the reserve (rolled %d). It's back in your stock (£2 listing fee lost)." % int(item.get("auction_roll", 0))})
			continue
		if item["auction_days_left"] <= 0:
			var final_price = float(item["auction_final_price"])
			var sniped = rng.randf() < 0.15
			if sniped:
				final_price = round(final_price * rng.randf_range(1.10, 1.25))
			record_rng("Auction result for %s: %s%s" % [item["name"], str(item["auction_tier"]).replace("_", " "), " + late snipe" if sniped else ""], false)
			var costs = selling_costs(item, final_price)
			costs["fee"] = float(costs["fee"]) + final_price * auction_fee_rate()
			var net = final_price - costs["fee"] - costs["postage"] - costs["insurance"] - costs["packaging"]
			cash += net
			var profit = record_completed_sale(item, final_price, costs, "auction")
			night_events.append({"kind": "sale", "text": "Auction: %s went for £%.0f" % [item["name"], final_price], "sub": "%s  (Rolled %d.)" % [auction_flavor_text(item["auction_tier"], sniped), int(item.get("auction_roll", 0))], "amount": final_price, "profit": profit})
			to_remove.append(i)
		else:
			var progress = (3.0 - float(item["auction_days_left"])) / 3.0
			var approach_frac = clamp(0.35 + progress * 0.35 + rng.randf_range(-0.15, 0.15), 0.2, 0.95)
			item["auction_current_bid"] = max(float(item["auction_current_bid"]), round(float(item.get("auction_center", true_market_value(item))) * approach_frac))
	for i in range(to_remove.size() - 1, -1, -1):
		inventory.remove_at(to_remove[i])

func create_listing_quiet(index, price):
	bulk_mode = true
	create_listing(index, price)
	bulk_mode = false

func test_item_quiet(index):
	bulk_mode = true
	test_item(index)
	bulk_mode = false

func create_listing(index, price_in):
	if index < 0 or index >= inventory.size():
		return
	var item = inventory[index]
	var price_val = price_in
	if typeof(price_in) == TYPE_OBJECT:
		if not is_instance_valid(price_in):
			return
		price_val = _parse_price(price_in.text)
	if item["auth_status"] == "Confirmed Counterfeit":
		queue_popup("You can't knowingly sell a counterfeit.")
		return
	if item["testable"] and not item["tested"]:
		queue_popup("Test it first: buyers want to know it works.")
		return
	if item["auctioned"] or item.get("consigned", false) or item.get("vaulted", false):
		return
	if not item["listed"] and active_listing_count() >= listing_cap():
		queue_popup("You're at your listing limit (%d). Bigger premises or a Light-Box Studio let you list more." % listing_cap())
		return
	var potential = estimate_identified_potential(item)
	var price = clamp(round(float(price_val)), 1.0, max(20.0, float(potential[1]) * 3.0))
	item["on_shop_floor"] = false
	if not item["listed"] or abs(float(item.get("listing", 0.0)) - price) >= 1.0:
		hist(item, "Listed online at %s." % fmt_money(price))
	item["listing"] = price
	item["listed"] = true
	item["listed_day"] = day
	var result = "no_sale"
	if int(item.get("instant_roll_day", -1)) < 0:
		# One first-day buyer per item, ever: relisting doesn't buy you another shot.
		item["instant_roll_day"] = day
		var interest = buyer_interest_score(item, price)
		var instant_chance = clamp(interest * 0.20, 0.0, 0.20)
		result = resolve_item_sale(item, instant_chance, "instant")
	if result == "sold_removed":
		inventory.remove_at(index)
		save_game()
	elif result != "returned":
		if not bulk_mode:
			add_toast("Listed %s at £%.0f. Buyers look overnight." % [item["name"], price], "success")
			play_sfx("confirm")
			save_game()
	if not bulk_mode:
		show_inventory()

func unlist_item(index):
	if index < 0 or index >= inventory.size():
		return
	inventory[index]["listed"] = false
	inventory[index]["listing"] = 0.0
	add_toast("Listing removed: %s" % inventory[index]["name"], "info")
	save_game()
	show_inventory()

func scrap_item(index):
	if index < 0 or index >= inventory.size():
		return
	var item = inventory[index]
	if item.get("vaulted", false):
		return
	var recovery = max(1.0, round(max(float(item["paid"]), perceived_center(item) * 0.3) * rng.randf_range(0.04, 0.18)))
	cash += recovery
	day_stats["other_income"] = float(day_stats.get("other_income", 0.0)) + recovery
	day_stats["items_scrapped"] += 1
	inventory.remove_at(index)
	unlock_achievement("Better Than Nothing")
	add_toast("Recovered £%.0f from scrap and parts." % recovery, "info")
	save_game()
	show_inventory()

func selling_costs(item, sale_price):
	var fee = sale_price * fee_rate()
	var postage = 2.70
	if item["size"] == "medium":
		postage = 5.20
	elif item["size"] == "large":
		postage = 8.50
	if sale_price < 10.0:
		postage *= 0.45
	elif sale_price < 20.0:
		postage *= 0.65
	elif sale_price < 35.0:
		postage *= 0.85
	var insurance = 0.0
	if sale_price >= 100.0:
		insurance = 3.50
	if sale_price >= 250.0:
		insurance = 6.50
	var packaging = 0.80
	if item["size"] == "medium":
		packaging = 1.50
	elif item["size"] == "large":
		packaging = 2.50
	if has_equip("packing"):
		packaging = 0.0
		postage *= 0.85
	return {"fee":fee, "postage":postage, "insurance":insurance, "packaging":packaging}

func record_completed_sale(item, sale_price, costs, channel):
	var net = sale_price - float(costs["fee"]) - float(costs["postage"]) - float(costs["insurance"]) - float(costs["packaging"])
	var sale_profit = net - float(item["paid"]) - float(item.get("extra_spend", 0.0))
	day_stats["sales_revenue"] += sale_price
	day_stats["fees"] += float(costs["fee"])
	day_stats["postage"] += float(costs["postage"]) + float(costs["insurance"]) + float(costs["packaging"])
	day_stats["items_sold"] += 1
	var missed = missed_traits_on_sale(item) if channel in ["listing", "instant", "shop"] else []
	hist(item, "Sold for %s %s." % [fmt_money(sale_price), sale_buyer_phrase(channel)])
	var missed_names = []
	for t in missed:
		missed_names.append(trait_def(t)["name"])
	var known_names = []
	for t in known_traits(item):
		if not missed.has(t):
			known_names.append(trait_def(t)["name"])
	sold_history.append({"name":item["name"], "price":sale_price, "day":day, "condition":item["condition"], "condition_checked":item["condition_checked"], "paid":item["paid"], "fee":costs["fee"], "postage":costs["postage"], "insurance":costs["insurance"], "packaging":costs["packaging"], "extra_spend":float(item.get("extra_spend", 0.0)), "channel":channel, "category":item["category"], "rarity":item["rarity"], "seller":item.get("seller", ""), "source":item.get("source", "stall"), "traits": known_names, "missed": missed_names, "from": item.get("bought_from", ""), "ident": str(item.get("ident", "")), "hist": item.get("hist", []).duplicate(true), "profit": sale_profit, "uid": int(item.get("uid", 0))})
	add_xp(5 + (5 if sale_profit > 0.0 else 0))
	if family_stats.has(item["name"]):
		var fs_sale = family_stats[item["name"]]
		fs_sale["highest_sold"] = max(float(fs_sale["highest_sold"]), sale_price)
		fs_sale["lifetime_profit"] = float(fs_sale["lifetime_profit"]) + sale_profit
	total_lifetime_profit += sale_profit
	day_stats["sale_profit"] = float(day_stats.get("sale_profit", 0.0)) + sale_profit
	world.add_player_profit(sale_profit)
	world.on_big_sale(item, sale_price, sale_profit)
	if int(item.get("from_reg", -1)) >= 0:
		var gem = false
		for t in known_traits(item):
			if float(t["mult"]) >= 1.3:
				gem = true
		world.remember(int(item["from_reg"]), {"kind": "sold", "item": item["name"], "price": float(item["paid"]), "sold": sale_price, "gem": gem})
	if in_end_day:
		log_activity("Overnight: sold %s for %s (%s)." % [item["name"], fmt_money(sale_price), money_signed(sale_profit)])
	if sale_profit > 0.0:
		day_stats["profitable_sales"] += 1
		unlock_achievement("First Flip")
	if sale_profit >= 200.0:
		unlock_achievement("Big Score")
	if channel in ["trader", "trade"]:
		add_expertise(item["category"], 2)
	else:
		add_expertise(item["category"], 8 + (4 if sale_profit > 0.0 else 0))
	if missed.size() > 0:
		var mline = "Missed on the %s: %s. %s" % [item["name"], ", ".join(missed_names), str(trait_def(missed[0]).get("missed", ""))]
		add_journal(mline, "bad")
		if in_end_day:
			night_events.append({"kind": "missed", "text": "You missed something on the %s" % item["name"], "sub": str(trait_def(missed[0]).get("missed", ", ".join(missed_names)))})
		else:
			add_toast(mline, "warn")
	return sale_profit

func resolve_item_sale(item, sale_chance, channel = "listing"):
	var sale_roll = rng.randf()
	var sold = sale_roll < sale_chance
	if sold:
		record_rng("%s @ £%.0f — buyer roll %.2f%% under the real chance of %.1f%% | SOLD" % [item["name"], float(item["listing"]), sale_roll * 100.0, sale_chance * 100.0], false)
	else:
		record_rng("%s @ £%.0f — buyer roll %.2f%% | no buyer (real odds hidden)" % [item["name"], float(item["listing"]), sale_roll * 100.0], false)
	if not sold:
		return "no_sale"
	var sale_price = float(item["listing"])
	var costs = selling_costs(item, sale_price)
	var net = sale_price - costs["fee"] - costs["postage"] - costs["insurance"] - costs["packaging"]
	cash += net
	var return_chance = 0.02
	var fake_unauth = false
	if item["auth_status"] != "Confirmed Genuine":
		return_chance += float(item["fake_chance"]) * 0.30
		if not item["authentic"]:
			return_chance += 0.45
			fake_unauth = true
	if item["fault"]:
		if fault_is_known(item):
			return_chance += 0.04
		else:
			return_chance += {"Minor": 0.08, "Moderate": 0.22, "Major": 0.42, "Dead": 0.65}.get(str(item["fault_severity"]), 0.3)
	if not item["condition_checked"]:
		return_chance += 0.06
	var trait_risk = unknown_trait_return_risk(item)
	return_chance += trait_risk
	var overprice = float(sale_price) / max(1.0, market_value(item))
	if overprice > 1.2:
		return_chance += min(0.10, (overprice - 1.2) * 0.2)
	return_chance = clamp(return_chance, 0.0, 0.85)
	var return_roll = rng.randf()
	var returned = return_roll < return_chance
	record_rng("%s — return chance %.1f%% | Rolled %.2f%% | %s" % [item["name"], return_chance * 100.0, return_roll * 100.0, "RETURNED" if returned else "kept"], false)
	if returned:
		cash -= sale_price
		day_stats["fees"] += costs["fee"]
		day_stats["postage"] += costs["postage"] + costs["insurance"] + costs["packaging"]
		day_stats["returns"] += 1
		item["listed"] = false
		item["listing"] = 0.0
		var hit = 1.0 if not has_perk("thick_skin") else 0.5
		var reason = "said it wasn't as described"
		if fake_unauth:
			reason = "says it's a fake, and filed a claim"
			seller_rating = max(0.0, seller_rating - 9.0 * hit)
			if item["auth_status"] != "Confirmed Counterfeit":
				item["auth_status"] = "Suspected Counterfeit"
				item["auth_attempted"] = false
		elif item["fault"] and not fault_is_known(item):
			reason = "found a fault you didn't mention"
			seller_rating = max(0.0, seller_rating - 5.0 * hit)
			if item["testable"]:
				item["tested"] = true
				item["test_note"] = "Buyer returned it with a %s fault." % item["fault_severity"]
			else:
				item["condition_checked"] = true
				item["condition_price_note"] = condition_reveal_note(item)
		elif trait_risk > 0.0:
			for t in item.get("traits", []):
				var d = trait_def(t)
				if not t.get("known", false) and d != null and d["kind"] != "good" and float(d.get("return_risk", 0.0)) > 0.0:
					t["known"] = true
					t["clue"] = true
					reason = "complained: %s" % d["name"].to_lower()
					break
			seller_rating = max(0.0, seller_rating - 4.0 * hit)
		else:
			seller_rating = max(0.0, seller_rating - 3.0 * hit)
		hist(item, "Sold for %s, then returned: the buyer %s." % [fmt_money(sale_price), reason])
		var msg = "RETURNED: %s. The buyer %s. Refunded £%.0f; fees and postage lost." % [item["name"], reason, sale_price]
		if in_end_day:
			night_events.append({"kind": "return", "text": "Returned: %s" % item["name"], "sub": "The buyer %s. -£%.0f" % [reason, sale_price], "amount": -(costs["fee"] + costs["postage"] + costs["insurance"] + costs["packaging"])})
		else:
			add_toast(msg, "error")
		add_journal("A buyer returned the %s: %s." % [item["name"], reason], "bad")
		play_sfx("fail")
		return "returned"
	seller_rating = min(100.0, seller_rating + 1.0)
	var sale_profit = record_completed_sale(item, sale_price, costs, channel)
	if in_end_day:
		night_events.append({"kind": "sale", "text": "Sold: %s for £%.0f" % [item_display_name(item), sale_price], "sub": buyer_message(item, sale_price), "amount": sale_price, "profit": sale_profit, "kind_name": item["name"]})
	else:
		add_toast("SOLD: %s for £%.0f (profit %s)" % [item["name"], sale_price, money_signed(sale_profit)], "success" if sale_profit >= 0.0 else "warn")
		fx_money(net)
	play_sfx("sale")
	return "sold_removed"

var listing_reports = []

func listing_report(item, interest):
	# Why hasn't it sold? Views and watchers come from the real buyer interest, so the hint is honest.
	var days = max(1, day - int(item.get("listed_day", day)) + 1)
	var r = float(item["listing"]) / max(1.0, market_value(item))
	var views = int(round(rng.randf_range(4.0, 10.0) * (0.7 + 0.35 * days) * clamp(1.35 - (r - 1.0) * 0.4, 0.5, 1.5)))
	var watchers = int(max(0.0, round(interest * 5.0 + rng.randf_range(-1.2, 0.8))))
	var key = "fine"
	var hidden_worse = market_value(item) < known_value(item) * 0.8
	if r > 1.35 and (not item["condition_checked"] or hidden_worse):
		key = "unchecked"
	elif r > 1.35:
		key = "too_high"
	elif float(current_trends.get(item["category"], 1.0)) < 0.9:
		key = "slow_category"
	elif watchers >= 2:
		key = "watchers"
	var hints = Lines012.NIGHT_LISTING_HINTS.get(key, [])
	if key == "unchecked":
		hints = ["Buyers are asking questions about {item}. Nobody's committing.", "Lots of views on {item}, no bites. Hard to say why.", "People keep zooming in on the photos of {item} and leaving."]
	var text = fill_line(pick_line(hints), {"item": "the " + lc(item["name"]), "cat": item["category"], "n": watchers})
	text = text.substr(0, 1).to_upper() + text.substr(1)
	return {"uid": int(item["uid"]), "name": item["name"], "ident": str(item.get("ident", "")), "price": float(item["listing"]), "days": days, "views": views, "watchers": watchers, "key": key, "text": text}

func drop_listing_price(uid, factor = 0.9):
	for item in inventory:
		if int(item["uid"]) == int(uid) and item["listed"]:
			var was = float(item["listing"])
			item["listing"] = max(1.0, round(was * factor))
			hist(item, "Price dropped to %s." % fmt_money(item["listing"]))
			add_toast("%s now %s (was %s)." % [item["name"], fmt_money(item["listing"]), fmt_money(was)], "info")
			save_game()
			return float(item["listing"])
	return 0.0

func process_sales():
	var to_remove = []
	for i in range(inventory.size()):
		var item = inventory[i]
		if not item["listed"]:
			continue
		if item["auth_status"] == "Confirmed Counterfeit":
			item["listed"] = false
			continue
		var interest = buyer_interest_score(item, float(item["listing"]))
		var chance = daily_sale_chance(interest)
		var result = resolve_item_sale(item, chance)
		if result == "sold_removed":
			to_remove.append(i)
		elif result == "no_sale" and item["listed"]:
			listing_reports.append(listing_report(item, interest))
	for j in range(to_remove.size() - 1, -1, -1):
		inventory.remove_at(to_remove[j])

func package_budget(tier):
	if tier == "Poor":
		return rng.randf_range(5, 20)
	if tier == "Average":
		return rng.randf_range(18, 35)
	if tier == "Good":
		return rng.randf_range(35, 60)
	if tier == "Excellent":
		return rng.randf_range(60, 120)
	if tier == "Jackpot":
		return rng.randf_range(150, 400)
	return rng.randf_range(500, 900)

func mystery_bands():
	# [[tier, cumulative chance from the best down]]
	var order = ["Grail", "Jackpot", "Excellent", "Good", "Average"]
	var out = []
	var cum = 0.0
	for t in order:
		for row in package_table:
			if row["tier"] == t:
				cum += float(row["chance"])
		out.append([t, cum])
	return out

func buy_mystery_package():
	if mystery_packages_left <= 0:
		queue_popup("No mystery packages left today.")
		return
	if cash < 30.0:
		queue_popup("You need £30 for a mystery package.")
		return
	if inventory_space_used() + 8 > storage_capacity():
		queue_popup("You need 8 free storage space before opening a package (it could hold two large items).")
		return
	cash -= 30.0
	day_stats["buy_spend"] += 30.0
	mystery_packages_left -= 1
	# Best tiers sit at the low end of the roll; anything under 45 is Average or better.
	var bands = mystery_bands()
	var mr = luck.roll("mystery", float(bands[bands.size() - 1][1]), "Mystery box")
	mr["label"] = "What's inside?"
	var mb = []
	var mcol = {"Grail": "purple", "Jackpot": "gold", "Excellent": "blue", "Good": "green", "Average": "green"}
	var mdesc = {"Grail": "£500–£900 inside", "Jackpot": "£150–£400 inside", "Excellent": "£60–£120 inside", "Good": "£35–£60 inside", "Average": "£18–£35 inside"}
	for b in bands:
		mb.append([b[0], b[1], mcol.get(b[0], "green"), mdesc.get(b[0], "")])
	luck.tier_bands(mr, mb, "Poor: £5–£20 inside")
	var tier = mr["band"] if mr["band"] != "" else "Poor"
	var count = 2 if rng.randf() < 0.30 else 1
	var budget = package_budget(tier)
	var contents = []
	for i in range(count):
		var source = "Collector" if tier in ["Excellent", "Jackpot", "Grail"] else "House Clearance"
		var item = generate_item(source)
		var share = budget / float(count) * rng.randf_range(0.85, 1.15)
		# Package value is rolled by tier; strip stall rarity so it can't double-dip.
		item["rarity"] = "Common"
		item["one_in"] = 1
		item["hidden_special"] = ""
		item["special_premium"] = 1.0
		var tp = 1.0
		for t in item.get("traits", []):
			tp *= float(t["mult"])
		item["true_value"] = max(1.0, share / condition_factor(int(item["condition"])) * tp)
		item["paid"] = 30.0 / float(count)
		item["asking"] = item["paid"]
		item["source"] = "package"
		item["story"] = "Came in a sealed mystery box."
		hist(item, "Pulled out of a mystery box.")
		inventory.append(item)
		register_collection(item)
		contents.append(item["name"])
	if tier == "Jackpot" or tier == "Grail":
		show_big_popup("MYSTERY BOX: %s!" % tier.to_upper(), "Inside: %s.\nThis one could be worth a lot." % ", ".join(contents), "rare")
	elif show_rolls and not sim_mode:
		show_roll("MYSTERY BOX", [mr], "%s box: %s. It's in your stock." % [tier, ", ".join(contents)])
	else:
		add_toast("Mystery box: %s. It's in your stock." % ", ".join(contents), "success" if tier in ["Good", "Excellent"] else "info")
	fx_money(-30.0)
	play_sfx("buy")
	save_game()
	show_stall()

func get_category_list():
	var cats = []
	for family in item_families:
		if not cats.has(family["category"]):
			cats.append(family["category"])
	cats.sort()
	return cats

func category_discovery_count(category):
	var found = 0
	var total = 0
	for family in item_families:
		if family["category"] != category:
			continue
		for tier_row in rarity_table:
			total += 1
			var key = category + "|" + family["name"] + "|" + tier_row["tier"]
			if discovered_log.has(key):
				found += 1
	return [found, total]

func grails_discovery_count():
	var found = 0
	for family in item_families:
		if family_stats.has(family["name"]) and family_stats[family["name"]]["highest_rarity"] == "Grail":
			found += 1
	return [found, item_families.size()]

func total_families_discovered():
	return [discovered_log.size(), item_families.size() * rarity_table.size()]

func sort_log(a, b):
	return int(a["one_in"]) > int(b["one_in"])

const ALL_ACHIEVEMENTS = {
	"First Flip": "Sell an item for more than you paid.",
	"Against the Odds": "Buy something 1-in-100 rare or rarer.",
	"Grail Hunter": "Buy a Grail-tier item.",
	"Big Score": "Make £200+ profit on a single sale.",
	"Grand Day Out": "Make £250+ cash profit in a single day.",
	"Survivor": "Climb out of the red after going overdrawn.",
	"Should've Known Better": "Have an authentication confirm a counterfeit.",
	"Better Than Nothing": "Scrap something for parts.",
	"Actually Mate...": "Get offered a seller's side deal.",
	"Level Headed": "Reach level 10.",
	"Challenge Crusher": "Complete 30 daily challenges.",
	"High Roller": "Win the Fixer's Gamble 5 times.",
	"Detective": "Identify 25 hidden details.",
	"Encyclopaedic": "Identify 100 different kinds of hidden detail.",
	"Treasure in the Lot": "Find a hidden item while sorting a lot.",
	"Missed It": "Sell something without spotting what made it special.",
	"Fixer-Upper": "Fix 10 problems with workshop kit.",
	"Specialist": "Become an Expert (tier 3) in any category.",
	"Authority": "Become an Authority (tier 4) in any category.",
	"Polymath": "Reach Enthusiast in 6 different categories.",
	"Friendly Face": "Become friends with a regular seller.",
	"Saved For You": "Buy something a regular put aside for you.",
	"Rain or Shine": "Buy something at a boot sale in a downpour.",
	"Early Riser": "Buy something at an Early Bird boot sale.",
	"Fair Game": "Buy something at a Collectors' Fair.",
	"House Call": "Complete a house clearance.",
	"Shopkeeper": "Sell 10 items from your shop floor.",
	"Van Man": "Buy a van.",
	"Empire": "Move into a warehouse.",
	"Car Boot King": "Complete every business goal.",
}

func unlock_achievement(name):
	if achievements.has(name):
		return
	achievements[name] = true
	add_journal("Achievement: %s." % name, "level")
	show_big_popup("ACHIEVEMENT UNLOCKED", "%s\n\n%s" % [name, ALL_ACHIEVEMENTS.get(name, "")], "achievement")

func record_rng(line, toast = true):
	last_rng_line = line
	if day_stats.has("rng_events"):
		day_stats["rng_events"].append(line)
		if day_stats["rng_events"].size() > 12:
			day_stats["rng_events"].pop_front()
	rng_log.append("Day %d %s  %s" % [day, format_time(), line])
	while rng_log.size() > 150:
		rng_log.pop_front()
	if toast and not in_end_day and show_rng_toasts:
		add_toast("RNG  " + line, "rng", false)

func chance_text(chance):
	if chance <= 0.0:
		return "0%"
	var pct = chance * 100.0
	var one = int(round(1.0 / chance))
	if chance < 0.10:
		return "%.2f%% (1/%d)" % [pct, one]
	return "%.1f%%" % pct

func inventory_estimated_net():
	var total = 0.0
	for item in inventory:
		if item["auth_status"] == "Confirmed Counterfeit":
			continue
		var c = perceived_center(item)
		var costs = selling_costs(item, c)
		total += max(0.0, c - float(costs["fee"]) - float(costs["postage"]) - float(costs["insurance"]) - float(costs["packaging"]))
	return total

func inventory_book_value():
	# What the player can reasonably count on: what they paid, not the hidden truth.
	var total = 0.0
	for item in inventory:
		total += float(item["paid"])
	return total

func end_day():
	if game_over or on_title_screen or in_end_day:
		return
	in_end_day = true
	clear_toasts()
	night_events = []
	listing_reports = []
	if pending_special_offer != null:
		pending_special_offer = null
	if clearance != null:
		remove_lead(int(clearance["lead"]["id"]))
		clearance = null
	var closing_day = day
	var start_cash = float(day_stats["start_cash"])
	var cash_before_resolution = cash
	var live_rng = rng
	rng = day_rng(closing_day, "night")
	process_sales()
	process_auctions()
	process_shop_floor()
	process_staff()
	world.gaz_night()
	trade.resolve_saleroom()
	world.check_big_finds()
	if closing_day % 7 == 0:
		world.week_rollover()
	for item in inventory:
		item["days_owned"] = int(item.get("days_owned", 0)) + 1
	var running = running_costs()
	var pitch = float(daily_expenses)
	cash -= pitch
	cash -= float(running["total"])
	day_stats["rent"] = pitch
	day_stats["upkeep"] = float(running["total"])
	day_stats["running"] = running
	day_stats["expenses"] += pitch + float(running["total"])
	if cash < 0:
		var interest = abs(cash) * 0.06
		cash -= interest
		day_stats["interest"] = interest
		day_stats["expenses"] += interest
		# The bank only calls it in when your stock couldn't plausibly cover the hole.
		if cash + inventory_book_value() * 0.4 < 0.0:
			negative_days_streak += 1
		else:
			negative_days_streak = 0
	else:
		if negative_days_streak > 0:
			unlock_achievement("Survivor")
		negative_days_streak = 0
	if cash - start_cash >= 250.0:
		unlock_achievement("Grand Day Out")
	check_daily_challenge_rewards()
	check_daily_challenge_bonus()
	expire_leads()
	var summary = {
		"start_worth": float(day_stats.get("start_worth", start_cash)),
		"end_worth": business_value(),
		"day": closing_day,
		"start_cash": start_cash,
		"end_cash": cash,
		"overnight_cash": cash - cash_before_resolution,
		"stats": day_stats.duplicate(true),
		"challenges_done": daily_challenges_completed_count(),
		"challenges_total": daily_challenges.size(),
		"streak": negative_days_streak,
		"events": night_events.duplicate(true),
		"listings": listing_reports.duplicate(true),
		"pitch": pitch,
		"running": running,
	}
	best_net_worth = max(best_net_worth, business_value())
	rng = live_rng
	in_end_day = false
	if negative_days_streak >= 4:
		game_over = true
		save_game()
		play_sfx("fail")
		show_bankruptcy_screen()
		return
	day += 1
	if (day - 1) % 7 == 0:
		rng = day_rng(day, "week")
		generate_weekly_trends()
		weekly_regular_churn()
		rng = live_rng
	reset_day_stats()
	generate_day_seeded()
	check_goals()
	check_progress_achievements()
	save_game()
	show_day_summary(summary)

func start_new_game():
	init_new_run()
	save_game()
	has_save = true
	on_title_screen = false
	play_sfx("confirm")
	if not tutorial_seen:
		tutorial_slide_index = 0
		show_tutorial()
	else:
		show_market()

func restart_game():
	start_new_game()


func log_activity(text):
	var clean = str(text)
	var re = RegEx.new()
	re.compile("\\[/?[a-z]+(=[^\\]]*)?\\]")
	clean = re.sub(clean, "", true)
	activity_log.append("Day %d %s  %s" % [day, format_time(), clean])
	while activity_log.size() > 150:
		activity_log.pop_front()

const SETTINGS_PATH = "user://settings.cfg"
var master_volume = 0.8
var sfx_enabled = true
var ui_scale = 1.0
var fullscreen = false
var show_rng_toasts = false
var show_rolls = true
# Roll cards: "auto" (the full key the first few times per kind, then slim), "full", "slim" or "off".
var roll_mode = "auto"
var roll_seen = {}

func load_settings():
	var cfg = ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		ui_scale = 1.0
		return
	master_volume = float(cfg.get_value("audio", "master_volume", 0.8))
	sfx_enabled = to_bool(cfg.get_value("audio", "sfx_enabled", true))
	ui_scale = float(cfg.get_value("display", "ui_scale2", 1.0))
	fullscreen = to_bool(cfg.get_value("display", "fullscreen", false))
	show_rng_toasts = to_bool(cfg.get_value("gameplay", "show_dice_popups", false))
	show_rolls = to_bool(cfg.get_value("gameplay", "show_rolls", true))
	roll_mode = str(cfg.get_value("gameplay", "roll_mode", "auto" if show_rolls else "off"))
	if not roll_mode in ["auto", "full", "slim", "off"]:
		roll_mode = "auto"
	show_rolls = roll_mode != "off"
	var rs = cfg.get_value("gameplay", "roll_seen", {})
	roll_seen = rs if typeof(rs) == TYPE_DICTIONARY else {}
	music_volume = float(cfg.get_value("audio", "music_volume", 0.5))
	var ts = cfg.get_value("gameplay", "tips_seen", {})
	tips_seen = ts if typeof(ts) == TYPE_DICTIONARY else {}

func save_settings():
	var cfg = ConfigFile.new()
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("audio", "sfx_enabled", sfx_enabled)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("display", "ui_scale2", ui_scale)
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("gameplay", "show_dice_popups", show_rng_toasts)
	cfg.set_value("gameplay", "show_rolls", show_rolls)
	cfg.set_value("gameplay", "roll_mode", roll_mode)
	cfg.set_value("gameplay", "roll_seen", roll_seen)
	cfg.set_value("gameplay", "tips_seen", tips_seen)
	cfg.save(SETTINGS_PATH)

func apply_settings():
	var bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(max(master_volume, 0.0001)))
	AudioServer.set_bus_mute(bus, master_volume <= 0.001)
	if not OS.has_feature("web") and DisplayServer.get_name() != "headless":
		var want = DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != want:
			DisplayServer.window_set_mode(want)
	adjust_scale_for_device()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if has_save and not on_title_screen and not sim_mode:
			save_game()

var sfx_streams = {}
var music_player
var music_volume = 0.5

func apply_music_volume():
	if music_player == null:
		return
	music_player.volume_db = linear_to_db(max(music_volume, 0.0001)) - 6.0
	if music_volume <= 0.001:
		music_player.stop()
	elif not music_player.playing:
		music_player.play()
var sfx_players = []
var sfx_next = 0
const SFX_RATE = 22050

func _synth(notes, wave = "square", volume = 0.35):
	# notes: array of [freq_hz, duration_s, start_s]
	var total = 0.0
	for n in notes:
		total = max(total, float(n[2]) + float(n[1]))
	var count = int(total * SFX_RATE) + 1
	var buf = PackedFloat32Array()
	buf.resize(count)
	for n in notes:
		var f = float(n[0])
		var d = float(n[1])
		var s0 = int(float(n[2]) * SFX_RATE)
		var len = int(d * SFX_RATE)
		var phase = 0.0
		for i in range(len):
			var t = float(i) / SFX_RATE
			var env = min(1.0, t / 0.004) * pow(max(0.0, 1.0 - t / d), 1.6)
			var v = 0.0
			if f <= 0.0:
				v = randf() * 2.0 - 1.0
			else:
				phase += f / SFX_RATE
				var p = fmod(phase, 1.0)
				if wave == "square":
					v = 1.0 if p < 0.5 else -1.0
				elif wave == "tri":
					v = 4.0 * abs(p - 0.5) - 1.0
				else:
					v = sin(p * TAU)
			var idx = s0 + i
			if idx < count:
				buf[idx] += v * env * volume
	var bytes = PackedByteArray()
	bytes.resize(count * 2)
	for i in range(count):
		bytes.encode_s16(i * 2, int(clamp(buf[i], -1.0, 1.0) * 32000.0))
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SFX_RATE
	stream.stereo = false
	stream.data = bytes
	return stream

func build_audio():
	if sim_mode:
		return
	sfx_streams["click"] = _synth([[1400, 0.025, 0.0]], "square", 0.12)
	sfx_streams["confirm"] = _synth([[660, 0.07, 0.0], [990, 0.10, 0.06]], "tri", 0.35)
	sfx_streams["error"] = _synth([[196, 0.12, 0.0], [147, 0.16, 0.10]], "square", 0.16)
	sfx_streams["coin"] = _synth([[1318, 0.06, 0.0], [1760, 0.16, 0.05]], "square", 0.14)
	sfx_streams["buy"] = _synth([[523, 0.06, 0.0], [784, 0.12, 0.05]], "tri", 0.38)
	sfx_streams["sale"] = _synth([[1568, 0.09, 0.0], [2093, 0.30, 0.08], [0, 0.05, 0.0]], "square", 0.12)
	sfx_streams["fail"] = _synth([[330, 0.14, 0.0], [262, 0.14, 0.13], [196, 0.35, 0.26]], "tri", 0.40)
	sfx_streams["haggle_ok"] = _synth([[587, 0.07, 0.0], [880, 0.14, 0.07]], "tri", 0.38)
	sfx_streams["haggle_no"] = _synth([[247, 0.10, 0.0], [220, 0.18, 0.09]], "tri", 0.40)
	sfx_streams["reveal"] = _synth([[880, 0.05, 0.0], [1175, 0.08, 0.04]], "sine", 0.35)
	sfx_streams["levelup"] = _synth([[523, 0.10, 0.0], [659, 0.10, 0.09], [784, 0.10, 0.18], [1047, 0.35, 0.27]], "square", 0.12)
	sfx_streams["rare"] = _synth([[784, 0.08, 0.0], [988, 0.08, 0.07], [1175, 0.08, 0.14], [1568, 0.40, 0.21]], "tri", 0.40)
	sfx_streams["grail"] = _synth([[523, 0.12, 0.0], [659, 0.12, 0.11], [784, 0.12, 0.22], [1047, 0.12, 0.33], [1319, 0.12, 0.44], [1568, 0.7, 0.55], [2093, 0.7, 0.55]], "tri", 0.32)
	sfx_streams["day_good"] = _synth([[392, 0.10, 0.0], [523, 0.10, 0.10], [659, 0.30, 0.20]], "tri", 0.35)
	sfx_streams["day_bad"] = _synth([[392, 0.14, 0.0], [311, 0.35, 0.14]], "tri", 0.35)
	sfx_streams["page"] = _synth([[0, 0.03, 0.0]], "square", 0.05)
	for i in range(6):
		var p = AudioStreamPlayer.new()
		add_child(p)
		sfx_players.append(p)
	if ResourceLoader.exists("res://audio/music_carboot.wav"):
		music_player = AudioStreamPlayer.new()
		music_player.stream = load("res://audio/music_carboot.wav")
		music_player.finished.connect(func(): music_player.play())
		add_child(music_player)
		apply_music_volume()
		if music_volume > 0.001:
			music_player.play()

func _safe_focus(node):
	if is_instance_valid(node) and node.is_inside_tree() and node.is_visible_in_tree():
		node.grab_focus()

func play_sfx(name):
	if sim_mode or not sfx_enabled or sfx_players.size() == 0 or not sfx_streams.has(name):
		return
	var p = sfx_players[sfx_next]
	sfx_next = (sfx_next + 1) % sfx_players.size()
	p.stream = sfx_streams[name]
	p.play()

func bug_report_text():
	var lines = []
	lines.append("Car Boot Reseller %s" % GAME_VERSION)
	lines.append("OS: %s  •  Godot %s  •  Window %s" % [OS.get_name(), Engine.get_version_info().get("string", "?"), str(get_window().size) if is_inside_tree() else "?"])
	lines.append("Day %d %s  •  Cash £%.2f  •  Stock %d  •  Level %d" % [day, format_time(), cash, inventory.size(), player_level])
	lines.append("Screen: %s" % current_screen_name)
	lines.append("Recent activity:")
	for i in range(max(0, activity_log.size() - 8), activity_log.size()):
		lines.append("  " + str(activity_log[i]))
	lines.append("Save code:")
	lines.append(export_save_code())
	return "\n".join(lines)

var patch_notes = [
	{"version": "0.14: High Stakes", "notes": [
		"The Vault (Business, once you have the shop): hold your best pieces out of stock. Every week the market moves on each one, and you see the roll: collector frenzy +60%, climbing +25%, up +10%, flat, or slipped −15%. Trends, rarity and a collection in one category tilt the odds.",
		"Taped-up boxes: some stalls sell one unopened. Odds shown up front (Treasure, Good, Fair, Junk), and your expertise in the box's category improves them.",
		"The back room: once a week (day 6 of each week), the Fixer runs a dealers' card game. Stake a researched piece against the pot. The bigger your stake against the pot, the better your odds. Winner takes the lot.",
		"Scratch cards: after a good day, the night report offers one for 5% of your profit. 1% 20×, 4% 5×, 15% 2×, 25% money back.",
	]},
	{"version": "0.13.4: A runner who helps", "notes": [
		"The runner brings back fewer, better buys: up to 2 a night by default (you choose 1–3 on the Business screen).",
		"Everything he brings is already checked, researched and tested (£2 an item), so it costs you no energy.",
		"He lists them for you at fair prices, if you leave that switched on. Reprice or pull them whenever you like.",
	]},
	{"version": "0.13.3: Deep research pays", "notes": [
		"A deep research Find now always gets you something: the provenance is written up, and buyers pay 5% more for it.",
		"The books also name specialist details (expert and eye marks) up to one tier past your own expertise.",
		"Rare find and Jackpot write up full provenance (+10%).",
	]},
	{"version": "0.13.2: Out of the way", "notes": [
		"Roll cards and notices never block a click: tap or click straight through them.",
		"After the first few rolls of each kind, the card shrinks to a slim bar: zones, the number, one line of result. On PC it sits in the sidebar, clear of the stalls and the Buy button.",
		"Settings → Roll cards: Auto, Full, Slim or Off.",
		"Fewer, shorter notices on PC (two at a time).",
	]},
	{"version": "0.13.1: Rare rolls", "notes": [
		"Every roll card now has a key: each zone of the bar is labelled with the roll you need and what it gets you, before the marker lands.",
		"Rarer outcomes sit inside the hit zone. Research and deep research: under 10 is a Rare find (one extra hidden detail, or your fee back), under 2 is the Jackpot (everything, fee back).",
		"Repairs: Perfect fix / Restored (condition +1). Cleaning: Like new (+2 condition). The Fixer: Treble. Coin toss: it can land on its edge. Mystery boxes and the tombola show what every tier holds.",
		"Rolls now read 0.0–99.9. Lower is better.",
	]},
	{"version": "0.13: Odds On", "notes": [
		"Every gamble shows its odds first and the roll it hit afterwards: research, deep research, long shots on clues, repairs, cleaning, auctions, the Fixer and mystery boxes.",
		"Dig again: another roll on the same item, a little dearer each time.",
		"Chancer sellers will toss you for it. The tombola turns up at some markets.",
		"Journal → Luck: your hits against expected, and your luckiest and unluckiest rolls.",
	]},
	{"version": "0.12: The Living Market", "notes": [
		"Haggling is a conversation: sellers counter, lose patience and name a final price. Point out flaws you've found; research in front of a sharp dealer and the price may go up.",
		"Every item has its own pixel art, a specific identity, where it came from, and a story that follows it until it sells. Your best deals go in the Best flips scrapbook.",
		"Gaz, your rival, has an online shop you can raid, a weekly scoreboard, and texts when he flips something you walked past.",
		"Regulars remember what you really bought and sold. Wanted requests, specialist phone calls for big finds, the weekly Valuation Tent, and one odd thing per market day.",
		"Late game: signature categories, the weekly Saleroom (bid, or consign your own finds), estate sales with sealed bids, category bubbles, and a Runner who works a second market.",
		"The night report leads with profit and explains why listings aren't selling, with one-tap price drops.",
	]},
	{"version": "0.11: The Business Update", "notes": [
		"Discoveries, Expertise, the Business (premises, vehicles, workshop, staff), a living market, and a new interface for desktop and phones.",
	]},
	{"version": "Known rough edges", "notes": [
		"Balance is still being tuned, especially past the warehouse.",
		"An item's name can occasionally contradict what you later discover about it.",
	]},
]

func channel_name(c):
	return {"listing": "online", "instant": "online, first day", "trader": "trader", "auction": "auction", "shop": "shop floor", "collector": "collector", "trade": "trade buyer"}.get(c, c)

func sale_profit_of(sale):
	var costs_total = float(sale.get("fee", 0.0)) + float(sale.get("postage", 0.0)) + float(sale.get("insurance", 0.0)) + float(sale.get("packaging", 0.0))
	return float(sale["price"]) - costs_total - float(sale.get("paid", 0.0)) - float(sale.get("extra_spend", 0.0))

var goals_done = 0
var business_goals = [
	{"id": "first_sale", "text": "Make your first sale", "xp": 15},
	{"id": "five_profit", "text": "Sell 5 items at a profit", "xp": 20},
	{"id": "discovery", "text": "Identify a hidden detail on an item", "xp": 20},
	{"id": "trolley", "text": "Buy a Shopping Trolley (Business)", "xp": 20},
	{"id": "kit", "text": "Install your first piece of workshop kit", "xp": 25},
	{"id": "level3", "text": "Reach level 3", "xp": 25},
	{"id": "worth800", "text": "Reach £800 business value", "xp": 30},
	{"id": "enthusiast", "text": "Become an Enthusiast in any category", "xp": 30},
	{"id": "garage", "text": "Rent a garage", "xp": 40},
	{"id": "regular", "text": "Become a regular at someone's stall", "xp": 30},
	{"id": "specialist", "text": "Become a Specialist in any category", "xp": 40},
	{"id": "worth2k", "text": "Reach £2,000 business value", "xp": 50},
	{"id": "estate_car", "text": "Buy an estate car", "xp": 50},
	{"id": "signature", "text": "Make a category your signature (Expertise)", "xp": 40},
	{"id": "commission", "text": "Fill a Wanted request", "xp": 45},
	{"id": "lockup", "text": "Move into an industrial lock-up", "xp": 60},
	{"id": "beat_gaz", "text": "Beat Gaz over a week", "xp": 50},
	{"id": "van", "text": "Buy a van", "xp": 70},
	{"id": "clearance", "text": "Do a house clearance", "xp": 70},
	{"id": "expert", "text": "Become an Expert in a signature", "xp": 80},
	{"id": "saleroom", "text": "Win a lot at the Saleroom", "xp": 70},
	{"id": "shop", "text": "Open a High Street shop", "xp": 100},
	{"id": "estate", "text": "Win an estate sale with a sealed bid (Luton van)", "xp": 110},
	{"id": "worth20k", "text": "Reach £20,000 business value", "xp": 120},
	{"id": "authority", "text": "Become an Authority", "xp": 130},
	{"id": "warehouse", "text": "Move into a warehouse", "xp": 150},
	{"id": "gaz10", "text": "Beat Gaz in ten weeks", "xp": 150},
	{"id": "worth35k", "text": "Reach £35,000 business value", "xp": 180},
	{"id": "king", "text": "Reach £60,000 business value: Car Boot King", "xp": 250},
]
# 0.11 goal order, for migrating old saves' progress.
const OLD_GOAL_IDS = ["first_sale", "five_profit", "discovery", "trolley", "kit", "level3", "worth800", "enthusiast", "garage", "regular", "specialist", "worth2k", "estate_car", "lockup", "van", "clearance", "expert", "shop", "worth20k", "warehouse", "king"]

func goal_index(id):
	for i in range(business_goals.size()):
		if business_goals[i]["id"] == id:
			return i
	return -1

func channel_count(ch):
	var n = 0
	for s2 in sold_history:
		if str(s2.get("channel", "")) == ch:
			n += 1
	return n

func profitable_sales_count():
	var n = 0
	for sale in sold_history:
		if sale_profit_of(sale) > 0.0:
			n += 1
	return n

func goal_met(index):
	var worth = business_value()
	var d = world.st()
	match str(business_goals[index]["id"]):
		"first_sale":
			return sold_history.size() >= 1
		"five_profit":
			return profitable_sales_count() >= 5
		"discovery":
			return discoveries_log.size() >= 1
		"trolley":
			return vehicle_level >= 1
		"kit":
			return workshop_slots_used() >= 1
		"level3":
			return player_level >= 3
		"worth800":
			return worth >= 800.0
		"enthusiast":
			return max_expertise_tier() >= 1
		"garage":
			return premises_level >= 1
		"regular":
			return best_rel() >= 35.0
		"specialist":
			return max_expertise_tier() >= 2
		"worth2k":
			return worth >= 2000.0
		"estate_car":
			return vehicle_level >= 2
		"signature":
			return signatures.size() >= 1
		"commission":
			return channel_count("commission") >= 1
		"lockup":
			return premises_level >= 2
		"beat_gaz":
			return int(d["record"]["wins"]) >= 1
		"van":
			return vehicle_level >= 3
		"clearance":
			return achievements.has("House Call")
		"expert":
			return max_expertise_tier() >= 3
		"saleroom":
			return int(d.get("saleroom_wins", 0)) >= 1
		"shop":
			return premises_level >= 3
		"estate":
			return int(d.get("estates_won", 0)) >= 1
		"worth20k":
			return worth >= 20000.0
		"authority":
			return max_expertise_tier() >= 4
		"warehouse":
			return premises_level >= 4
		"gaz10":
			return int(d["record"]["wins"]) >= 10
		"worth35k":
			return worth >= 35000.0
		"king":
			return worth >= 60000.0
	return false

func check_goals():
	var guard = 0
	while goals_done < business_goals.size() and goal_met(goals_done) and guard < 25:
		guard += 1
		var g = business_goals[goals_done]
		goals_done += 1
		add_xp(int(g["xp"]))
		var next_text = ("Next: " + business_goals[goals_done]["text"]) if goals_done < business_goals.size() else "That's every goal. You're the Car Boot King."
		show_big_popup("GOAL COMPLETE", "%s\n+%d XP\n\n%s" % [g["text"], int(g["xp"]), next_text], "achievement")
		if goals_done >= business_goals.size():
			unlock_achievement("Car Boot King")

func current_goal_text():
	if goals_done >= business_goals.size():
		return "All goals complete"
	return business_goals[goals_done]["text"]
func bulk_list_at_estimate():
	var listed = 0
	var skipped = 0
	var loss_skipped = 0
	var capped = 0
	for i in range(inventory.size() - 1, -1, -1):
		if i >= inventory.size():
			continue
		var item = inventory[i]
		if item["listed"] or item["auctioned"] or item.get("on_shop_floor", false) or item.get("vaulted", false) or item.get("consigned", false):
			continue
		if (item["testable"] and not item["tested"]) or item["auth_status"] == "Confirmed Counterfeit":
			skipped += 1
			continue
		if active_listing_count() >= listing_cap():
			capped += 1
			continue
		var mid = suggested_price(item)
		if estimated_profit_at(item, mid) < 0.0:
			loss_skipped += 1
			continue
		create_listing_quiet(i, mid)
		listed += 1
	var extra = ""
	if skipped > 0:
		extra += " %d need testing first." % skipped
	if loss_skipped > 0:
		extra += " %d would sell at a loss: price those yourself." % loss_skipped
	if capped > 0:
		extra += " %d didn't fit under your listing limit." % capped
	add_toast("Listed %d item%s at your estimate.%s" % [listed, "" if listed == 1 else "s", extra], "success")
	save_game()
	show_inventory()

func bulk_test_all():
	var n = 0
	bulk_mode = true
	for i in range(inventory.size()):
		var item = inventory[i]
		if item["testable"] and not item["tested"]:
			if cash < test_cost() or energy < test_energy():
				queue_popup("Ran out of cash or energy after testing %d." % n)
				break
			test_item(i)
			n += 1
	bulk_mode = false
	if n > 0:
		add_toast("Tested %d item%s." % [n, "" if n == 1 else "s"], "info")
	show_inventory()

func _debug_force_offer():
	pending_special_offer = generate_special_offer("Collector", "Arran the Collector")
	show_special_offer()

func to_bool(v):
	match typeof(v):
		TYPE_BOOL:
			return v
		TYPE_INT, TYPE_FLOAT:
			return v != 0
		TYPE_STRING, TYPE_STRING_NAME:
			return str(v).to_lower() in ["true", "1", "yes"]
		TYPE_NIL:
			return false
	return true

# ---------------------------------------------------------------------------
# First-time tips (remembered across runs in settings.cfg)
# ---------------------------------------------------------------------------
var tips_seen = {}
const TIPS = {
	"inventory": "Your stock. The price range shown is YOUR estimate and it can be wrong. Check Condition, Research and Deep Research narrow it down. Electrical items must be tested before you can sell them. When you're happy with a price, List it: buyers turn up overnight when you End Day.",
	"for_sale": "Listed items get one shot at an instant buyer today, then a buyer roll every night. The real odds depend on what the item's actually worth, so if nothing bites for a few days you may be asking more than buyers think it's worth.",
	"summary": "Every night you pay the pitch fee (plus upkeep on upgrades) and buyers roll for everything you've listed. 'Business value' counts stock at what you paid, so buying stock doesn't look like a loss. Four nights in a row in the red means bankruptcy.",
	"shop": "Upgrades cost money now and a little upkeep every day. A bigger bag lets you carry more per trip; more storage lets you hold more stock at home. Don't spend your last trading cash.",
	"stalls": "Every stall packs up at a different time, so plan your route. Walking between stalls costs 5 minutes.",
}


func inspect_clue_text(pc):
	if pc <= 3:
		return "Looks rough: wear or damage likely."
	if pc <= 5:
		return "Fairly worn, hard to judge for sure."
	if pc <= 7:
		return "Looks reasonably tidy."
	return "Looks very clean and well-kept."

func do_check_condition(where, index):
	var item = item_at(where, index)
	if item == null or item["condition_checked"]:
		return
	var cc_cost = condition_cost()
	if cash < cc_cost or energy < 4:
		queue_popup("Checking condition needs £%d and 4 energy." % int(cc_cost))
		return
	var before = estimate_identified_potential(item)
	cash -= cc_cost
	item["extra_spend"] += cc_cost
	energy -= 4
	spend_time(5)
	day_stats["research"] += cc_cost
	item["condition_checked"] = true
	item["action_order"].append("condition")
	update_family_condition(item)
	day_stats["condition_checks"] += 1
	add_expertise(item["category"], 1)
	item["condition_price_note"] = condition_reveal_note(item)
	var found = reveal_traits(item, "condition")
	var message = "Condition %d/10." % item["condition"]
	if item["testable"] and not item["tested"]:
		message += " Whether it works stays unknown until you test it."
	elif item["testable"]:
		message += " Tested: %s." % ("works" if not item["fault"] else fault_label(item).to_lower())
	elif item["fault"]:
		message += " Hidden flaw: %s." % fault_label(item)
	elif found.size() == 0:
		message += " No hidden defects."
	if where == "inv":
		var after = estimate_identified_potential(item)
		item["condition_price_note"] += "\nYour estimate: £%d–£%d → £%d–£%d" % [before[0], before[1], after[0], after[1]]
	log_activity(message)
	play_sfx("reveal")
	refresh_after(where)

func do_research(where, index):
	var item = item_at(where, index)
	if item == null or item["basic_researched"]:
		return
	var rc_cost = research_cost()
	if cash < rc_cost or energy < 2:
		queue_popup("Research needs %s and 2 energy." % fmt_money(rc_cost))
		return
	cash -= rc_cost
	item["extra_spend"] += rc_cost
	energy -= 2
	spend_time(4)
	day_stats["research"] += rc_cost
	day_stats["researches_done"] += 1
	add_expertise(item["category"], 2 if has_equip("library") else 1)
	item["basic_researched"] = true
	item["action_order"].append("research")
	var res = luck.do_dig(item, "research", where, rc_cost)
	item["basic_comps"] = make_comps(item, false)
	item["locked_gamble_hint"] = gamble_hint_chance(item)
	item["research_note"] = luck.dig_result_text(item, "research", res)
	show_roll("RESEARCH", res["entries"], item["research_note"])
	if where == "stall" and current_stall_index >= 0 and current_stall_index < stalls.size():
		seller_notices(stalls[current_stall_index], item)
	play_sfx("reveal")
	refresh_after(where)

func dig_again(where, index, method):
	# Another go at the same item: costs a bit more each time.
	var item = item_at(where, index)
	if item == null or not luck.can_dig_again(item, method):
		return
	var cost = luck.dig_cost(item, method)
	var en = luck.dig_energy(method)
	if cash < cost or energy < en:
		queue_popup("Digging again needs %s and %d energy." % [fmt_money(cost), en])
		return
	cash -= cost
	item["extra_spend"] += cost
	energy -= en
	spend_time(4 if method == "research" else 15)
	day_stats["research"] += cost
	var res = luck.do_dig(item, method, where, cost)
	var note = luck.dig_result_text(item, method, res)
	if method == "research":
		item["research_note"] = note
	else:
		item["deep_note"] = note
	if res["found"].size() > 0:
		item["basic_comps"] = make_comps(item, method == "deep")
	hist(item, "Dug again (%s): %s" % ["research" if method == "research" else "deep research", note.to_lower()])
	show_roll("DIG AGAIN", res["entries"], note)
	play_sfx("reveal")
	refresh_after(where)

func show_roll(title, entries, text):
	# The visible dice: odds, the roll, hit or miss.
	if sim_mode or ui == null or entries.size() == 0:
		return
	if show_rolls:
		var slim = roll_mode == "slim"
		if roll_mode == "auto":
			# Learn it properly a few times, then it gets out of the way.
			var n = int(roll_seen.get(title, 0))
			slim = n >= 3
			if n < 3:
				roll_seen[title] = n + 1
				save_settings()
		ui.roll_card(title, entries, text, slim)
	else:
		add_toast(text, "info")

func stall_haggle_bonus(stall):
	var b = 0.0
	var p = personality_of(stall)
	if p != null:
		b += float(p.get("haggle_mod", 0.0))
	var r = regular_by_id(int(stall.get("regular_id", -1))) if int(stall.get("regular_id", -1)) >= 0 else null
	if r != null:
		b += clamp(float(r["rel"]), -50.0, 100.0) * 0.0015
	return b

func haggle_chance_here(index, offer):
	if not valid_stall_index(index):
		return 0.0
	var stall = stalls[current_stall_index]
	return compute_haggle_chance(stall["stock"][index], stall["seller"], offer, stall)

func test_cost():
	return 0.0 if has_equip("test_rig") else 2.0

func test_energy():
	return 2 if has_equip("test_rig") else 5

func repair_bonus():
	return [0.0, 0.08, 0.18, 0.30][clamp(equip_level("repair"), 0, 3)]

func can_repair(item):
	if not has_equip("repair"):
		return false
	if item["repair_attempted"]:
		return false
	return (item["fault"] and fault_is_known(item)) or known_fixable(item, "repair").size() > 0

func listing_appeal_mult():
	var m = 1.0
	if has_equip("photo", 1):
		m *= 1.06
	if has_equip("photo", 2):
		m *= 1.06
	if has_perk("good_photos"):
		m *= 1.06
	return m

func auctions_unlocked():
	return player_level >= 6 or has_perk("auctioneer")

func auction_fee_rate():
	return 0.04 if has_perk("auctioneer") else 0.08

func _init():
	if _content_cache == null:
		_content_cache = ContentScript.new()
	content = _content_cache
	item_families = content.families

func _ready():
	rng.randomize()
	load_settings()
	has_save = load_game()
	if not has_save:
		init_new_run()
	ui = UIRoot.new()
	ui.setup(self)
	build_audio()
	apply_settings()
	show_title_screen()

func day_rng(d, stream):
	var r = RandomNumberGenerator.new()
	r.seed = hash([int(run_seed), int(d), str(stream)])
	return r

func generate_day_seeded():
	var live = rng
	rng = day_rng(day, "market")
	generate_day()
	rng = live

func init_new_run():
	# 0.12 state lives outside the old reset list: clear it first so a new game starts clean.
	w2 = {}
	signatures = []
	signature_changed_day = -99
	signature_nagged = {}
	lines_used_today = {}
	# Resets every piece of run state. Settings and tutorial_seen survive.
	if forced_run_seed >= 0:
		run_seed = forced_run_seed
	else:
		var seeder = RandomNumberGenerator.new()
		seeder.randomize()
		run_seed = seeder.randi()
	rng.seed = hash([run_seed, "live"])
	day = 1
	cash = STARTING_CASH
	energy = 100
	player_level = 1
	player_xp = 0
	current_time_minutes = 7 * 60
	daily_expenses = 6.50
	current_stall_index = 0
	stalls = []
	inventory = []
	sold_history = []
	discovered_log = {}
	family_stats = {}
	achievements = {}
	negative_days_streak = 0
	bag_level = 0
	storage_level = 0
	toolbox_level = 0
	eye_level = 0
	fee_level = 0
	carry_used = 0
	mystery_packages_left = 0
	fixer_uses_today = 0
	current_trends = {}
	trend_random = {}
	trend_rumour = {}
	trend_headlines = []
	week_news = {}
	current_week = 1
	pending_special_offer = null
	skills_unlocked = {}
	total_haggled_savings = 0.0
	total_lifetime_profit = 0.0
	lifetime_challenges_completed = 0
	lifetime_fixer_wins = 0
	game_over = false
	seller_rating = 100.0
	rng_log = []
	activity_log = []
	best_net_worth = STARTING_CASH
	goals_done = 0
	cash_last_shown = -999999.0
	category_knowledge = {}
	expertise = {}
	discoveries_log = {}
	journal = []
	premises_level = 0
	vehicle_level = 0
	equipment = {}
	staff = {}
	week_plan = []
	market_today = {}
	clearance_leads = []
	clearance = null
	next_lead_id = 1
	next_item_uid = 1
	next_regular_id = 1
	collector_used_today = {}
	collector_offers = {}
	night_events = []
	fixed_count = 0
	var md = WorldData.MARKET_DAYS.get("regular", {})
	home_venue = pick_line(md.get("venues", ["The Top Field"]))
	init_regulars()
	init_rival()
	generate_weekly_trends()
	reset_day_stats()
	generate_day_seeded()

var pending_notices = []   # shown once the UI is up (e.g. after migrating an old save)

var fixed_count = 0

func init_new_run_state_only():
	# Blank 0.11 state before applying a save, without generating a day.
	expertise = {}
	discoveries_log = {}
	journal = []
	premises_level = 0
	vehicle_level = 0
	equipment = {}
	staff = {}
	regulars = []
	rival = {}
	clearance_leads = []
	clearance = null
	week_plan = []
	market_today = {}
	rival_route = []
	collector_used_today = {}
	collector_offers = {}
	home_venue = ""
	pending_notices = []
	w2 = {}
	signatures = []
	signature_changed_day = -99
	signature_nagged = {}

func migrate_from_0_10(parsed):
	# 0.10 -> 0.11: upgrade tracks become the business; knowledge becomes expertise; old perks are refunded.
	var notes = []
	premises_level = {0: 0, 1: 0, 2: 1, 3: 2, 4: 3, 5: 4}.get(storage_level, 0)
	if storage_level >= 1:
		equipment["shelving"] = 1
	vehicle_level = {0: 0, 1: 1, 2: 1, 3: 2, 4: 3}.get(bag_level, 0)
	goals_done = 0
	if toolbox_level > 0:
		equipment["repair"] = min(3, toolbox_level)
	fee_level = clamp(fee_level, 0, Biz.ACCOUNTS.size() - 1)
	for cat in category_knowledge:
		expertise[cat] = max(0.0, (float(category_knowledge[cat]) - 5.0) * 10.0)
	var refund = 0.0
	for l in range(int(parsed.get("package_insight_level", 0))):
		refund += round(50.0 * pow(1.28, l))
	for l in range(int(parsed.get("persuasion_level", 0))):
		refund += round(50.0 * pow(1.28, l))
	if refund > 0.0:
		cash += refund
		notes.append("Persuasion and Package Insight upgrades have been retired: £%s refunded." % fmt_int(refund))
	if skills_unlocked.size() > 0:
		skills_unlocked = {}
		notes.append("The skill tree is now Perks, with new mechanical abilities. Your points have been refunded.")
	notes.append("Welcome to 0.11. Your upgrades have become a business: %s, %s%s. Premises, vehicles and staff now have running costs (rent, fuel, wages) every night instead of upkeep. Check the Business page." % [premises()["name"], vehicle()["name"], (" and a " + Biz.EQUIPMENT["repair"]["levels"][equip_level("repair") - 1]["name"]) if equip_level("repair") > 0 else ""])
	return notes

func asset_value():
	# Resale value of the business's kit (counts toward business value).
	var v = 0.0
	for i in range(1, premises_level + 1):
		v += float(Biz.PREMISES[i]["cost"]) * 0.85
	for i in range(1, vehicle_level + 1):
		v += float(Biz.VEHICLES[i]["cost"]) * 0.75
	for id in equipment:
		if Biz.EQUIPMENT.has(id):
			for i in range(int(equipment[id])):
				v += float(Biz.EQUIPMENT[id]["levels"][i]["cost"]) * 0.4
	v += gamble.vault_asset_value()
	return v

func business_value():
	return cash + inventory_book_value() + asset_value()

func weekly_regular_churn():
	# Out of sight, out of mind: regulars you haven't seen for a fortnight cool a little.
	for r in regulars:
		if float(r["rel"]) > 0.0 and day - int(r.get("last_seen", -99)) > 14:
			r["rel"] = max(0.0, float(r["rel"]) - 3.0)
	# One stranger drifts away; a new face turns up. Friends stay.
	var candidates = []
	for i in range(regulars.size()):
		if float(regulars[i]["rel"]) < 20.0:
			candidates.append(i)
	if candidates.size() > 0 and rng.randf() < 0.7:
		regulars.remove_at(candidates[rng.randi_range(0, candidates.size() - 1)])
		regulars.append(make_regular())

func max_expertise_tier():
	var t = 0
	for c in CATEGORIES:
		t = max(t, expertise_tier(c))
	return t

func best_rel():
	var b = 0.0
	for r in regulars:
		b = max(b, float(r["rel"]))
	return b

func check_progress_achievements():
	var total = 0
	for k in discoveries_log:
		total += int(discoveries_log[k])
	if total >= 25:
		unlock_achievement("Detective")
	if discoveries_log.size() >= 100:
		unlock_achievement("Encyclopaedic")
	if fixed_count >= 10:
		unlock_achievement("Fixer-Upper")
	var enth = 0
	for c in CATEGORIES:
		var t = expertise_tier(c)
		if t >= 1:
			enth += 1
		if t >= 4:
			unlock_achievement("Authority")
	if enth >= 6:
		unlock_achievement("Polymath")
	var shop_sales = 0
	var missed = false
	for s in sold_history:
		if s.get("channel", "") == "shop":
			shop_sales += 1
		if s.get("missed", []).size() > 0:
			missed = true
	if shop_sales >= 10:
		unlock_achievement("Shopkeeper")
	if missed:
		unlock_achievement("Missed It")
	if vehicle_level >= 3:
		unlock_achievement("Van Man")
	if premises_level >= 4:
		unlock_achievement("Empire")
	check_milestone_achievements()

func suggested_price(item):
	# "Fair": just under what the evidence says it's worth, so it actually sells.
	var pot = estimate_identified_potential(item)
	if item["basic_researched"]:
		return round((float(pot[0]) + float(pot[1])) / 2.0 * 0.95)
	return round(sqrt(max(1.0, float(pot[0])) * max(1.0, float(pot[1]))))

func estimated_profit_at(item, price):
	var c = selling_costs(item, price)
	return price - float(c["fee"]) - float(c["postage"]) - float(c["insurance"]) - float(c["packaging"]) - float(item["paid"]) - float(item.get("extra_spend", 0.0))

func fmt_int(v):
	var n = int(round(float(v)))
	var s = str(abs(n))
	var out = ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out

func fmt_money(v):
	var f = float(v)
	if abs(f) >= 1000.0:
		return ("-£" if f < 0 else "£") + fmt_int(abs(f))
	return ("-£%.0f" % abs(f)) if f < 0 else ("£%.0f" % f)

func add_toast(text, kind = "info", log_it = true):
	if log_it:
		log_activity(text)
	if sim_mode or ui == null:
		return
	ui.toast(str(text), kind)

func queue_popup(text, kind = "error"):
	add_toast(str(text), kind)
	if kind == "error":
		play_sfx("error")

func set_status(text, color = null):
	add_toast(str(text), "info")

func show_big_popup(title, text, kind = "info", extra = {}):
	log_activity(title + ": " + str(text).replace("\n", " "))
	if sim_mode or ui == null:
		return
	ui.big_popup(title, text, kind, extra)

func clear_toasts():
	if ui != null:
		ui.clear_toasts()

func fx_money(amount):
	if sim_mode or ui == null:
		return
	ui.fx_money(float(amount))

func _screen(name, args = []):
	if sim_mode or ui == null:
		return
	if has_save and not on_title_screen and not game_over:
		save_game()
	if game_over and name in ["show_market", "show_stall", "show_inventory", "show_business", "show_clearance", "show_perks"]:
		ui.call("show_bankruptcy_screen")
		return
	ui.callv(name, args)

func update_header():
	if ui != null and not sim_mode:
		ui.update_hud()

func show_stall():
	_screen("show_stall")

func show_market():
	_screen("show_market")

func show_gaz_shop():
	_screen("show_gaz_shop")

func show_saleroom():
	_screen("show_saleroom")

func show_stall_list():
	_screen("show_market")

func show_special_offer():
	_screen("show_stall")

func show_inventory():
	_screen("show_inventory")

func show_inventory_fresh():
	_screen("show_inventory", [true])

func show_business():
	_screen("show_business")

func show_skill_tree():
	_screen("show_perks")

func show_clearance():
	_screen("show_clearance")

func show_knowledge():
	_screen("show_knowledge")

func show_perks():
	_screen("show_perks")

func show_day_summary(summary):
	_screen("show_day_summary", [summary])

func show_bankruptcy_screen():
	_screen("show_bankruptcy_screen")

func show_title_screen():
	_screen("show_title_screen")

func show_tutorial():
	_screen("show_tutorial")

func adjust_scale_for_device():
	if ui != null and not sim_mode:
		ui.adjust_scale()

# =====================================================================
# 0.11 — EXPERTISE
# =====================================================================
const EXPERTISE_TIERS = [0, 70, 220, 560, 1200]
const EXPERTISE_TIER_NAMES = ["Novice", "Enthusiast", "Specialist", "Expert", "Authority"]
const SPECIALIST_ACTIONS = {
	"Vinyl": "Read the run-out",
	"Cameras": "Check the glass",
	"Electronics": "Plug-in test",
	"Games": "Check board & label",
	"Trading Cards": "Check the print",
	"Clothing": "Check the labels",
	"Jewellery": "Loupe & hallmarks",
	"Books": "Check copyright page",
	"Collectables": "Check maker's marks",
	"Tools": "Check maker's stamp",
	"Home": "Check the base mark",
	"Musical Instruments": "Check serial & headstock",
	"Garden & Outdoor": "Check maker's plate",
}
var discoveries_log = {}     # trait id -> times identified
var journal = []             # recent story lines: {"day":d, "text":t, "kind":k}

func expertise_xp(cat):
	return float(expertise.get(cat, 0.0))

# Signatures: only the categories you commit to can go past Specialist.
var signatures = []
const NON_SIGNATURE_XP_CAP = 400.0   # halfway through Specialist: a new signature still has to earn Expert
var signature_changed_day = -99
var signature_nagged = {}

func signature_slots():
	return 2 + (1 if premises_level >= 3 else 0)

func is_signature(cat):
	return signatures.has(cat)

func raw_expertise_tier(cat):
	var xp = expertise_xp(cat)
	var t = 0
	for i in range(EXPERTISE_TIERS.size()):
		if xp >= EXPERTISE_TIERS[i]:
			t = i
	return t

func expertise_tier(cat):
	var t = raw_expertise_tier(cat)
	if not is_signature(cat):
		t = min(t, 2)
	if has_perk("polymath"):
		t = max(t, 1)
	return t

func set_signature(cat):
	if is_signature(cat) or not CATEGORIES.has(cat):
		return
	if signatures.size() >= signature_slots():
		queue_popup("You've no signature slots free. Drop one first (once a fortnight).")
		return
	var before = expertise_tier(cat)
	signatures.append(cat)
	add_journal("Made %s a signature. This is what you're known for now." % cat, "level")
	var after = expertise_tier(cat)
	if after > before:
		show_big_popup("%s: YOUR SIGNATURE" % cat.to_upper(), "Everything you've learned counts now: you're %s %s.\n\n%s" % [a_an(cat), EXPERTISE_TIER_NAMES[after], tier_unlock_text(cat, after)], "level")
	else:
		add_toast("%s is now a signature. It can go all the way to Authority." % cat, "success")
	save_game()
	refresh_current()

func drop_signature(cat):
	if not is_signature(cat):
		return
	if day - signature_changed_day < 14:
		queue_popup("You can only drop a signature once a fortnight (next on day %d)." % (signature_changed_day + 14))
		return
	signatures.erase(cat)
	signature_changed_day = day
	expertise[cat] = min(expertise_xp(cat), float(EXPERTISE_TIERS[2]))   # back to the start of Specialist
	add_journal("Stepped back from %s. Your knowledge stays, capped at Specialist." % cat, "info")
	save_game()
	refresh_current()

func refresh_current():
	if ui != null and not sim_mode:
		ui.refresh()

func expertise_progress(cat):
	# [xp into tier, xp needed for next tier] (needed = 0 at max)
	var t = 0
	var xp = expertise_xp(cat)
	for i in range(EXPERTISE_TIERS.size()):
		if xp >= EXPERTISE_TIERS[i]:
			t = i
	if t >= EXPERTISE_TIERS.size() - 1:
		return [xp - EXPERTISE_TIERS[t], 0.0]
	return [xp - EXPERTISE_TIERS[t], float(EXPERTISE_TIERS[t + 1] - EXPERTISE_TIERS[t])]

func tier_unlock_text(cat, tier):
	match tier:
		1:
			return "You spot the subtler tells when you Inspect %s items, and your estimates tighten." % cat
		2:
			return "New action: \"%s\". Use it on %s items at stalls or at home to identify specialist details." % [SPECIALIST_ACTIONS.get(cat, "Specialist check"), cat]
		3:
			return "Expert-level details are now within reach, and a %s collector contact will make you a private offer once a day." % cat
		4:
			return "You can tell fakes at a glance: \"%s\" now confirms authenticity." % SPECIALIST_ACTIONS.get(cat, "Specialist check")
	return ""

func add_expertise(cat, amount):
	if not CATEGORIES.has(cat) or amount <= 0:
		return
	if has_perk("quick_study"):
		amount *= 1.5
	var before = expertise_tier(cat)
	var raw_before = raw_expertise_tier(cat)
	expertise[cat] = expertise_xp(cat) + float(amount)
	if not is_signature(cat):
		expertise[cat] = min(expertise_xp(cat), NON_SIGNATURE_XP_CAP)   # past Specialist only as a signature
	var after = expertise_tier(cat)
	if not is_signature(cat) and expertise_xp(cat) >= NON_SIGNATURE_XP_CAP and not signature_nagged.has(cat):
		signature_nagged[cat] = true
		if signatures.size() < signature_slots():
			if not sim_mode and ui != null:
				ui.big_popup("MAKE %s A SIGNATURE?" % cat.to_upper(), "You know more about %s than most. Only signature categories go beyond Specialist: to Expert, a private collector contact, and Authority.\n\nYou have %d signature slot%s free." % [cat, signature_slots() - signatures.size(), "" if signature_slots() - signatures.size() == 1 else "s"], "level", {"buttons": [["Make it my signature", func(): set_signature(cat), "gold"], ["Not yet", func(): pass, "ghost"]]})
		else:
			add_journal("Your %s knowledge has hit the Specialist ceiling. Only signatures go further." % cat, "info")
	if after > before:
		for t in range(before + 1, after + 1):
			add_journal("Became %s %s." % [a_an(cat), EXPERTISE_TIER_NAMES[t]], "level")
			show_big_popup("%s %s" % [cat.to_upper(), EXPERTISE_TIER_NAMES[t].to_upper()], tier_unlock_text(cat, t), "level")
			if t >= 3:
				unlock_achievement("Specialist")

func add_journal(text, kind = "info"):
	journal.append({"day": day, "text": text, "kind": kind})
	if journal.size() > 120:
		journal = journal.slice(journal.size() - 120)

func inspect_accuracy(item):
	var acc = 0.62 + 0.06 * float(expertise_tier(item["category"]))
	acc += 0.04 * float(eye_level)   # legacy 0.10 Eye upgrades
	if has_perk("keen_eye"):
		acc += 0.12
	return clamp(acc, 0.5, 0.96)

# =====================================================================
# 0.11 — DISCOVERY TRAITS
# =====================================================================
const TRAIT_DIFFICULTY = {"look": 0.15, "condition": 0.35, "research": 0.40, "test": 0.50, "eye": 0.45, "deep": 0.65, "expert": 0.55, "uv": 0.85, "clean": 0.60, "sort": 2.0, "sale": 2.0}

func trait_def(t):
	return content.get_trait(str(t.get("id", "")))

func trait_difficulty(d):
	var base = float(TRAIT_DIFFICULTY.get(d.get("reveal", "look"), 0.5))
	if d.get("reveal", "") in ["eye", "expert"]:
		base += 0.12 * float(d.get("tier", 1))
	return base

func _pick_weighted_trait(ids, taken_groups, taken_ids):
	var pool = []
	var total = 0.0
	for tid in ids:
		if taken_ids.has(tid):
			continue
		var d = content.get_trait(tid)
		var grp = str(d.get("group", ""))
		if grp != "" and taken_groups.has(grp):
			continue
		pool.append(tid)
		total += float(d.get("weight", 1))
	if pool.size() == 0:
		return ""
	var r = rng.randf() * total
	for tid in pool:
		r -= float(content.get_trait(tid).get("weight", 1))
		if r <= 0.0:
			return tid
	return pool[pool.size() - 1]

func roll_item_traits(item, fam, profile, rarity_tier, ctx = {}):
	# Rolls hidden traits and folds their value into true_value.
	var entry = content.family_traits.get(fam["name"], {"good": [], "bad": [], "hidden": []})
	var traits_out = []
	var taken_groups = {}
	var taken_ids = {}
	var r = rng.randf()
	var n = 0
	if r < 0.40:
		n = 0
	elif r < 0.76:
		n = 1
	elif r < 0.94:
		n = 2
	else:
		n = 3
	var good_p = 0.38
	good_p += {"Common": 0.0, "Uncommon": 0.06, "Rare": 0.12, "Very Rare": 0.18, "Grail": 0.26}.get(rarity_tier, 0.0)
	good_p += (float(item["condition"]) - 6.5) * 0.025
	good_p += float(profile.get("trait_bias", 0.0))
	good_p += float(ctx.get("trait_bias", 0.0))
	good_p = clamp(good_p, 0.15, 0.85)
	for i in range(n):
		var want_good = rng.randf() < good_p
		var ids = entry["good"] if want_good else entry["bad"]
		if item["fault"]:
			# Don't stack a test-found bad trait on top of an existing electrical fault.
			var filtered = []
			for tid in ids:
				var d = content.get_trait(tid)
				if not (d["kind"] != "good" and d.get("reveal", "") == "test"):
					filtered.append(tid)
			ids = filtered
		var tid = _pick_weighted_trait(ids, taken_groups, taken_ids)
		if tid == "":
			continue
		var d = content.get_trait(tid)
		taken_ids[tid] = true
		if str(d.get("group", "")) != "":
			taken_groups[str(d["group"])] = true
		var m = rng.randf_range(float(d["mult"][0]), float(d["mult"][1]))
		traits_out.append({"id": tid, "mult": m, "known": false, "clue": false, "fixed": false})
	# Lots can hide a separate item.
	if fam.get("lot", false) and entry["hidden"].size() > 0:
		var hide_p = 0.22 + float(ctx.get("hidden_bonus", 0.0))
		if rng.randf() < hide_p:
			var tid = _pick_weighted_trait(entry["hidden"], taken_groups, taken_ids)
			if tid != "":
				traits_out.append({"id": tid, "mult": 1.0, "known": false, "clue": false, "fixed": false})
	var product = 1.0
	for t in traits_out:
		product *= float(t["mult"])
	item["traits"] = traits_out
	item["true_value"] = float(item["true_value"]) * product
	return product

func seller_known_trait_mult(item, knowledge):
	# How much of the traits' effect the seller prices in. Dealers know the easy stuff; nobody prices in what they can't see.
	var m = 1.0
	for t in item.get("traits", []):
		var d = trait_def(t)
		if d == null:
			continue
		var knew = knowledge * rng.randf_range(0.6, 1.3) > trait_difficulty(d)
		t["seller_knew"] = knew
		if knew:
			m *= float(t["mult"])
	return m

func item_unknown_trait_mult(item):
	var m = 1.0
	for t in item.get("traits", []):
		if not t.get("known", false):
			m *= float(t["mult"])
	return m

func known_traits(item):
	var out = []
	for t in item.get("traits", []):
		if t.get("known", false):
			out.append(t)
	return out

func item_has_open_clue(item):
	for t in item.get("traits", []):
		if t.get("clue", false) and not t.get("known", false):
			return true
	return false

func trait_can_reveal(item, d, method):
	# Can `method` identify this trait for the player right now?
	var rv = str(d.get("reveal", ""))
	var tier = expertise_tier(item["category"])
	match method:
		"look":
			return rv == "look" or (rv == "eye" and tier >= int(d.get("tier", 1)))
		"expert":
			return (rv == "expert" or rv == "eye") and tier >= int(d.get("tier", 1))
		_:
			return rv == method

func reveal_traits_quiet(item, methods):
	# Identify traits without the fanfare (catalogues, the Tent's paperwork). Clues still show.
	for t in item.get("traits", []):
		if t.get("known", false):
			continue
		var d = trait_def(t)
		if d == null:
			continue
		for m in methods:
			if trait_can_reveal(item, d, m) or (m == "eye" and str(d.get("reveal", "")) == "eye" and expertise_tier(item["category"]) >= int(d.get("tier", 1))):
				t["known"] = true
				t["clue"] = true
				break
			if str(d.get("clue_by", "")) == m and str(d.get("clue", "")) != "":
				t["clue"] = true

func reveal_traits(item, method, chance = 1.0):
	# Identify every trait `method` can find; show clues whose clue_by matches. Returns newly identified traits.
	var found = []
	for t in item.get("traits", []):
		if t.get("known", false):
			continue
		var d = trait_def(t)
		if d == null:
			continue
		if trait_can_reveal(item, d, method) and (chance >= 1.0 or rng.randf() < chance):
			t["known"] = true
			t["clue"] = true
			found.append(t)
		elif str(d.get("clue_by", "")) == method or (method == "expert" and str(d.get("reveal", "")) in ["expert", "eye"]):
			# Expert checks always notice there's something there, even beyond your tier.
			if str(d.get("clue", "")) != "" or method == "expert":
				t["clue"] = true
	for t in found:
		on_trait_found(item, t, method)
	return found

func trait_value_pct(t):
	return int(round((float(t["mult"]) - 1.0) * 100.0))

func on_trait_found(item, t, method):
	var d = trait_def(t)
	if d == null:
		return
	discoveries_log[d["id"]] = int(discoveries_log.get(d["id"], 0)) + 1
	day_stats["discoveries"] = int(day_stats.get("discoveries", 0)) + 1
	var owned = inventory.has(item)
	add_expertise(item["category"], (6 if d["kind"] == "good" else 4) if owned else 2)
	var pct = trait_value_pct(t)
	var kind = str(d["kind"])
	if kind == "hidden_item":
		return  # handled by sort_lot
	var line = "%s: %s" % [item["name"], d["found"]]
	hist(item, "%s %s (%s%d%%)." % ["Found:" if kind == "good" else "Turned out:", str(d["name"]), "+" if pct >= 0 else "", pct])
	if kind == "good":
		add_journal("Found %s on %s (+%d%%)." % [d["name"], a_an(item["name"]), pct], "good")
		if float(t["mult"]) >= 1.6:
			show_discovery(item, t)
		else:
			add_toast("DISCOVERY  %s  +%d%%" % [line, pct], "success")
			play_sfx("rare")
	else:
		add_journal("%s turned out to have: %s (%d%%)." % [item["name"], d["name"], pct], "bad")
		add_toast("%s  %d%%" % [line, pct], "warn")
		play_sfx("fail")

func show_discovery(item, t):
	var d = trait_def(t)
	if sim_mode or d == null:
		return
	play_sfx("rare")
	var r = estimate_identified_potential(item)
	show_big_popup("DISCOVERY: %s" % d["name"].to_upper(), "[b]%s[/b]\n%s\n\n%s\n\n[color=#7fd6c8]Worth %s–%s now, as far as you know.[/color]" % [item["name"], item_display_name(item) if str(item.get("ident", "")) != "" else "", d["found"], fmt_money(r[0]), fmt_money(r[1])], "rare", {"icon": item["category"], "item_name": item["name"], "big": "+%d%%" % trait_value_pct(t)})

func missed_traits_on_sale(item):
	# Called when an item sells: good traits you never found are revealed as missed.
	var missed = []
	for t in item.get("traits", []):
		if t.get("known", false):
			continue
		var d = trait_def(t)
		if d == null or not (d["kind"] in ["good", "hidden_item"]):
			continue
		missed.append(t)
		t["known"] = true
	return missed

func unknown_trait_return_risk(item):
	var r = 0.0
	for t in item.get("traits", []):
		if t.get("known", false):
			continue
		var d = trait_def(t)
		if d != null and d["kind"] != "good":
			r += float(d.get("return_risk", 0.0))
	return r

# --- player actions -----------------------------------------------------

func item_at(where, index) -> Variant:
	if where == "stall":
		if not valid_stall_index(index):
			return null
		return stalls[current_stall_index]["stock"][index]
	if index < 0 or index >= inventory.size():
		return null
	return inventory[index]

func refresh_after(where):
	if bulk_mode:
		return
	if where == "stall":
		show_stall()
	else:
		show_inventory()

func can_specialist_check(item):
	return expertise_tier(item["category"]) >= 2 and not item.get("expert_checked", false)

func specialist_check(where, index):
	var item = item_at(where, index)
	if item == null:
		return
	if expertise_tier(item["category"]) < 2:
		queue_popup("You need to be %s Specialist (tier 2) for that." % a_an(item["category"]))
		return
	if item.get("expert_checked", false):
		return
	if energy < 3:
		queue_popup("You need 3 energy.")
		return
	energy -= 3
	spend_time(3)
	item["expert_checked"] = true
	add_expertise(item["category"], 2)
	var found = reveal_traits(item, "expert")
	if where == "stall" and current_stall_index >= 0 and current_stall_index < stalls.size():
		seller_notices(stalls[current_stall_index], item)
	var beyond = 0
	for t in item.get("traits", []):
		var d = trait_def(t)
		if not t.get("known", false) and d != null and str(d.get("reveal", "")) in ["expert", "eye"]:
			beyond += 1
	var msg = ""
	if found.size() == 0 and beyond == 0:
		msg = "%s: nothing out of the ordinary." % SPECIALIST_ACTIONS.get(item["category"], "Check")
	elif found.size() == 0:
		msg = "There's something here you can't quite place. It's beyond your %s knowledge for now." % item["category"]
	if expertise_tier(item["category"]) >= 4 and float(item["fake_chance"]) > 0.0 and item["auth_status"] in ["Unauthenticated", "Inconclusive"]:
		item["auth_status"] = "Confirmed Genuine" if item["authentic"] else "Confirmed Counterfeit"
		item["auth_attempted"] = true
		msg += (" " if msg != "" else "") + "Authority eye: it's %s." % ("genuine" if item["authentic"] else "a FAKE")
		if not item["authentic"]:
			item["identified_mult"] = float(item["identified_mult"]) * 0.10
			item["listed"] = false
			item["auctioned"] = false
			item["on_shop_floor"] = false
			item["listing"] = 0.0
	if msg != "":
		add_toast(msg, "info")
	item["expert_note"] = msg
	play_sfx("reveal")
	refresh_after(where)

func uv_check(index):
	var item = item_at("inv", index)
	if item == null or item.get("uv_checked", false):
		return
	if not has_equip("auth"):
		queue_popup("You need an Authentication Kit (UV lamp) in your workshop.")
		return
	if energy < 2:
		queue_popup("You need 2 energy.")
		return
	energy -= 2
	spend_time(3)
	item["uv_checked"] = true
	var found = reveal_traits(item, "uv")
	if found.size() == 0:
		add_toast("UV lamp: no restorations, repaints or touch-ups show up.", "info")
	play_sfx("reveal")
	refresh_after("inv")

func can_clean(item):
	return has_equip("cleaning") and not item.get("cleaned", false)

func clean_item(index):
	var item = item_at("inv", index)
	if item == null or item.get("cleaned", false):
		return
	if not has_equip("cleaning"):
		queue_popup("You need a Cleaning Station in your workshop.")
		return
	if cash < 1.0 or energy < 4:
		queue_popup("Cleaning needs £1 and 4 energy.")
		return
	cash -= 1.0
	item["extra_spend"] = float(item["extra_spend"]) + 1.0
	day_stats["repairs"] += 1.0
	energy -= 4
	spend_time(12)
	item["cleaned"] = true
	var notes = []
	reveal_traits(item, "clean")
	for t in item.get("traits", []):
		var d = trait_def(t)
		if d != null and d["kind"] == "fixable" and str(d.get("fix", "")) == "clean" and not t.get("fixed", false):
			if not t.get("known", false):
				t["known"] = true
				t["clue"] = true
			fix_trait(item, t)
			notes.append("%s sorted" % d["name"])
	var centries = []
	if int(item["condition"]) < 8:
		var cr = luck.roll("clean", 0.30, "Cleaning: condition up a point")
		cr["label"] = "Does it come up nicely?"
		luck.tier_bands(cr, [["Like new", 0.04, "gold", "condition up two points"], ["Brighter", 0.30, "green", "condition up a point"]], "cleaner, same condition")
		centries.append(cr)
		if cr["hit"]:
			item["condition"] = min(10, int(item["condition"]) + (2 if cr["band"] == "Like new" else 1))
			notes.append("condition up to %d/10" % int(item["condition"]))
		if item["condition_checked"]:
			item["condition_price_note"] = condition_reveal_note(item)
	hist(item, "Cleaned%s." % ((": " + ", ".join(notes)) if notes.size() > 0 else ""))
	if show_rolls and centries.size() > 0 and not sim_mode:
		show_roll("CLEANING", centries, "Cleaned%s" % ((": " + ", ".join(notes)) if notes.size() > 0 else ". Looks a bit brighter."))
	else:
		add_toast("Cleaned %s%s" % [item["name"], (": " + ", ".join(notes)) if notes.size() > 0 else ". Looks a bit brighter."], "success" if notes.size() > 0 else "info")
	play_sfx("confirm")
	refresh_after("inv")

func fix_trait(item, t):
	var d = trait_def(t)
	if d == null or t.get("fixed", false):
		return
	var old_m = max(0.01, float(t["mult"]))
	var new_m = max(old_m, float(d.get("fix_mult", 0.95)))
	item["true_value"] = float(item["true_value"]) * new_m / old_m
	t["mult"] = new_m
	t["fixed"] = true
	fixed_count += 1
	add_journal("Fixed %s on %s." % [d["name"], a_an(item["name"])], "good")

func known_fixable(item, fix_kind):
	var out = []
	for t in item.get("traits", []):
		var d = trait_def(t)
		if d != null and d["kind"] == "fixable" and t.get("known", false) and not t.get("fixed", false) and str(d.get("fix", "")) == fix_kind:
			out.append(t)
	return out

func parts_fix(index):
	var item = item_at("inv", index)
	if item == null:
		return
	if not has_equip("parts"):
		queue_popup("You need a Parts Bin in your workshop.")
		return
	var todo = known_fixable(item, "parts")
	if todo.size() == 0:
		return
	var cost = 4.0 * todo.size()
	if cash < cost or energy < 3:
		queue_popup("Needs £%d and 3 energy." % int(cost))
		return
	cash -= cost
	item["extra_spend"] = float(item["extra_spend"]) + cost
	day_stats["repairs"] += cost
	energy -= 3
	spend_time(10)
	var names = []
	for t in todo:
		fix_trait(item, t)
		names.append(trait_def(t)["name"])
	add_toast("Fitted replacement parts: %s fixed." % ", ".join(names), "success")
	play_sfx("confirm")
	refresh_after("inv")

func is_unsorted_lot(item):
	var fam = content.family(item["name"])
	return fam != null and fam.get("lot", false) and not item.get("sorted", false) and item.has("traits")

func sort_lot(index):
	var item = item_at("inv", index)
	if item == null or not is_unsorted_lot(item):
		return
	if energy < 6:
		queue_popup("Sorting through a lot takes 6 energy.")
		return
	energy -= 6
	spend_time(20)
	item["sorted"] = true
	add_expertise(item["category"], 3)
	var spawned = []
	for t in item.get("traits", []):
		var d = trait_def(t)
		if d == null or d["kind"] != "hidden_item" or t.get("known", false):
			continue
		t["known"] = true
		t["clue"] = true
		discoveries_log[d["id"]] = int(discoveries_log.get(d["id"], 0)) + 1
		var sp = d.get("spawn", {})
		var fams = sp.get("families", [])
		if fams.size() == 0:
			continue
		var fam = content.family(fams[rng.randi_range(0, fams.size() - 1)])
		if fam == null:
			continue
		var vm = sp.get("value_mult", [1.0, 2.0])
		var it = make_item_from_family(fam, item.get("seller", "House Clearance"), {})
		it["true_value"] = float(it["true_value"]) * rng.randf_range(float(vm[0]), float(vm[1]))
		it["paid"] = 0.0
		it["asking"] = 0.0
		it["source"] = "found"
		it["found_in"] = item["name"]
		it["story"] = "Found at the bottom of %s." % item_display_name(item)
		hist(it, "Found inside the %s." % item["name"])
		inventory.append(it)
		register_collection(it)
		spawned.append(it)
		add_journal("Sorted %s and found %s inside." % [a_an(item["name"]), a_an(it["name"])], "good")
		if not sim_mode:
			show_big_popup("FOUND INSIDE THE LOT", "%s\n\n%s\n\nIt's been added to your stock." % [d["found"], it["name"]], "rare")
			play_sfx("rare")
	if spawned.size() == 0:
		add_toast("Sorted through the %s: nothing hiding in there. At least you know it's all accounted for." % item["name"], "info")
	refresh_after("inv")

func collector_contact_available(item):
	return expertise_tier(item["category"]) >= 3 and day - int(collector_used_today.get(item["category"], -99)) >= 2 and item["auth_status"] != "Confirmed Counterfeit" and not item["listed"] and not item["auctioned"] and not item.get("on_shop_floor", false)

var collector_used_today = {}
var collector_offers = {}   # item uid -> offer amount (rolled once per day)

func collector_offer_for(item):
	var key = str(item.get("uid", 0)) + ":" + str(day)
	if not collector_offers.has(key):
		var needs_test = item["testable"] and not item["tested"]
		collector_offers[key] = max(1.0, round(min(perceived_center(item), true_market_value(item)) * rng.randf_range(0.8, 0.95) * (0.85 if needs_test else 1.0)))
	return float(collector_offers[key])

func sell_to_collector(index):
	var item = item_at("inv", index)
	if item == null or not collector_contact_available(item) or item.get("vaulted", false):
		return
	var price = collector_offer_for(item)
	collector_used_today[item["category"]] = day
	spend_time(3)
	# The collector looks it over properly before paying.
	if not item["authentic"] and item["auth_status"] != "Confirmed Genuine":
		item["auth_status"] = "Suspected Counterfeit"
		add_toast("Your %s collector turns it over and hands it back: \"That's not right, mate. Not for me.\"" % item["category"], "error")
		add_journal("A collector refused the %s as a fake." % item["name"], "bad")
		save_game()
		show_inventory()
		return
	if item["fault"] and not fault_is_known(item):
		price = max(1.0, round(price * fault_multiplier(item["fault_severity"])))
		if item["testable"]:
			item["tested"] = true
		else:
			item["condition_checked"] = true
		add_toast("The collector spots a fault and knocks the price down to £%.0f." % price, "warn")
	cash += price
	var profit = record_completed_sale(item, price, {"fee": 0.0, "postage": 0.0, "insurance": 0.0, "packaging": 0.0}, "collector")
	inventory.remove_at(index)
	add_toast("Your %s collector paid £%.0f for the %s (profit %s)." % [item["category"], price, item["name"], money_signed(profit)], "success" if profit >= 0 else "warn")
	fx_money(price)
	play_sfx("sale")
	save_game()
	show_inventory()

# =====================================================================
# 0.11 — THE BUSINESS (premises, vehicle, workshop, account, staff)
# =====================================================================
var premises_level = 0
var vehicle_level = 0
var equipment = {}        # id -> level (1-based)
var staff = {}            # id -> true
var shop_floor_cap_base = 10

func premises():
	return Biz.PREMISES[clamp(premises_level, 0, Biz.PREMISES.size() - 1)]

func vehicle():
	return Biz.VEHICLES[clamp(vehicle_level, 0, Biz.VEHICLES.size() - 1)]

func equip_level(id):
	return int(equipment.get(id, 0))

func has_equip(id, lvl = 1):
	return equip_level(id) >= lvl

func workshop_slots():
	return int(premises()["slots"])

func workshop_slots_used():
	var n = 0
	for id in equipment:
		if int(equipment[id]) > 0:
			n += 1
	return n

func storage_capacity():
	var cap = int(premises()["storage"])
	var sh = equip_level("shelving")
	if sh >= 1:
		cap += 12
	if sh >= 2:
		cap += 18
	return cap

func effective_bag_capacity():
	return int(vehicle()["carry"])

func listing_cap():
	var cap = int(premises()["listings"])
	if has_equip("photo", 2):
		cap += 4
	return cap

func active_listing_count():
	var n = 0
	for it in inventory:
		if it["listed"] or it["auctioned"]:
			n += 1
	return n

func shop_floor_enabled():
	return premises_level >= 3

func shop_floor_cap():
	return shop_floor_cap_base + (6 if staff.has("shopkeeper") else 0) if shop_floor_enabled() else 0

func shop_floor_count():
	var n = 0
	for it in inventory:
		if it.get("on_shop_floor", false):
			n += 1
	return n

func account():
	return Biz.ACCOUNTS[clamp(fee_level, 0, Biz.ACCOUNTS.size() - 1)]

func fee_rate():
	return float(account()["fee"])

func cost_mult():
	return 0.85 if has_perk("frugal") else 1.0

func running_costs():
	var rent = float(premises()["rent"])
	var fuel = float(vehicle()["fuel"])
	var wages = 0.0
	for id in staff:
		if Biz.STAFF.has(id):
			wages += float(Biz.STAFF[id]["wage"])
	var m = cost_mult()
	var vault = gamble.vault_upkeep()
	return {"rent": rent * m, "fuel": fuel * m, "wages": wages * m, "vault": vault * m, "total": (rent + fuel + wages + vault) * m}

func compute_upkeep():
	return float(running_costs()["total"])

func pitch_fee():
	var fee = min(15.0, 6.50 + float(day - 1) * 0.08)
	fee += float(market_today.get("entry_fee", 0.0))
	if market_today.get("clearance", false):
		fee = 0.0
	if cash < 40.0 and not market_today.get("clearance", false):
		fee = 0.0   # skint: the gate man knows you, and waves you through
	return fee * cost_mult()

func can_buy_premises():
	return premises_level < Biz.PREMISES.size() - 1

func buy_premises():
	if not can_buy_premises():
		return
	var nxt = Biz.PREMISES[premises_level + 1]
	if cash < float(nxt["cost"]):
		queue_popup("You need £%s for the %s." % [fmt_int(nxt["cost"]), nxt["name"]])
		return
	cash -= float(nxt["cost"])
	day_stats["business_spend"] = float(day_stats.get("business_spend", 0.0)) + float(nxt["cost"])
	premises_level += 1
	add_journal("Moved the business into %s." % a_an(nxt["name"]), "level")
	show_big_popup("NEW PREMISES", "%s\n\n%s\n\nStorage %d  •  Workshop slots %d  •  Listings %d  •  Rent £%.0f/day" % [nxt["name"], nxt["desc"], nxt["storage"], nxt["slots"], nxt["listings"], nxt["rent"]], "level")
	play_sfx("level")
	check_goals()
	save_game()
	show_business()

func buy_vehicle():
	if vehicle_level >= Biz.VEHICLES.size() - 1:
		return
	var nxt = Biz.VEHICLES[vehicle_level + 1]
	if cash < float(nxt["cost"]):
		queue_popup("You need £%s for the %s." % [fmt_int(nxt["cost"]), nxt["name"]])
		return
	cash -= float(nxt["cost"])
	day_stats["business_spend"] = float(day_stats.get("business_spend", 0.0)) + float(nxt["cost"])
	vehicle_level += 1
	add_journal("Bought %s." % a_an(nxt["name"]), "level")
	var extra = ""
	if nxt.has("unlocks"):
		extra = "\n\nUnlocks: " + ", ".join(nxt["unlocks"])
	show_big_popup("NEW WHEELS", "%s\n\n%s\n\nCarry %d  •  Fuel £%.0f/day%s" % [nxt["name"], nxt["desc"], nxt["carry"], nxt["fuel"], extra], "level")
	play_sfx("level")
	if vehicle_level >= 3 and clearance_leads.size() == 0:
		add_clearance_lead("paper")
	check_goals()
	save_game()
	show_business()

func equipment_next_cost(id):
	var def = Biz.EQUIPMENT[id]
	var lvl = equip_level(id)
	if lvl >= def["levels"].size():
		return -1.0
	return float(def["levels"][lvl]["cost"])

func buy_equipment(id, confirmed = false):
	if not Biz.EQUIPMENT.has(id):
		return
	var def = Biz.EQUIPMENT[id]
	var lvl = equip_level(id)
	if lvl >= def["levels"].size():
		return
	if lvl == 0 and workshop_slots_used() >= workshop_slots():
		queue_popup("No free workshop slots. Bigger premises have more room, or remove something.")
		return
	var cost = float(def["levels"][lvl]["cost"])
	if cash < cost:
		queue_popup("You need £%s." % fmt_int(cost))
		return
	if lvl == 0 and workshop_slots() - workshop_slots_used() == 1 and not confirmed and not sim_mode and ui != null:
		ui.big_popup("YOUR LAST WORKSHOP SLOT", "The %s would take your last free slot. Nothing else fits until you move somewhere bigger.\n\n%s" % [def["levels"][0]["name"], def["levels"][0]["desc"]], "info", {"buttons": [["Install it", func(): buy_equipment(id, true), "primary"], ["Not yet", func(): pass, "ghost"]]})
		return
	cash -= cost
	day_stats["business_spend"] = float(day_stats.get("business_spend", 0.0)) + cost
	equipment[id] = lvl + 1
	add_journal("Installed: %s." % def["levels"][lvl]["name"], "level")
	add_toast("Installed %s." % def["levels"][lvl]["name"], "success")
	play_sfx("confirm")
	check_goals()
	save_game()
	show_business()

func remove_equipment(id):
	if equip_level(id) <= 0:
		return
	var def = Biz.EQUIPMENT[id]
	var refund = 0.0
	for i in range(equip_level(id)):
		refund += float(def["levels"][i]["cost"]) * 0.4
	if id == "shelving" and inventory_space_used() > int(premises()["storage"]):
		queue_popup("You'd have nowhere to put your stock. Clear some space first.")
		return
	equipment.erase(id)
	cash += refund
	add_toast("Sold the %s for £%.0f. Slot freed." % [def["name"], refund], "info")
	save_game()
	show_business()

func account_requirements_met(i):
	var a = Biz.ACCOUNTS[i]
	return sold_history.size() >= int(a["sales"]) and seller_rating >= float(a["rating"])

func buy_account():
	if fee_level >= Biz.ACCOUNTS.size() - 1:
		return
	var nxt = Biz.ACCOUNTS[fee_level + 1]
	if not account_requirements_met(fee_level + 1):
		queue_popup("Needs %d sales and a %d%% seller rating." % [int(nxt["sales"]), int(nxt["rating"])])
		return
	if cash < float(nxt["cost"]):
		queue_popup("You need £%s." % fmt_int(nxt["cost"]))
		return
	cash -= float(nxt["cost"])
	fee_level += 1
	add_journal("Upgraded to %s (fees %.1f%%)." % [a_an(nxt["name"]), float(nxt["fee"]) * 100.0], "level")
	add_toast("Now %s: selling fees %.1f%%." % [a_an(nxt["name"]), float(nxt["fee"]) * 100.0], "success")
	play_sfx("level")
	save_game()
	show_business()

func staff_allowed(id):
	return premises_level >= int(Biz.STAFF[id]["needs"])

func toggle_staff(id):
	if not Biz.STAFF.has(id):
		return
	if staff.has(id):
		staff.erase(id)
		add_toast("%s let go. No more wages." % Biz.STAFF[id]["name"], "info")
	else:
		if not staff_allowed(id):
			queue_popup("You need bigger premises to take on %s." % a_an(Biz.STAFF[id]["name"]))
			return
		staff[id] = true
		add_journal("Hired %s." % a_an(Biz.STAFF[id]["name"]), "level")
		add_toast("Hired %s (£%.0f/day)." % [a_an(Biz.STAFF[id]["name"]), float(Biz.STAFF[id]["wage"])], "success")
	save_game()
	show_business()

func has_perk(id):
	return skills_unlocked.has(id)

func perk_def(id) -> Variant:
	for p in Biz.PERKS:
		if p["id"] == id:
			return p
	return null

func buy_perk(id):
	var p = perk_def(id)
	if p == null or has_perk(id):
		return
	if p["requires"] != "" and not has_perk(p["requires"]):
		queue_popup("Needs %s first." % perk_def(p["requires"])["name"])
		return
	if skill_points_available() < int(p["cost"]):
		queue_popup("Not enough skill points.")
		return
	skills_unlocked[id] = true
	add_toast("Perk unlocked: %s" % p["name"], "success")
	play_sfx("level")
	save_game()
	show_skill_tree()

func skill_points_spent():
	var total = 0
	for p in Biz.PERKS:
		if has_perk(p["id"]):
			total += int(p["cost"])
	return total

func skill_points_available():
	return max(0, (player_level - 1) - skill_points_spent())

# --- overnight business --------------------------------------------------

func process_shop_floor():
	if not shop_floor_enabled():
		return
	var to_remove = []
	var footfall = 1.0 * (1.5 if staff.has("shopkeeper") else 1.0)
	for i in range(inventory.size()):
		var item = inventory[i]
		if not item.get("on_shop_floor", false):
			continue
		var price = float(item.get("shop_price", 0.0))
		if item["auth_status"] == "Confirmed Counterfeit":
			item["on_shop_floor"] = false
			continue
		# Walk-in customers handle the item: they judge it on what it really is.
		var chance = daily_sale_chance(buyer_interest_score(item, price, false, true_market_value(item))) * 0.65 * footfall
		var roll = rng.randf()
		if roll < chance:
			# Walk-ins always ask "what's your best price?"
			price = round(price * rng.randf_range(0.86, 1.0))
			cash += price
			var profit = record_completed_sale(item, price, {"fee": 0.0, "postage": 0.0, "insurance": 0.0, "packaging": 0.0}, "shop")
			record_rng("Shop floor: %s @ £%.0f | SOLD" % [item["name"], price], false)
			var msgs = WorldData.BUYER_MESSAGES.get("shop", [""])
			night_events.append({"kind": "sale", "text": "Shop: %s sold for £%.0f" % [item["name"], price], "sub": msgs[rng.randi_range(0, msgs.size() - 1)], "amount": price, "profit": profit})
			to_remove.append(i)
	for j in range(to_remove.size() - 1, -1, -1):
		inventory.remove_at(to_remove[j])

func put_on_shop_floor(index, price):
	var item = item_at("inv", index)
	if item == null or item.get("vaulted", false):
		return
	if not shop_floor_enabled():
		return
	if item.get("on_shop_floor", false):
		item["on_shop_floor"] = false
		show_inventory()
		return
	if shop_floor_count() >= shop_floor_cap():
		queue_popup("The shop floor's full (%d items)." % shop_floor_cap())
		return
	if item["auth_status"] in ["Confirmed Counterfeit", "Suspected Counterfeit"]:
		queue_popup("You can't put a suspected fake on the shelf.")
		return
	if item["listed"] or item["auctioned"]:
		queue_popup("Take it off the internet first.")
		return
	if item["testable"] and not item["tested"]:
		queue_popup("Test it before it goes on the shelf.")
		return
	item["on_shop_floor"] = true
	item["shop_price"] = max(1.0, round(float(price)))
	add_toast("%s is on the shop floor at £%.0f." % [item["name"], float(item["shop_price"])], "success")
	save_game()
	show_inventory()

func process_staff():
	if staff.has("runner"):
		trade.runner_night()
	if staff.has("assistant"):
		var did = []
		var tested = 0
		var cleaned = 0
		var trimmed = 0
		for i in range(inventory.size()):
			var item = inventory[i]
			if item["testable"] and not item["tested"]:
				item["tested"] = true
				item["action_order"].append("test")
				var r = "WORKING" if not item["fault"] else "FAULT — " + fault_label(item)
				item["test_note"] = "Tested by your assistant: %s." % r
				reveal_traits(item, "test")
				tested += 1
			if has_equip("cleaning") and not item.get("cleaned", false) and known_fixable(item, "clean").size() > 0:
				item["cleaned"] = true
				reveal_traits(item, "clean")
				for t in known_fixable(item, "clean"):
					fix_trait(item, t)
				cleaned += 1
			if item["listed"] and day - int(item.get("listed_day", day)) >= 7:
				item["listing"] = max(1.0, round(float(item["listing"]) * 0.9))
				item["listed_day"] = day
				trimmed += 1
		if tested + cleaned + trimmed > 0:
			night_events.append({"kind": "info", "text": "Your assistant tested %d, cleaned %d and trimmed %d stale listings." % [tested, cleaned, trimmed]})


# =====================================================================
# 0.11 — LIVING MARKET (weather, market days, regulars, rival, clearances)
# =====================================================================
const WEATHER_FX = {
	"sunny":    {"stalls": 1,  "crowd": 0.08,  "price": 1.00, "rival": 0.75, "energy": 0,   "start": 0,  "icon": "sun"},
	"overcast": {"stalls": 0,  "crowd": 0.00,  "price": 1.00, "rival": 0.70, "energy": 0,   "start": 0,  "icon": "cloud"},
	"drizzle":  {"stalls": -1, "crowd": -0.08, "price": 0.96, "rival": 0.55, "energy": 0,   "start": 0,  "icon": "rain"},
	"downpour": {"stalls": -3, "crowd": -0.25, "price": 0.86, "rival": 0.25, "energy": -5,  "start": 0,  "icon": "storm"},
	"heatwave": {"stalls": 1,  "crowd": 0.14,  "price": 1.02, "rival": 0.85, "energy": -10, "start": 0,  "icon": "sun"},
	"frost":    {"stalls": -2, "crowd": -0.10, "price": 0.95, "rival": 0.50, "energy": -5,  "start": 30, "icon": "snow"},
	"windy":    {"stalls": -1, "crowd": -0.05, "price": 0.98, "rival": 0.60, "energy": 0,   "start": 0,  "icon": "wind"},
}
const MARKET_FX = {
	"regular":          {"stalls": [6, 8],   "fee": 0.0,  "rarity": 1.00, "archetypes": [], "early": 0},
	"early_bird":       {"stalls": [6, 8],   "fee": 5.0,  "rarity": 1.00, "archetypes": [], "early": 60},
	"bank_holiday":     {"stalls": [11, 14], "fee": 3.0,  "rarity": 1.10, "archetypes": [], "early": 0},
	"collectors_fair":  {"stalls": [5, 6],   "fee": 10.0, "rarity": 1.60, "archetypes": ["Collector", "Dealer", "Collector", "Regular Seller"], "early": 0},
	"village_fete":     {"stalls": [4, 6],   "fee": 0.0,  "rarity": 0.80, "archetypes": ["Clueless Seller", "Clueless Seller", "Desperate Seller", "House Clearance"], "early": 0},
	"christmas_market": {"stalls": [7, 9],   "fee": 3.0,  "rarity": 1.05, "archetypes": [], "early": 0},
}
var market_today = {}      # {"type","weather","venue","entry_fee","intro"}
var week_plan = []         # 7 upcoming days: [{"day":d,"type":t,"weather":w}]
var regulars = []          # persistent sellers
var next_regular_id = 1
var rival = {}             # {"name","nickname","cats":[..],"level","wins","losses"}
var clearance_leads = []   # [{"id","story","price","expires","size","source","from"}]
var next_lead_id = 1
var clearance = null       # active clearance job
var night_events = []      # overnight report entries (built during end_day)
var next_item_uid = 1

func spend_time(minutes):
	current_time_minutes += int(minutes)
	advance_rival()
	world.event_tick()

func season_weather_weights(season):
	match season:
		"Winter":
			return {"sunny": 1, "overcast": 4, "drizzle": 3, "downpour": 2, "frost": 4, "windy": 2}
		"Spring":
			return {"sunny": 3, "overcast": 3, "drizzle": 3, "downpour": 1, "frost": 1, "windy": 2}
		"Summer":
			return {"sunny": 6, "overcast": 2, "drizzle": 1, "downpour": 1, "heatwave": 2, "windy": 1}
	return {"sunny": 2, "overcast": 4, "drizzle": 3, "downpour": 2, "windy": 3}

func _weighted_key(weights):
	var total = 0.0
	for k in weights:
		total += float(weights[k])
	var r = rng.randf() * total
	for k in weights:
		r -= float(weights[k])
		if r <= 0.0:
			return k
	return weights.keys()[0]

func plan_day_type(d):
	# Special days are rare enough to feel special, and known a week ahead.
	var season = get_season_name()
	if d > 1 and d % 7 == 0 and rng.randf() < 0.5:
		return "early_bird"
	if d >= 8 and d % 21 == 15:
		return "bank_holiday"
	if vehicle_level >= 2 and d % 7 == 4 and rng.randf() < 0.7:
		return "collectors_fair"
	if season == "Winter" and d % 7 == 6:
		return "christmas_market"
	if (season == "Summer" or season == "Spring") and d % 7 == 2 and rng.randf() < 0.45:
		return "village_fete"
	return "regular"

func ensure_week_plan():
	# Keep a rolling 7-day forecast.
	var have = {}
	for e in week_plan:
		have[int(e["day"])] = true
	var filtered = []
	for e in week_plan:
		if int(e["day"]) >= day:
			filtered.append(e)
	week_plan = filtered
	for d in range(day, day + 7):
		if not have.has(d):
			var w = _weighted_key(season_weather_weights(get_season_name()))
			week_plan.append({"day": d, "type": plan_day_type(d), "weather": w})
	week_plan.sort_custom(func(a, b): return int(a["day"]) < int(b["day"]))

func plan_for(d):
	for e in week_plan:
		if int(e["day"]) == d:
			return e
	return {"day": d, "type": "regular", "weather": "overcast"}

func market_name(type_id):
	if type_id == "regular":
		return "Car Boot Sale"
	var md = WorldData.MARKET_DAYS.get(type_id, {})
	return str(md.get("name", "Car Boot Sale"))

func weather_name(w):
	return str(WorldData.WEATHER.get(w, {}).get("name", w.capitalize()))

func pick_line(arr):
	if typeof(arr) != TYPE_ARRAY or arr.size() == 0:
		return ""
	return str(arr[rng.randi_range(0, arr.size() - 1)])

func fill_line(text, vars):
	var s = str(text)
	for k in vars:
		s = s.replace("{" + k + "}", str(vars[k]))
	return s

# --- regulars -----------------------------------------------------------

func make_regular(archetype = ""):
	var arch_list = seller_profiles.keys()
	if archetype == "":
		archetype = arch_list[rng.randi_range(0, arch_list.size() - 1)]
	var pers_ids = []
	for pid in WorldData.PERSONALITIES:
		if WorldData.PERSONALITIES[pid]["archetypes"].has(archetype):
			pers_ids.append(pid)
	if pers_ids.size() == 0:
		pers_ids = WorldData.PERSONALITIES.keys()
	var pid = pers_ids[rng.randi_range(0, pers_ids.size() - 1)]
	var gender = str(WorldData.PERSONALITY_GENDER.get(pid, ""))
	var first = pick_line(WorldData.FEMALE_NAMES if gender == "f" else (WorldData.MALE_NAMES if gender == "m" else WorldData.FIRST_NAMES))
	var sur = pick_line(WorldData.SURNAMES)
	var r = {"id": next_regular_id, "first": first, "name": "%s %s" % [first, sur], "archetype": archetype, "personality": pid,
		"cats": WorldData.PERSONALITIES[pid]["cats"].duplicate(), "rel": 0.0, "visits": 0, "last_seen": -1,
		"bought": 0, "last_item": "", "dressing": rng.randi_range(0, WorldData.STALL_DRESSING.size() - 1), "banned_until": -1}
	next_regular_id += 1
	return r

func init_regulars():
	regulars = []
	var arch = seller_profiles.keys()
	# At least two of each archetype, then random.
	for a in arch:
		regulars.append(make_regular(a))
		regulars.append(make_regular(a))
	for i in range(8):
		regulars.append(make_regular())

func regular_by_id(id) -> Variant:
	for r in regulars:
		if int(r["id"]) == int(id):
			return r
	return null

func rel_tier(rel):
	if rel >= 65:
		return 3
	if rel >= 35:
		return 2
	if rel >= 15:
		return 1
	return 0

func rel_name(rel):
	return ["Stranger", "Familiar face", "Regular", "Friend"][rel_tier(rel)]

func change_rel(stall, amount):
	var rid = int(stall.get("regular_id", -1))
	if rid < 0:
		return
	var r = regular_by_id(rid)
	if r == null:
		return
	if amount > 0 and has_perk("charmer"):
		amount *= 2.0
	var before = rel_tier(float(r["rel"]))
	r["rel"] = clamp(float(r["rel"]) + amount, -50.0, 100.0)
	var after = rel_tier(float(r["rel"]))
	if after > before:
		add_toast("%s now counts you as %s." % [r["first"], a_an(rel_name(float(r["rel"])).to_lower())], "success")
		add_journal("%s now counts you as %s." % [r["name"], a_an(rel_name(float(r["rel"])).to_lower())], "good")
		if after >= 3:
			unlock_achievement("Friendly Face")

func personality_of(stall):
	return WorldData.PERSONALITIES.get(str(stall.get("personality", "")), null)

func stall_line(stall, key, vars = {}):
	var p = personality_of(stall)
	if p == null:
		return ""
	return fill_line(pick_line(p["lines"].get(key, [])), vars)

var lines_used_today = {}

func unique_line(arr, filter_claims = false):
	# A line nobody else has said today, and (optionally) none that claim history that didn't happen.
	var cands = []
	for l in arr:
		var t = str(l)
		if lines_used_today.has(t):
			continue
		if filter_claims and (t.findn("you bought") >= 0 or t.findn("you had") >= 0 or t.findn("who bought") >= 0 or t.findn("you took") >= 0):
			continue
		cands.append(t)
	if cands.size() == 0:
		cands = arr
	if typeof(cands) != TYPE_ARRAY or cands.size() == 0:
		return ""
	var pick = str(cands[rng.randi_range(0, cands.size() - 1)])
	lines_used_today[pick] = true
	return pick

func stall_greeting(stall):
	if stall.get("greeting", "") != "":
		return stall["greeting"]
	var rid = int(stall.get("regular_id", -1))
	var r = regular_by_id(rid) if rid >= 0 else null
	var p = personality_of(stall)
	if p == null:
		return ""
	if r == null or int(r["visits"]) <= 1 or float(r["rel"]) < 8.0:
		return unique_line(p["lines"].get("greet_new", []), true)
	var mem = world.memory_greeting(stall)
	if mem != "":
		return mem
	if float(r["rel"]) >= 65:
		return unique_line(p["lines"].get("greet_friend", []), true)
	return unique_line(p["lines"].get("greet_regular", []), true)

# --- rival --------------------------------------------------------------

func init_rival():
	var cats = CATEGORIES.duplicate()
	cats.shuffle()
	rival = {"name": WorldData.RIVAL["name"], "nickname": WorldData.RIVAL["nickname"], "cats": [cats[0], cats[1], cats[2]], "snatched": 0, "beaten": 0}
	# He's already trading when you start: a few things on his shop.
	for i in range(4):
		var it = generate_item(["Dealer", "House Clearance", "Clueless Seller", "Desperate Seller"][i])
		world.gaz_took(it, {"seller_full_name": ""}, false)

func plan_rival_route():
	# Rival visits a subset of stalls through the morning, grabbing the best things in his categories.
	rival_route = []
	var fx = WEATHER_FX.get(market_today.get("weather", "overcast"), WEATHER_FX["overcast"])
	var attend = float(fx["rival"])
	if market_today.get("type", "") == "village_fete":
		attend *= 0.4
	if day == 2:
		attend = 1.0   # he makes a point of introducing himself
	if staff.has("picker"):
		attend *= 0.6
	market_today["rival_here"] = rng.randf() < attend and stalls.size() > 0
	if not market_today["rival_here"]:
		return
	var order = range(stalls.size())
	order.shuffle()
	var visits = min(stalls.size(), rng.randi_range(2, 4))
	var t = 7 * 60 + 20 + max(0, int(market_today.get("start_offset", 0)))
	for i in range(visits):
		t += rng.randi_range(12, 45)
		rival_route.append({"stall": order[i], "minute": t, "done": false})
		stalls[order[i]]["rival_eta"] = t

var rival_route = []

func advance_rival():
	if rival_route.size() == 0 or stalls.size() == 0 or clearance != null:
		return
	for step in rival_route:
		if step["done"] or current_time_minutes < int(step["minute"]):
			continue
		step["done"] = true
		rival_visit(int(step["stall"]))

func rival_visit(si):
	if si < 0 or si >= stalls.size():
		return
	var stall = stalls[si]
	stall["rival_visited"] = true
	if str(stall.get("beat_gaz_item", "")) != "":
		add_toast(fill_line(pick_line(Lines012.RIVAL_LINES["you_beat_him"]), {"item": "the " + lc(stall["beat_gaz_item"])}), "success")
		rival["beaten"] = int(rival.get("beaten", 0)) + 1
	if current_time_minutes >= int(stall["packing_minute"]):
		return
	# He takes up to 2 of the most valuable items in his categories (or the best overall bargain).
	var best = []
	for j in range(stall["stock"].size()):
		var it = stall["stock"][j]
		var seen_value = float(it["true_value"])
		if not rival.get("cats", []).has(it["category"]):
			# Outside his patch he's guessing from what the thing usually is.
			if not it.has("gaz_view"):
				it["gaz_view"] = rng.randf_range(0.4, 1.7)
			seen_value = typical_value(it) * float(it["gaz_view"])
		var score = seen_value * float(current_trends.get(it["category"], 1.0)) / max(1.0, float(it["asking"]))
		if rival.get("cats", []).has(it["category"]):
			score *= 1.8
		if it.get("saved_for_player", false):
			continue
		best.append([score, j])
	best.sort_custom(func(a, b): return a[0] > b[0])
	var max_takes = 1 if staff.has("picker") else 2
	var remove_idx = []
	for pair in best:
		if remove_idx.size() >= max_takes or float(pair[0]) < 1.3:
			break
		remove_idx.append(int(pair[1]))
	if remove_idx.size() == 0:
		return
	var new_stock = []
	var revealed_removed = 0
	var took = stall.get("rival_took", [])
	for j in range(stall["stock"].size()):
		if remove_idx.has(j):
			if j < int(stall["revealed"]):
				revealed_removed += 1
			took.append(stall["stock"][j]["name"])
			world.gaz_took(stall["stock"][j], stall, stall.get("visited", false) and j < int(stall["revealed"]))
			rival["snatched"] = int(rival.get("snatched", 0)) + 1
			continue
		new_stock.append(stall["stock"][j])
	stall["rival_took"] = took
	stall["stock"] = new_stock
	stall["revealed"] = clamp(int(stall["revealed"]) - revealed_removed, 0, new_stock.size())
	if si == current_stall_index:
		add_toast(fill_line(pick_line(WorldData.RIVAL["lines"]["snatch"]), {"item": took[took.size() - 1]}), "warn")
	elif stall.get("visited", false):
		add_toast("%s just bought the %s from %s's stall." % [rival.get("nickname", "Gaz"), took[took.size() - 1], stall["seller_display_name"]], "warn")

# --- clearances ----------------------------------------------------------

func can_do_clearances():
	return vehicle_level >= 3

func add_clearance_lead(source, from_name = ""):
	var idx = rng.randi_range(0, WorldData.CLEARANCE_STORIES.size() - 1)
	var st = WorldData.CLEARANCE_STORIES[idx]
	var size = str(st["size"])
	if size == "large" and vehicle_level < 4:
		size = "medium"
	var lead = {"id": next_lead_id, "story": idx, "size": size, "expires": day + rng.randi_range(3, 6), "source": source, "from": from_name,
		"seed": rng.randi()}
	next_lead_id += 1
	clearance_leads.append(lead)
	var where = st["title"]
	if source == "tip":
		add_toast("%s tipped you off: a house clearance — %s." % [from_name, where], "success")
		add_journal("%s tipped you off about a clearance: %s." % [from_name, where], "good")
	else:
		add_toast("New clearance job in the local paper: %s." % where, "info")
	return lead

func clearance_item_count(size):
	return {"small": [10, 14], "medium": [16, 22], "large": [30, 40]}.get(size, [12, 16])

func build_clearance(lead):
	# Deterministic per lead: generate the whole house now.
	var st = WorldData.CLEARANCE_STORIES[int(lead["story"])]
	var saved_seed = rng.seed
	var saved_state = rng.state
	rng.seed = int(lead["seed"])
	var rng_range = clearance_item_count(lead["size"])
	var n = rng.randi_range(rng_range[0], rng_range[1])
	var cats = st["cats"]
	var rooms_names = ["Loft", "Front room", "Back bedroom", "Garage", "Shed", "Kitchen", "Dining room", "Cellar", "Box room"]
	rooms_names.shuffle()
	var room_count = {"small": 3, "medium": 4, "large": 5}.get(lead["size"], 3)
	var rooms = []
	for i in range(room_count):
		rooms.append({"name": rooms_names[i], "items": [], "looked": false})
	var items = []
	for i in range(n):
		var cat = _weighted_key(cats)
		var fams = content.families_by_cat.get(cat, [])
		var cands = []
		for f in fams:
			if str(f.get("season", "")) == "" or f["season"] == get_season_name():
				cands.append(f)
		if cands.size() == 0:
			continue
		var fam = cands[rng.randi_range(0, cands.size() - 1)]
		if lead["size"] == "large":
			# A proper estate: better things, and more of them worth having.
			var better = []
			for f in cands:
				if float(f["value"][1]) >= 120.0:
					better.append(f)
			if better.size() > 0 and rng.randf() < 0.85:
				fam = better[rng.randi_range(0, better.size() - 1)]
		var it = make_item_from_family(fam, "House Clearance", {"trait_bias": 0.04 if lead["size"] != "large" else 0.08, "hidden_bonus": 0.12, "rarity_boost": 1.2 if lead["size"] != "large" else 3.0})
		it["source"] = "clearance"
		it["seller"] = "House Clearance"
		it["story"] = "Belonged to %s." % str(st["owner"])
		it["provenance"] = str(st["owner"])
		it["house"] = str(st["title"]).substr(0, 1).to_lower() + str(st["title"]).substr(1)
		items.append(it)
		rooms[i % room_count]["items"].append(items.size() - 1)
	if lead["size"] == "large":
		# Every estate has one headline piece: the thing the family didn't know about.
		var heads = []
		for f in item_families:
			if float(f["value"][1]) >= 200.0 and st["cats"].has(f["category"]):
				heads.append(f)
		if heads.size() > 0:
			var hf = heads[rng.randi_range(0, heads.size() - 1)]
			var hi = make_item_from_family(hf, "House Clearance", {"trait_bias": 0.25, "rarity_boost": 40.0})
			hi["source"] = "clearance"
			hi["seller"] = "House Clearance"
			hi["story"] = "Belonged to %s." % str(st["owner"])
			hi["provenance"] = str(st["owner"])
			hi["house"] = str(st["title"]).substr(0, 1).to_lower() + str(st["title"]).substr(1)
			items.append(hi)
			rooms[rng.randi_range(0, room_count - 1)]["items"].append(items.size() - 1)
	var total = 0.0
	for it in items:
		total += true_market_value(it)
	# The family want a quick, fixed price: a fraction of what it'll fetch, with noise the player can't see.
	var price = round(total * rng.randf_range(0.48, 0.98) / 5.0) * 5.0
	rng.seed = saved_seed
	rng.state = saved_state
	return {"lead": lead, "items": items, "rooms": rooms, "price": max(40.0, price), "looked": 0}

func start_clearance(lead_id):
	if not can_do_clearances():
		queue_popup("You need a van for house clearances.")
		return
	if current_time_minutes > 7 * 60 + 30 + int(market_today.get("start_offset", 0)):
		queue_popup("Clearance jobs start first thing. Go tomorrow morning.")
		return
	var lead = null
	for l in clearance_leads:
		if int(l["id"]) == int(lead_id):
			lead = l
	if lead == null:
		return
	clearance = build_clearance(lead)
	market_today["clearance"] = true
	daily_expenses = pitch_fee()
	add_journal("Went to do a clearance: %s." % WorldData.CLEARANCE_STORIES[int(lead["story"])]["title"], "info")
	save_game()
	show_clearance()

func clearance_look(room_index):
	if clearance == null:
		return
	var room = clearance["rooms"][room_index]
	if room["looked"]:
		return
	if energy < 8:
		queue_popup("You're shattered: looking round a room takes 8 energy.")
		return
	energy -= 8
	spend_time(25)
	room["looked"] = true
	clearance["looked"] = int(clearance["looked"]) + 1
	for idx in room["items"]:
		var it = clearance["items"][idx]
		it["quick_look_done"] = true
		it["quick_look_accuracy"] = inspect_accuracy(it)
		it["quick_look_roll"] = rng.randf()
		it["perceived_condition"] = clamp(int(it["condition"]) + (0 if float(it["quick_look_roll"]) < float(it["quick_look_accuracy"]) else rng.randi_range(-3, 3)), 1, 10)
		it["quick_look_note"] = inspect_clue_text(int(it["perceived_condition"]))
		reveal_traits(it, "look")
		if can_specialist_check(it):
			reveal_traits(it, "expert")
			it["expert_checked"] = true
	play_sfx("reveal")
	save_game()
	show_clearance()

func clearance_space_needed():
	if clearance == null:
		return 0
	var n = 0
	for it in clearance["items"]:
		n += size_units(it)
	return n

func accept_clearance():
	if clearance == null:
		return
	var price = float(clearance["price"])
	if cash < price:
		queue_popup("You need £%d to take the job." % int(price))
		return
	var need = clearance_space_needed()
	if inventory_space_used() + need > storage_capacity():
		queue_popup("You need %d free storage space for the haul (you have %d)." % [need, storage_capacity() - inventory_space_used()])
		return
	cash -= price
	day_stats["buy_spend"] += price
	var n = clearance["items"].size()
	var share = price / float(max(1, n))
	for it in clearance["items"]:
		it["paid"] = round(share * 100.0) / 100.0
		it["asking"] = it["paid"]
		hist(it, "Cleared from %s for a share of %s." % [str(it.get("house", "a house")), fmt_money(price)])
		inventory.append(it)
		register_collection(it)
	day_stats["items_bought"] += n
	remove_lead(int(clearance["lead"]["id"]))
	add_journal("Cleared %s: %d items for £%d." % [WorldData.CLEARANCE_STORIES[int(clearance["lead"]["story"])]["title"], n, int(price)], "good")
	if rng.randf() < 0.35:
		rival["beaten"] = int(rival.get("beaten", 0)) + 1
		add_toast(fill_line(pick_line(WorldData.RIVAL["lines"]["lost"]), {}), "success")
	add_xp(20)
	unlock_achievement("House Call")
	clearance = null
	current_time_minutes = 12 * 60
	play_sfx("sale")
	fx_money(-price)
	save_game()
	show_inventory_fresh()

func walk_away_clearance():
	if clearance == null:
		return
	remove_lead(int(clearance["lead"]["id"]))
	clearance = null
	current_time_minutes = max(current_time_minutes, 11 * 60)
	add_toast("You shook hands and left. The morning's mostly gone.", "info")
	save_game()
	show_stall_list()

func remove_lead(id):
	var out = []
	for l in clearance_leads:
		if int(l["id"]) != id:
			out.append(l)
	clearance_leads = out

func expire_leads():
	var out = []
	for l in clearance_leads:
		if int(l["expires"]) < day:
			continue
		out.append(l)
	# Sometimes the rival gets there first.
	if out.size() > 0 and rng.randf() < 0.12:
		var gone = out.pop_at(rng.randi_range(0, out.size() - 1))
		night_events.append({"kind": "bad", "text": fill_line(pick_line(WorldData.RIVAL["lines"]["outbid"]), {})})
	clearance_leads = out
	if can_do_clearances() and clearance_leads.size() < 2 and rng.randf() < 0.18:
		add_clearance_lead("paper")


func _ui_rerender():
	if ui != null:
		ui.rerender()

func _ui_restore_scrolls():
	if ui != null:
		ui.restore_scrolls()

func _unhandled_input(event):
	if ui != null and ui.handle_key(event):
		get_viewport().set_input_as_handled()

func _input(event):
	# Drag-to-scroll anywhere (touch or mouse), even when the finger starts on a button.
	if ui != null and not sim_mode:
		ui.handle_pointer(event)

func _process(delta):
	if ui != null and not sim_mode:
		ui.process_scroll(delta)
# --- debug helpers (used by tools/shot.gd) ---
func _debug_open_first():
	if stalls.size() == 0:
		return
	var st = stalls[current_stall_index]
	if st["stock"].size() == 0:
		return
	selected_stall_uid = int(st["stock"][0]["uid"])
	if ui != null:
		ui.sheet_open = true
		ui.refresh()

func _debug_open_inv(i = 0):
	if i >= inventory.size():
		return
	selected_inv_uid = int(inventory[i]["uid"])
	if ui != null:
		ui.sheet_open = true
		ui.show_inventory()

func _debug_rich_state():
	# Mid-game state for screenshots: some cash, stock with discoveries, a garage.
	cash = 1840.0
	player_level = 7
	premises_level = 1
	vehicle_level = 2
	equipment = {"cleaning": 1, "repair": 1}
	expertise = {"Vinyl": 230.0, "Cameras": 70.0, "Jewellery": 20.0}
	for i in range(8):
		var it = generate_item("Collector")
		it["paid"] = it["asking"]
		inventory.append(it)
		for t in it["traits"]:
			t["clue"] = true
			if rng.randf() < 0.5:
				t["known"] = true
	inventory[0]["listed"] = true
	inventory[0]["listing"] = 45.0
	inventory[1]["condition_checked"] = true
	inventory[1]["basic_researched"] = true
	inventory[1]["basic_comps"] = make_comps(inventory[1], false)
	for r in regulars.slice(0, 4):
		r["rel"] = 55.0
		r["visits"] = 5
	if ui != null:
		ui.refresh()


func max_energy():
	return 100 + int(premises().get("energy", 0))

# --- warehouse trade buyer --------------------------------------------------------
var trade_buyer_day = -1

func trade_buyer_candidates():
	var out = []
	for i in range(inventory.size()):
		var it = inventory[i]
		if it["listed"] or it["auctioned"] or it.get("on_shop_floor", false) or it.get("consigned", false) or it.get("vaulted", false):
			continue
		if it["auth_status"] in ["Confirmed Counterfeit", "Suspected Counterfeit"]:
			continue
		if it["testable"] and not it["tested"]:
			continue
		if int(it.get("days_owned", 0)) < 3:
			continue
		out.append(i)
	return out

func trade_buyer_available():
	return premises_level >= 4 and trade_buyer_day != day and trade_buyer_candidates().size() > 0

func trade_buyer_offer():
	var total = 0.0
	for i in trade_buyer_candidates():
		total += round(true_market_value(inventory[i]) * 0.62)
	return total

func trade_buyer_sale():
	if not trade_buyer_available():
		return
	var idx = trade_buyer_candidates()
	var total = 0.0
	var n = 0
	for j in range(idx.size() - 1, -1, -1):
		var i = idx[j]
		var it = inventory[i]
		var price = max(1.0, round(true_market_value(it) * 0.62))
		cash += price
		total += price
		record_completed_sale(it, price, {"fee": 0.0, "postage": 0.0, "insurance": 0.0, "packaging": 0.0}, "trade")
		inventory.remove_at(i)
		n += 1
	trade_buyer_day = day
	add_toast("A trade buyer backed up to the loading bay and took %d items for £%s." % [n, fmt_int(total)], "success")
	fx_money(total)
	play_sfx("sale")
	save_game()
	show_inventory()
