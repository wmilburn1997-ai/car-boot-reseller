
extends Control

var rng = RandomNumberGenerator.new()

var day = 1
var cash = 300.0
var energy = 100
var reputation = 50
var current_time_minutes = 7 * 60
var daily_expenses = 6.50
var current_stall_index = 0
var stalls = []
var inventory = []
var sold_history = []
var discovered_log = {}
var achievements = {}
var day_stats = {}
var last_rng_line = "No RNG rolls yet."

var category_knowledge = {
	"Clothing": 5,
	"Games": 5,
	"Pokemon": 5,
	"Vinyl": 5,
	"Cameras": 5,
	"Tools": 5,
	"Electronics": 5,
	"Collectables": 5,
	"Jewellery": 5,
	"Books": 5,
	"Home": 5,
	"Musical Instruments": 5,
	"Garden & Outdoor": 5
}

var seller_profiles = {
	"Desperate Seller": {"knowledge":0.42, "haggle":0.23, "pricing":0.88, "fault":1.15, "fake":1.05, "side":0.005, "depth":18, "categories":["Clothing","Games","Pokemon","Electronics","Home","Garden & Outdoor"]},
	"House Clearance": {"knowledge":0.28, "haggle":0.34, "pricing":0.90, "fault":1.30, "fake":0.90, "side":0.010, "depth":26, "categories":["Home","Vinyl","Cameras","Tools","Books","Collectables","Jewellery","Musical Instruments","Garden & Outdoor"]},
	"Clueless Seller": {"knowledge":0.16, "haggle":0.38, "pricing":0.84, "fault":0.95, "fake":0.85, "side":0.002, "depth":15, "categories":["Games","Pokemon","Clothing","Books","Home","Collectables","Garden & Outdoor"]},
	"Regular Seller": {"knowledge":0.60, "haggle":0.56, "pricing":0.98, "fault":1.00, "fake":1.00, "side":0.0015, "depth":14, "categories":["Clothing","Games","Tools","Home","Electronics","Books","Musical Instruments","Garden & Outdoor"]},
	"Collector": {"knowledge":0.90, "haggle":0.78, "pricing":1.06, "fault":0.70, "fake":0.45, "side":0.003, "depth":10, "categories":["Vinyl","Cameras","Collectables","Jewellery","Games","Pokemon","Musical Instruments"]},
	"Dodgy Seller": {"knowledge":0.48, "haggle":0.36, "pricing":0.82, "fault":1.55, "fake":2.40, "side":0.013, "depth":13, "categories":["Clothing","Pokemon","Electronics","Games","Jewellery"]},
	"Dealer": {"knowledge":0.95, "haggle":0.84, "pricing":1.10, "fault":0.65, "fake":0.55, "side":0.001, "depth":8, "categories":["Clothing","Games","Cameras","Vinyl","Collectables","Jewellery","Musical Instruments"]}
}

var item_families = [
	{"name":"Football Shirt","category":"Clothing","value":[18,120],"ask":[15,110],"fake":0.10,"size":"small","testable":false,"specials":["Autographed","Rare Sponsor Print","Match-Worn Indicators"]},
	{"name":"Vintage Track Jacket","category":"Clothing","value":[15,95],"ask":[12,85],"fake":0.08,"size":"small","testable":false,"specials":["Rare Embroidered Variant","Deadstock Tags","Autographed"]},
	{"name":"Designer Hoodie","category":"Clothing","value":[25,180],"ask":[20,150],"fake":0.15,"size":"small","testable":false,"specials":["Limited Colourway","Sample Piece","Autographed"]},
	{"name":"Band T-Shirt","category":"Clothing","value":[8,110],"ask":[5,90],"fake":0.05,"size":"small","testable":false,"specials":["Tour Original","Single Stitch","Autographed"]},
	{"name":"Workwear Jacket","category":"Clothing","value":[20,130],"ask":[15,110],"fake":0.06,"size":"small","testable":false,"specials":["Vintage Union Label","Rare Colour","Deadstock Tags"]},
	{"name":"Pokemon Card Binder","category":"Pokemon","value":[20,220],"ask":[15,180],"fake":0.08,"size":"small","testable":false,"specials":["1st Edition Card","Misprint Card","Autographed Card"]},
	{"name":"Pokemon Card Tin","category":"Pokemon","value":[12,160],"ask":[10,140],"fake":0.07,"size":"small","testable":false,"specials":["Sealed Promo","Error Card","Autographed Insert"]},
	{"name":"Pokemon Deck Box","category":"Pokemon","value":[10,140],"ask":[8,120],"fake":0.08,"size":"small","testable":false,"specials":["Rare Promo","Misprint","Tournament Stamp"]},
	{"name":"Retro Games Bundle","category":"Games","value":[15,150],"ask":[12,130],"fake":0.03,"size":"small","testable":true,"specials":["Rare Variant","Promo Disc","Sealed Game"]},
	{"name":"PS2 Game Bundle","category":"Games","value":[6,90],"ask":[5,80],"fake":0.02,"size":"small","testable":true,"specials":["Rare Horror Title","Promo Copy","Sealed Copy"]},
	{"name":"Game Boy Advance","category":"Games","value":[35,160],"ask":[30,145],"fake":0.04,"size":"small","testable":true,"specials":["Limited Colour","Boxed Complete","Development Cart"]},
	{"name":"Nintendo DS Lite","category":"Games","value":[20,90],"ask":[18,80],"fake":0.03,"size":"small","testable":true,"specials":["Limited Edition","Boxed Complete","Unused Old Stock"]},
	{"name":"GameCube Controller","category":"Games","value":[15,80],"ask":[12,70],"fake":0.03,"size":"small","testable":true,"specials":["Club Nintendo Variant","Unused Old Stock","Rare Colour"]},
	{"name":"35mm Film Camera","category":"Cameras","value":[20,180],"ask":[18,160],"fake":0.01,"size":"small","testable":true,"specials":["Rare Lens Kit","Black Paint Variant","Original Case"]},
	{"name":"Vintage SLR Camera","category":"Cameras","value":[25,220],"ask":[20,190],"fake":0.01,"size":"small","testable":true,"specials":["Rare Lens","Early Serial","Professional Provenance"]},
	{"name":"Digital Compact Camera","category":"Cameras","value":[10,130],"ask":[8,110],"fake":0.01,"size":"small","testable":true,"specials":["Cult Model","Limited Colour","Original Box"]},
	{"name":"35mm Lens","category":"Cameras","value":[15,210],"ask":[12,180],"fake":0.01,"size":"small","testable":true,"specials":["Rare Aperture","Early Production","Original Hood"]},
	{"name":"Vinyl Record Lot","category":"Vinyl","value":[10,150],"ask":[8,130],"fake":0.01,"size":"medium","testable":false,"specials":["First Pressing","Promo Press","Autographed Sleeve"]},
	{"name":"Classic Rock LP","category":"Vinyl","value":[8,180],"ask":[6,150],"fake":0.01,"size":"small","testable":false,"specials":["First Pressing","Mispress","Autographed Sleeve"]},
	{"name":"Punk LP","category":"Vinyl","value":[12,220],"ask":[10,190],"fake":0.01,"size":"small","testable":false,"specials":["Original Press","White Label Promo","Autographed Sleeve"]},
	{"name":"Vintage Wristwatch","category":"Jewellery","value":[15,250],"ask":[12,220],"fake":0.10,"size":"small","testable":true,"specials":["Rare Dial","Military Engraving","Original Papers"]},
	{"name":"Silver Jewellery Lot","category":"Jewellery","value":[15,180],"ask":[12,160],"fake":0.05,"size":"small","testable":false,"specials":["Designer Hallmark","Antique Piece","Provenance Note"]},
	{"name":"Cordless Drill","category":"Tools","value":[15,120],"ask":[12,105],"fake":0.01,"size":"medium","testable":true,"specials":["Pro Model","Unused Battery","Complete Kit"]},
	{"name":"Hand Tool Box","category":"Tools","value":[10,100],"ask":[8,90],"fake":0.01,"size":"medium","testable":false,"specials":["Vintage Maker","Rare Specialist Tool","Complete Set"]},
	{"name":"Portable CD Player","category":"Electronics","value":[8,90],"ask":[6,80],"fake":0.01,"size":"small","testable":true,"specials":["Cult Model","Limited Colour","Boxed Complete"]},
	{"name":"Mini Hi-Fi","category":"Electronics","value":[15,140],"ask":[12,120],"fake":0.01,"size":"large","testable":true,"specials":["Rare Model","Remote Included","Original Box"]},
	{"name":"Vintage Toy Car","category":"Collectables","value":[5,130],"ask":[4,110],"fake":0.03,"size":"small","testable":false,"specials":["Early Casting","Rare Colour","Original Box"]},
	{"name":"Action Figure Lot","category":"Collectables","value":[10,160],"ask":[8,140],"fake":0.04,"size":"small","testable":false,"specials":["First Release","Factory Error","Sealed Figure"]},
	{"name":"Vintage Board Game","category":"Collectables","value":[8,100],"ask":[6,90],"fake":0.01,"size":"medium","testable":false,"specials":["First Edition","Complete Insert","Promotional Version"]},
	{"name":"Coin Lot","category":"Collectables","value":[8,180],"ask":[6,150],"fake":0.02,"size":"small","testable":false,"specials":["Error Coin","Silver Issue","Low Mintage"]},
	{"name":"Ceramic Vase","category":"Home","value":[5,120],"ask":[4,100],"fake":0.01,"size":"medium","testable":false,"specials":["Studio Mark","Early Pattern","Signed Base"]},
	{"name":"Glassware Set","category":"Home","value":[5,90],"ask":[4,80],"fake":0.01,"size":"medium","testable":false,"specials":["Designer Mark","Rare Colour","Complete Set"]},
	{"name":"Old Lamp","category":"Home","value":[3,35],"ask":[2,30],"fake":0.00,"size":"large","testable":true,"specials":["Designer Maker","Original Shade","Vintage Wiring"]},
	{"name":"Paperback Bundle","category":"Books","value":[2,35],"ask":[2,30],"fake":0.00,"size":"medium","testable":false,"specials":["Signed Copy","First Edition","Proof Copy"]},
	{"name":"Hardback Book","category":"Books","value":[3,80],"ask":[2,65],"fake":0.00,"size":"small","testable":false,"specials":["Signed Copy","First Edition","Presentation Copy"]},
	{"name":"DVD Bundle","category":"Home","value":[2,20],"ask":[2,16],"fake":0.00,"size":"medium","testable":false,"specials":[]},
	{"name":"Random Mugs","category":"Home","value":[1,12],"ask":[1,10],"fake":0.00,"size":"medium","testable":false,"specials":[]},
	{"name":"Cable Box","category":"Electronics","value":[1,18],"ask":[1,15],"fake":0.00,"size":"medium","testable":false,"specials":[]},
	{"name":"Leather Jacket","category":"Clothing","value":[30,220],"ask":[25,190],"fake":0.12,"size":"medium","testable":false,"specials":["Vintage Biker Label","Rare Colour","Designer Collab"]},
	{"name":"Denim Jacket","category":"Clothing","value":[10,90],"ask":[8,75],"fake":0.07,"size":"small","testable":false,"specials":["Selvedge Denim","Rare Wash","Deadstock Tags"]},
	{"name":"Silk Scarf","category":"Clothing","value":[5,60],"ask":[4,50],"fake":0.09,"size":"small","testable":false,"specials":["Designer Print","Limited Run","Hand-Rolled Hem"]},
	{"name":"Pokemon Plush Lot","category":"Pokemon","value":[8,90],"ask":[6,75],"fake":0.05,"size":"medium","testable":false,"specials":["Retired Line","Tag Error","Store Display"]},
	{"name":"Pokemon Promo Poster","category":"Pokemon","value":[6,120],"ask":[5,100],"fake":0.06,"size":"medium","testable":false,"specials":["Store Exclusive","Misprint","Signed by Artist"]},
	{"name":"N64 Cartridge Bundle","category":"Games","value":[10,110],"ask":[8,95],"fake":0.03,"size":"small","testable":true,"specials":["Rare Title","Kiosk Demo","Sealed Game"]},
	{"name":"Handheld Console Lot","category":"Games","value":[15,130],"ask":[12,110],"fake":0.03,"size":"small","testable":true,"specials":["Rare Colour","Development Unit","Boxed Complete"]},
	{"name":"Vintage Movie Camera","category":"Cameras","value":[20,200],"ask":[16,170],"fake":0.01,"size":"medium","testable":true,"specials":["Rare Format","Working Motor","Original Case"]},
	{"name":"Camera Tripod","category":"Cameras","value":[5,60],"ask":[4,50],"fake":0.00,"size":"medium","testable":false,"specials":["Studio Grade","Rare Maker","Complete Head"]},
	{"name":"Jazz LP","category":"Vinyl","value":[10,200],"ask":[8,170],"fake":0.01,"size":"small","testable":false,"specials":["Original Press","Rare Label Variant","Autographed Sleeve"]},
	{"name":"Soundtrack LP","category":"Vinyl","value":[6,90],"ask":[5,75],"fake":0.01,"size":"small","testable":false,"specials":["Promo Only","Coloured Vinyl","Autographed Sleeve"]},
	{"name":"Gold Ring","category":"Jewellery","value":[20,300],"ask":[15,260],"fake":0.14,"size":"small","testable":false,"specials":["Hallmarked Antique","Designer Maker","Gemstone Upgrade"]},
	{"name":"Cufflink Set","category":"Jewellery","value":[8,110],"ask":[6,95],"fake":0.08,"size":"small","testable":false,"specials":["Designer Box Set","Engraved Initials","Rare Material"]},
	{"name":"Vintage Hand Plane","category":"Tools","value":[10,90],"ask":[8,75],"fake":0.01,"size":"medium","testable":false,"specials":["Rare Maker","Early Pattern","Complete Set"]},
	{"name":"Socket Set","category":"Tools","value":[10,80],"ask":[8,70],"fake":0.01,"size":"medium","testable":false,"specials":["Pro Grade","Complete Case","Rare Sizes Included"]},
	{"name":"Vintage Turntable","category":"Electronics","value":[15,160],"ask":[12,140],"fake":0.01,"size":"large","testable":true,"specials":["Rare Model","Original Cartridge","Belt-Drive Classic"]},
	{"name":"Retro Calculator","category":"Electronics","value":[3,60],"ask":[2,50],"fake":0.00,"size":"small","testable":true,"specials":["Cult Model","Boxed Complete","Rare Colour"]},
	{"name":"Comic Book Lot","category":"Collectables","value":[5,220],"ask":[4,190],"fake":0.03,"size":"small","testable":false,"specials":["Key Issue","First Print","Signed by Artist"]},
	{"name":"Sports Memorabilia","category":"Collectables","value":[10,250],"ask":[8,220],"fake":0.09,"size":"medium","testable":false,"specials":["Match-Used Item","Signed Item","Limited Edition"]},
	{"name":"Model Train Set","category":"Collectables","value":[15,200],"ask":[12,170],"fake":0.02,"size":"medium","testable":false,"specials":["Rare Livery","Complete Boxed Set","Limited Run"]},
	{"name":"Antique Clock","category":"Home","value":[10,180],"ask":[8,150],"fake":0.02,"size":"medium","testable":true,"specials":["Rare Maker","Working Movement","Original Key"]},
	{"name":"Rug","category":"Home","value":[10,150],"ask":[8,130],"fake":0.02,"size":"large","testable":false,"specials":["Handwoven","Designer Pattern","Rare Size"]},
	{"name":"Vintage Map","category":"Books","value":[5,120],"ask":[4,100],"fake":0.02,"size":"medium","testable":false,"specials":["Rare Edition","Hand-Coloured","Publisher's Proof"]},
	{"name":"Comic Annual","category":"Books","value":[3,40],"ask":[2,35],"fake":0.00,"size":"small","testable":false,"specials":["First Print","Signed Copy","Complete Set"]},
	{"name":"Acoustic Guitar","category":"Musical Instruments","value":[25,300],"ask":[20,260],"fake":0.03,"size":"large","testable":false,"specials":["Vintage Luthier","Rare Wood","Celebrity Owned"]},
	{"name":"Vintage Amplifier","category":"Musical Instruments","value":[20,250],"ask":[16,220],"fake":0.02,"size":"large","testable":true,"specials":["Valve Classic","Rare Model","Original Cover"]},
	{"name":"Trumpet","category":"Musical Instruments","value":[15,180],"ask":[12,150],"fake":0.02,"size":"medium","testable":false,"specials":["Pro Model","Rare Finish","Engraved Bell"]},
	{"name":"Violin","category":"Musical Instruments","value":[20,220],"ask":[16,190],"fake":0.03,"size":"medium","testable":false,"specials":["Handmade","Rare Maker's Mark","Original Case"]},
	{"name":"Harmonica Set","category":"Musical Instruments","value":[5,60],"ask":[4,50],"fake":0.01,"size":"small","testable":false,"specials":["Vintage Maker","Boxed Set","Rare Key"]},
	{"name":"Garden Tool Set","category":"Garden & Outdoor","value":[8,80],"ask":[6,70],"fake":0.00,"size":"medium","testable":false,"specials":["Vintage Maker","Complete Set","Rare Pattern"]},
	{"name":"Patio Furniture Set","category":"Garden & Outdoor","value":[15,150],"ask":[12,130],"fake":0.00,"size":"large","testable":false,"specials":["Designer Set","Rare Material","Complete Set"]},
	{"name":"Vintage Wheelbarrow","category":"Garden & Outdoor","value":[5,50],"ask":[4,40],"fake":0.00,"size":"large","testable":false,"specials":["Rare Maker","Original Paint","Working Order"]},
	{"name":"Camping Stove","category":"Garden & Outdoor","value":[5,60],"ask":[4,50],"fake":0.00,"size":"medium","testable":true,"specials":["Rare Model","Unused Old Stock","Complete Kit"]},
	{"name":"Fishing Rod Set","category":"Garden & Outdoor","value":[8,90],"ask":[6,75],"fake":0.01,"size":"medium","testable":false,"specials":["Pro Grade","Rare Maker","Complete Tackle"]}
]

var rarity_table = [
	{"tier":"Common","one_in":1,"chance":0.9400},
	{"tier":"Uncommon","one_in":25,"chance":0.0400},
	{"tier":"Rare","one_in":125,"chance":0.0120},
	{"tier":"Very Rare","one_in":750,"chance":0.0060},
	{"tier":"Grail","one_in":5000,"chance":0.0020}
]

var package_table = [
	{"tier":"Poor","chance":0.55},
	{"tier":"Average","chance":0.25},
	{"tier":"Good","chance":0.14},
	{"tier":"Excellent","chance":0.05},
	{"tier":"Jackpot","chance":0.009},
	{"tier":"Grail","chance":0.001}
]

var root_vbox
var page_scroll
var stat_labels = {}
var body
var footer_label
var status_label
var status_panel
var tooltip_panel
var status_hide_timer
var blocked_popup
var blocked_popup_label
var blocked_popup_timer
var tooltip_is_held = false


var bag_level = 0
var storage_level = 0
var toolbox_level = 0
var eye_level = 0
var fee_level = 0
var carry_used = 0
var mystery_packages_left = 0
var current_trends = {}
var trend_headlines = []
var current_week = 1
var negative_days_streak = 0
var last_scroll_value = 0.0
var current_screen_name = "show_stall"
var tooltip_saved_text = ""
var total_haggled_savings = 0.0
var pending_instant_sale_banner = ""
var inventory_tab = "unlisted"
var package_insight_level = 0
var persuasion_level = 0
const PACKAGE_INSIGHT_MAX = 20
const PERSUASION_MAX = 20

func package_insight_cost(level):
	return round(50.0 * pow(1.28, level))

func persuasion_cost(level):
	return round(50.0 * pow(1.28, level))

func get_package_chances():
	var shift_frac = float(package_insight_level) / 100.0
	var chances = []
	for row in package_table:
		var tier = row["tier"]
		var base = float(row["chance"])
		var adj = base
		if tier == "Poor":
			adj = max(0.05, base - shift_frac)
		elif tier == "Average":
			adj = base + shift_frac * 0.60
		elif tier == "Good":
			adj = base + shift_frac * 0.30
		elif tier == "Excellent":
			adj = base + shift_frac * 0.08
		elif tier == "Jackpot":
			adj = base + shift_frac * 0.015
		elif tier == "Grail":
			adj = base + shift_frac * 0.005
		chances.append({"tier":tier, "chance":adj})
	return chances

var bag_upgrades = [
	{"name":"Canvas Tote","capacity":6,"cost":0},
	{"name":"Large Holdall","capacity":10,"cost":75},
	{"name":"Folding Trolley","capacity":16,"cost":220},
	{"name":"Van Crates","capacity":24,"cost":650},
	{"name":"Small Van Load","capacity":36,"cost":1800}
]

var storage_upgrades = [
	{"name":"Bedroom Corner","capacity":18,"cost":0},
	{"name":"Heavy-Duty Shelving","capacity":30,"cost":120},
	{"name":"Garage Storage","capacity":50,"cost":350},
	{"name":"Lock-up Unit","capacity":85,"cost":950},
	{"name":"Small Warehouse","capacity":150,"cost":2800},
	{"name":"Distribution Unit","capacity":260,"cost":7500}
]

var toolbox_upgrades = [
	{"name":"No Repair Kit","bonus":0.0,"cost":0},
	{"name":"Basic Toolbox","bonus":0.08,"cost":90},
	{"name":"Electronics Kit","bonus":0.16,"cost":260},
	{"name":"Workbench","bonus":0.25,"cost":700},
	{"name":"Full Workshop","bonus":0.34,"cost":1900}
]

var eye_upgrades = [
	{"name":"Untrained Eye","accuracy":0.60,"cost":0},
	{"name":"Boot Sale Regular","accuracy":0.68,"cost":60},
	{"name":"Experienced Eye","accuracy":0.76,"cost":180},
	{"name":"Sharp Eye","accuracy":0.84,"cost":450},
	{"name":"Expert Eye","accuracy":0.90,"cost":1100}
]

var fee_upgrades = [
	{"name":"Casual Seller","fee":0.115,"cost":0},
	{"name":"Registered Seller","fee":0.095,"cost":400},
	{"name":"Business Account","fee":0.075,"cost":1200},
	{"name":"Trade Account","fee":0.055,"cost":3200},
	{"name":"Wholesale Partner","fee":0.035,"cost":9000}
]

var special_event_profiles = {
	"Desperate Seller": {"title":"Something in the Car","flavor":"\"Look, I need this gone today. I've got more of this in the car if you want first look.\"","price_mult":[0.55,0.80],"value_mult":[0.85,1.15],"fault_bonus":0.10},
	"House Clearance": {"title":"More in the Van","flavor":"\"There's a lot more of this back in the van, actually. Take it or leave it.\"","price_mult":[0.75,1.00],"value_mult":[0.90,1.30],"fault_bonus":0.05},
	"Collector": {"title":"From My Personal Collection","flavor":"\"I don't usually let this go... but from my personal collection, if you're serious.\"","price_mult":[0.95,1.30],"value_mult":[1.30,2.20],"fault_bonus":-0.05},
	"Dodgy Seller": {"title":"Bit of a Grey Area","flavor":"\"Between you and me, this one's a bit of a grey area — no questions asked, cash only.\"","price_mult":[0.45,0.70],"value_mult":[1.00,1.80],"fault_bonus":0.08,"fake_bonus":0.35}
}

var pending_special_offer = null

func _ready():
	rng.randomize()
	reset_day_stats()
	generate_weekly_trends()
	generate_day()
	adjust_scale_for_device()
	build_ui()
	show_stall()
	get_tree().root.size_changed.connect(_on_size_changed)

func _on_size_changed():
	adjust_scale_for_device()
	match current_screen_name:
		"show_stall":
			show_stall()
		"show_stall_list":
			show_stall_list()
		"show_special_offer":
			show_special_offer()
		"show_inventory":
			show_inventory()
		"show_trends":
			show_trends()
		"show_shop":
			show_shop()
		"show_sold_history":
			show_sold_history()
		"show_collection_log":
			show_collection_log()
		"show_achievements":
			show_achievements()
		_:
			show_stall()

func adjust_scale_for_device():
	var w = 0.0
	var h = 0.0
	if OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge"):
		var js = Engine.get_singleton("JavaScriptBridge")
		w = float(js.call("eval", "window.innerWidth"))
		h = float(js.call("eval", "window.innerHeight"))
	if w <= 0.0 or h <= 0.0:
		var vp_size = get_window().size
		w = float(vp_size.x)
		h = float(vp_size.y)
	var auto_shrink = min(w / 1600.0, h / 900.0)
	auto_shrink = max(auto_shrink, 0.05)
	get_window().content_scale_factor = clamp(1.0 / auto_shrink, 1.0, 4.5)

func build_ui():
	# Global UI font: Jersey 10.
	# Keep Jersey10-Regular.ttf in res://fonts/
	var global_theme = Theme.new()
	var jersey_font = load("res://fonts/Jersey10-Regular.ttf")
	if jersey_font != null:
		global_theme.default_font = jersey_font
		# Use Godot's imported font resource so the same font is packaged correctly for Web exports.
		for control_type in ["Label", "Button", "CheckButton", "CheckBox", "LineEdit", "TextEdit", "RichTextLabel", "SpinBox", "OptionButton", "MenuButton", "TooltipLabel"]:
			global_theme.set_font("font", control_type, jersey_font)
		theme = global_theme
	else:
		push_error("Could not load UI font: res://fonts/Jersey10-Regular.ttf")

	var bg = ColorRect.new()
	bg.color = Color(0.035, 0.045, 0.06, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	root_vbox = VBoxContainer.new()
	root_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 8)
	root_vbox.offset_left = 16
	root_vbox.offset_top = 12
	root_vbox.offset_right = -16
	root_vbox.offset_bottom = -12
	add_child(root_vbox)

	var header_row = PanelContainer.new()
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color(0.055,0.07,0.095,1.0)
	header_style.corner_radius_top_left = 8
	header_style.corner_radius_top_right = 8
	header_style.corner_radius_bottom_left = 8
	header_style.corner_radius_bottom_right = 8
	header_style.content_margin_left = 10
	header_style.content_margin_right = 10
	header_style.content_margin_top = 6
	header_style.content_margin_bottom = 6
	header_row.add_theme_stylebox_override("panel", header_style)
	root_vbox.add_child(header_row)

	var header_vbox = VBoxContainer.new()
	header_vbox.add_theme_constant_override("separation", 6)
	header_row.add_child(header_vbox)

	var primary_row = HBoxContainer.new()
	primary_row.add_theme_constant_override("separation", 8)
	header_vbox.add_child(primary_row)
	add_stat_chip(primary_row, "cash", "Cash on hand. Staying negative accrues daily overdraft interest, and 4 consecutive days in the red ends the run.")
	add_stat_chip(primary_row, "carry", "Space used in your car-boot bag today vs its capacity. Upgrade capacity in the Shop.")
	add_stat_chip(primary_row, "storage", "Space used in home storage vs its capacity. Upgrade capacity in the Shop.")

	var secondary_row = HBoxContainer.new()
	secondary_row.add_theme_constant_override("separation", 5)
	header_vbox.add_child(secondary_row)
	add_stat_chip(secondary_row, "energy", "Energy left today. Most actions cost some; it refills to 100 at the start of each day.", true)
	add_stat_chip(secondary_row, "rep", "Reputation. Clean sales raise it, returns lower it. Higher reputation nudges Buyer Interest up slightly.", true)
	add_stat_chip(secondary_row, "listed", "Number of items you currently have listed for sale.", true)
	add_stat_chip(secondary_row, "day", "In-game day and current time. The car boot closes at 12:00.", true)
	var end_day_button = Button.new()
	end_day_button.text = "End Day"
	end_day_button.tooltip_text = "End the day, resolve pending sales, and start fresh tomorrow."
	style_button(end_day_button, "danger")
	end_day_button.custom_minimum_size = Vector2(0, 28)
	end_day_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	end_day_button.size_flags_stretch_ratio = 1.0
	end_day_button.add_theme_font_size_override("font_size", 14)
	end_day_button.pressed.connect(end_day)
	secondary_row.add_child(end_day_button)

	var nav_panel = PanelContainer.new()
	var nav_style = StyleBoxFlat.new()
	nav_style.bg_color = Color(0.07,0.09,0.12,1.0)
	nav_style.corner_radius_top_left = 8
	nav_style.corner_radius_top_right = 8
	nav_style.corner_radius_bottom_left = 8
	nav_style.corner_radius_bottom_right = 8
	nav_style.content_margin_left = 8
	nav_style.content_margin_right = 8
	nav_style.content_margin_top = 7
	nav_style.content_margin_bottom = 7
	nav_panel.add_theme_stylebox_override("panel", nav_style)
	root_vbox.add_child(nav_panel)

	var nav = HBoxContainer.new()
	nav.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_theme_constant_override("separation", 5)
	nav_panel.add_child(nav)
	add_nav_button(nav, "Stall", Callable(self, "show_stall"))
	add_nav_button(nav, "Stalls", Callable(self, "show_stall_list"))
	add_nav_button(nav, "Inventory", Callable(self, "show_inventory_fresh"))
	add_nav_button(nav, "£ Sold", Callable(self, "show_sold_history"))
	add_nav_button(nav, "Shop", Callable(self, "show_shop"))
	add_nav_button(nav, "More", Callable(self, "show_more_menu"))

	page_scroll = ScrollContainer.new()
	page_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(page_scroll)
	remember_scroll(page_scroll)

	var page_content = VBoxContainer.new()
	page_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_content.add_theme_constant_override("separation", 7)
	page_scroll.add_child(page_content)

	if ResourceLoader.exists("res://banner.png"):
		var banner_tex = load("res://banner.png")
		var banner_rect = TextureRect.new()
		banner_rect.texture = banner_tex
		banner_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		banner_rect.stretch_mode = TextureRect.STRETCH_SCALE
		banner_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		page_content.add_child(banner_rect)

	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 7)
	page_content.add_child(body)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", Color(0.95,0.84,0.62,1.0))

	tooltip_panel = PanelContainer.new()
	tooltip_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	tooltip_panel.offset_left = 16
	tooltip_panel.offset_right = -16
	tooltip_panel.offset_top = -64
	tooltip_panel.offset_bottom = -14
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_panel.visible = false
	var tooltip_style = StyleBoxFlat.new()
	tooltip_style.bg_color = Color(0.06,0.07,0.09,0.96)
	tooltip_style.border_width_left = 1
	tooltip_style.border_width_top = 1
	tooltip_style.border_width_right = 1
	tooltip_style.border_width_bottom = 1
	tooltip_style.border_color = Color(0.30,0.28,0.22,1.0)
	tooltip_style.corner_radius_top_left = 8
	tooltip_style.corner_radius_top_right = 8
	tooltip_style.corner_radius_bottom_left = 8
	tooltip_style.corner_radius_bottom_right = 8
	tooltip_style.content_margin_left = 10
	tooltip_style.content_margin_right = 10
	tooltip_style.content_margin_top = 8
	tooltip_style.content_margin_bottom = 8
	tooltip_panel.add_theme_stylebox_override("panel", tooltip_style)
	add_child(tooltip_panel)
	tooltip_panel.add_child(status_label)

	footer_label = Label.new()
	footer_label.visible = false

	blocked_popup = PanelContainer.new()
	blocked_popup.set_anchors_preset(Control.PRESET_TOP_LEFT)
	blocked_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blocked_popup.visible = false
	blocked_popup.z_index = 100
	var blocked_style = StyleBoxFlat.new()
	blocked_style.bg_color = Color(0.16,0.05,0.05,0.97)
	blocked_style.border_width_left = 2
	blocked_style.border_width_top = 2
	blocked_style.border_width_right = 2
	blocked_style.border_width_bottom = 2
	blocked_style.border_color = Color(0.75,0.35,0.32,1.0)
	blocked_style.corner_radius_top_left = 10
	blocked_style.corner_radius_top_right = 10
	blocked_style.corner_radius_bottom_left = 10
	blocked_style.corner_radius_bottom_right = 10
	blocked_style.content_margin_left = 22
	blocked_style.content_margin_right = 22
	blocked_style.content_margin_top = 16
	blocked_style.content_margin_bottom = 16
	blocked_popup.add_theme_stylebox_override("panel", blocked_style)
	add_child(blocked_popup)

	blocked_popup_label = Label.new()
	blocked_popup_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blocked_popup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	blocked_popup_label.custom_minimum_size = Vector2(220, 0)
	blocked_popup_label.add_theme_font_size_override("font_size", 16)
	blocked_popup_label.add_theme_color_override("font_color", Color(0.95,0.88,0.86,1.0))
	blocked_popup.add_child(blocked_popup_label)

	blocked_popup_timer = Timer.new()
	blocked_popup_timer.one_shot = true
	blocked_popup_timer.wait_time = 2.6
	blocked_popup_timer.timeout.connect(Callable(self, "_hide_blocked_popup"))
	add_child(blocked_popup_timer)

	update_header()

func show_more_menu():
	current_screen_name = "show_more_menu"
	clear_body()
	update_header()
	var title = Label.new()
	title.add_theme_font_size_override("font_size", 20)
	title.text = "MORE"
	body.add_child(title)
	var more_row = HFlowContainer.new()
	more_row.add_theme_constant_override("separation", 8)
	body.add_child(more_row)
	add_nav_button(more_row, "Trends", Callable(self, "show_trends"))
	add_nav_button(more_row, "Collection", Callable(self, "show_collection_log"))
	add_nav_button(more_row, "Achievements", Callable(self, "show_achievements"))
	add_nav_button(more_row, "Patch Notes", Callable(self, "show_patch_notes"))
	footer_label.text = ""

func make_icon(kind, color):
	var icon = Control.new()
	icon.custom_minimum_size = Vector2(18, 18)
	icon.draw.connect(Callable(self, "_draw_icon").bind(icon, kind, color))
	icon.queue_redraw()
	return icon

func _draw_icon(icon, kind, color):
	var shade = Color(0, 0, 0, 0.35)
	match kind:
		"cash":
			icon.draw_circle(Vector2(9, 9), 8, color)
			icon.draw_arc(Vector2(9, 9), 5, 0, TAU, 20, shade, 1.5, true)
		"carry":
			var pts = PackedVector2Array([Vector2(4, 7), Vector2(14, 7), Vector2(15, 17), Vector2(3, 17)])
			icon.draw_colored_polygon(pts, color)
			icon.draw_rect(Rect2(6, 2, 6, 5), color)
			icon.draw_line(Vector2(6, 2), Vector2(6, 7), shade, 1.0)
			icon.draw_line(Vector2(12, 2), Vector2(12, 7), shade, 1.0)
		"storage":
			icon.draw_rect(Rect2(3, 6, 10, 10), color, false, 2.0)
			icon.draw_rect(Rect2(6, 3, 10, 10), color, false, 2.0)
			icon.draw_line(Vector2(3, 6), Vector2(6, 3), color, 2.0)
			icon.draw_line(Vector2(13, 6), Vector2(16, 3), color, 2.0)
			icon.draw_line(Vector2(3, 16), Vector2(6, 13), color, 2.0)
			icon.draw_line(Vector2(13, 16), Vector2(16, 13), color, 2.0)

func add_stat_chip(parent, key, tooltip, compact = false):
	var pill = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	var bg = Color(0.10,0.13,0.18,1.0)
	var border = Color(0.18,0.22,0.28,1.0)
	if key == "cash":
		bg = Color(0.07,0.16,0.11,1.0)
		border = Color(0.20,0.55,0.32,1.0)
	elif key == "carry":
		bg = Color(0.06,0.12,0.20,1.0)
		border = Color(0.20,0.45,0.72,1.0)
	elif key == "storage":
		bg = Color(0.20,0.13,0.05,1.0)
		border = Color(0.72,0.50,0.18,1.0)
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
	sb.content_margin_left = 6 if compact else 10
	sb.content_margin_right = 6 if compact else 10
	sb.content_margin_top = 2 if compact else 4
	sb.content_margin_bottom = 2 if compact else 4
	pill.add_theme_stylebox_override("panel", sb)
	pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pill.size_flags_stretch_ratio = 1.0
	parent.add_child(pill)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	if compact:
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.alignment = BoxContainer.ALIGNMENT_CENTER
	pill.add_child(row)
	if key == "cash" or key == "carry" or key == "storage":
		var icon_color = border
		row.add_child(make_icon(key, icon_color))
	var lbl = Label.new()
	lbl.tooltip_text = tooltip
	lbl.add_theme_font_size_override("font_size", 14 if compact else 15)
	if compact:
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color(0.92,0.95,1.0,1.0))
	row.add_child(lbl)
	stat_labels[key] = lbl

func add_nav_button(parent, text, callback):
	var b = Button.new()
	b.text = text
	b.pressed.connect(func(): last_scroll_value = 0.0; page_scroll.scroll_vertical = 0)
	b.pressed.connect(callback)
	style_button(b, "nav")
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Give the longer primary destinations a little more room while keeping all six on one line.
	if text == "Inventory":
		b.size_flags_stretch_ratio = 1.35
	elif text == "Stall" or text == "Stalls":
		b.size_flags_stretch_ratio = 1.08
	elif text == "£ Sold":
		b.size_flags_stretch_ratio = 1.02
	else:
		b.size_flags_stretch_ratio = 0.92
	b.add_theme_font_size_override("font_size", 15)
	parent.add_child(b)

func style_button(button, kind):
	var normal = StyleBoxFlat.new()
	var hover = StyleBoxFlat.new()
	var pressed = StyleBoxFlat.new()
	if kind == "buy":
		normal.bg_color = Color(0.09,0.30,0.22,1.0)
		hover.bg_color = Color(0.11,0.40,0.28,1.0)
		pressed.bg_color = Color(0.07,0.24,0.18,1.0)
	elif kind == "danger":
		normal.bg_color = Color(0.34,0.10,0.12,1.0)
		hover.bg_color = Color(0.46,0.13,0.16,1.0)
		pressed.bg_color = Color(0.26,0.07,0.09,1.0)
	elif kind == "action":
		normal.bg_color = Color(0.10,0.20,0.35,1.0)
		hover.bg_color = Color(0.13,0.27,0.46,1.0)
		pressed.bg_color = Color(0.08,0.16,0.29,1.0)
	else:
		normal.bg_color = Color(0.12,0.14,0.18,1.0)
		hover.bg_color = Color(0.18,0.21,0.27,1.0)
		pressed.bg_color = Color(0.08,0.10,0.14,1.0)
	for sb in [normal, hover, pressed]:
		sb.corner_radius_top_left = 6
		sb.corner_radius_top_right = 6
		sb.corner_radius_bottom_left = 6
		sb.corner_radius_bottom_right = 6
		sb.content_margin_left = 6
		sb.content_margin_right = 6
		sb.content_margin_top = 6
		sb.content_margin_bottom = 6
	button.custom_minimum_size.y = 36
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.button_down.connect(Callable(self, "_on_tooltip_button_down").bind(button))
	button.button_up.connect(Callable(self, "_on_tooltip_button_up"))

func _on_tooltip_button_down(button):
	if button.tooltip_text == "":
		return
	tooltip_is_held = true
	status_label.text = button.tooltip_text
	if tooltip_panel != null:
		tooltip_panel.visible = true
		tooltip_panel.move_to_front()

func _on_tooltip_button_up():
	tooltip_is_held = false
	if tooltip_panel != null:
		tooltip_panel.visible = false

func update_highest_max(item, action_key, new_max):
	if new_max > float(item["highest_max_price"]):
		item["highest_max_price"] = new_max
		item["highest_max_action"] = action_key

func make_completed_action_box(header_text, note_bbcode_text, note_color = "#b8dcff"):
	var panel = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.09,0.10,0.12,1.0)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.20,0.22,0.26,1.0)
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", sb)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	var header = Label.new()
	header.text = header_text
	header.add_theme_font_size_override("font_size", 15)
	header.add_theme_color_override("font_color", Color(0.58,0.63,0.70,1.0))
	box.add_child(header)
	if note_bbcode_text != "":
		var note = RichTextLabel.new()
		note.bbcode_enabled = true
		note.fit_content = true
		note.scroll_active = false
		note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		note.add_theme_font_size_override("normal_font_size", 14)
		note.add_theme_color_override("default_color", Color(note_color))
		note.text = note_bbcode_text
		box.add_child(note)
	return panel

func make_card():
	var panel = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.065,0.078,0.10,1.0)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.13,0.17,0.22,1.0)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", sb)
	return panel

func clear_body():
	for c in body.get_children():
		c.queue_free()

var active_scroll_container = null

func remember_scroll(scroll):
	active_scroll_container = scroll
	scroll.get_v_scroll_bar().value_changed.connect(Callable(self, "_on_scroll_changed"))
	call_deferred("_restore_scroll", scroll)

func _input(event):
	if active_scroll_container == null or not is_instance_valid(active_scroll_container):
		return
	if event is InputEventScreenDrag:
		active_scroll_container.scroll_vertical += int(-event.relative.y)
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		active_scroll_container.scroll_vertical += int(-event.relative.y)

func set_status(text, color = null):
	status_label.text = text

func show_blocked_popup(text):
	if blocked_popup == null:
		return
	blocked_popup_label.text = text
	blocked_popup.visible = true
	blocked_popup.move_to_front()
	call_deferred("_center_blocked_popup")
	blocked_popup_timer.start()

func _center_blocked_popup():
	if blocked_popup == null or not blocked_popup.visible:
		return
	var viewport_size = get_viewport_rect().size
	blocked_popup.position = (viewport_size - blocked_popup.size) / 2.0

func _hide_blocked_popup():
	if blocked_popup != null:
		blocked_popup.visible = false

func _show_status_overlay(auto_hide = true):
	if status_panel == null:
		return
	status_panel.visible = true
	status_panel.move_to_front()
	if auto_hide and not tooltip_is_held and status_hide_timer != null:
		status_hide_timer.start()

func _hide_status_overlay():
	if tooltip_is_held:
		return
	if status_panel != null:
		status_panel.visible = false

func _on_scroll_changed(value):
	last_scroll_value = value

func _restore_scroll(scroll):
	if is_instance_valid(scroll):
		scroll.scroll_vertical = int(last_scroll_value)

func update_header():
	var listed_count = 0
	for item in inventory:
		if item["listed"]:
			listed_count += 1
	var bag = bag_upgrades[bag_level]
	var storage = storage_upgrades[storage_level]
	stat_labels["day"].text = "Day %d %s" % [day, format_time()]
	stat_labels["cash"].text = "£%.2f" % cash
	if cash < 0.0:
		stat_labels["cash"].add_theme_color_override("font_color", Color(0.95,0.55,0.45,1.0))
	else:
		stat_labels["cash"].add_theme_color_override("font_color", Color(0.92,0.95,1.0,1.0))
	stat_labels["energy"].text = "E %d/100" % energy
	if energy <= 15:
		stat_labels["energy"].add_theme_color_override("font_color", Color(0.95,0.55,0.45,1.0))
	elif energy <= 35:
		stat_labels["energy"].add_theme_color_override("font_color", Color(0.90,0.78,0.45,1.0))
	else:
		stat_labels["energy"].add_theme_color_override("font_color", Color(0.92,0.95,1.0,1.0))
	stat_labels["rep"].text = "Rep %d" % reputation
	stat_labels["carry"].text = "Carry %d/%d" % [carry_used, bag["capacity"]]
	stat_labels["storage"].text = "Storage %d/%d" % [inventory_space_used(), storage["capacity"]]
	stat_labels["listed"].text = "Listed %d" % listed_count
	footer_label.text = "Last RNG: " + last_rng_line

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
		"start_cash": cash,
		"buy_spend": 0.0,
		"sales_revenue": 0.0,
		"fees": 0.0,
		"postage": 0.0,
		"research": 0.0,
		"authentication": 0.0,
		"repairs": 0.0,
		"expenses": 0.0,
		"rent": 0.0,
		"upkeep": 0.0,
		"interest": 0.0,
		"items_bought": 0,
		"items_sold": 0,
		"items_scrapped": 0,
		"returns": 0,
		"collection_adds": 0,
		"rarest_one_in": 1,
		"rng_events": []
	}

func compute_upkeep():
	var tier_sum = bag_level + storage_level + toolbox_level + eye_level + fee_level
	return float(tier_sum) * 1.75

func generate_weekly_trends():
	current_week = int((day - 1) / 7) + 1
	current_trends.clear()
	trend_headlines.clear()
	var categories = category_knowledge.keys()
	var season = get_season_name()
	for category in categories:
		var mult = rng.randf_range(0.92, 1.08)
		if season == "Winter" and category == "Clothing":
			mult *= 1.12
		if season == "Winter" and (category == "Games" or category == "Pokemon"):
			mult *= 1.07
		if season == "Summer" and (category == "Tools" or category == "Cameras"):
			mult *= 1.07
		current_trends[category] = clamp(mult, 0.82, 1.22)
	var hot = categories[rng.randi_range(0, categories.size() - 1)]
	current_trends[hot] = clamp(float(current_trends[hot]) * rng.randf_range(1.10, 1.20), 0.82, 1.30)
	var cold = categories[rng.randi_range(0, categories.size() - 1)]
	if cold == hot and categories.size() > 1:
		var next_index = (categories.find(hot) + 1) % categories.size()
		cold = categories[next_index]
	current_trends[cold] = clamp(float(current_trends[cold]) * rng.randf_range(0.82, 0.92), 0.72, 1.30)
	trend_headlines.append("%s is attracting more buyers this week." % hot)
	trend_headlines.append("%s demand looks softer than normal." % cold)

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
	mystery_packages_left = rng.randi_range(0, 2)
	daily_expenses = min(25.0, 6.50 + float(day - 1) * 0.25)
	var seller_names = seller_profiles.keys()
	var count = rng.randi_range(6, 8)
	for i in range(count):
		var seller = seller_names[rng.randi_range(0, seller_names.size() - 1)]
		var profile = seller_profiles[seller]
		var stall = {
			"seller": seller,
			"stock": [],
			"revealed": 0,
			"packing_minute": rng.randi_range(10 * 60 + 45, 12 * 60),
			"crowd": rng.randf_range(0.10, 0.45),
			"banned_today": false
		}
		var stock_count = rng.randi_range(max(6, int(profile["depth"] * 0.65)), profile["depth"])
		for j in range(stock_count):
			stall["stock"].append(generate_item(seller))
		stall["revealed"] = min(rng.randi_range(4, 6), stock_count)
		stalls.append(stall)
	current_stall_index = 0

func generate_item(seller):
	var profile = seller_profiles[seller]
	var candidates = []
	for family in item_families:
		if family["category"] in profile["categories"]:
			candidates.append(family)
	if candidates.size() == 0:
		candidates = item_families
	var base = candidates[rng.randi_range(0, candidates.size() - 1)].duplicate(true)

	var rarity_roll = rng.randf()
	var rarity = rarity_table[0]
	var cumulative = 0.0
	for row in rarity_table:
		cumulative += row["chance"]
		if rarity_roll <= cumulative:
			rarity = row
			break

	var rarity_mult = 1.0
	if rarity["tier"] == "Uncommon":
		rarity_mult = rng.randf_range(1.15, 1.45)
	elif rarity["tier"] == "Rare":
		rarity_mult = rng.randf_range(1.5, 2.2)
	elif rarity["tier"] == "Very Rare":
		rarity_mult = rng.randf_range(2.4, 4.0)
	elif rarity["tier"] == "Grail":
		rarity_mult = rng.randf_range(5.0, 12.0)

	var condition = rng.randi_range(3, 10)
	var true_value = rng.randf_range(base["value"][0], base["value"][1]) * rarity_mult
	var fake_chance = clamp(float(base["fake"]) * float(profile["fake"]), 0.0, 0.60)
	var authentic = rng.randf() > fake_chance
	var fault_chance = get_fault_chance(base["name"], base["category"], condition, float(profile["fault"]))
	var fault_roll = rng.randf()
	var fault = fault_roll < fault_chance
	var fault_severity = "None"
	if fault:
		var severity_roll = rng.randf()
		if severity_roll < 0.45:
			fault_severity = "Minor"
		elif severity_roll < 0.75:
			fault_severity = "Moderate"
		elif severity_roll < 0.93:
			fault_severity = "Major"
		else:
			fault_severity = "Dead"

	var hidden_special = ""
	var special_genuine = true
	if base["specials"].size() > 0:
		var special_chance = 0.035
		if rarity["tier"] == "Uncommon":
			special_chance = 0.07
		elif rarity["tier"] == "Rare":
			special_chance = 0.14
		elif rarity["tier"] == "Very Rare":
			special_chance = 0.22
		elif rarity["tier"] == "Grail":
			special_chance = 0.40
		if rng.randf() < special_chance:
			hidden_special = base["specials"][rng.randi_range(0, base["specials"].size() - 1)]
			special_genuine = rng.randf() > 0.18
			if special_genuine:
				true_value *= rng.randf_range(1.5, 4.5)

	var random_ask = rng.randf_range(base["ask"][0], base["ask"][1])
	var marketish = true_value * float(profile["pricing"]) * rng.randf_range(0.78, 1.20)
	var asking = lerp(random_ask, marketish, float(profile["knowledge"]))
	asking = max(1.0, round(asking))

	return {
		"name": base["name"],
		"category": base["category"],
		"condition": condition,
		"condition_checked": false,
		"quick_look_done": false,
		"quick_look_note": "",
		"quick_look_accuracy": 0.0,
		"quick_look_roll": 0.0,
		"size": base["size"],
		"testable": base["testable"],
		"seller": seller,
		"true_value": true_value,
		"asking": asking,
		"paid": 0.0,
		"authentic": authentic,
		"auth_status": "Unauthenticated",
		"auth_attempted": false,
		"fake_chance": fake_chance,
		"fault": fault,
		"fault_chance": fault_chance,
		"fault_roll": fault_roll,
		"fault_severity": fault_severity,
		"tested": false,
		"basic_researched": false,
		"basic_comps": "",
		"deep_researched": false,
		"research_note": "",
		"rare_variant_hit": false,
		"rare_variant_roll_pct": 0.0,
		"rare_variant_tier": "",
		"rare_variant_mult": 1.0,
		"hidden_special": hidden_special,
		"special_discovered": false,
		"special_genuine": special_genuine,
		"rarity": rarity["tier"],
		"one_in": rarity["one_in"],
		"identified_mult": 1.0,
		"listing": 0.0,
		"listed": false,
		"repair_attempted": false,
		"haggle_attempted": false,
		"seller_refuses": false,
		"haggle_result": "",
		"haggle_savings": 0.0,
		"extra_spend": 0.0,
		"condition_price_note": "",
		"auth_note": "",
		"haggle_note": "",
		"repair_note": "",
		"buy_block_note": "",
		"listing_block_note": "",
		"action_order": [],
		"highest_max_price": 0.0,
		"highest_max_action": "",
		"basic_comps_max": 0.0,
		"locked_gamble_hint": 0.20,
		"dismissed": false
	}

func get_fault_chance(name, category, condition, seller_mult):
	var base = 0.10
	if name == "Nintendo DS Lite":
		base = 0.17
	elif name == "Game Boy Advance":
		base = 0.13
	elif name == "Digital Compact Camera":
		base = 0.20
	elif name == "35mm Film Camera":
		base = 0.15
	elif name == "Vintage SLR Camera":
		base = 0.14
	elif name == "35mm Lens":
		base = 0.11
	elif name == "Mini Hi-Fi":
		base = 0.24
	elif name == "Portable CD Player":
		base = 0.22
	elif name == "Cordless Drill":
		base = 0.16
	elif name == "Vintage Wristwatch":
		base = 0.14
	elif category == "Games":
		base = 0.12
	elif category == "Electronics":
		base = 0.20
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
		used += size_units(item)
	return used

func show_stall():
	current_screen_name = "show_stall"
	clear_body()
	update_header()
	if pending_special_offer != null:
		show_special_offer()
		return
	if current_time_minutes >= 12 * 60:
		var closing = Label.new()
		closing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		closing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		closing.text = "The car boot is closing. End the day or manage your inventory."
		body.add_child(closing)
		return

	var stall = stalls[current_stall_index]
	var seller = stall["seller"]
	if current_time_minutes >= stall["packing_minute"] or bool(stall.get("banned_today", false)):
		var packed_title = Label.new()
		packed_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		packed_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		packed_title.add_theme_font_size_override("font_size", 20)
		packed_title.text = "STALL %d/%d — %s" % [current_stall_index + 1, stalls.size(), seller]
		body.add_child(packed_title)
		var packed = Label.new()
		packed.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		packed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if bool(stall.get("banned_today", false)):
			packed.text = "You've been kicked off %s's stall for the rest of the day." % seller
		else:
			packed.text = "%s has already packed up and left for the day." % seller
		body.add_child(packed)
		var back_note = Label.new()
		back_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		back_note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		back_note.text = "Check the Stalls list for who's still open."
		body.add_child(back_note)
		return
	var title_row = HFlowContainer.new()
	title_row.add_theme_constant_override("h_separation", 8)
	title_row.add_theme_constant_override("v_separation", 4)
	title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(title_row)

	var title = Label.new()
	title.add_theme_font_size_override("font_size", 18)
	title.text = "Stall %d/%d — %s" % [current_stall_index + 1, stalls.size(), seller]
	title_row.add_child(title)

	var browse = Button.new()
	browse.text = "Dig Deeper E4"
	style_button(browse, "action")
	browse.custom_minimum_size.y = 32
	browse.pressed.connect(browse_stall)
	title_row.add_child(browse)

	if mystery_packages_left > 0:
		var package_button = Button.new()
		package_button.text = "? Mystery £30"
		var odds_lines = []
		var budget_ranges = {"Poor":"£5-20", "Average":"£18-35", "Good":"£35-60", "Excellent":"£60-120", "Jackpot":"£150-400", "Grail":"£500-900"}
		for row in get_package_chances():
			odds_lines.append("%s %.1f%% (%s)" % [row["tier"], row["chance"] * 100.0, budget_ranges.get(row["tier"], "")])
		package_button.tooltip_text = "£30 for 1-2 items (30% chance of 2). Tier odds:\n" + "\n".join(odds_lines)
		style_button(package_button, "action")
		package_button.custom_minimum_size.y = 32
		package_button.pressed.connect(buy_mystery_package)
		title_row.add_child(package_button)

	var info = Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_font_size_override("font_size", 14)
	info.add_theme_color_override("font_color", Color(0.62,0.68,0.76,1.0))
	info.text = "Revealed %d/%d  •  Crowd %d%%  •  Packs up %s  •  Carry %d/%d  •  Mystery packages %d" % [stall["revealed"], stall["stock"].size(), int(float(stall["crowd"]) * 100.0), minute_to_clock(stall["packing_minute"]), carry_used, bag_upgrades[bag_level]["capacity"], mystery_packages_left]
	body.add_child(info)


	for i in range(stall["revealed"]):
		var item = stall["stock"][i]
		if item["dismissed"]:
			continue
		var panel = make_card()
		body.add_child(panel)
		var card = VBoxContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_constant_override("separation", 3)
		panel.add_child(card)

		var rarity_text = ""
		if item["one_in"] >= 20:
			rarity_text = " %s 1/%d  •  " % [item["rarity"], item["one_in"]]
		var condition_text = "Unknown"
		if item["condition_checked"]:
			condition_text = "%d/10" % item["condition"]
		var function_text_value = "N/A"
		if item["testable"]:
			function_text_value = "Untested"

		var name_row = HBoxContainer.new()
		name_row.add_theme_constant_override("separation", 6)
		card.add_child(name_row)
		var name_line = Label.new()
		name_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_line.add_theme_font_size_override("font_size", 16)
		name_line.text = "%s%s  •  £%.0f  •  Space %d" % [rarity_text, item["name"], item["asking"], size_units(item)]
		name_row.add_child(name_line)
		var dismiss_button = Button.new()
		dismiss_button.text = "×"
		dismiss_button.tooltip_text = "Not interested — hide this item for the rest of this stall visit. Free, no time cost. It's still there for anyone else, and dismissing doesn't affect the real item pool."
		dismiss_button.custom_minimum_size = Vector2(44, 44)
		dismiss_button.add_theme_font_size_override("font_size", 20)
		style_button(dismiss_button, "nav")
		dismiss_button.pressed.connect(Callable(self, "dismiss_stall_item").bind(i))
		name_row.add_child(dismiss_button)

		var state_line = Label.new()
		state_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		state_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		state_line.add_theme_font_size_override("font_size", 14)
		state_line.add_theme_color_override("font_color", Color(0.62,0.68,0.76,1.0))
		state_line.text = "%s  •  Condition: %s  •  Function: %s" % [item["category"], condition_text, function_text_value]
		card.add_child(state_line)

		if item["quick_look_done"] and item["quick_look_note"] != "":
			var look_result = RichTextLabel.new()
			look_result.bbcode_enabled = true
			look_result.fit_content = true
			look_result.scroll_active = false
			look_result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			look_result.add_theme_font_size_override("normal_font_size", 14)
			look_result.add_theme_color_override("default_color", Color(0.72,0.88,1.0,1.0))
			look_result.text = item["quick_look_note"]
			card.add_child(look_result)

		if item["condition_checked"]:
			var stall_condition_note = item["condition_price_note"]
			if not item["testable"]:
				if item["fault"]:
					stall_condition_note += "\n[color=#e88c7a][!] Hidden flaw found: %s[/color]" % item["fault_severity"]
				else:
					stall_condition_note += "\n[color=#8cd98f]No hidden defects found.[/color]"
			card.add_child(make_completed_action_box("Condition Checked", stall_condition_note, "#f0d060" if item["highest_max_action"] == "condition" else "#b8dcff"))

		if item["basic_researched"]:
			var stall_research_note = "Researched Prices: %s  •  [color=#e08fd0]Rare-variant gamble: ~%.0f%%[/color]" % [item["basic_comps"], float(item["locked_gamble_hint"]) * 100.0]
			card.add_child(make_completed_action_box("Researched", stall_research_note, "#f0d060" if item["highest_max_action"] == "research" else "#b8dcff"))

		var top_row = HFlowContainer.new()
		top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_row.add_theme_constant_override("h_separation", 6)
		top_row.add_theme_constant_override("v_separation", 6)
		card.add_child(top_row)

		var buy_button = Button.new()
		buy_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if item["haggle_attempted"]:
			match item["haggle_result"]:
				"accepted":
					buy_button.text = "Haggled — Buy £%.0f" % item["asking"]
					style_button(buy_button, "buy")
					buy_button.pressed.connect(Callable(self, "buy_item").bind(i))
				"refused":
					buy_button.text = "They won't sell this to you after that offer"
					buy_button.disabled = true
					style_button(buy_button, "danger")
				_:
					buy_button.text = "Rejected — Buy £%.0f" % item["asking"]
					style_button(buy_button, "buy")
					buy_button.pressed.connect(Callable(self, "buy_item").bind(i))
		else:
			buy_button.text = "BUY £%.0f" % item["asking"]
			buy_button.tooltip_text = "Buy at the current asking price. Anything you haven't checked stays a gamble."
			style_button(buy_button, "buy")
			buy_button.pressed.connect(Callable(self, "buy_item").bind(i))
		top_row.add_child(buy_button)

		if not item["haggle_attempted"]:
			var haggle_cluster = HBoxContainer.new()
			haggle_cluster.add_theme_constant_override("separation", 4)
			var haggle_asking = max(1.0, float(item["asking"]))
			var haggle_initial = round(haggle_asking * 0.85)

			var haggle_minus = Button.new()
			haggle_minus.text = "-"
			style_button(haggle_minus, "nav")
			haggle_minus.custom_minimum_size = Vector2(34, 36)
			haggle_cluster.add_child(haggle_minus)

			var haggle_value_edit = LineEdit.new()
			haggle_value_edit.text = str(int(haggle_initial))
			haggle_value_edit.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
			haggle_value_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
			haggle_value_edit.custom_minimum_size = Vector2(60, 36)
			haggle_cluster.add_child(haggle_value_edit)

			var haggle_plus = Button.new()
			haggle_plus.text = "+"
			style_button(haggle_plus, "nav")
			haggle_plus.custom_minimum_size = Vector2(34, 36)
			haggle_cluster.add_child(haggle_plus)

			var haggle_chance_label = Label.new()
			haggle_chance_label.add_theme_font_size_override("font_size", 12)
			haggle_chance_label.text = "%.0f%%" % (compute_haggle_chance(item, seller, haggle_initial) * 100.0)
			haggle_cluster.add_child(haggle_chance_label)
			top_row.add_child(haggle_cluster)

			haggle_minus.pressed.connect(Callable(self, "_adjust_haggle_value").bind(haggle_value_edit, -1.0, haggle_asking, haggle_chance_label, item, seller))
			haggle_plus.pressed.connect(Callable(self, "_adjust_haggle_value").bind(haggle_value_edit, 1.0, haggle_asking, haggle_chance_label, item, seller))
			haggle_value_edit.text_submitted.connect(Callable(self, "_on_haggle_value_submitted").bind(haggle_value_edit, haggle_asking, haggle_chance_label, item, seller))
			haggle_value_edit.focus_exited.connect(Callable(self, "_adjust_haggle_value").bind(haggle_value_edit, 0.0, haggle_asking, haggle_chance_label, item, seller))

			var haggle_offer_button = Button.new()
			haggle_offer_button.text = "Offer | E2"
			haggle_offer_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			haggle_offer_button.tooltip_text = "One attempt at this price. Lowballing risks annoying the seller — they might refuse to sell you this item, or even kick you off their whole stall for the rest of the day."
			style_button(haggle_offer_button, "nav")
			haggle_offer_button.pressed.connect(Callable(self, "haggle_item").bind(i, haggle_value_edit))
			top_row.add_child(haggle_offer_button)

		if item["buy_block_note"] != "":
			var buy_block_line = Label.new()
			buy_block_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			buy_block_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			buy_block_line.add_theme_font_size_override("font_size", 13)
			buy_block_line.add_theme_color_override("font_color", Color(0.72,0.88,1.0,1.0))
			buy_block_line.text = item["buy_block_note"]
			card.add_child(buy_block_line)

		if item["haggle_note"] != "":
			var haggle_note_line = RichTextLabel.new()
			haggle_note_line.bbcode_enabled = true
			haggle_note_line.fit_content = true
			haggle_note_line.scroll_active = false
			haggle_note_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			haggle_note_line.add_theme_font_size_override("normal_font_size", 13)
			haggle_note_line.add_theme_color_override("default_color", Color(0.72,0.88,1.0,1.0))
			haggle_note_line.text = item["haggle_note"]
			card.add_child(haggle_note_line)

		var actions = HFlowContainer.new()
		actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		actions.add_theme_constant_override("h_separation", 6)
		actions.add_theme_constant_override("v_separation", 6)
		card.add_child(actions)

		var look = Button.new()
		var look_accuracy = int(float(eye_upgrades[eye_level]["accuracy"]) * 100.0)
		look.text = "Inspect %d%% | E1" % look_accuracy if not item["quick_look_done"] else "Inspected"
		look.disabled = item["quick_look_done"]
		look.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		look.tooltip_text = "Cheap first impression of Condition. Can genuinely be wrong at this accuracy — never reveals the exact score."
		style_button(look, "nav")
		look.pressed.connect(Callable(self, "quick_look").bind(i))
		actions.add_child(look)

		if not item["condition_checked"]:
			var condition_button = Button.new()
			condition_button.text = "Condition £5 | E4"
			condition_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			condition_button.tooltip_text = "Reveals the exact Condition score for certain. This is the only reliable way to know it before buying — and, for non-electronic items, the only way to know about hidden defects at all."
			style_button(condition_button, "action")
			condition_button.add_theme_font_size_override("font_size", 14)
			condition_button.pressed.connect(Callable(self, "check_condition").bind(i))
			actions.add_child(condition_button)

		if not item["basic_researched"]:
			var research_button = Button.new()
			research_button.text = "Research £1 | E2"
			research_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			research_button.tooltip_text = "Shows real sold-price comparables for this exact item. Evidence to weigh, not a guaranteed value — one-time only."
			style_button(research_button, "action")
			research_button.add_theme_font_size_override("font_size", 14)
			research_button.pressed.connect(Callable(self, "prebuy_research").bind(i))
			actions.add_child(research_button)

	footer_label.text = ""

func quick_look(index):
	var item = stalls[current_stall_index]["stock"][index]
	if item["quick_look_done"]:
		set_status("You've already taken a quick look at this item.")
		return
	if energy < 1:
		set_status("Not enough E energy.")
		return
	energy -= 1
	current_time_minutes += 1
	item["quick_look_done"] = true

	var accuracy = float(eye_upgrades[eye_level]["accuracy"])
	var roll = rng.randf()
	var accurate = roll < accuracy
	var perceived_condition = int(item["condition"])
	if not accurate:
		var error = rng.randi_range(2, 4)
		if rng.randf() < 0.5:
			error = -error
		perceived_condition = clamp(perceived_condition + error, 1, 10)

	var clue = "Looks average at a glance."
	if perceived_condition <= 3:
		clue = "Looks rough — wear/damage likely."
	elif perceived_condition <= 5:
		clue = "Fairly worn, hard to judge for sure."
	elif perceived_condition <= 7:
		clue = "Looks reasonably tidy."
	else:
		clue = "Looks very clean and well-kept."

	item["quick_look_accuracy"] = accuracy
	item["quick_look_roll"] = roll
	item["quick_look_note"] = "[color=#e08fd0]Inspect %d%%[/color]: %s" % [int(accuracy * 100.0), clue]
	record_rng("Inspect accuracy: %.1f%% | Rolled: %.2f%% | Result: %s" % [accuracy * 100.0, roll * 100.0, "ACCURATE" if accurate else "INACCURATE"])
	set_status(item["quick_look_note"])
	show_stall()

func check_condition(index):
	var item = stalls[current_stall_index]["stock"][index]
	if item["condition_checked"]:
		set_status("Condition has already been checked.")
		return
	if cash < 5.0 or energy < 4:
		set_status("Need £5 and E4.")
		return
	cash -= 5.0
	item["extra_spend"] += 5.0
	energy -= 4
	current_time_minutes += 5
	day_stats["research"] += 5.0
	var before_check = estimate_identified_potential(item)
	item["condition_checked"] = true
	item["action_order"].append("condition")
	var after_check = estimate_identified_potential(item)
	var before_center = (float(before_check[0]) + float(before_check[1])) / 2.0
	var after_center = (float(after_check[0]) + float(after_check[1])) / 2.0
	var change_word = "increased" if after_center >= before_center else "decreased"
	item["condition_price_note"] = "Condition Checked — %d/10. Selling price %s: £%d–£%d -> £%d–£%d." % [item["condition"], change_word, before_check[0], before_check[1], after_check[0], after_check[1]]
	update_highest_max(item, "condition", float(after_check[1]))
	var message = "CONDITION CHECK COMPLETE — Condition %d/10." % item["condition"]
	if item["testable"]:
		message += " Function remains unknown until testing."
	elif item["fault"]:
		message += " It also reveals a hidden flaw: %s." % item["fault_severity"]
	else:
		message += " No hidden defects found."
	set_status(message)
	rival_pressure(0.05)
	show_stall()

func prebuy_research(index):
	var item = stalls[current_stall_index]["stock"][index]
	if item["basic_researched"]:
		set_status("Basic Research is already complete. Cached comps: " + item["basic_comps"])
		return
	if cash < 1.0 or energy < 2:
		set_status("Need £1 and E2.")
		return
	cash -= 1.0
	item["extra_spend"] += 1.0
	energy -= 2
	current_time_minutes += 4
	day_stats["research"] += 1.0
	item["basic_researched"] = true
	item["basic_comps"] = make_comps(item, false)
	update_highest_max(item, "research", float(item["basic_comps_max"]))
	item["locked_gamble_hint"] = gamble_hint_chance(item)
	rival_pressure(0.07)
	show_stall()

func make_comps(item, deep):
	var values = []
	var count = 5
	if deep:
		count = 6
	for i in range(count):
		var spread = rng.randf_range(0.45, 1.60)
		if deep:
			spread = rng.randf_range(0.70, 1.30)
		values.append(max(1, int(item["true_value"] * spread)))
	values.sort()
	item["basic_comps_max"] = float(values[-1])
	var text = ""
	for i in range(values.size()):
		if i > 0:
			text += ", "
		text += "£" + str(values[i])
	return text

func compute_haggle_chance(item, seller, target_price):
	var asking = max(1.0, float(item["asking"]))
	var discount_pct = clamp((asking - float(target_price)) / asking, 0.0, 0.95)
	var seller_haggle = float(seller_profiles[seller]["haggle"])
	var leniency = 1.0 - seller_haggle
	var base_chance = 0.75 + leniency * 0.20 + float(persuasion_level) * 0.01
	var penalty = pow(discount_pct, 1.3) * 3.0
	var trend_mult = float(current_trends.get(item["category"], 1.0))
	var trend_adjustment = (1.0 - trend_mult) * 0.3
	return clamp(base_chance - penalty + trend_adjustment, 0.03, 0.96)

func _adjust_haggle_value(value_edit, delta, asking, chance_label, item, seller):
	var v = clamp(_parse_price(value_edit.text) + delta, 1.0, max(1.0, asking - 1.0))
	value_edit.text = str(int(v))
	chance_label.text = "%.0f%%" % (compute_haggle_chance(item, seller, v) * 100.0)

func _on_haggle_value_submitted(submitted_text, value_edit, asking, chance_label, item, seller):
	_adjust_haggle_value(value_edit, 0.0, asking, chance_label, item, seller)

func dismiss_stall_item(index):
	var stall = stalls[current_stall_index]
	if index >= stall["stock"].size():
		return
	stall["stock"][index]["dismissed"] = true
	show_stall()

func haggle_item(index, value_edit):
	var stall = stalls[current_stall_index]
	var item = stall["stock"][index]
	var seller = stall["seller"]
	if item["haggle_attempted"]:
		set_status("You already made your one haggle attempt on this item.")
		return
	if bool(stall.get("banned_today", false)):
		set_status("%s won't deal with you again today." % seller)
		return
	if energy < 2:
		set_status("Need E2 to haggle.")
		return
	var asking = float(item["asking"])
	var target_price = clamp(round(_parse_price(value_edit.text)), 1.0, max(1.0, asking - 1.0))
	var discount_pct = clamp((asking - target_price) / asking, 0.0, 0.95)
	var chance = compute_haggle_chance(item, seller, target_price)
	energy -= 2
	current_time_minutes += 2
	item["haggle_attempted"] = true
	var roll = rng.randf()
	var success = roll < chance
	record_rng("Haggle chance: %.0f%% | Rolled: %.2f%% | Offer £%.0f (of £%.0f) | Result: %s" % [chance * 100.0, roll * 100.0, target_price, asking, "ACCEPTED" if success else "REJECTED"])
	if success:
		item["asking"] = target_price
		item["haggle_result"] = "accepted"
		item["haggle_savings"] = asking - target_price
		item["haggle_note"] = "Offer £%.0f — [color=#e08fd0]Chance %.0f%% | Rolled %.2f%%[/color] — Accepted." % [target_price, chance * 100.0, roll * 100.0]
		show_stall()
		return

	var escalation_roll = rng.randf()
	var kicked_out = discount_pct >= 0.35 and escalation_roll < 0.35
	var item_banned = (not kicked_out) and discount_pct >= 0.20 and escalation_roll < 0.55
	record_rng("Haggle escalation chance: %.0f%% (kickout) / %.0f%% (item ban), needs %.0f%% discount | Rolled: %.2f%% | Result: %s" % [35.0 if discount_pct >= 0.35 else 0.0, 55.0 if discount_pct >= 0.20 else 0.0, discount_pct * 100.0, escalation_roll * 100.0, "STALL BAN" if kicked_out else ("ITEM REFUSED" if item_banned else "plain rejection")])
	if kicked_out:
		stall["banned_today"] = true
		item["haggle_result"] = "refused"
		item["haggle_note"] = "Offer £%.0f — [color=#e08fd0]Chance %.0f%% | Rolled %.2f%%[/color] — Refused. Kicked off the stall for today." % [target_price, chance * 100.0, roll * 100.0]
	elif item_banned:
		item["seller_refuses"] = true
		item["haggle_result"] = "refused"
		item["haggle_note"] = "Offer £%.0f — [color=#e08fd0]Chance %.0f%% | Rolled %.2f%%[/color] — Refused." % [target_price, chance * 100.0, roll * 100.0]
	else:
		item["haggle_result"] = "rejected"
		item["haggle_note"] = "Offer £%.0f — [color=#e08fd0]Chance %.0f%% | Rolled %.2f%%[/color] — Rejected." % [target_price, chance * 100.0, roll * 100.0]
	show_stall()

func browse_stall():
	var stall = stalls[current_stall_index]
	if stall["revealed"] >= stall["stock"].size():
		set_status("You've already dug through everything at this stall.")
		return
	if energy < 4:
		set_status("Not enough E energy.")
		return
	energy -= 4
	current_time_minutes += 8
	stall["revealed"] = min(stall["stock"].size(), stall["revealed"] + rng.randi_range(2, 4))
	rival_pressure(float(stall["crowd"]) * 0.35)
	show_stall()

func next_stall():
	current_time_minutes += 5
	current_stall_index += 1
	if current_stall_index >= stalls.size():
		current_stall_index = 0
	show_stall()

func show_stall_list():
	current_screen_name = "show_stall_list"
	clear_body()
	update_header()
	var title = Label.new()
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	title.text = "CAR BOOT — %d STALLS TODAY" % stalls.size()
	body.add_child(title)

	if pending_special_offer != null:
		var note = Label.new()
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		note.text = "You have a special offer waiting — resolve it before moving on."
		body.add_child(note)
		var go_button = Button.new()
		go_button.text = "View Offer"
		go_button.pressed.connect(show_special_offer)
		style_button(go_button, "action")
		body.add_child(go_button)
		return

	if current_time_minutes >= 12 * 60:
		var closing = Label.new()
		closing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		closing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		closing.text = "The car boot is closing. End the day or manage your inventory."
		body.add_child(closing)
		return


	for i in range(stalls.size()):
		var stall = stalls[i]
		var panel = make_card()
		body.add_child(panel)
		var row = HFlowContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 10)
		panel.add_child(row)

		var info_box = VBoxContainer.new()
		info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info_box)

		var banned = bool(stall.get("banned_today", false))
		var packed = current_time_minutes >= stall["packing_minute"] or banned
		var here_tag = " (here now)" if i == current_stall_index else ""
		var name_line = Label.new()
		name_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_line.add_theme_font_size_override("font_size", 15)
		name_line.text = "Stall %d — %s%s" % [i + 1, stall["seller"], here_tag]
		if packed:
			name_line.add_theme_color_override("font_color", Color(0.5,0.5,0.55,1.0))
		info_box.add_child(name_line)

		var status_line = Label.new()
		status_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		status_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if banned:
			status_line.text = "You've been kicked off this stall for the day."
		elif packed:
			status_line.text = "Packed up and gone for the day."
		else:
			status_line.text = "Revealed %d/%d in stock  •  Crowd %d%%  •  Packs up %s" % [stall["revealed"], stall["stock"].size(), int(float(stall["crowd"]) * 100.0), minute_to_clock(stall["packing_minute"])]
		info_box.add_child(status_line)

		var go_button = Button.new()
		if i == current_stall_index:
			go_button.text = "You're Here"
			go_button.disabled = true
			style_button(go_button, "nav")
		elif packed:
			go_button.text = "Closed"
			go_button.disabled = true
			style_button(go_button, "nav")
		else:
			go_button.text = "Go | 5 min"
			go_button.tooltip_text = "Travel to this stall. Costs 5 minutes either way."
			go_button.pressed.connect(Callable(self, "go_to_stall").bind(i))
			style_button(go_button, "action")
		row.add_child(go_button)

	footer_label.text = "Pick any stall to visit next — moving always costs 5 minutes, whichever direction."

func go_to_stall(index):
	if index < 0 or index >= stalls.size():
		return
	if index == current_stall_index:
		show_stall()
		return
	current_time_minutes += 5
	current_stall_index = index
	show_stall()

func can_carry(item):
	return carry_used + size_units(item) <= int(bag_upgrades[bag_level]["capacity"])

func can_store(item):
	return inventory_space_used() + size_units(item) <= int(storage_upgrades[storage_level]["capacity"])

func buy_item(index):
	var stall = stalls[current_stall_index]
	if index >= stall["revealed"]:
		return
	if bool(stall.get("banned_today", false)):
		set_status("%s won't deal with you again today." % stall["seller"])
		return
	var item = stall["stock"][index]
	if bool(item.get("seller_refuses", false)):
		set_status("They won't sell you this item today.")
		return
	if cash < item["asking"]:
		show_blocked_popup("Not enough cash.")
		return
	if not can_carry(item):
		show_blocked_popup("Not enough space in your bag.")
		return
	if not can_store(item):
		set_status("HOME STORAGE FULL — Upgrade storage in the Shop before buying more stock.")
		return
	cash -= item["asking"]
	day_stats["buy_spend"] += item["asking"]
	day_stats["items_bought"] += 1
	item["paid"] = item["asking"]
	if item["haggle_result"] == "accepted":
		total_haggled_savings += float(item["haggle_savings"])
	carry_used += size_units(item)
	inventory.append(item)
	stall["stock"].remove_at(index)
	stall["revealed"] = min(stall["revealed"], stall["stock"].size())
	register_collection(item)
	check_side_deal(stall["seller"])
	set_status("Bought %s for £%.2f. Carry used %d/%d." % [item["name"], item["paid"], carry_used, bag_upgrades[bag_level]["capacity"]])
	show_stall()

func register_collection(item):
	var key = item["category"] + "|" + item["name"] + "|" + item["rarity"]
	if not discovered_log.has(key):
		discovered_log[key] = {"name":item["name"], "category":item["category"], "rarity":item["rarity"], "one_in":item["one_in"]}
		day_stats["collection_adds"] += 1
		day_stats["rarest_one_in"] = max(day_stats["rarest_one_in"], item["one_in"])
		if item["one_in"] >= 100:
			unlock_achievement("Against the Odds")

func check_side_deal(seller):
	if not special_event_profiles.has(seller):
		return
	if pending_special_offer != null:
		return
	var chance = float(seller_profiles[seller]["side"])
	var roll = rng.randf()
	var result = roll < chance
	record_rng("Side deal chance: %s | Rolled: %.2f%% | Result: %s" % [chance_text(chance), roll * 100.0, "TRIGGERED" if result else "MISS"])
	if result:
		pending_special_offer = generate_special_offer(seller)
		status_label.text += " \"%s\" — %s has a special offer for you." % [special_event_profiles[seller]["title"], seller]
		unlock_achievement("Actually Mate...")

func generate_special_offer(seller):
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
	return {"seller":seller, "title":profile["title"], "flavor":profile["flavor"], "item":item}

func show_special_offer():
	current_screen_name = "show_special_offer"
	clear_body()
	update_header()
	if pending_special_offer == null:
		show_stall()
		return
	var offer = pending_special_offer
	var item = offer["item"]

	var title = Label.new()
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	title.text = "SPECIAL OFFER — %s (%s)" % [offer["title"], offer["seller"]]
	body.add_child(title)

	var flavor = Label.new()
	flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flavor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flavor.text = offer["flavor"]
	flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flavor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flavor.add_theme_color_override("font_color", Color(0.95,0.84,0.62,1.0))
	body.add_child(flavor)

	var panel = make_card()
	body.add_child(panel)
	var card = VBoxContainer.new()
	card.add_theme_constant_override("separation", 5)
	panel.add_child(card)

	var rarity_text = ""
	if item["one_in"] >= 20:
		rarity_text = " %s 1/%d  •  " % [item["rarity"], item["one_in"]]
	var name_line = Label.new()
	name_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_line.add_theme_font_size_override("font_size", 16)
	name_line.text = "%s%s  •  %s  •  £%.0f  •  Space %d" % [rarity_text, item["name"], item["category"], item["asking"], size_units(item)]
	card.add_child(name_line)

	var function_text_value = "N/A"
	if item["testable"]:
		function_text_value = "Untested"
	var state_line = Label.new()
	state_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	state_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	state_line.text = "Condition: Unknown  •  Function: %s" % function_text_value
	card.add_child(state_line)

	var note = Label.new()
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note.text = "One-off offer — no Inspect, Research or haggling available. Decide now, before it's gone."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(note)

	var actions = HFlowContainer.new()
	actions.add_theme_constant_override("separation", 8)
	card.add_child(actions)

	var buy_button = Button.new()
	buy_button.text = "Take It — £%.0f" % item["asking"]
	style_button(buy_button, "buy")
	buy_button.pressed.connect(accept_special_offer)
	actions.add_child(buy_button)

	var decline_button = Button.new()
	decline_button.text = "Walk Away"
	style_button(decline_button, "danger")
	decline_button.pressed.connect(decline_special_offer)
	actions.add_child(decline_button)

	footer_label.text = "Special offers are one-off — no inspection tools apply here. Weigh the risk quickly."

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
	carry_used += size_units(item)
	inventory.append(item)
	register_collection(item)
	set_status("Took the special offer: %s for £%.2f." % [item["name"], item["paid"]])
	pending_special_offer = null
	show_stall()

func decline_special_offer():
	set_status("You walked away from the offer.")
	pending_special_offer = null
	show_stall()

func rival_pressure(chance):
	if rng.randf() < chance:
		var stall = stalls[current_stall_index]
		if stall["stock"].size() > stall["revealed"] and stall["stock"].size() > 0:
			var idx = rng.randi_range(stall["revealed"], stall["stock"].size() - 1)
			var gone = stall["stock"][idx]["name"]
			stall["stock"].remove_at(idx)
			status_label.text += " A rival grabbed %s while you were occupied." % gone

func show_inventory_fresh():
	inventory_tab = "unlisted"
	show_inventory()

func show_inventory():
	current_screen_name = "show_inventory"
	clear_body()
	update_header()
	var title = Label.new()
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	title.text = "INVENTORY — Storage %d/%d" % [inventory_space_used(), storage_upgrades[storage_level]["capacity"]]
	body.add_child(title)

	var unlisted_count = 0
	var listed_count = 0
	for it in inventory:
		if it["listed"]:
			listed_count += 1
		else:
			unlisted_count += 1

	var tab_row = HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 8)
	body.add_child(tab_row)
	var unlisted_tab = Button.new()
	unlisted_tab.text = "UNLISTED (%d)" % unlisted_count
	unlisted_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	style_button(unlisted_tab, "buy" if inventory_tab == "unlisted" else "nav")
	unlisted_tab.pressed.connect(Callable(self, "_switch_inventory_tab").bind("unlisted"))
	tab_row.add_child(unlisted_tab)
	var listed_tab = Button.new()
	listed_tab.text = "LISTED (%d)" % listed_count
	listed_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	style_button(listed_tab, "buy" if inventory_tab == "listed" else "nav")
	listed_tab.pressed.connect(Callable(self, "_switch_inventory_tab").bind("listed"))
	tab_row.add_child(listed_tab)

	if pending_instant_sale_banner != "":
		var banner_panel = make_card()
		body.add_child(banner_panel)
		var banner_label = Label.new()
		banner_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		banner_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		banner_label.add_theme_font_size_override("font_size", 15)
		banner_label.add_theme_color_override("font_color", Color(0.55,0.85,0.58,1.0))
		banner_label.text = pending_instant_sale_banner
		banner_panel.add_child(banner_label)
		pending_instant_sale_banner = ""
	if inventory.size() == 0:
		var empty = Label.new()
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty.text = "No stock."
		body.add_child(empty)
		return
	var showing_any = false


	for i in range(inventory.size()):
		var item = inventory[i]
		if item["listed"] != (inventory_tab == "listed"):
			continue
		showing_any = true
		var panel = make_card()
		body.add_child(panel)
		var card = VBoxContainer.new()
		card.add_theme_constant_override("separation", 5)
		panel.add_child(card)

		var inv_condition_text = "Unknown"
		if item["condition_checked"]:
			inv_condition_text = "%d/10" % item["condition"]
		var head = Label.new()
		head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_theme_font_size_override("font_size", 16)
		head.text = "%d. %s  •  Paid £%.2f" % [i + 1, item["name"], item["paid"]]
		card.add_child(head)

		var badge_line = Label.new()
		badge_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		badge_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		badge_line.add_theme_font_size_override("font_size", 14)
		badge_line.add_theme_color_override("font_color", Color(0.62,0.68,0.76,1.0))
		badge_line.text = "%s  •  Space %d  •  Trend %+.0f%%" % [item["category"], size_units(item), (float(current_trends.get(item["category"], 1.0)) - 1.0) * 100.0]
		card.add_child(badge_line)

		var potential = estimate_identified_potential(item)
		var preview_price = (float(potential[0]) + float(potential[1])) / 2.0
		if item["listed"]:
			preview_price = float(item["listing"])

		var status_line = Label.new()
		status_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		status_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		status_line.add_theme_font_size_override("font_size", 15)
		status_line.text = "Condition: %s  •  Function: %s  •  %s" % [inv_condition_text, function_status(item), item["auth_status"]]
		card.add_child(status_line)

		var details = Label.new()
		details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		details.add_theme_font_size_override("font_size", 15)
		details.text = "Est. value £%d–£%d" % [potential[0], potential[1]]
		card.add_child(details)

		if item["quick_look_done"] and item["quick_look_note"] != "":
			var inv_look_result = RichTextLabel.new()
			inv_look_result.bbcode_enabled = true
			inv_look_result.fit_content = true
			inv_look_result.scroll_active = false
			inv_look_result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			inv_look_result.add_theme_font_size_override("normal_font_size", 14)
			inv_look_result.add_theme_color_override("default_color", Color(0.72,0.88,1.0,1.0))
			inv_look_result.text = item["quick_look_note"]
			card.add_child(inv_look_result)

		var actions = HFlowContainer.new()
		actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		actions.add_theme_constant_override("h_separation", 6)
		actions.add_theme_constant_override("v_separation", 6)
		card.add_child(actions)


		if item["condition_checked"]:
			var condition_note = item["condition_price_note"]
			if not item["testable"]:
				if item["fault"]:
					condition_note += "\n[color=#e88c7a][!] Hidden flaw found: %s[/color]" % item["fault_severity"]
				else:
					condition_note += "\n[color=#8cd98f]No hidden defects found.[/color]"
			card.add_child(make_completed_action_box("Condition Checked", condition_note, "#f0d060" if item["highest_max_action"] == "condition" else "#b8dcff"))
		else:
			var inv_condition_button = Button.new()
			inv_condition_button.text = "Condition £5 | E4"
			inv_condition_button.pressed.connect(Callable(self, "inventory_check_condition").bind(i))
			inv_condition_button.tooltip_text = "Reveals the exact Condition score, and — for non-electronic items — any hidden defect. Only reliable way to know for sure if you skipped it before buying."
			inv_condition_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			style_button(inv_condition_button, "action")
			inv_condition_button.add_theme_font_size_override("font_size", 14)
			actions.add_child(inv_condition_button)

		if item["basic_researched"]:
			card.add_child(make_completed_action_box("Researched", "Researched Prices: %s" % item["basic_comps"], "#f0d060" if item["highest_max_action"] == "research" else "#b8dcff"))
		else:
			var basic_button = Button.new()
			basic_button.text = "Research £1 | E2"
			basic_button.pressed.connect(Callable(self, "inventory_basic_research").bind(i))
			basic_button.tooltip_text = "Sold-price comparables for this item. Evidence only, one-time."
			basic_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			style_button(basic_button, "action")
			basic_button.add_theme_font_size_override("font_size", 14)
			actions.add_child(basic_button)

		if item["deep_researched"]:
			var deep_note = item["research_note"]
			if item["rare_variant_hit"]:
				deep_note += "\nRARE VARIANT — [color=#e08fd0]rolled %.2f%%[/color] (%s) — value x%.1f!" % [item["rare_variant_roll_pct"], item["rare_variant_tier"], item["rare_variant_mult"]]
			card.add_child(make_completed_action_box("Deep Researched", deep_note, "#f0d060" if item["highest_max_action"] == "deep_research" else "#b8dcff"))
		else:
			var deep_knowledge = float(category_knowledge.get(item["category"], 5))
			var deep_chance = clamp(0.28 + deep_knowledge / 180.0, 0.28, 0.78)
			var real_rare_chance = 0.20
			if item["basic_researched"]:
				real_rare_chance = clamp(float(item["locked_gamble_hint"]), 0.03, 0.35)
			var deep_button = Button.new()
			deep_button.text = "Deep Research £9 | E12\nDiscovery %.0f%% | Rare %.0f%%" % [deep_chance * 100.0, real_rare_chance * 100.0]
			deep_button.pressed.connect(Callable(self, "deep_research").bind(i))
			deep_button.tooltip_text = "Digs into exact model/variant details. If you Basic Researched this item first, your rare-variant odds are set by how good or bad that research looked — a bad-looking deal gets better odds here. Can raise or lower your Selling Potential range with an explanation — one-time only, may find nothing new."
			deep_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			style_button(deep_button, "action")
			deep_button.custom_minimum_size.y = 48
			deep_button.add_theme_font_size_override("font_size", 14)
			actions.add_child(deep_button)

		if item["testable"]:
			if item["tested"]:
				card.add_child(make_completed_action_box("Tested", item["test_note"]))
			else:
				var test_button = Button.new()
				test_button.text = "Test £2 | E5\nFault chance: %.0f%%" % (float(item["fault_chance"]) * 100.0)
				test_button.pressed.connect(Callable(self, "test_item").bind(i))
				test_button.custom_minimum_size.y = 48
				test_button.tooltip_text = "Reveals whether this electronic item actually works. Required before it can be listed."
				test_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				style_button(test_button, "action")
				test_button.add_theme_font_size_override("font_size", 14)
				actions.add_child(test_button)

		if item["auth_attempted"]:
			card.add_child(make_completed_action_box("Authenticated — %s" % item["auth_status"], item["auth_note"]))
		else:
			var auth_button = Button.new()
			auth_button.text = "Authenticate £%d | E6\nAccuracy: %.0f%%" % [int(authentication_cost(item)), authentication_accuracy(item) * 100.0]
			auth_button.pressed.connect(Callable(self, "authenticate_item").bind(i))
			auth_button.custom_minimum_size.y = 48
			auth_button.tooltip_text = "Checks for counterfeits. Not perfectly accurate, and confirmed fakes can't be sold normally — but selling unauthenticated carries its own return risk."
			auth_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			style_button(auth_button, "action")
			auth_button.add_theme_font_size_override("font_size", 14)
			actions.add_child(auth_button)


		if toolbox_level > 0 and item["tested"] and item["fault"]:
			var repair_button = Button.new()
			if item["repair_attempted"]:
				repair_button.text = "Repair Attempt Used"
				repair_button.disabled = true
			else:
				repair_button.text = "Repair £%d | E10" % int(repair_cost(item))
				repair_button.pressed.connect(Callable(self, "repair_item").bind(i))
			repair_button.tooltip_text = "One attempt to fix the fault. Better tools improve the odds; a failed attempt still costs the fee."
			repair_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			style_button(repair_button, "buy")
			actions.add_child(repair_button)
			if item["repair_note"] != "":
				var repair_note_line = RichTextLabel.new()
				repair_note_line.bbcode_enabled = true
				repair_note_line.fit_content = true
				repair_note_line.scroll_active = false
				repair_note_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				repair_note_line.add_theme_font_size_override("normal_font_size", 13)
				repair_note_line.add_theme_color_override("default_color", Color(0.72,0.88,1.0,1.0))
				repair_note_line.text = item["repair_note"]
				card.add_child(repair_note_line)

		if item["listing_block_note"] != "":
			var listing_block_line = Label.new()
			listing_block_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			listing_block_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			listing_block_line.add_theme_font_size_override("font_size", 13)
			listing_block_line.add_theme_color_override("font_color", Color(0.72,0.88,1.0,1.0))
			listing_block_line.text = item["listing_block_note"]
			card.add_child(listing_block_line)

		if item["auth_status"] == "Confirmed Counterfeit":
			var scrap_button = Button.new()
			scrap_button.text = "Scrap / Recover"
			scrap_button.tooltip_text = "Confirmed counterfeits can't be sold normally. Recover a small fraction of what you paid instead."
			scrap_button.pressed.connect(Callable(self, "scrap_item").bind(i))
			style_button(scrap_button, "danger")
			actions.add_child(scrap_button)
		else:
			add_listing_controls(card, i, item, potential)

	if not showing_any:
		var empty_tab = Label.new()
		empty_tab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if inventory_tab == "listed":
			empty_tab.text = "Nothing listed yet. Create a listing from the Unlisted tab."
		else:
			empty_tab.text = "Nothing unlisted — everything you own is currently listed."
		body.add_child(empty_tab)
	else:
		set_status("Choose your own asking price. Buyer Interest is tied directly to the daily buyer roll.")

func _switch_inventory_tab(tab):
	inventory_tab = tab
	show_inventory()

func function_status(item):
	if not item["testable"]:
		return "N/A"
	if not item["tested"]:
		return "TEST REQUIRED"
	if item["fault"]:
		return item["fault_severity"] + " fault"
	return "Working"

func add_listing_controls(card, index, item, potential):
	var box = HFlowContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)
	if item["listed"]:
		var live = RichTextLabel.new()
		live.bbcode_enabled = true
		live.fit_content = true
		live.scroll_active = false
		live.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		live.text = "LIVE LISTING £%.2f" % item["listing"]
		box.add_child(live)
		var unlist = Button.new()
		unlist.text = "Unlist"
		unlist.pressed.connect(Callable(self, "unlist_item").bind(index))
		style_button(unlist, "danger")
		box.add_child(unlist)
		var breakdown_live = RichTextLabel.new()
		breakdown_live.bbcode_enabled = true
		breakdown_live.fit_content = true
		breakdown_live.scroll_active = false
		breakdown_live.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		breakdown_live.add_theme_font_size_override("normal_font_size", 15)
		breakdown_live.add_theme_color_override("default_color", Color(0.72,0.78,0.85,1.0))
		breakdown_live.text = format_sale_breakdown(item, float(item["listing"])) + "\n" + format_sale_estimate(item, float(item["listing"]))
		card.add_child(breakdown_live)
		return

	var label = Label.new()
	label.text = "Choose asking price:"
	box.add_child(label)

	var initial_value = round((float(potential[0]) + float(potential[1])) / 2.0)

	var interest = RichTextLabel.new()
	interest.bbcode_enabled = true
	interest.fit_content = true
	interest.scroll_active = false
	interest.custom_minimum_size = Vector2(170, 0)
	interest.text = "Buyer Interest: [color=%s]%s[/color]" % [buyer_interest_color(buyer_interest_label(item, initial_value)), buyer_interest_label(item, initial_value)]

	var breakdown = RichTextLabel.new()
	breakdown.bbcode_enabled = true
	breakdown.fit_content = true
	breakdown.scroll_active = false
	breakdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	breakdown.add_theme_font_size_override("normal_font_size", 15)
	breakdown.add_theme_color_override("default_color", Color(0.72,0.78,0.85,1.0))
	breakdown.text = format_sale_breakdown(item, initial_value) + "\n" + format_sale_estimate(item, initial_value)

	var minus_btn = Button.new()
	minus_btn.text = "-"
	style_button(minus_btn, "nav")
	minus_btn.custom_minimum_size = Vector2(40, 36)
	box.add_child(minus_btn)

	var value_edit = LineEdit.new()
	value_edit.text = str(int(initial_value))
	value_edit.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	value_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_edit.custom_minimum_size = Vector2(75, 36)
	box.add_child(value_edit)

	var plus_btn = Button.new()
	plus_btn.text = "+"
	style_button(plus_btn, "nav")
	plus_btn.custom_minimum_size = Vector2(40, 36)
	box.add_child(plus_btn)

	minus_btn.pressed.connect(Callable(self, "_adjust_listing_price").bind(value_edit, -1.0, float(potential[0]), float(potential[1]), index, interest, breakdown))
	plus_btn.pressed.connect(Callable(self, "_adjust_listing_price").bind(value_edit, 1.0, float(potential[0]), float(potential[1]), index, interest, breakdown))
	value_edit.text_submitted.connect(Callable(self, "_on_listing_price_submitted").bind(value_edit, float(potential[0]), float(potential[1]), index, interest, breakdown))
	value_edit.focus_exited.connect(Callable(self, "_refresh_listing_price").bind(value_edit, float(potential[0]), float(potential[1]), index, interest, breakdown))

	box.add_child(interest)

	var list_button = Button.new()
	list_button.text = "Create Listing"
	list_button.pressed.connect(Callable(self, "create_listing").bind(index, value_edit))
	style_button(list_button, "buy")
	box.add_child(list_button)

	var quick_sell_button = Button.new()
	var quick_sell_low = max(1.0, round(float(potential[0]) * 0.45))
	var quick_sell_high = max(1.0, round(float(potential[0]) * 0.75))
	quick_sell_button.text = "Quick Sell £%d-%d" % [quick_sell_low, quick_sell_high]
	quick_sell_button.tooltip_text = "Instant cash, no listing wait — but well below market value. Rarely, a great buy can still turn a small profit."
	style_button(quick_sell_button, "danger")
	quick_sell_button.pressed.connect(Callable(self, "quick_sell_item").bind(index))
	box.add_child(quick_sell_button)

	var guide = Label.new()
	if item["deep_researched"]:
		guide.text = "Researched range"
	else:
		guide.text = "Rough range — Deep Research improves confidence"
	box.add_child(guide)

	card.add_child(breakdown)

func _parse_price(text):
	var cleaned = text.strip_edges()
	if cleaned == "" or not cleaned.is_valid_float():
		return 0.0
	return float(cleaned)

func _refresh_listing_price(value_edit, min_val, max_val, index, interest_label, breakdown_label):
	var v = clamp(_parse_price(value_edit.text), min_val, max_val)
	value_edit.text = str(int(v))
	if index >= inventory.size():
		return
	var item = inventory[index]
	interest_label.text = "Buyer Interest: [color=%s]%s[/color]" % [buyer_interest_color(buyer_interest_label(item, v)), buyer_interest_label(item, v)]
	breakdown_label.text = format_sale_breakdown(item, v) + "\n" + format_sale_estimate(item, v)

func _on_listing_price_submitted(submitted_text, value_edit, min_val, max_val, index, interest_label, breakdown_label):
	_refresh_listing_price(value_edit, min_val, max_val, index, interest_label, breakdown_label)

func _adjust_listing_price(value_edit, delta, min_val, max_val, index, interest_label, breakdown_label):
	var v = clamp(_parse_price(value_edit.text) + delta, min_val, max_val)
	value_edit.text = str(int(v))
	_refresh_listing_price(value_edit, min_val, max_val, index, interest_label, breakdown_label)

func quick_sell_item(index):
	if index >= inventory.size():
		return
	var item = inventory[index]
	if item["auth_status"] == "Confirmed Counterfeit":
		set_status("Confirmed counterfeits can't be quick sold — use Scrap instead.")
		return
	var potential = estimate_identified_potential(item)
	var quick_price = max(1.0, round(float(potential[0]) * rng.randf_range(0.45, 0.75)))
	var profit = quick_price - float(item["paid"])
	cash += quick_price
	current_time_minutes += 2
	carry_used = max(0, carry_used - size_units(item))
	inventory.remove_at(index)
	var color = Color(0.55,0.85,0.58,1.0) if profit >= 0.0 else Color(0.92,0.55,0.45,1.0)
	set_status("Quick Sold — £%.2f — Profit %+.2f" % [quick_price, profit], color)
	show_inventory()

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
	return "Asking £%.2f  ->  Fee £%.2f, Postage £%.2f, Ins./Packaging £%.2f  ->  Net after sale £%.2f%s  ->  Profit [color=%s]£%+.2f[/color]" % [price, costs["fee"], costs["postage"], insurance_pack, net, extra_line, profit_color, profit]

func buyer_interest_color(label_text):
	if label_text == "VERY HIGH" or label_text == "HIGH":
		return "#8cd98f"
	elif label_text == "AVERAGE":
		return "#e0c96e"
	else:
		return "#e88c7a"

func format_sale_estimate(item, price):
	var interest = buyer_interest_score(item, price)
	var chance = clamp(0.05 + interest * 0.47, 0.04, 0.55)
	var expected_days = max(1, int(round(1.0 / chance)))
	return "Est. time to sell ~%d day%s at %d%% daily chance." % [expected_days, "" if expected_days == 1 else "s"]

func fault_is_known(item):
	if item["testable"]:
		return item["tested"]
	return item["condition_checked"]

func gamble_hint_chance(item):
	var potential = estimate_identified_potential(item)
	var center = (float(potential[0]) + float(potential[1])) / 2.0
	var value_ratio = clamp(float(item["asking"]) / max(1.0, center), 0.3, 2.5)
	return clamp(0.05 + (value_ratio - 0.8) * 0.20, 0.03, 0.35)

func estimate_identified_potential(item):
	var center = float(item["true_value"]) * float(item["identified_mult"]) * float(current_trends.get(item["category"], 1.0))
	if item["condition_checked"]:
		center *= lerp(0.62, 1.38, float(item["condition"] - 3) / 7.0)
	if item["auth_status"] == "Unauthenticated" and float(item["true_value"]) > 80.0:
		center *= 0.88
	if item["fault"] and fault_is_known(item):
		center *= fault_multiplier(item["fault_severity"])
	var spread_low = 0.68
	var spread_high = 1.28
	if item["basic_researched"]:
		spread_low = 0.74
		spread_high = 1.22
	if item["deep_researched"]:
		spread_low = 0.82
		spread_high = 1.16
	var low = int(max(1.0, center * spread_low))
	var high = int(max(float(low) + 1.0, center * spread_high))
	return [low, high]

func inventory_check_condition(index):
	if index >= inventory.size():
		return
	var item = inventory[index]
	if item["condition_checked"]:
		set_status("Condition has already been checked.")
		return
	if cash < 5.0 or energy < 4:
		set_status("Need £5 and E4.")
		return
	cash -= 5.0
	item["extra_spend"] += 5.0
	energy -= 4
	current_time_minutes += 5
	day_stats["research"] += 5.0
	var before_check = estimate_identified_potential(item)
	item["condition_checked"] = true
	item["action_order"].append("condition")
	var after_check = estimate_identified_potential(item)
	var before_center = (float(before_check[0]) + float(before_check[1])) / 2.0
	var after_center = (float(after_check[0]) + float(after_check[1])) / 2.0
	var change_word = "increased" if after_center >= before_center else "decreased"
	item["condition_price_note"] = "Condition Checked — %d/10. Selling price %s: £%d–£%d -> £%d–£%d." % [item["condition"], change_word, before_check[0], before_check[1], after_check[0], after_check[1]]
	update_highest_max(item, "condition", float(after_check[1]))
	var message = "CONDITION CHECK COMPLETE — Condition %d/10." % item["condition"]
	if item["testable"]:
		message += " Function remains unknown until testing."
	elif item["fault"]:
		message += " It also reveals a hidden flaw: %s." % item["fault_severity"]
	else:
		message += " No hidden defects found."
	set_status(message)
	show_inventory()

func inventory_basic_research(index):
	if index >= inventory.size():
		return
	var item = inventory[index]
	if item["basic_researched"]:
		set_status("Research already completed once for this item.")
		return
	if cash < 1.0 or energy < 2:
		set_status("Need £1 and E2.")
		return
	cash -= 1.0
	item["extra_spend"] += 1.0
	energy -= 2
	current_time_minutes += 4
	day_stats["research"] += 1.0
	item["basic_researched"] = true
	item["action_order"].append("research")
	item["basic_comps"] = make_comps(item, false)
	update_highest_max(item, "research", float(item["basic_comps_max"]))
	show_inventory()

func deep_research(index):
	if index >= inventory.size():
		return
	var item = inventory[index]
	if item["deep_researched"]:
		set_status("Deep Research has already been completed once.")
		return
	if cash < 9.0 or energy < 12:
		set_status("Need £9 and E12.")
		return
	var before = estimate_identified_potential(item)
	cash -= 9.0
	item["extra_spend"] += 9.0
	energy -= 12
	current_time_minutes += 20
	day_stats["research"] += 9.0
	item["deep_researched"] = true
	item["action_order"].append("deep_research")

	var knowledge = float(category_knowledge.get(item["category"], 5))
	var chance = clamp(0.28 + knowledge / 180.0, 0.28, 0.78)
	var roll = rng.randf()
	var success = roll < chance
	record_rng("Deep research discovery chance: %.1f%% | Rolled: %.2f%% | Result: %s" % [chance * 100.0, roll * 100.0, "DISCOVERY" if success else "NO MAJOR DISCOVERY"])

	var reason = "No new info."
	if success:
		if item["hidden_special"] != "" and not item["special_discovered"]:
			item["special_discovered"] = true
			if item["special_genuine"]:
				item["identified_mult"] *= 1.55
			else:
				item["identified_mult"] *= 0.92
			reason = "Possible hidden special: %s." % item["hidden_special"]
		else:
			var up = rng.randf() > 0.42
			if up:
				item["identified_mult"] *= rng.randf_range(1.12, 1.45)
				reason = "More desirable variant identified."
			else:
				item["identified_mult"] *= rng.randf_range(0.55, 0.85)
				reason = "Common/reissue version identified."

	var after = estimate_identified_potential(item)
	var rare_text = ""
	var rare_roll = rng.randf()
	var rare_mult = 1.0
	var rare_tier = ""
	var total_chance = 0.20
	if item["basic_researched"]:
		total_chance = clamp(float(item["locked_gamble_hint"]), 0.03, 0.35)
	var exceptional_cut = total_chance * 0.05
	var significant_cut = total_chance * 0.20
	if rare_roll < exceptional_cut:
		rare_mult = rng.randf_range(5.0, 10.0)
		rare_tier = "EXCEPTIONAL rare variant"
	elif rare_roll < exceptional_cut + significant_cut:
		rare_mult = rng.randf_range(3.0, 5.0)
		rare_tier = "significant rare variant"
	elif rare_roll < total_chance:
		rare_mult = rng.randf_range(2.0, 3.0)
		rare_tier = "rare variant"
	record_rng("Deep research rare-variant chance: %.1f%% | Rolled: %.2f%% | Result: %s" % [total_chance * 100.0, rare_roll * 100.0, ("%s x%.1f" % [rare_tier, rare_mult]) if rare_mult > 1.0 else "no rare variant"])
	if rare_mult > 1.0:
		item["true_value"] = float(item["true_value"]) * rare_mult
		after = estimate_identified_potential(item)
		rare_text = " Rare variant found (x%.1f)!" % rare_mult
		item["rare_variant_hit"] = true
		item["rare_variant_roll_pct"] = rare_roll * 100.0
		item["rare_variant_tier"] = rare_tier
		item["rare_variant_mult"] = rare_mult

	item["research_note"] = "Deep Research — [color=#e08fd0]Chance %.0f%% | Rolled %.2f%%[/color] | Result: %s%s Range £%d–£%d -> £%d–£%d." % [chance * 100.0, roll * 100.0, reason, rare_text, before[0], before[1], after[0], after[1]]
	update_highest_max(item, "deep_research", float(after[1]))
	show_inventory()

func test_item(index):
	if index >= inventory.size():
		return
	var item = inventory[index]
	if item["tested"]:
		set_status("Testing has already been completed once.")
		return
	if cash < 2.0 or energy < 5:
		set_status("Need £2 and E5.")
		return
	var before = estimate_identified_potential(item)
	cash -= 2.0
	item["extra_spend"] += 2.0
	energy -= 5
	current_time_minutes += 10
	day_stats["research"] += 2.0
	item["tested"] = true
	item["action_order"].append("test")

	var result_text = "WORKING"
	if item["fault"]:
		result_text = item["fault_severity"] + " FAULT"
	var plain_line = "Fault chance: %.1f%% | Rolled: %.2f%% | Result: %s" % [item["fault_chance"] * 100.0, item["fault_roll"] * 100.0, result_text]
	record_rng(plain_line)
	var colored_line = "[color=#e08fd0]Fault chance: %.1f%% | Rolled: %.2f%%[/color] | Result: %s" % [item["fault_chance"] * 100.0, item["fault_roll"] * 100.0, result_text]
	var after = estimate_identified_potential(item)
	item["test_note"] = "Test Complete — %s. Selling price %s: £%d–£%d -> £%d–£%d." % [colored_line, ("decreased" if after[1] < before[1] else "unchanged"), before[0], before[1], after[0], after[1]]
	show_inventory()

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
	var cost = 18.0
	if float(item["true_value"]) > 150.0:
		cost = 32.0
	if item["special_discovered"] and item["hidden_special"] != "":
		cost += 42.0
	return cost

func authentication_accuracy(item):
	var cost = authentication_cost(item)
	var accuracy = 0.84
	if cost >= 32.0:
		accuracy = 0.92
	if item["special_discovered"] and item["hidden_special"] != "":
		accuracy = 0.96
	return accuracy

func authenticate_item(index):
	if index >= inventory.size():
		return
	var item = inventory[index]
	if item["auth_attempted"]:
		set_status("Authentication has already been attempted once.")
		return
	var cost = authentication_cost(item)
	if cash < cost or energy < 6:
		set_status("Need £%.0f and E6." % cost)
		return
	cash -= cost
	item["extra_spend"] += cost
	energy -= 6
	current_time_minutes += 15
	day_stats["authentication"] += cost
	item["auth_attempted"] = true
	item["action_order"].append("authenticate")

	var accuracy = authentication_accuracy(item)
	var roll = rng.randf()
	var success = roll < accuracy
	var plain_line = "Accuracy: %.0f%% | Rolled: %.2f%% | Result: %s" % [accuracy * 100.0, roll * 100.0, "SUCCESS" if success else "INCONCLUSIVE"]
	var line = "[color=#e08fd0]Accuracy: %.0f%% | Rolled: %.2f%%[/color] | Result: %s" % [accuracy * 100.0, roll * 100.0, "SUCCESS" if success else "INCONCLUSIVE"]
	record_rng(plain_line)
	if success:
		if item["authentic"]:
			item["auth_status"] = "Confirmed Genuine"
		else:
			item["auth_status"] = "Confirmed Counterfeit"
			item["identified_mult"] *= 0.10
			unlock_achievement("Should've Known Better")
	else:
		item["auth_status"] = "Inconclusive"
	item["auth_note"] = "%s — %s" % [line, item["auth_status"]]
	set_status("AUTHENTICATION COMPLETE — %s. This one-time attempt cannot be rerolled." % item["auth_status"])
	show_inventory()

func repair_cost(item):
	if item["fault_severity"] == "Minor":
		return 5.0
	if item["fault_severity"] == "Moderate":
		return 10.0
	if item["fault_severity"] == "Major":
		return 18.0
	return 25.0

func repair_item(index):
	if index >= inventory.size():
		return
	var item = inventory[index]
	if toolbox_level <= 0:
		set_status("Buy a Toolbox in the Shop first.")
		return
	if item["repair_attempted"]:
		set_status("You've already attempted this repair once.")
		return
	var cost = repair_cost(item)
	if cash < cost or energy < 10:
		set_status("Need £%.0f and E10." % cost)
		return
	cash -= cost
	item["extra_spend"] += cost
	energy -= 10
	current_time_minutes += 30
	day_stats["repairs"] += cost
	item["repair_attempted"] = true

	var base_chance = 0.62
	if item["fault_severity"] == "Moderate":
		base_chance = 0.48
	elif item["fault_severity"] == "Major":
		base_chance = 0.30
	elif item["fault_severity"] == "Dead":
		base_chance = 0.16
	var chance = clamp(base_chance + float(toolbox_upgrades[toolbox_level]["bonus"]), 0.05, 0.90)
	var roll = rng.randf()
	var success = roll < chance
	record_rng("Repair success chance: %.1f%% | Rolled: %.2f%% | Result: %s" % [chance * 100.0, roll * 100.0, "SUCCESS" if success else "FAILED"])
	if success:
		if item["fault_severity"] == "Minor" or item["fault_severity"] == "Moderate":
			item["fault"] = false
			item["fault_severity"] = "None"
		elif item["fault_severity"] == "Major":
			item["fault_severity"] = "Minor"
		else:
			item["fault_severity"] = "Moderate"
	item["repair_note"] = "Repair — [color=#e08fd0]Chance %.0f%% | Rolled %.2f%%[/color] — %s. %s" % [chance * 100.0, roll * 100.0, ("SUCCESS" if success else "FAILED"), function_status(item)]
	show_inventory()

func buyer_interest_score(item, price):
	var potential = estimate_identified_potential(item)
	var low = float(potential[0])
	var high = float(potential[1])
	var span = max(1.0, high - low)
	var position = clamp((price - low) / span, 0.0, 1.0)
	var score = 0.92 - position * 0.70
	score *= float(current_trends.get(item["category"], 1.0))
	if item["condition"] >= 8:
		score *= 1.08
	elif item["condition"] <= 4:
		score *= 0.90
	if item["auth_status"] == "Confirmed Genuine":
		score *= 1.10
	elif item["auth_status"] == "Unauthenticated" and item["fake_chance"] >= 0.08:
		score *= 0.88
	if item["one_in"] >= 500:
		score *= 1.08
	score *= lerp(0.92, 1.08, float(reputation) / 100.0)
	var checks_done = 0
	var checks_total = 4
	if item["condition_checked"]:
		checks_done += 1
	if item["basic_researched"]:
		checks_done += 1
	if item["deep_researched"]:
		checks_done += 1
	if item["auth_attempted"]:
		checks_done += 1
	if item["testable"]:
		checks_total += 1
		if item["tested"]:
			checks_done += 1
	score *= lerp(0.90, 1.14, float(checks_done) / float(checks_total))
	return clamp(score, 0.08, 0.98)

func buyer_interest_label(item, price):
	var score = buyer_interest_score(item, price)
	if score >= 0.78:
		return "VERY HIGH"
	if score >= 0.62:
		return "HIGH"
	if score >= 0.45:
		return "AVERAGE"
	if score >= 0.28:
		return "LOW"
	return "VERY LOW"

func create_listing(index, value_edit):
	if index >= inventory.size():
		return
	var item = inventory[index]
	if item["auth_status"] == "Confirmed Counterfeit":
		set_status("Confirmed counterfeit items cannot be listed normally.")
		return
	if item["testable"] and not item["tested"]:
		show_blocked_popup("You need to test this item first.")
		return
	var potential = estimate_identified_potential(item)
	var price = clamp(_parse_price(value_edit.text), float(potential[0]), float(potential[1]))
	item["listing"] = price
	item["listed"] = true
	var interest = buyer_interest_score(item, price)
	var instant_chance = clamp(0.04 + interest * 0.22, 0.02, 0.30)
	var result = resolve_item_sale(item, instant_chance)
	if result == "sold_removed":
		inventory.remove_at(index)
		pending_instant_sale_banner = "SOLD INSTANTLY! %s went for £%.2f the moment you listed it — the price was too good to pass up." % [item["name"], price]
		set_status(pending_instant_sale_banner, Color(0.55,0.85,0.58,1.0))
	elif result == "returned":
		set_status("Sold instantly, then returned — %s is back in your inventory, unlisted." % item["name"])
	else:
		set_status("LISTED %s at £%.2f — Buyer Interest %s." % [item["name"], price, buyer_interest_label(item, price)])
	show_inventory()

func unlist_item(index):
	if index >= inventory.size():
		return
	inventory[index]["listed"] = false
	inventory[index]["listing"] = 0.0
	set_status("Listing removed.")
	show_inventory()

func scrap_item(index):
	if index >= inventory.size():
		return
	var item = inventory[index]
	var recovery = max(1.0, round(float(item["paid"]) * rng.randf_range(0.04, 0.18)))
	cash += recovery
	day_stats["items_scrapped"] += 1
	carry_used = max(0, carry_used - size_units(item))
	inventory.remove_at(index)
	unlock_achievement("Better Than Nothing")
	set_status("Recovered £%.2f from scrap/parts." % recovery)
	show_inventory()

func selling_costs(item, sale_price):
	var fee = sale_price * float(fee_upgrades[fee_level]["fee"])
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
	return {"fee":fee, "postage":postage, "insurance":insurance, "packaging":packaging}

func resolve_item_sale(item, sale_chance):
	var sale_roll = rng.randf()
	var sold = sale_roll < sale_chance
	record_rng("Buyer chance: %.1f%% | Rolled: %.2f%% | Result: %s" % [sale_chance * 100.0, sale_roll * 100.0, "SOLD" if sold else "NO SALE"])
	if not sold:
		return "no_sale"
	var sale_price = float(item["listing"])
	var costs = selling_costs(item, sale_price)
	var net = sale_price - costs["fee"] - costs["postage"] - costs["insurance"] - costs["packaging"]
	cash += net
	day_stats["sales_revenue"] += sale_price
	day_stats["fees"] += costs["fee"]
	day_stats["postage"] += costs["postage"] + costs["insurance"] + costs["packaging"]
	day_stats["items_sold"] += 1

	var return_chance = 0.02
	if item["auth_status"] == "Unauthenticated":
		return_chance += float(item["fake_chance"]) * 0.55
	if not item["authentic"] and item["auth_status"] == "Unauthenticated":
		return_chance += 0.18
	if item["fault"]:
		if fault_is_known(item):
			return_chance += 0.06
		else:
			return_chance += 0.14
	if not item["condition_checked"]:
		return_chance += 0.12
	var return_roll = rng.randf()
	var returned = return_roll < return_chance
	record_rng("Buyer return chance: %.2f%% | Rolled: %.2f%% | Result: %s" % [return_chance * 100.0, return_roll * 100.0, "RETURN" if returned else "NO RETURN"])
	if returned:
		cash -= sale_price
		reputation = max(0, reputation - 3)
		day_stats["returns"] += 1
		item["listed"] = false
		return "returned"
	sold_history.append({"name":item["name"], "price":sale_price, "day":day, "condition":item["condition"], "condition_checked":item["condition_checked"], "paid":item["paid"], "fee":costs["fee"], "postage":costs["postage"], "insurance":costs["insurance"], "packaging":costs["packaging"], "extra_spend":float(item.get("extra_spend", 0.0))})
	carry_used = max(0, carry_used - size_units(item))
	if sale_price - item["paid"] > 0:
		unlock_achievement("First Flip")
	return "sold_removed"

func process_sales():
	var to_remove = []
	for i in range(inventory.size()):
		var item = inventory[i]
		if not item["listed"]:
			continue
		var interest = buyer_interest_score(item, float(item["listing"]))
		var chance = clamp(0.05 + interest * 0.47, 0.04, 0.55)
		var result = resolve_item_sale(item, chance)
		if result == "sold_removed":
			to_remove.append(i)
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

func buy_mystery_package():
	if mystery_packages_left <= 0:
		set_status("No Mystery Packages left today.")
		return
	if cash < 30.0:
		set_status("You need £30.")
		return
	if inventory_space_used() + 2 > int(storage_upgrades[storage_level]["capacity"]):
		set_status("You need at least 2 free storage space before opening a package.")
		return
	cash -= 30.0
	day_stats["buy_spend"] += 30.0
	mystery_packages_left -= 1

	var roll = rng.randf()
	var cumulative = 0.0
	var tier = "Poor"
	for row in get_package_chances():
		cumulative += row["chance"]
		if roll <= cumulative:
			tier = row["tier"]
			break
	record_rng("Mystery Package tier roll | Rolled: %.2f%% | Result: %s" % [roll * 100.0, tier])

	var count = 1
	if rng.randf() < 0.30:
		count = 2
	var budget = package_budget(tier)
	var contents = []
	for i in range(count):
		var source = "House Clearance"
		if tier == "Excellent" or tier == "Jackpot" or tier == "Grail":
			source = "Collector"
		var item = generate_item(source)
		var share = budget / float(count) * rng.randf_range(0.85, 1.15)
		item["true_value"] = max(1.0, share)
		item["paid"] = 30.0 / float(count)
		inventory.append(item)
		register_collection(item)
		contents.append(item["name"])
	set_status("MYSTERY PACKAGE — %s tier | %d item(s) | Contents: %s" % [tier, count, ", ".join(contents)])
	update_header()

func show_trends():
	current_screen_name = "show_trends"
	clear_body()
	update_header()
	var title = Label.new()
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	title.text = "MARKET & TRENDS — Week %d | %s" % [current_week, get_season_name()]
	body.add_child(title)
	var intro = Label.new()
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	intro.text = "Public market signals affect selling potential and Buyer Interest. Future changes remain hidden."
	body.add_child(intro)
	for category in current_trends.keys():
		var mult = float(current_trends[category])
		var direction = "-> STEADY"
		if mult >= 1.10:
			direction = "^ HOT"
		elif mult >= 1.03:
			direction = "^ RISING"
		elif mult <= 0.90:
			direction = "v WEAK"
		elif mult <= 0.97:
			direction = "v COOLING"
		var line = Label.new()
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.text = "%-13s %s %+.0f%%" % [category, direction, (mult - 1.0) * 100.0]
		body.add_child(line)
	var chatter = Label.new()
	chatter.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chatter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chatter.add_theme_font_size_override("font_size", 16)
	chatter.text = "MARKET CHATTER"
	body.add_child(chatter)
	for headline in trend_headlines:
		var line = Label.new()
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.text = "• " + headline
		body.add_child(line)

func show_shop():
	current_screen_name = "show_shop"
	clear_body()
	update_header()
	var title = Label.new()
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	title.text = "SHOP & UPGRADES"
	body.add_child(title)
	var upkeep_note = Label.new()
	upkeep_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	upkeep_note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upkeep_note.text = "Current daily business upkeep: £%.2f (scales with total upgrade levels owned — a bigger operation costs more to run every day, on top of rent)." % compute_upkeep()
	upkeep_note.add_theme_color_override("font_color", Color(0.85,0.68,0.55,1.0))
	body.add_child(upkeep_note)
	add_upgrade_card("Car Boot Carrying", bag_upgrades, bag_level, "bag")
	add_upgrade_card("Home Storage", storage_upgrades, storage_level, "storage")
	add_upgrade_card("Repair Tools", toolbox_upgrades, toolbox_level, "toolbox")
	add_upgrade_card("Inspect Skill", eye_upgrades, eye_level, "eye")
	add_upgrade_card("Selling Fees", fee_upgrades, fee_level, "fee")
	add_scaling_upgrade_card("Package Insight", package_insight_level, PACKAGE_INSIGHT_MAX, package_insight_cost(package_insight_level), "Shifts Mystery Package odds away from Poor and into better tiers. Current: Poor reduced by %d%%, redistributed mostly to Average/Good." % package_insight_level, "package_insight")
	add_scaling_upgrade_card("Persuasion Knowledge", persuasion_level, PERSUASION_MAX, persuasion_cost(persuasion_level), "A flat bonus to your acceptance chance on every haggle offer. Current: +%d%%." % persuasion_level, "persuasion")

func add_scaling_upgrade_card(title, level, max_level, cost, description, kind, target = null):
	if target == null:
		target = body
	var panel = make_card()
	target.add_child(panel)
	var box = VBoxContainer.new()
	panel.add_child(box)
	var head = Label.new()
	head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_theme_font_size_override("font_size", 17)
	head.text = "%s — Level %d/%d" % [title, level, max_level]
	box.add_child(head)
	var desc = Label.new()
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc.text = description
	box.add_child(desc)
	if level < max_level:
		var button = Button.new()
		button.text = "Upgrade to Level %d — £%.0f" % [level + 1, cost]
		button.pressed.connect(Callable(self, "buy_scaling_upgrade").bind(kind))
		style_button(button, "buy")
		box.add_child(button)
	else:
		var maxed = Label.new()
		maxed.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		maxed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		maxed.text = "MAX LEVEL"
		box.add_child(maxed)

func buy_scaling_upgrade(kind):
	var level = 0
	var max_level = 0
	var cost = 0.0
	if kind == "package_insight":
		level = package_insight_level
		max_level = PACKAGE_INSIGHT_MAX
		cost = package_insight_cost(level)
	else:
		level = persuasion_level
		max_level = PERSUASION_MAX
		cost = persuasion_cost(level)
	if level >= max_level:
		return
	if cash < cost:
		set_status("You need £%.0f for that upgrade." % cost)
		return
	cash -= cost
	if kind == "package_insight":
		package_insight_level += 1
	else:
		persuasion_level += 1
	set_status("UPGRADE PURCHASED.")
	show_shop()

func add_upgrade_card(title, data, level, kind, target = null):
	if target == null:
		target = body
	var panel = make_card()
	target.add_child(panel)
	var box = VBoxContainer.new()
	panel.add_child(box)
	var head = Label.new()
	head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_theme_font_size_override("font_size", 17)
	head.text = title + " — Current: " + str(data[level]["name"])
	box.add_child(head)
	var description = Label.new()
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if kind == "bag":
		description.text = "Capacity %d per car-boot day. Small=1, Medium=2, Large=4." % data[level]["capacity"]
	elif kind == "storage":
		description.text = "Home inventory capacity %d space." % data[level]["capacity"]
	elif kind == "eye":
		description.text = "Inspect accuracy %d%%. An Inspect can still be wrong and never reveals exact Condition." % int(float(data[level]["accuracy"]) * 100.0)
	elif kind == "fee":
		description.text = "Platform fee %.1f%% on every sale. Lower fees compound the more you sell." % (float(data[level]["fee"]) * 100.0)
	else:
		description.text = "Unlocks repair RNG and improves repair chance by +%d%%." % int(float(data[level]["bonus"]) * 100.0)
	box.add_child(description)
	if level < data.size() - 1:
		var next = data[level + 1]
		var button = Button.new()
		button.text = "Upgrade to %s — £%.0f" % [next["name"], next["cost"]]
		button.pressed.connect(Callable(self, "buy_upgrade").bind(kind))
		style_button(button, "buy")
		box.add_child(button)
	else:
		var maxed = Label.new()
		maxed.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		maxed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		maxed.text = "MAX UPGRADE"
		box.add_child(maxed)

func buy_upgrade(kind):
	var data = []
	var level = 0
	if kind == "bag":
		data = bag_upgrades
		level = bag_level
	elif kind == "storage":
		data = storage_upgrades
		level = storage_level
	elif kind == "eye":
		data = eye_upgrades
		level = eye_level
	elif kind == "fee":
		data = fee_upgrades
		level = fee_level
	else:
		data = toolbox_upgrades
		level = toolbox_level
	if level >= data.size() - 1:
		return
	var cost = float(data[level + 1]["cost"])
	if cash < cost:
		set_status("You need £%.0f for that upgrade." % cost)
		return
	cash -= cost
	if kind == "bag":
		bag_level += 1
	elif kind == "storage":
		storage_level += 1
	elif kind == "eye":
		eye_level += 1
	elif kind == "fee":
		fee_level += 1
	else:
		toolbox_level += 1
	set_status("UPGRADE PURCHASED.")
	show_shop()

var patch_notes = [
	{"version": "Latest — 09/09/2026 17:30", "notes": [
		"Reverted the box reordering from last update — Condition/Research/Deep Research/Test/Authenticate now stay in their original fixed positions again",
		"Fixed: Condition checked on the STALL page (before buying) never actually recorded the price-change note — only the Inventory version did. Now both do, so the values genuinely carry over when you buy the item",
		"Stall page now uses the same greyed-out box style as Inventory for Condition and Research results, instead of a bare line above the buttons",
		"New: the action currently holding the highest max price value (across Condition, Research, and Deep Research) is now highlighted yellow — recalculated live as you do more actions, whichever action or page it happens on",
	]},
	{"version": "Latest — 09/09/2026 17:05", "notes": [
		"Fixed: Condition/Research/Deep Research results were showing twice in Inventory (old lines above the actions row never got removed when the boxes were added) — removed the duplicates",
		"Hidden-defect description ('No hidden defects found' / fault warning) now lives inside the Condition Checked box instead of its own separate line",
		"Completed-action boxes (Condition/Research/Deep Research/Test/Authenticate) now stack most-recently-clicked first",
		"Slightly larger text in these boxes, before and after completion",
	]},
	{"version": "Latest — 09/09/2026 16:40", "notes": [
		"Fixed: blocked-action popup wasn't actually centering correctly — was positioning itself before the box's size had updated for the new text; now waits for layout to settle first",
		"Fixed: press-and-hold tooltips on mobile stopped working after the popup rework — restored with their own small bottom bar, separate from the red error popup",
		"Inventory cards decluttered: Buyer Interest now shows only next to Create Listing (was appearing 3 times), removed the redundant Unlisted/Listed text (tabs already show this)",
		"Condition, Research, Deep Research, Test, and Authenticate now show their result INSIDE the greyed-out completed box, instead of as a separate line below it",
	]},
	{"version": "Latest — 09/09/2026 16:20", "notes": [
		"Brought back the floating red center popup for the three blocked-action messages (not enough cash, not enough bag space, test-required) — everything else stays inline as before",
	]},
	{"version": "Latest — 09/09/2026 16:05", "notes": [
		"Fixed: Deep Research note was missing the actual rolled value — now shows Chance/Rolled/Result like everywhere else",
		"Fixed: blocked-action messages (not enough cash, not enough bag space, test-required) had genuinely stopped showing anywhere after the popup removal — now shown inline on the relevant item card",
	]},
	{"version": "Latest — 09/09/2026 15:45", "notes": [
		"Removed all floating popups/toasts entirely — action results now appear inline in the item card instead",
		"Unified coloring: normal result text blue, any RNG/chance/rolled-percentage text pink — applies to Inspect, Research, Condition, Offers, Testing, Authentication, Repairs, and rare-variant rolls",
		"Offers and Repairs now show a persistent inline result for the first time (previously only a temporary message)",
	]},
	{"version": "Latest — 09/09/2026 15:20", "notes": [
		"Removed swipe-to-dismiss on mobile (kept just the × button, made bigger and easier to tap on both mobile and desktop)",
		"Blocked-action messages now use exact short wording: 'Not enough cash.', 'Not enough space in your bag.', 'You need to test this item first.'",
		"Inventory split into UNLISTED / LISTED tabs with live counts — always opens on Unlisted; listing/unlisting moves items between tabs immediately",
	]},
	{"version": "Latest — 09/09/2026 14:50", "notes": [
		"Swipe left to dismiss a stall item on mobile (session-only, doesn't touch the real item pool, free — no Energy or time cost)",
		"Added a small × button next to every stall item for the same dismiss action on desktop",
	]},
	{"version": "Latest — 09/09/2026 14:30", "notes": [
		"Authenticate button now shows its accuracy % before pressing, and the actual Chance/Rolled/Result outcome on the button itself afterward — matching Test and Deep Research",
	]},
	{"version": "Latest — 09/09/2026 14:10", "notes": [
		"The exact Inspect result (e.g. 'Looks rough', 'Looks unusually clean') now persists into the Inventory card if the item was inspected before buying",
	]},
	{"version": "Latest — 09/09/2026 13:50", "notes": [
		"£ Sold tab now shows a Profit column, calculated from the actual realised sale after fees/postage/packaging/paid/research spend — green if positive, red if negative",
	]},
	{"version": "Latest — 08/09/2026 22:28", "notes": [
		"Polished the main mobile navigation: Stall, Stalls, Inventory, £ Sold, Shop and More now fill the full row cleanly with no wasted space",
		"Stall, Stalls and especially Inventory have been given more room while all six navigation buttons remain on one line",
	]},
	{"version": "Latest — 08/09/2026 22:45", "notes": [
		"Reclaimed mobile screen space: status/help and Last RNG no longer reserve a permanent footer area",
		"Button hold-help and RNG results now appear in a temporary bottom overlay and automatically disappear after 4 seconds",
	]},
	{"version": "Latest — 08/09/2026 22:34", "notes": [
		"Improved mobile readability: increased smaller gameplay, research, condition, sale-breakdown and RNG text sizes",
		"Energy, Rep, Listed and Day are now larger and centred in the second HUD row; End Day text increased to match",
	]},
	{"version": "Latest — 08/09/2026 21:56", "notes": [
		"Header spacing polished for mobile: Cash, Carry and Storage now fill the entire first row evenly; Energy, Rep, Listed, Day and End Day fill the entire second row evenly",
	]},
	{"version": "Previous Update — 08/09/2026 21:39", "notes": [
		"Fixed Jersey 10 font loading for Web/mobile exports by using Godot's imported font resource",
	]},
	{"version": "Previous Update — 08/09/2026 21:33", "notes": [
		"Added Jersey 10 as the global UI font across the game",
	]},
	{"version": "Previous Update", "notes": [
		"Fixed: Haggled Savings achievement wasn't tracking at all — it was wired to the wrong purchase path (special offers instead of normal buys)",
		"Selling an item without ever checking Condition now carries a real extra return risk",
		"The 'Rare-variant gamble' shown after Basic Research is now real — it directly sets your Deep Research odds instead of being flavor text",
		"Test and Deep Research buttons now show their odds directly on the button; results appear as blue text in the same place as other research results",
		"Renamed 'Quick Look' to 'Inspect' throughout",
		"Removed nested scrollboxes — the whole page now scrolls as one, with Cash/Carry/Storage/nav fixed at the top",
		"Added this Patch Notes screen",
	]},
	{"version": "Earlier", "notes": [
		"Mobile support: Web export, real touch-drag scrolling, numeric keyboard on price fields, responsive layout for phone portrait/landscape",
		"Haggle overhaul: player-chosen offer price with a live acceptance %, escalating consequences for aggressive lowballing",
		"Quick Sell, Condition now visibly affects price, postage rebalanced for cheap items, colored profit/Buyer Interest throughout",
		"Header redesigned with colored stat pills and hand-drawn icons for Cash/Carry/Storage",
		"Shop economy expanded (Selling Fees, Package Insight, Persuasion Knowledge tracks) for a longer game",
		"Bankruptcy, business upkeep, and haggle-backfire risk added for a harder long game",
	]},
]

func show_patch_notes():
	current_screen_name = "show_patch_notes"
	clear_body()
	update_header()
	var title = Label.new()
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	title.text = "PATCH NOTES"
	body.add_child(title)
	for entry in patch_notes:
		var panel = make_card()
		body.add_child(panel)
		var box = VBoxContainer.new()
		box.add_theme_constant_override("separation", 4)
		panel.add_child(box)
		var version_label = Label.new()
		version_label.add_theme_font_size_override("font_size", 15)
		version_label.text = entry["version"]
		box.add_child(version_label)
		for note in entry["notes"]:
			var note_label = Label.new()
			note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			note_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			note_label.add_theme_font_size_override("font_size", 13)
			note_label.add_theme_color_override("font_color", Color(0.72,0.78,0.85,1.0))
			note_label.text = "- " + note
			box.add_child(note_label)
	footer_label.text = ""

func show_sold_history():
	current_screen_name = "show_sold_history"
	clear_body()
	update_header()
	var title = Label.new()
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	title.text = "£ SOLD LISTINGS"
	body.add_child(title)
	if sold_history.size() == 0:
		var empty = Label.new()
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty.text = "No sales yet."
		body.add_child(empty)
		return
	for sale in sold_history:
		var sold_condition_text = "Unknown"
		if sale["condition_checked"]:
			sold_condition_text = "%d/10" % sale["condition"]
		var costs_total = float(sale.get("fee", 0.0)) + float(sale.get("postage", 0.0)) + float(sale.get("insurance", 0.0)) + float(sale.get("packaging", 0.0))
		var profit = float(sale["price"]) - costs_total - float(sale.get("paid", 0.0)) - float(sale.get("extra_spend", 0.0))
		var profit_color = "#8cd98f" if profit >= 0.0 else "#e88c7a"
		var line = RichTextLabel.new()
		line.bbcode_enabled = true
		line.fit_content = true
		line.scroll_active = false
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.text = "%s | Condition %s | Sold £%.2f | [color=%s]Profit £%+.2f[/color] | Day %d" % [sale["name"], sold_condition_text, sale["price"], profit_color, profit, sale["day"]]
		body.add_child(line)

func show_collection_log():
	current_screen_name = "show_collection_log"
	clear_body()
	update_header()
	var total_possible = item_families.size() * rarity_table.size()
	var title = Label.new()
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	title.text = " COLLECTION LOG — %d/%d discovered" % [discovered_log.size(), total_possible]
	body.add_child(title)


	var entries = []
	for family in item_families:
		for tier_row in rarity_table:
			var key = family["category"] + "|" + family["name"] + "|" + tier_row["tier"]
			if discovered_log.has(key):
				var found = discovered_log[key]
				entries.append({"discovered":true, "name":found["name"], "category":found["category"], "rarity":found["rarity"], "one_in":found["one_in"]})
			else:
				entries.append({"discovered":false, "name":"???", "category":family["category"], "rarity":tier_row["tier"], "one_in":int(tier_row["one_in"])})
	entries.sort_custom(Callable(self, "sort_log"))

	for entry in entries:
		var odds = "Common"
		if entry["one_in"] > 1:
			odds = "%s — 1/%d" % [entry["rarity"], entry["one_in"]]
		var line = Label.new()
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var prefix = "" if entry["discovered"] else "· "
		line.text = "%s%s | %s | %s" % [prefix, entry["name"], entry["category"], odds]
		if not entry["discovered"]:
			line.add_theme_color_override("font_color", Color(0.42,0.47,0.55,1.0))
		body.add_child(line)

func sort_log(a, b):
	return int(a["one_in"]) > int(b["one_in"])

func show_achievements():
	current_screen_name = "show_achievements"
	clear_body()
	update_header()
	var title = Label.new()
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	title.text = "ACHIEVEMENTS"
	body.add_child(title)

	var haggle_title = Label.new()
	haggle_title.add_theme_font_size_override("font_size", 15)
	haggle_title.text = "Total Haggled Savings: £%.2f / £100,000" % total_haggled_savings
	body.add_child(haggle_title)

	var haggle_bar = ProgressBar.new()
	haggle_bar.min_value = 0
	haggle_bar.max_value = 100000
	haggle_bar.value = clamp(total_haggled_savings, 0, 100000)
	haggle_bar.show_percentage = false
	haggle_bar.custom_minimum_size = Vector2(0, 22)
	body.add_child(haggle_bar)

	var milestones = [100.0, 500.0, 1000.0, 5000.0, 10000.0, 25000.0, 50000.0, 100000.0]
	var milestone_parts = []
	for m in milestones:
		var reached = total_haggled_savings >= m
		var label_text = "£%d" % int(m) if m < 1000.0 else "£%dk" % int(m / 1000.0)
		milestone_parts.append(("X" if reached else "-") + label_text)
	var milestone_line = Label.new()
	milestone_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	milestone_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	milestone_line.add_theme_font_size_override("font_size", 12)
	milestone_line.add_theme_color_override("font_color", Color(0.62,0.68,0.76,1.0))
	milestone_line.text = "  ".join(milestone_parts)
	body.add_child(milestone_line)

	var all_achievements = ["First Flip", "Against the Odds", "Should've Known Better", "Better Than Nothing", "Actually Mate...", "Car Boot King"]
	for achievement in all_achievements:
		var line = Label.new()
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var prefix = "[ ] "
		if achievements.has(achievement):
			prefix = ""
		line.text = prefix + achievement
		body.add_child(line)

func unlock_achievement(name):
	if not achievements.has(name):
		achievements[name] = true
		set_status("Achievement unlocked: " + name)

func record_rng(line):
	last_rng_line = line
	footer_label.text = "Last RNG: " + last_rng_line
	day_stats["rng_events"].append(line)
	if day_stats["rng_events"].size() > 12:
		day_stats["rng_events"].pop_front()
	_show_status_overlay(true)

func chance_text(chance):
	if chance <= 0.0:
		return "0%"
	var pct = chance * 100.0
	var one = int(round(1.0 / chance))
	if chance < 0.10:
		return "%.2f%% (1/%d)" % [pct, one]
	return "%.1f%%" % pct

func end_day():
	process_sales()
	var upkeep = compute_upkeep()
	cash -= daily_expenses
	cash -= upkeep
	day_stats["rent"] = daily_expenses
	day_stats["upkeep"] = upkeep
	day_stats["expenses"] += daily_expenses + upkeep
	if cash < 0:
		var interest = abs(cash) * 0.06
		cash -= interest
		day_stats["interest"] = interest
		day_stats["expenses"] += interest
		negative_days_streak += 1
	else:
		negative_days_streak = 0
	if negative_days_streak >= 4:
		show_bankruptcy_screen()
		return
	show_day_summary()
	day += 1
	energy = 100
	current_time_minutes = 7 * 60
	if cash >= 50000:
		unlock_achievement("Car Boot King")
	if (day - 1) % 7 == 0:
		generate_weekly_trends()
	reset_day_stats()
	generate_day()
	update_header()

func show_bankruptcy_screen():
	clear_body()
	var title = Label.new()
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 24)
	title.text = "BANKRUPT — GAME OVER"
	body.add_child(title)
	var msg = Label.new()
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	msg.text = "Cash stayed negative for %d days in a row and the overdraft interest finally buried the business. Final cash: £%.2f on Day %d." % [negative_days_streak, cash, day]
	body.add_child(msg)
	var stats = Label.new()
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.text = "Items sold: %d  •  Achievements unlocked: %d/6  •  Collection: %d discovered" % [sold_history.size(), achievements.size(), discovered_log.size()]
	body.add_child(stats)
	var restart = Button.new()
	restart.text = "Start New Game"
	restart.pressed.connect(restart_game)
	style_button(restart, "buy")
	body.add_child(restart)
	set_status("Game over. Start a new run whenever you're ready.")
	footer_label.text = ""

func restart_game():
	day = 1
	cash = 300.0
	energy = 100
	reputation = 50
	current_time_minutes = 7 * 60
	daily_expenses = 6.50
	current_stall_index = 0
	stalls.clear()
	inventory.clear()
	sold_history.clear()
	discovered_log.clear()
	achievements.clear()
	negative_days_streak = 0
	bag_level = 0
	storage_level = 0
	toolbox_level = 0
	eye_level = 0
	fee_level = 0
	package_insight_level = 0
	persuasion_level = 0
	carry_used = 0
	mystery_packages_left = 0
	current_trends.clear()
	trend_headlines.clear()
	current_week = 1
	pending_special_offer = null
	reset_day_stats()
	generate_weekly_trends()
	generate_day()
	update_header()
	show_stall()

func show_day_summary():
	clear_body()
	var end_cash = cash
	var start_cash = float(day_stats["start_cash"])
	var profit_today = end_cash - start_cash
	var title = Label.new()
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 22)
	title.text = "DAY %d COMPLETE" % day
	body.add_child(title)
	var profit_line = Label.new()
	profit_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	profit_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	profit_line.add_theme_font_size_override("font_size", 18)
	profit_line.text = "Profit today: %+.2f" % profit_today
	if profit_today >= 0.0:
		profit_line.add_theme_color_override("font_color", Color(0.55,0.85,0.58,1.0))
	else:
		profit_line.add_theme_color_override("font_color", Color(0.92,0.55,0.45,1.0))
	body.add_child(profit_line)
	var lines = [
		"Cash £%.2f -> £%.2f (%+.2f)" % [start_cash, end_cash, end_cash - start_cash],
		"Stock purchased £%.2f" % day_stats["buy_spend"],
		"Sales revenue £%.2f" % day_stats["sales_revenue"],
		"Selling fees -£%.2f" % day_stats["fees"],
		"Postage/insurance/packaging -£%.2f" % day_stats["postage"],
		"Research/testing spend -£%.2f" % day_stats["research"],
		"Authentication spend -£%.2f" % day_stats["authentication"],
		"Repair spend -£%.2f" % day_stats["repairs"],
		"Daily rent -£%.2f  |  Business upkeep -£%.2f" % [day_stats["rent"], day_stats["upkeep"]],
		"Bought %d | Sold %d | Scrapped %d | Returns %d" % [day_stats["items_bought"], day_stats["items_sold"], day_stats["items_scrapped"], day_stats["returns"]],
		"Collection additions %d | Rarest 1/%d" % [day_stats["collection_adds"], day_stats["rarest_one_in"]]
	]
	if float(day_stats["interest"]) > 0.0:
		lines.append("[!] Overdraft interest -£%.2f (cash negative %d day%s running — bankruptcy after 4)" % [day_stats["interest"], negative_days_streak, "" if negative_days_streak == 1 else "s"])
	for text in lines:
		var line = Label.new()
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_theme_font_size_override("font_size", 13)
		line.text = text
		body.add_child(line)
	if cash < 0:
		var warning = Label.new()
		warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		warning.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		warning.text = "[!] CASH NEGATIVE — sell stock or the run is in serious trouble."
		body.add_child(warning)
	var sold_today = []
	for sale in sold_history:
		if sale["day"] == day:
			sold_today.append(sale)
	if sold_today.size() > 0:
		var sold_title = Label.new()
		sold_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sold_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sold_title.add_theme_font_size_override("font_size", 16)
		sold_title.text = "SOLD TODAY (%d)" % sold_today.size()
		body.add_child(sold_title)
		for sale in sold_today:
			var sold_condition_text = "Unknown"
			if sale["condition_checked"]:
				sold_condition_text = "%d/10" % sale["condition"]
			var net = float(sale["price"]) - float(sale["fee"]) - float(sale["postage"]) - float(sale["insurance"]) - float(sale["packaging"])
			var profit = net - float(sale["paid"]) - float(sale.get("extra_spend", 0.0))
			var sold_line = Label.new()
			sold_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			sold_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			sold_line.add_theme_font_size_override("font_size", 13)
			sold_line.text = "• %s | Sold £%.2f | Paid £%.2f | Net £%.2f | Profit %+.2f | Condition %s" % [sale["name"], sale["price"], sale["paid"], net, profit, sold_condition_text]
			body.add_child(sold_line)
			var cost_line = Label.new()
			cost_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			cost_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cost_line.add_theme_font_size_override("font_size", 12)
			cost_line.add_theme_color_override("font_color", Color(0.62,0.68,0.76,1.0))
			cost_line.text = "    Fee £%.2f  •  Postage £%.2f  •  Insurance £%.2f  •  Packaging £%.2f" % [sale["fee"], sale["postage"], sale["insurance"], sale["packaging"]]
			body.add_child(cost_line)
	if day_stats["rng_events"].size() > 0:
		var rng_title = Label.new()
		rng_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rng_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rng_title.text = "Today's RNG events:"
		body.add_child(rng_title)
		for event in day_stats["rng_events"]:
			var event_line = Label.new()
			event_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			event_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			event_line.text = "• " + event
			event_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			event_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			body.add_child(event_line)
	set_status("A new day is ready after this summary.")
