
extends Control

var rng = RandomNumberGenerator.new()

const GAME_VERSION = "0.10.0-playtest"
const STARTING_CASH = 300.0
var has_save = false
var game_over = false
var seller_rating = 100.0
var rng_log = []
var activity_log = []
var best_net_worth = 300.0
var on_title_screen = false
var in_end_day = false
var header_row_ref
var header_grid_ref
var nav_grid_ref
var nav_panel_ref
var nav_buttons = {}
var toast_box
var big_popup
var big_popup_title
var big_popup_body
var big_popup_queue = []

var day = 1
var cash = 300.0
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

var category_knowledge = {
	"Clothing": 5,
	"Games": 5,
	"Trading Cards": 5,
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
	"Desperate Seller": {"knowledge":0.45, "haggle":0.23, "pricing":0.88, "fault":1.15, "fake":1.05, "side":0.010, "depth":18, "rarity_boost":0.80, "categories":["Clothing","Games","Trading Cards","Electronics","Home","Garden & Outdoor"]},
	"House Clearance": {"knowledge":0.35, "haggle":0.34, "pricing":0.90, "fault":1.30, "fake":0.90, "side":0.018, "depth":26, "rarity_boost":0.70, "categories":["Home","Vinyl","Cameras","Tools","Books","Collectables","Jewellery","Musical Instruments","Garden & Outdoor"]},
	"Clueless Seller": {"knowledge":0.40, "haggle":0.38, "pricing":0.84, "fault":0.95, "fake":0.85, "side":0.002, "depth":15, "rarity_boost":0.55, "categories":["Games","Trading Cards","Clothing","Books","Home","Collectables","Garden & Outdoor"]},
	"Regular Seller": {"knowledge":0.60, "haggle":0.56, "pricing":0.98, "fault":1.00, "fake":1.00, "side":0.0015, "depth":14, "rarity_boost":1.00, "categories":["Clothing","Games","Tools","Home","Electronics","Books","Musical Instruments","Garden & Outdoor"]},
	"Collector": {"knowledge":0.86, "haggle":0.78, "pricing":1.06, "fault":0.70, "fake":0.45, "side":0.008, "depth":10, "rarity_boost":1.60, "categories":["Vinyl","Cameras","Collectables","Jewellery","Games","Trading Cards","Musical Instruments"]},
	"Dodgy Seller": {"knowledge":0.48, "haggle":0.36, "pricing":0.82, "fault":1.55, "fake":2.40, "side":0.022, "depth":13, "rarity_boost":0.95, "categories":["Clothing","Trading Cards","Electronics","Games","Jewellery"]},
	"Dealer": {"knowledge":0.90, "haggle":0.84, "pricing":1.10, "fault":0.65, "fake":0.55, "side":0.001, "depth":8, "rarity_boost":1.85, "categories":["Clothing","Games","Cameras","Vinyl","Collectables","Jewellery","Musical Instruments"]}
}

var item_families = [
	{"name":"Football Shirt","category":"Clothing","value":[18,120],"ask":[15,110],"fake":0.10,"size":"small","testable":false,"specials":["Autographed","Rare Sponsor Print","Match-Worn Indicators"]},
	{"name":"Vintage Track Jacket","category":"Clothing","value":[15,95],"ask":[12,85],"fake":0.08,"size":"small","testable":false,"specials":["Rare Embroidered Variant","Deadstock Tags","Autographed"]},
	{"name":"Designer Hoodie","category":"Clothing","value":[25,180],"ask":[20,150],"fake":0.15,"size":"small","testable":false,"specials":["Limited Colourway","Sample Piece","Autographed"]},
	{"name":"Band T-Shirt","category":"Clothing","value":[8,110],"ask":[5,90],"fake":0.05,"size":"small","testable":false,"specials":["Tour Original","Single Stitch","Autographed"]},
	{"name":"Workwear Jacket","category":"Clothing","value":[20,130],"ask":[15,110],"fake":0.06,"size":"small","testable":false,"specials":["Vintage Union Label","Rare Colour","Deadstock Tags"]},
	{"name":"Trading Card Binder","category":"Trading Cards","value":[20,220],"ask":[15,180],"fake":0.08,"size":"small","testable":false,"specials":["1st Edition Card","Misprint Card","Autographed Card"]},
	{"name":"Trading Card Tin","category":"Trading Cards","value":[12,160],"ask":[10,140],"fake":0.07,"size":"small","testable":false,"specials":["Sealed Promo","Error Card","Autographed Insert"]},
	{"name":"Card Game Deck Box","category":"Trading Cards","value":[10,140],"ask":[8,120],"fake":0.08,"size":"small","testable":false,"specials":["Rare Promo","Misprint","Tournament Stamp"]},
	{"name":"Retro Games Bundle","category":"Games","value":[15,150],"ask":[12,130],"fake":0.03,"size":"small","testable":true,"specials":["Rare Variant","Promo Disc","Sealed Game"]},
	{"name":"Console Game Bundle","category":"Games","value":[6,90],"ask":[5,80],"fake":0.02,"size":"small","testable":true,"specials":["Rare Horror Title","Promo Copy","Sealed Copy"]},
	{"name":"Retro Handheld Console","category":"Games","value":[35,160],"ask":[30,145],"fake":0.04,"size":"small","testable":true,"specials":["Limited Colour","Boxed Complete","Development Cart"]},
	{"name":"Dual-Screen Handheld","category":"Games","value":[20,90],"ask":[18,80],"fake":0.03,"size":"small","testable":true,"specials":["Limited Edition","Boxed Complete","Unused Old Stock"]},
	{"name":"Retro Console Controller","category":"Games","value":[15,80],"ask":[12,70],"fake":0.03,"size":"small","testable":true,"specials":["Club Nintendo Variant","Unused Old Stock","Rare Colour"]},
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
	{"name":"Monster Plush Lot","category":"Trading Cards","value":[8,90],"ask":[6,75],"fake":0.05,"size":"medium","testable":false,"specials":["Retired Line","Tag Error","Store Display"]},
	{"name":"Anime Promo Poster","category":"Trading Cards","value":[6,120],"ask":[5,100],"fake":0.06,"size":"medium","testable":false,"specials":["Store Exclusive","Misprint","Signed by Artist"]},
	{"name":"Retro Cartridge Bundle","category":"Games","value":[10,110],"ask":[8,95],"fake":0.03,"size":"small","testable":true,"specials":["Rare Title","Kiosk Demo","Sealed Game"]},
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
	{"name":"Fishing Rod Set","category":"Garden & Outdoor","value":[8,90],"ask":[6,75],"fake":0.01,"size":"medium","testable":false,"specials":["Pro Grade","Rare Maker","Complete Tackle"]},
	{"name":"Christmas Decorations","category":"Home","value":[15,90],"ask":[10,75],"fake":0.04,"size":"small","testable":false,"season":"Winter","specials":["Antique Bauble Set","Hand-Blown Glass Set","Vintage Fairy Lights"]},
	{"name":"Christmas Jumper","category":"Clothing","value":[10,70],"ask":[8,55],"fake":0.05,"size":"small","testable":false,"season":"Winter","specials":["Novelty Rare Print","Designer Collab","Autographed"]},
	{"name":"Winter Coat","category":"Clothing","value":[20,140],"ask":[15,115],"fake":0.08,"size":"medium","testable":false,"season":"Winter","specials":["Vintage Designer Label","Rare Colourway","Deadstock Tags"]},
	{"name":"Garden Furniture Set","category":"Garden & Outdoor","value":[30,180],"ask":[25,150],"fake":0.02,"size":"large","testable":false,"season":"Summer","specials":["Antique Wrought Iron","Rare Original Finish","Limited Edition Set"]},
	{"name":"BBQ Set","category":"Garden & Outdoor","value":[20,120],"ask":[15,100],"fake":0.02,"size":"large","testable":false,"season":"Summer","specials":["Rare Vintage Model","Cast Iron Original","Collector's Edition"]},
	{"name":"Paddling Pool","category":"Garden & Outdoor","value":[8,45],"ask":[5,38],"fake":0.01,"size":"medium","testable":false,"season":"Summer","specials":["Vintage Design Print","Sealed New Old Stock","Rare Pattern"]},
	{"name":"Halloween Costume","category":"Clothing","value":[8,60],"ask":[5,48],"fake":0.03,"size":"small","testable":false,"season":"Autumn","specials":["Rare Movie Replica","Screen-Worn Style","Limited Run"]},
	{"name":"Fireworks Display Box","category":"Collectables","value":[10,55],"ask":[8,45],"fake":0.02,"size":"small","testable":false,"season":"Autumn","specials":["Collector's Tin","Vintage Packaging","Rare Brand"]},
	{"name":"Easter Decorations","category":"Home","value":[6,40],"ask":[4,32],"fake":0.02,"size":"small","testable":false,"season":"Spring","specials":["Hand-Painted Original","Vintage Ceramic","Rare Set"]},
	{"name":"Antique Mirror","category":"Home","value":[25,160],"ask":[20,135],"fake":0.03,"size":"large","testable":false,"specials":["Gilt Frame Original","Bevelled Glass","Rare Maker's Mark"]},
	{"name":"Leather Satchel","category":"Clothing","value":[15,110],"ask":[12,90],"fake":0.10,"size":"small","testable":false,"specials":["Vintage Leather Original","Designer Label","Rare Hardware"]},
	{"name":"Board Game Collection","category":"Games","value":[10,95],"ask":[8,80],"fake":0.02,"size":"medium","testable":false,"specials":["Rare Out-of-Print Title","Complete Original Set","Sealed Copy"]},
	{"name":"Wax Jacket","category":"Clothing","value":[25,160],"ask":[20,130],"fake":0.10,"size":"medium","testable":false,"specials":["Vintage Royal Warrant","Rare Colour","Unworn Deadstock"]},
	{"name":"Vintage Trainers","category":"Clothing","value":[15,220],"ask":[10,180],"fake":0.18,"size":"small","testable":false,"specials":["Original Box","Rare Colourway","Sample Pair"]},
	{"name":"Rugby Shirt","category":"Clothing","value":[8,75],"ask":[6,60],"fake":0.05,"size":"small","testable":false,"specials":["Match Issue","Signed","Rare Sponsor"]},
	{"name":"Ski Jacket","category":"Clothing","value":[15,140],"ask":[12,115],"fake":0.08,"size":"medium","testable":false,"season":"Winter","specials":["Designer Label","Rare Colourway","Tags Attached"]},
	{"name":"Wellington Boots","category":"Clothing","value":[3,50],"ask":[2,40],"fake":0.03,"size":"medium","testable":false,"season":"Autumn","specials":["Heritage Maker","Unworn","Rare Print"]},
	{"name":"Arcade Stick","category":"Games","value":[15,120],"ask":[12,100],"fake":0.03,"size":"medium","testable":true,"specials":["Tournament Edition","Custom Parts","Boxed Complete"]},
	{"name":"PC Big Box Game","category":"Games","value":[5,150],"ask":[4,120],"fake":0.02,"size":"medium","testable":false,"specials":["First Print","Sealed Copy","Rare Publisher"]},
	{"name":"Console Accessories Box","category":"Games","value":[3,45],"ask":[2,35],"fake":0.02,"size":"medium","testable":true,"specials":["Rare Peripheral","Boxed Light Gun","Limited Controller"]},
	{"name":"Sports Card Album","category":"Trading Cards","value":[5,160],"ask":[4,130],"fake":0.05,"size":"small","testable":false,"specials":["Rookie Card","Autographed Card","Short Print"]},
	{"name":"Card Sleeves & Binder Lot","category":"Trading Cards","value":[3,35],"ask":[2,30],"fake":0.02,"size":"small","testable":false,"specials":["Hidden Holo Card","Sealed Pack Inside","Promo Card"]},
	{"name":"Northern Soul 7-inch Lot","category":"Vinyl","value":[10,260],"ask":[8,210],"fake":0.02,"size":"small","testable":false,"specials":["Original Label","Rare Demo","Unreleased Acetate"]},
	{"name":"Cassette Tape Box","category":"Vinyl","value":[2,60],"ask":[2,50],"fake":0.01,"size":"medium","testable":false,"specials":["Rare Demo Tape","Sealed Album","Limited Release"]},
	{"name":"Instant Film Camera","category":"Cameras","value":[10,130],"ask":[8,110],"fake":0.02,"size":"small","testable":true,"specials":["Rare Edition","Boxed Complete","Unused Film Pack"]},
	{"name":"Camcorder","category":"Cameras","value":[5,80],"ask":[4,65],"fake":0.01,"size":"small","testable":true,"specials":["Cult Model","Full Kit","Low Hours"]},
	{"name":"Slide Projector","category":"Cameras","value":[5,60],"ask":[4,50],"fake":0.01,"size":"large","testable":true,"specials":["Rare Lens","Complete Carousel","Original Case"]},
	{"name":"Circular Saw","category":"Tools","value":[15,110],"ask":[12,95],"fake":0.01,"size":"medium","testable":true,"specials":["Pro Model","Unused Blade Set","Complete Case"]},
	{"name":"Vintage Chisel Roll","category":"Tools","value":[8,120],"ask":[6,100],"fake":0.01,"size":"small","testable":false,"specials":["Rare Maker","Complete Set","Early Pattern"]},
	{"name":"Personal Cassette Player","category":"Electronics","value":[8,180],"ask":[6,150],"fake":0.02,"size":"small","testable":true,"specials":["Cult Model","Boxed Complete","Rare Colour"]},
	{"name":"Bluetooth Speaker","category":"Electronics","value":[5,60],"ask":[4,50],"fake":0.06,"size":"small","testable":true,"specials":["Limited Edition","Boxed Unused","Pro Model"]},
	{"name":"Old Mobile Phone","category":"Electronics","value":[2,90],"ask":[2,75],"fake":0.04,"size":"small","testable":true,"specials":["Cult Classic Model","Boxed Complete","Rare Colour"]},
	{"name":"Tablet (unknown model)","category":"Electronics","value":[10,120],"ask":[8,100],"fake":0.03,"size":"small","testable":true,"specials":["Higher Storage Model","Pro Variant","Boxed Complete"]},
	{"name":"Stereo Headphones","category":"Electronics","value":[5,120],"ask":[4,100],"fake":0.08,"size":"small","testable":true,"specials":["Studio Grade","Boxed Complete","Rare Colour"]},
	{"name":"Box of Old Cables","category":"Electronics","value":[1,12],"ask":[1,10],"fake":0.00,"size":"medium","testable":false,"specials":["Rare Adapter","Vintage Leads","Pro Audio Cables"]},
	{"name":"Die-cast Bus Collection","category":"Collectables","value":[8,140],"ask":[6,120],"fake":0.02,"size":"medium","testable":false,"specials":["Rare Livery","Boxed Set","Limited Run"]},
	{"name":"Vintage Teddy Bear","category":"Collectables","value":[5,300],"ask":[4,250],"fake":0.03,"size":"small","testable":false,"specials":["Button in Ear","Early Mohair","Named Maker"]},
	{"name":"Stamp Album","category":"Collectables","value":[3,200],"ask":[2,160],"fake":0.03,"size":"small","testable":false,"specials":["Penny Red Page","Error Stamp","Rare Overprint"]},
	{"name":"Tin Toy Robot","category":"Collectables","value":[10,250],"ask":[8,200],"fake":0.05,"size":"small","testable":false,"specials":["Original Box","Early Version","Working Mechanism"]},
	{"name":"Garden Gnome Collection","category":"Collectables","value":[3,90],"ask":[2,75],"fake":0.01,"size":"medium","testable":false,"season":"Spring","specials":["Rare Maker","Hand-Painted Original","Early Design"]},
	{"name":"Costume Brooch Tin","category":"Jewellery","value":[3,90],"ask":[2,75],"fake":0.12,"size":"small","testable":false,"specials":["Signed Designer Piece","Real Silver Piece","Vintage Paste"]},
	{"name":"Pocket Watch","category":"Jewellery","value":[15,300],"ask":[12,250],"fake":0.10,"size":"small","testable":true,"specials":["Solid Silver Case","Railway Issue","Rare Movement"]},
	{"name":"Vintage Children's Annuals","category":"Books","value":[3,60],"ask":[2,50],"fake":0.00,"size":"medium","testable":false,"specials":["First Year Edition","Signed","Complete Run"]},
	{"name":"Cookbook Stack","category":"Books","value":[2,25],"ask":[1,20],"fake":0.00,"size":"medium","testable":false,"specials":["Signed Chef Copy","First Edition","Rare Regional"]},
	{"name":"Crystal Decanter","category":"Home","value":[8,110],"ask":[6,90],"fake":0.03,"size":"medium","testable":false,"specials":["Maker Etched","Antique Cut","Complete Stopper Set"]},
	{"name":"Carriage Clock","category":"Home","value":[10,140],"ask":[8,115],"fake":0.02,"size":"small","testable":true,"specials":["Working Movement","Rare Maker","Original Key"]},
	{"name":"Stand Mixer","category":"Home","value":[10,150],"ask":[8,120],"fake":0.02,"size":"large","testable":true,"specials":["Rare Colour","Full Attachments","Pro Model"]},
	{"name":"VHS Tape Box","category":"Home","value":[1,30],"ask":[1,25],"fake":0.00,"size":"medium","testable":false,"specials":["Rare Horror Release","Sealed Copy","Promo Screener"]},
	{"name":"Guitar Effects Pedal","category":"Musical Instruments","value":[10,160],"ask":[8,130],"fake":0.04,"size":"small","testable":true,"specials":["Early Version","Rare Circuit","Boxed Complete"]},
	{"name":"Home Keyboard","category":"Musical Instruments","value":[10,200],"ask":[8,160],"fake":0.01,"size":"large","testable":true,"specials":["Cult Synth Model","Full Kit","Rare Colour"]},
	{"name":"Lawnmower","category":"Garden & Outdoor","value":[10,120],"ask":[8,100],"fake":0.00,"size":"large","testable":true,"specials":["Pro Model","Barely Used","Complete Kit"]},
	{"name":"Beach Windbreak & Chairs","category":"Garden & Outdoor","value":[3,30],"ask":[2,25],"fake":0.00,"size":"large","testable":false,"season":"Summer","specials":["Vintage Deckchairs","Unused Set","Rare Stripes"]}
]

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

var root_vbox
var page_scroll
var stat_labels = {}
var body
var footer_label
var status_label
var status_panel
var tooltip_panel
var status_hide_timer
var deep_research_icon
var condition_icon
var research_icon
var test_icon
var authenticate_icon
var inspect_icon
var cash_icon
var carry_icon
var storage_icon
var energy_icon
var category_icons = {}
var blocked_popup
var blocked_popup_label
var blocked_popup_timer
var blocked_popup_style
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
var total_lifetime_profit = 0.0
var inventory_tab = "unlisted"
var fixer_uses_today = 0
var daily_challenges = []
var daily_challenge_bonus_given = false
var lifetime_challenges_completed = 0
var lifetime_fixer_wins = 0
const SAVE_PATH = "user://savegame.json"
var last_save_time = ""
var stat_chip_styles = {}
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
	if ResourceLoader.exists("res://deep_research_icon.png"):
		deep_research_icon = load("res://deep_research_icon.png")
	if ResourceLoader.exists("res://condition_icon.png"):
		condition_icon = load("res://condition_icon.png")
	if ResourceLoader.exists("res://research_icon.png"):
		research_icon = load("res://research_icon.png")
	if ResourceLoader.exists("res://test_icon.png"):
		test_icon = load("res://test_icon.png")
	if ResourceLoader.exists("res://authenticate_icon.png"):
		authenticate_icon = load("res://authenticate_icon.png")
	if ResourceLoader.exists("res://inspect_icon.png"):
		inspect_icon = load("res://inspect_icon.png")
	if ResourceLoader.exists("res://cash_icon.png"):
		cash_icon = load("res://cash_icon.png")
	if ResourceLoader.exists("res://carry_icon.png"):
		carry_icon = load("res://carry_icon.png")
	if ResourceLoader.exists("res://energy_icon.png"):
		energy_icon = load("res://energy_icon.png")
	if ResourceLoader.exists("res://storage_icon.png"):
		storage_icon = load("res://storage_icon.png")
	var category_icon_files = {
		"Clothing": "res://cat_icons/cat_clothing.png",
		"Games": "res://cat_icons/cat_games.png",
		"Trading Cards": "res://cat_icons/cat_trading_cards.png",
		"Electronics": "res://cat_icons/cat_electronics.png",
		"Home": "res://cat_icons/cat_home.png",
		"Vinyl": "res://cat_icons/cat_vinyl.png",
		"Cameras": "res://cat_icons/cat_cameras.png",
		"Tools": "res://cat_icons/cat_tools.png",
		"Collectables": "res://cat_icons/cat_collectables.png",
		"Jewellery": "res://cat_icons/cat_jewellery.png",
		"Books": "res://cat_icons/cat_books.png",
		"Musical Instruments": "res://cat_icons/cat_musical_instruments.png",
		"Garden & Outdoor": "res://cat_icons/cat_garden_outdoor.png",
	}
	for cat in category_icon_files:
		if ResourceLoader.exists(category_icon_files[cat]):
			category_icons[cat] = load(category_icon_files[cat])
	rng.randomize()
	load_settings()
	has_save = load_game()
	if not has_save:
		init_new_run()
	adjust_scale_for_device()
	build_ui()
	build_audio()
	apply_settings()
	show_title_screen()
	get_tree().root.size_changed.connect(_on_size_changed)

func init_new_run():
	# Resets every piece of run state. Settings and tutorial_seen survive.
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
	package_insight_level = 0
	persuasion_level = 0
	carry_used = 0
	mystery_packages_left = 0
	fixer_uses_today = 0
	current_trends = {}
	trend_random = {}
	trend_rumour = {}
	trend_headlines = []
	current_week = 1
	pending_special_offer = null
	skills_unlocked = {}
	total_haggled_savings = 0.0
	total_lifetime_profit = 0.0
	lifetime_challenges_completed = 0
	lifetime_fixer_wins = 0
	game_over = false
	big_popup_queue = []
	popup_queue = []
	seller_rating = 100.0
	rng_log = []
	activity_log = []
	best_net_worth = STARTING_CASH
	goals_done = 0
	cash_last_shown = -999999.0
	for k in category_knowledge.keys():
		category_knowledge[k] = 5
	generate_weekly_trends()
	reset_day_stats()
	generate_day()

func adapt_layout():
	if header_grid_ref != null:
		header_grid_ref.columns = 4 if is_narrow() else 8
	if nav_grid_ref != null:
		nav_grid_ref.columns = 3 if is_narrow() else 6

func _on_size_changed():
	if sim_mode:
		return
	adjust_scale_for_device()
	call_deferred("_rerender_after_resize")

func _rerender_after_resize():
	adapt_layout()
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
		"show_title_screen":
			show_title_screen()
		"show_settings_screen":
			show_settings_screen()
		"show_tutorial":
			show_tutorial()
		"show_more_menu":
			show_more_menu()
		"show_skill_tree":
			show_skill_tree()
		_:
			pass

const MIN_LOGICAL_WIDTH = 560.0

func adjust_scale_for_device():
	if sim_mode:
		return
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
	var factor = clamp(1.0 / auto_shrink, 1.0, 4.5) * ui_scale
	# Never let the logical canvas get narrower than MIN_LOGICAL_WIDTH units, or
	# the layout can't fit (phones in portrait). Logical width = window width / (base scale * factor).
	var base_scale = min(float(get_window().size.x) / 1600.0, float(get_window().size.y) / 900.0)
	if base_scale > 0.0:
		var logical_w = float(get_window().size.x) / (base_scale * factor)
		if logical_w < MIN_LOGICAL_WIDTH:
			factor *= logical_w / MIN_LOGICAL_WIDTH
	get_window().content_scale_factor = max(0.25, factor)

func build_ui():
	# Global UI font: Jersey 10.
	# Keep Jersey10-Regular.ttf in res://fonts/
	var global_theme = Theme.new()
	var jersey_font = load("res://fonts/Jersey10-Regular.ttf")
	if jersey_font != null:
		if ResourceLoader.exists("res://fonts/Symbols.ttf"):
			var sym = load("res://fonts/Symbols.ttf")
			if sym != null:
				jersey_font.fallbacks = [sym]
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

	var pattern_size = 22
	var pattern_img = Image.create(pattern_size, pattern_size, false, Image.FORMAT_RGBA8)
	pattern_img.fill(Color(0, 0, 0, 0))
	var dot_color = Color(0.55, 0.70, 0.95, 0.10)
	for dx in range(3):
		for dy in range(3):
			pattern_img.set_pixel(3 + dx, 3 + dy, dot_color)
	var pattern_tex = ImageTexture.create_from_image(pattern_img)
	var pattern_rect = TextureRect.new()
	pattern_rect.texture = pattern_tex
	pattern_rect.stretch_mode = TextureRect.STRETCH_TILE
	pattern_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pattern_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pattern_rect)

	var pattern2_size = 64
	var pattern2_img = Image.create(pattern2_size, pattern2_size, false, Image.FORMAT_RGBA8)
	pattern2_img.fill(Color(0, 0, 0, 0))
	var dot2_color = Color(0.55, 0.70, 0.95, 0.045)
	for dx in range(5):
		for dy in range(5):
			pattern2_img.set_pixel(8 + dx, 8 + dy, dot2_color)
	var pattern2_tex = ImageTexture.create_from_image(pattern2_img)
	var pattern2_rect = TextureRect.new()
	pattern2_rect.texture = pattern2_tex
	pattern2_rect.stretch_mode = TextureRect.STRETCH_TILE
	pattern2_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pattern2_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pattern2_rect)

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
	header_row_ref = header_row

	var header_vbox = VBoxContainer.new()
	header_vbox.add_theme_constant_override("separation", 6)
	header_row.add_child(header_vbox)

	var primary_row = GridContainer.new()
	primary_row.columns = 8
	primary_row.add_theme_constant_override("h_separation", 6)
	primary_row.add_theme_constant_override("v_separation", 6)
	header_vbox.add_child(primary_row)
	header_grid_ref = primary_row
	add_stat_chip(primary_row, "cash", "Cash on hand. Negative cash costs 6% a day in overdraft interest, and 4 days in a row in the red is bankruptcy.", true)
	add_stat_chip(primary_row, "energy", "Energy left today. Most actions cost some; it refills to 100 each morning.", true)
	add_stat_chip(primary_row, "carry", "Bag space used today. Resets each morning. Bigger bags in the Shop.", true)
	add_stat_chip(primary_row, "storage", "Space used at home. Everything you own takes space until it sells.", true)
	add_stat_chip(primary_row, "listed", "Items listed for sale, and your seller rating (returns lower it, and a low rating slows sales).", true)
	add_stat_chip(primary_row, "level", "Level and XP. Levels give Skill Points and unlock perks.", true)
	add_stat_chip(primary_row, "day", "Day and time. Stalls pack up from late morning; the car boot shuts at 12:00. Buyers come overnight.", true)
	var end_day_button = Button.new()
	end_day_button.text = "End Day  >"
	end_day_button.tooltip_text = "Go home for the night: pay the day's costs (pitch fee & fuel, plus upkeep on upgrades) and see what sells overnight."
	style_button(end_day_button, "gold")
	end_day_button.custom_minimum_size = Vector2(0, 36)
	end_day_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	end_day_button.add_theme_font_size_override("font_size", 17)
	end_day_button.pressed.connect(end_day)
	primary_row.add_child(end_day_button)

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
	nav_panel_ref = nav_panel

	var nav = GridContainer.new()
	nav.columns = 6
	nav.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_theme_constant_override("h_separation", 5)
	nav.add_theme_constant_override("v_separation", 5)
	nav_grid_ref = nav
	nav_panel.add_child(nav)
	add_nav_button(nav, "This Stall", Callable(self, "show_stall"))
	add_nav_button(nav, "All Stalls", Callable(self, "show_stall_list"))
	add_nav_button(nav, "Inventory", Callable(self, "show_inventory_fresh"))
	add_nav_button(nav, "Sales", Callable(self, "show_sold_history"))
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
	blocked_popup_style = blocked_style
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
	build_overlays()
	call_deferred("adapt_layout")

	update_header()

func show_daily_challenges():
	if sim_mode:
		return
	if game_over and not on_title_screen:
		show_bankruptcy_screen()
		return
	current_screen_name = "show_daily_challenges"
	clear_body()
	update_header()
	var title = Label.new()
	title.add_theme_font_size_override("font_size", 24)
	title.text = "DAILY CHALLENGES"
	body.add_child(title)

	var completed = daily_challenges_completed_count()
	var bonus_panel = make_card()
	body.add_child(bonus_panel)
	var bonus_label = RichTextLabel.new()
	bonus_label.bbcode_enabled = true
	bonus_label.fit_content = true
	bonus_label.scroll_active = false
	bonus_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bonus_label.add_theme_font_size_override("normal_font_size", 17)
	if daily_challenge_bonus_given:
		bonus_label.text = "[color=#8cd98f][b]Bonus claimed today: +£40 and +30 XP![/b][/color]"
	else:
		bonus_label.text = "[color=#e8c15a][b]Complete ALL %d challenges today for an extra bonus on top: +£40 and +30 XP![/b][/color]" % daily_challenges.size()
	bonus_panel.add_child(bonus_label)

	for c in daily_challenges:
		var done = check_daily_challenge(c)
		var card = make_card()
		body.add_child(card)
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		card.add_child(row)
		var check_label = Label.new()
		check_label.text = "[DONE]" if done else "[ ]"
		check_label.add_theme_color_override("font_color", Color(0.55,0.85,0.58,1.0) if done else Color(0.50,0.55,0.62,1.0))
		row.add_child(check_label)
		var desc_label = Label.new()
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var progress_val = float(day_stats.get(c["type"], 0))
		var target_val = float(c["target"])
		desc_label.text = "%s (%d/%d) — Reward: +£%d, +%d XP" % [c["desc"], int(min(progress_val, target_val)), int(target_val), int(c["reward_cash"]), int(c["reward_xp"])]
		if done:
			desc_label.add_theme_color_override("font_color", Color(0.55,0.85,0.58,1.0))
		row.add_child(desc_label)

var level_unlock_tiers = [
	{"level": 3, "desc": "+1 Mystery Package available each day"},
	{"level": 5, "desc": "The Fixer's Gamble unlocks a bigger £350 stake"},
	{"level": 8, "desc": "Dig Deeper reveals 1 extra item each time"},
	{"level": 12, "desc": "Daily upkeep reduced by 10%"},
	{"level": 15, "desc": "The Fixer's Gamble can be used twice a day"},
]

func show_level_unlocks():
	if sim_mode:
		return
	if game_over and not on_title_screen:
		show_bankruptcy_screen()
		return
	current_screen_name = "show_level_unlocks"
	clear_body()
	update_header()
	var title = Label.new()
	title.add_theme_font_size_override("font_size", 24)
	title.text = "LEVEL UNLOCKS"
	body.add_child(title)

	var progress_panel = make_card()
	body.add_child(progress_panel)
	var progress_box = VBoxContainer.new()
	progress_box.add_theme_constant_override("separation", 4)
	progress_panel.add_child(progress_box)
	var level_label = Label.new()
	level_label.add_theme_font_size_override("font_size", 18)
	level_label.text = "Level %d" % player_level
	progress_box.add_child(level_label)
	var xp_needed = xp_needed_for_level(player_level)
	var xp_bar = ProgressBar.new()
	xp_bar.min_value = 0
	xp_bar.max_value = xp_needed
	xp_bar.value = clamp(player_xp, 0, xp_needed)
	xp_bar.show_percentage = false
	xp_bar.custom_minimum_size = Vector2(0, 20)
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.55,0.45,0.85,1.0)
	fill_style.corner_radius_top_left = 6
	fill_style.corner_radius_top_right = 6
	fill_style.corner_radius_bottom_left = 6
	fill_style.corner_radius_bottom_right = 6
	xp_bar.add_theme_stylebox_override("fill", fill_style)
	progress_box.add_child(xp_bar)
	var xp_label = Label.new()
	xp_label.add_theme_font_size_override("font_size", 16)
	xp_label.add_theme_color_override("font_color", Color(0.72,0.78,0.85,1.0))
	xp_label.text = "XP %d/%d — %d XP to Level %d" % [player_xp, xp_needed, xp_needed - player_xp, player_level + 1]
	progress_box.add_child(xp_label)

	for tier in level_unlock_tiers:
		var unlocked = player_level >= tier["level"]
		var card = make_card()
		body.add_child(card)
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		card.add_child(row)
		var status_label = Label.new()
		status_label.text = "[UNLOCKED]" if unlocked else "[LEVEL %d]" % tier["level"]
		status_label.add_theme_color_override("font_color", Color(0.55,0.85,0.58,1.0) if unlocked else Color(0.50,0.55,0.62,1.0))
		row.add_child(status_label)
		var desc_label = Label.new()
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc_label.text = tier["desc"]
		if unlocked:
			desc_label.add_theme_color_override("font_color", Color(0.55,0.85,0.58,1.0))
		row.add_child(desc_label)

func make_skill_node(s):
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.alignment = BoxContainer.ALIGNMENT_CENTER

	var unlocked = has_skill(s["name"])
	var prereq_ok = s["requires"] == "" or has_skill(s["requires"])
	var can_afford = skill_points_available() >= int(s["cost"])

	var node_color = Color(0.16,0.17,0.20,1.0)
	var border_color = Color(0.32,0.35,0.40,0.5)
	if unlocked:
		node_color = Color(0.11,0.30,0.19,1.0)
		border_color = Color(0.45,0.85,0.55,0.95)
	elif prereq_ok and can_afford:
		node_color = Color(0.32,0.25,0.09,1.0)
		border_color = Color(0.90,0.76,0.35,0.95)

	var node_button = Button.new()
	var initials = ""
	for word in s["name"].split(" "):
		initials += word[0]
	node_button.text = initials
	node_button.custom_minimum_size = Vector2(64, 64)
	var sb_normal = StyleBoxFlat.new()
	sb_normal.bg_color = node_color
	sb_normal.border_color = border_color
	sb_normal.border_width_left = 3
	sb_normal.border_width_right = 3
	sb_normal.border_width_top = 3
	sb_normal.border_width_bottom = 3
	sb_normal.corner_radius_top_left = 32
	sb_normal.corner_radius_top_right = 32
	sb_normal.corner_radius_bottom_left = 32
	sb_normal.corner_radius_bottom_right = 32
	sb_normal.shadow_color = Color(0,0,0,0.4)
	sb_normal.shadow_size = 5
	var sb_hover = sb_normal.duplicate()
	sb_hover.bg_color = node_color.lightened(0.15)
	var sb_pressed = sb_normal.duplicate()
	sb_pressed.bg_color = node_color.darkened(0.15)
	node_button.add_theme_stylebox_override("normal", sb_normal)
	node_button.add_theme_stylebox_override("hover", sb_hover)
	node_button.add_theme_stylebox_override("pressed", sb_pressed)
	node_button.add_theme_font_size_override("font_size", 18)
	node_button.tooltip_text = s["desc"]
	node_button.pressed.connect(Callable(self, "queue_popup").bind("%s: %s" % [s["name"], s["desc"]], "info"))
	col.add_child(node_button)

	var name_label = Label.new()
	name_label.text = s["name"]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size = Vector2(78, 0)
	name_label.add_theme_font_size_override("font_size", 11)
	if unlocked:
		name_label.add_theme_color_override("font_color", Color(0.55,0.85,0.58,1.0))
	col.add_child(name_label)

	if unlocked:
		var done_label = Label.new()
		done_label.text = "UNLOCKED"
		done_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		done_label.add_theme_font_size_override("font_size", 9)
		done_label.add_theme_color_override("font_color", Color(0.55,0.85,0.58,1.0))
		col.add_child(done_label)
	else:
		var buy_button = Button.new()
		var point_word = "pt" if int(s["cost"]) == 1 else "pts"
		buy_button.text = "%d %s" % [int(s["cost"]), point_word]
		buy_button.custom_minimum_size = Vector2(64, 26)
		style_button(buy_button, "buy")
		buy_button.add_theme_font_size_override("font_size", 11)
		buy_button.disabled = not can_afford or not prereq_ok
		buy_button.pressed.connect(Callable(self, "buy_skill").bind(s["name"]))
		col.add_child(buy_button)

	return col

func make_skill_connector(from_unlocked):
	var connector = ColorRect.new()
	connector.custom_minimum_size = Vector2(4, 22)
	connector.color = Color(0.45,0.85,0.55,0.9) if from_unlocked else Color(0.32,0.35,0.40,0.5)
	var wrap = CenterContainer.new()
	wrap.add_child(connector)
	return wrap

func show_skill_tree():
	if sim_mode:
		return
	if game_over and not on_title_screen:
		show_bankruptcy_screen()
		return
	current_screen_name = "show_skill_tree"
	clear_body()
	update_header()
	body.add_child(small_label("SKILL TREE", 24, Color(0.95,0.96,1.0,1.0)))
	body.add_child(small_label("Skill Points to spend: %d   (you earn 1 each time you level up — %d spent so far)" % [skill_points_available(), skill_points_spent()], 18, Color(0.78,0.60,0.98,1.0)))
	var cols = GridContainer.new()
	cols.columns = 1 if is_narrow() else 3
	cols.add_theme_constant_override("h_separation", 12)
	cols.add_theme_constant_override("v_separation", 12)
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(cols)
	for cat in ["Trading", "Appraisal", "Fortune"]:
		var col = VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 8)
		cols.add_child(col)
		col.add_child(small_label(cat.to_upper(), 20, Color(0.95,0.84,0.62,1.0)))
		for s in skill_tree:
			if s["category"] != cat:
				continue
			var unlocked = has_skill(s["name"])
			var prereq_ok = s["requires"] == "" or has_skill(s["requires"])
			var can_afford = skill_points_available() >= int(s["cost"])
			var card = make_card()
			var sb = card.get_theme_stylebox("panel").duplicate()
			if unlocked:
				sb.border_color = Color(0.45,0.85,0.55,0.95)
			elif prereq_ok and can_afford:
				sb.border_color = Color(0.95,0.78,0.35,0.95)
			else:
				sb.border_color = Color(0.32,0.35,0.40,0.6)
			card.add_theme_stylebox_override("panel", sb)
			col.add_child(card)
			var box = VBoxContainer.new()
			box.add_theme_constant_override("separation", 5)
			card.add_child(box)
			box.add_child(small_label(("★ " if unlocked else "") + s["name"], 19, Color(0.55,0.88,0.58,1.0) if unlocked else Color(0.92,0.95,1.0,1.0)))
			var d = small_label(s["desc"], 16, Color(0.78,0.83,0.90,1.0))
			d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			box.add_child(d)
			if s["requires"] != "":
				box.add_child(small_label("Needs %s first" % s["requires"], 15, Color(0.55,0.88,0.58,1.0) if has_skill(s["requires"]) else Color(0.90,0.60,0.50,1.0)))
			if unlocked:
				box.add_child(small_label("Unlocked", 16, Color(0.55,0.88,0.58,1.0)))
			else:
				var b = action_button("Unlock — %d point%s" % [int(s["cost"]), "" if int(s["cost"]) == 1 else "s"], "buy", Callable(self, "buy_skill").bind(s["name"]))
				b.disabled = not can_afford or not prereq_ok
				box.add_child(b)

var tutorial_seen = false
var tutorial_slide_index = 0
var tutorial_slides = [
	{"title": "Welcome to the car boot", "body": "You've got £300, a tote bag and a spare room. Each morning you walk the car boot sale and buy things you think are underpriced. Then you sell them online for more.\n\nSmart buys grow the business. Bad ones sink it: four days in the red and you're bankrupt."},
	{"title": "Every seller is different", "body": "A Clueless Seller prices almost at random, so bargains sit next to junk. A Dealer knows what things are worth but stocks rarer pieces. A Dodgy Seller is cheap, but fakes and faults are common.\n\nEach stall tells you who you're dealing with."},
	{"title": "Look before you buy", "body": "INSPECT: a quick glance at condition. Cheap, but it can be wrong.\nCHECK CONDITION (£5): the exact score. Better condition sells for a lot more.\nRESEARCH (£1): recent sold prices, and what they come to AFTER fees and postage.\n\nFees eat cheap stuff. Only buy when the after-fees number clearly beats the asking price. Green means worth a look, red means walk away."},
	{"title": "One offer, limited time", "body": "You get ONE haggle offer per item, and the chance they accept is shown first. Lowball too hard and they may refuse, or throw you off the stall.\n\nEverything costs time and energy (⚡). Stalls pack up from late morning and the car boot shuts at noon. You can't check everything, so pick your battles."},
	{"title": "At home: sort, price, sell", "body": "In Inventory, each item shows YOUR estimate of its worth, and it can be wrong. More checks narrow it down. Electronics must be TESTED before selling. Authenticate anything that might be fake.\n\nYou set the price and buyers arrive overnight when you End Day. Price low to sell fast, high to earn more. Faults, fakes and unchecked items can come back as returns, and that hurts your seller rating."},
	{"title": "Build it up", "body": "Spend profits in the Shop on bigger bags, more storage, repair tools, a sharper eye and lower fees. Levels earn Skill Points. Trends shift weekly, and somewhere out there are 1-in-5,000 Grail finds.\n\nGood luck. Don't go skint."},
]

func show_tutorial():
	if sim_mode:
		return
	current_screen_name = "show_tutorial"
	clear_body()
	set_chrome_visible(false)
	tutorial_slide_index = clamp(tutorial_slide_index, 0, tutorial_slides.size() - 1)
	var slide = tutorial_slides[tutorial_slide_index]
	var outer = CenterContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(outer)
	var column = VBoxContainer.new()
	column.custom_minimum_size = Vector2(cw(860), 0)
	column.add_theme_constant_override("separation", 12)
	outer.add_child(column)
	var spacer_top = Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 60)
	column.add_child(spacer_top)
	var progress_label = Label.new()
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_label.add_theme_font_size_override("font_size", 16)
	progress_label.add_theme_color_override("font_color", Color(0.62,0.68,0.76,1.0))
	progress_label.text = "%d / %d" % [tutorial_slide_index + 1, tutorial_slides.size()]
	column.add_child(progress_label)

	var panel = make_card()
	column.add_child(panel)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var title_label = Label.new()
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", 30)
	title_label.text = slide["title"]
	box.add_child(title_label)

	var body_label = Label.new()
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_label.add_theme_font_size_override("font_size", 20)
	body_label.add_theme_color_override("font_color", Color(0.80,0.85,0.90,1.0))
	body_label.text = slide["body"]
	box.add_child(body_label)

	var nav_row = HBoxContainer.new()
	nav_row.add_theme_constant_override("separation", 10)
	column.add_child(nav_row)

	var back_button = Button.new()
	back_button.text = "Back"
	back_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	style_button(back_button, "nav")
	back_button.add_theme_font_size_override("font_size", 20)
	back_button.custom_minimum_size.y = 50
	back_button.disabled = tutorial_slide_index == 0
	back_button.pressed.connect(func():
		tutorial_slide_index -= 1
		show_tutorial()
	)
	nav_row.add_child(back_button)

	var next_button = Button.new()
	var is_last = tutorial_slide_index >= tutorial_slides.size() - 1
	next_button.text = "Let's Go!" if is_last else "Next"
	next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	style_button(next_button, "buy")
	next_button.add_theme_font_size_override("font_size", 20)
	next_button.custom_minimum_size.y = 50
	next_button.pressed.connect(func():
		if is_last:
			tutorial_seen = true
			tutorial_slide_index = 0
			if on_title_screen:
				save_settings()
				show_title_screen()
			else:
				save_game()
				show_stall()
		else:
			tutorial_slide_index += 1
			show_tutorial()
	)
	nav_row.add_child(next_button)

	if not tutorial_seen:
		var skip_button = Button.new()
		skip_button.text = "Skip — I'll figure it out"
		style_button(skip_button, "nav")
		skip_button.add_theme_font_size_override("font_size", 16)
		skip_button.pressed.connect(func():
			tutorial_seen = true
			tutorial_slide_index = 0
			if on_title_screen:
				show_title_screen()
			else:
				save_game()
				show_stall()
		)
		column.add_child(skip_button)

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
	elif key == "energy":
		bg = Color(0.06,0.16,0.16,1.0)
		border = Color(0.25,0.62,0.62,0.75)
	elif key == "level":
		bg = Color(0.13,0.09,0.19,1.0)
		border = Color(0.55,0.40,0.78,0.75)
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
	sb.content_margin_left = 6 if compact else 12
	sb.content_margin_right = 6 if compact else 12
	sb.content_margin_top = 2 if compact else 5
	sb.content_margin_bottom = 2 if compact else 5
	sb.shadow_color = Color(0.0,0.0,0.0,0.35)
	sb.shadow_size = 5
	sb.shadow_offset = Vector2(0, 2)
	pill.add_theme_stylebox_override("panel", sb)
	stat_chip_styles[key] = sb
	pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pill.size_flags_stretch_ratio = 1.0
	parent.add_child(pill)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	if compact:
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.alignment = BoxContainer.ALIGNMENT_CENTER
	pill.add_child(row)
	var stat_icon_tex = null
	if key == "cash":
		stat_icon_tex = cash_icon
	elif key == "carry":
		stat_icon_tex = carry_icon
	elif key == "storage":
		stat_icon_tex = storage_icon
	elif key == "energy":
		stat_icon_tex = energy_icon
	if stat_icon_tex != null:
		var stat_icon_rect = TextureRect.new()
		stat_icon_rect.texture = stat_icon_tex
		stat_icon_rect.custom_minimum_size = Vector2(28, 28)
		stat_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		stat_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		stat_icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		row.add_child(stat_icon_rect)
	elif key == "cash" or key == "carry" or key == "storage":
		var icon_color = border
		row.add_child(make_icon(key, icon_color))
	var lbl = Label.new()
	lbl.tooltip_text = tooltip
	lbl.add_theme_font_size_override("font_size", 17 if key == "cash" else 15)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	lbl.add_theme_color_override("font_color", Color(0.92,0.95,1.0,1.0))
	row.add_child(lbl)
	stat_labels[key] = lbl

func add_nav_button(parent, text, callback):
	var b = Button.new()
	b.text = text
	b.pressed.connect(func(): last_scroll_value = 0.0; page_scroll.scroll_vertical = 0; clear_toasts())
	b.pressed.connect(callback)
	style_button(b, "nav")
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Give the longer primary destinations a little more room while keeping all six on one line.
	b.size_flags_stretch_ratio = 1.0
	b.add_theme_font_size_override("font_size", 17)
	nav_buttons[text] = b
	parent.add_child(b)

func style_button(button, kind):
	var normal = StyleBoxFlat.new()
	var hover = StyleBoxFlat.new()
	var pressed = StyleBoxFlat.new()
	var accent_border = Color(0.35,0.62,0.68,0.65)
	if kind == "buy":
		normal.bg_color = Color(0.09,0.30,0.22,1.0)
		hover.bg_color = Color(0.11,0.40,0.28,1.0)
		pressed.bg_color = Color(0.07,0.24,0.18,1.0)
		accent_border = Color(0.35,0.80,0.55,0.85)
	elif kind == "danger":
		normal.bg_color = Color(0.34,0.10,0.12,1.0)
		hover.bg_color = Color(0.46,0.13,0.16,1.0)
		pressed.bg_color = Color(0.26,0.07,0.09,1.0)
		accent_border = Color(0.85,0.40,0.38,0.85)
	elif kind == "gold":
		normal.bg_color = Color(0.36,0.27,0.07,1.0)
		hover.bg_color = Color(0.48,0.36,0.09,1.0)
		pressed.bg_color = Color(0.28,0.21,0.05,1.0)
		accent_border = Color(0.95,0.78,0.35,0.95)
	elif kind == "action":
		normal.bg_color = Color(0.10,0.20,0.35,1.0)
		hover.bg_color = Color(0.13,0.27,0.46,1.0)
		pressed.bg_color = Color(0.08,0.16,0.29,1.0)
		accent_border = Color(0.40,0.65,0.95,0.85)
	else:
		normal.bg_color = Color(0.12,0.15,0.19,1.0)
		hover.bg_color = Color(0.19,0.23,0.29,1.0)
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
		sb.border_width_top = 2
		sb.border_color = accent_border
	normal.shadow_color = Color(0.0,0.0,0.0,0.40)
	normal.shadow_size = 5
	normal.shadow_offset = Vector2(0, 3)
	hover.shadow_color = Color(0.0,0.0,0.0,0.45)
	hover.shadow_size = 6
	hover.shadow_offset = Vector2(0, 3)
	button.custom_minimum_size.y = 36
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	var disabled_sb = normal.duplicate()
	disabled_sb.bg_color = Color(0.10,0.10,0.11,0.55)
	disabled_sb.border_color = Color(0.25,0.25,0.27,0.30)
	disabled_sb.shadow_color = Color(0,0,0,0)
	button.add_theme_stylebox_override("disabled", disabled_sb)
	button.add_theme_color_override("font_disabled_color", Color(0.62,0.64,0.68,0.95))
	if not button.has_meta("click_sfx"):
		button.set_meta("click_sfx", true)
		button.pressed.connect(func(): play_sfx("click"))
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

func apply_price_highlight(item, action_key, before_max, after_max):
	item["highlight_action"] = action_key
	item["highlight_color"] = "gold" if after_max < before_max else "yellow"

func flatten_button_corner(button, side):
	for state in ["normal", "hover", "pressed"]:
		var sb = button.get_theme_stylebox(state)
		if sb != null and sb is StyleBoxFlat:
			if side == "right":
				sb.corner_radius_top_right = 0
				sb.corner_radius_bottom_right = 0
			elif side == "left":
				sb.corner_radius_top_left = 0
				sb.corner_radius_bottom_left = 0

func wrap_button_with_help(button, help_text):
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flatten_button_corner(button, "right")
	row.add_child(button)
	if help_text != "":
		var help_btn = Button.new()
		help_btn.text = "?"
		help_btn.custom_minimum_size = Vector2(36, 0)
		help_btn.size_flags_vertical = Control.SIZE_FILL
		help_btn.add_theme_font_size_override("font_size", 13)
		for state in ["normal", "hover", "pressed"]:
			var src = button.get_theme_stylebox(state)
			if src != null and src is StyleBoxFlat:
				var copy = src.duplicate()
				copy.corner_radius_top_left = 0
				copy.corner_radius_bottom_left = 0
				copy.corner_radius_top_right = 6
				copy.corner_radius_bottom_right = 6
				help_btn.add_theme_stylebox_override(state, copy)
		help_btn.pressed.connect(Callable(self, "queue_popup").bind(help_text, "info"))
		row.add_child(help_btn)
	return row

func apply_button_icon(button, icon_tex):
	if icon_tex != null:
		button.icon = icon_tex
		button.add_theme_constant_override("icon_max_width", 32)
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func get_highlight_color(item, action_key):
	if item["highlight_action"] != action_key:
		return "#b8dcff"
	if item["highlight_color"] == "gold":
		return "#d4af37"
	return "#f0d060"

func make_completed_action_box(header_text, note_bbcode_text, note_color = "#b8dcff", header_icon = null, help_text = ""):
	var panel = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.095,0.11,0.135,1.0)
	sb.border_width_left = 5
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.45,0.65,0.90,0.80)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	sb.shadow_color = Color(0.0,0.0,0.0,0.35)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 2)
	panel.add_theme_stylebox_override("panel", sb)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	var header_row = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 6)
	box.add_child(header_row)
	if header_icon != null:
		var header_icon_rect = TextureRect.new()
		header_icon_rect.texture = header_icon
		header_icon_rect.custom_minimum_size = Vector2(32, 32)
		header_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		header_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		header_icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		header_row.add_child(header_icon_rect)
	var header = Label.new()
	header.text = header_text
	header.add_theme_font_size_override("font_size", 15)
	header.add_theme_color_override("font_color", Color(0.58,0.63,0.70,1.0))
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(header)
	if help_text != "":
		var help_btn = Button.new()
		help_btn.text = "?"
		style_button(help_btn, "nav")
		help_btn.custom_minimum_size = Vector2(28, 28)
		help_btn.add_theme_font_size_override("font_size", 13)
		help_btn.pressed.connect(Callable(self, "queue_popup").bind(help_text, "info"))
		header_row.add_child(help_btn)
	if note_bbcode_text != "" and show_action_details:
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

func apply_grail_glow(panel):
	var grail_sb = StyleBoxFlat.new()
	grail_sb.bg_color = Color(0.15,0.12,0.04,1.0)
	grail_sb.border_width_left = 5
	grail_sb.border_width_top = 3
	grail_sb.border_width_right = 3
	grail_sb.border_width_bottom = 3
	grail_sb.border_color = Color(1.0,0.84,0.35,1.0)
	grail_sb.corner_radius_top_left = 10
	grail_sb.corner_radius_top_right = 10
	grail_sb.corner_radius_bottom_left = 10
	grail_sb.corner_radius_bottom_right = 10
	grail_sb.content_margin_left = 12
	grail_sb.content_margin_right = 10
	grail_sb.content_margin_top = 8
	grail_sb.content_margin_bottom = 8
	grail_sb.shadow_color = Color(1.0,0.84,0.35,0.45)
	grail_sb.shadow_size = 10
	grail_sb.shadow_offset = Vector2(0, 0)
	panel.add_theme_stylebox_override("panel", grail_sb)

func make_grail_badge():
	var badge = Label.new()
	badge.text = "GRAIL FIND"
	badge.add_theme_font_size_override("font_size", 13)
	badge.add_theme_color_override("font_color", Color(1.0,0.84,0.35,1.0))
	return badge

func make_action_details_toggle():
	var btn = Button.new()
	btn.text = "Hide Action Details" if show_action_details else "Show Action Details"
	btn.tooltip_text = "Toggles whether Condition/Research/Test/etc. results show their full detail text, or just a compact header."
	style_button(btn, "nav")
	btn.pressed.connect(func():
		show_action_details = not show_action_details
		if current_screen_name == "show_stall":
			show_stall()
		else:
			show_inventory()
	)
	return btn

func make_pricing_details_toggle():
	var btn = Button.new()
	btn.text = "Hide Pricing Details" if show_pricing_details else "Show Pricing Details"
	btn.tooltip_text = "Toggles whether the fee/postage/profit breakdown shows in full, or just the estimated profit."
	style_button(btn, "nav")
	btn.pressed.connect(func():
		show_pricing_details = not show_pricing_details
		show_inventory()
	)
	return btn

func make_category_icon_rect(category):
	if not category_icons.has(category):
		return null
	var icon_rect = TextureRect.new()
	icon_rect.texture = category_icons[category]
	icon_rect.custom_minimum_size = Vector2(22, 22)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return icon_rect

func make_card():
	var panel = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.075,0.090,0.118,1.0)
	sb.border_width_left = 5
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.35,0.55,0.85,0.85)
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
	sb.content_margin_left = 12
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	sb.shadow_color = Color(0.0,0.0,0.0,0.40)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 3)
	panel.add_theme_stylebox_override("panel", sb)
	return panel

func clear_body():
	for c in body.get_children():
		body.remove_child(c)
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
	var roll = rng.randf()
	var win_chance = 0.49 if has_skill("Lucky Streak") else 0.46
	var won = roll < win_chance
	record_rng("Fixer's Gamble: Wager £%.0f | Chance %.0f%% | Rolled: %.2f%% | Result: %s" % [amount, win_chance * 100.0, roll * 100.0, "WON" if won else "LOST"])
	if won:
		cash += amount * 2.0
		day_stats["other_income"] = float(day_stats.get("other_income", 0.0)) + amount * 2.0
		lifetime_fixer_wins += 1
		add_toast("The Fixer's Gamble — WON! £%.0f -> £%.0f" % [amount, amount * 2.0], "success")
		play_sfx("rare")
		unlock_check_high_roller()
	else:
		add_toast("The Fixer's Gamble — lost £%.0f." % amount, "error")
		play_sfx("fail")
	save_game()
	show_stall_list()

const SAVE_VERSION = 2

func get_save_data():
	return {
		"save_version": SAVE_VERSION,
		"game_version": GAME_VERSION,
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
		"current_week": current_week,
		"pending_special_offer": pending_special_offer,
		"day_stats": day_stats,
		"category_knowledge": category_knowledge,
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
		"package_insight_level": package_insight_level,
		"persuasion_level": persuasion_level,
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
		"save_time": Time.get_datetime_string_from_system(false, true),
	}

func manual_save():
	save_game()
	queue_popup("Game Saved!", "success")
	show_more_menu()

func save_game():
	if sim_mode:
		return
	var data = get_save_data()
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
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
	cash = float(parsed.get("cash", cash))
	day = int(parsed.get("day", day))
	player_level = int(parsed.get("player_level", player_level))
	player_xp = int(parsed.get("player_xp", player_xp))
	inventory = parsed.get("inventory", inventory)
	bag_level = int(parsed.get("bag_level", bag_level))
	storage_level = int(parsed.get("storage_level", storage_level))
	toolbox_level = int(parsed.get("toolbox_level", toolbox_level))
	eye_level = int(parsed.get("eye_level", eye_level))
	fee_level = int(parsed.get("fee_level", fee_level))
	package_insight_level = int(parsed.get("package_insight_level", package_insight_level))
	persuasion_level = int(parsed.get("persuasion_level", persuasion_level))
	achievements = parsed.get("achievements", achievements)
	discovered_log = parsed.get("discovered_log", discovered_log)
	family_stats = parsed.get("family_stats", family_stats)
	sold_history = parsed.get("sold_history", sold_history)
	total_haggled_savings = float(parsed.get("total_haggled_savings", total_haggled_savings))
	total_lifetime_profit = float(parsed.get("total_lifetime_profit", total_lifetime_profit))
	lifetime_challenges_completed = int(parsed.get("lifetime_challenges_completed", lifetime_challenges_completed))
	lifetime_fixer_wins = int(parsed.get("lifetime_fixer_wins", lifetime_fixer_wins))
	skills_unlocked = parsed.get("skills_unlocked", skills_unlocked)
	tutorial_seen = to_bool(parsed.get("tutorial_seen", tutorial_seen))
	negative_days_streak = int(parsed.get("negative_days_streak", negative_days_streak))
	last_save_time = str(parsed.get("save_time", ""))
	for i in range(inventory.size()):
		inventory[i] = normalize_item(inventory[i])
	# Full mid-day state (save_version 2+). Older saves fall back to a fresh day.
	var restored_day = false
	if int(parsed.get("save_version", 1)) >= 2 and typeof(parsed.get("stalls", null)) == TYPE_ARRAY and parsed["stalls"].size() > 0:
		energy = int(parsed.get("energy", 100))
		current_time_minutes = int(parsed.get("current_time_minutes", 7 * 60))
		daily_expenses = float(parsed.get("daily_expenses", daily_expenses))
		stalls = parsed["stalls"]
		for stall in stalls:
			stall["revealed"] = int(stall.get("revealed", 0))
			stall["packing_minute"] = int(stall.get("packing_minute", 12 * 60))
			var stock = stall.get("stock", [])
			for j in range(stock.size()):
				stock[j] = normalize_item(stock[j])
			stall["stock"] = stock
		current_stall_index = clamp(int(parsed.get("current_stall_index", 0)), 0, stalls.size() - 1)
		carry_used = int(parsed.get("carry_used", 0))
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
		restored_day = true
	var trends = parsed.get("current_trends", null)
	if typeof(trends) == TYPE_DICTIONARY and trends.size() > 0:
		current_trends = trends
		trend_random = parsed.get("trend_random", trends.duplicate())
		trend_rumour = parsed.get("trend_rumour", {})
		trend_headlines = parsed.get("trend_headlines", [])
		current_week = int(parsed.get("current_week", current_week))
	else:
		generate_weekly_trends()
	var ck = parsed.get("category_knowledge", null)
	if typeof(ck) == TYPE_DICTIONARY:
		for k in ck.keys():
			category_knowledge[k] = int(ck[k])
	game_over = to_bool(parsed.get("game_over", false))
	seller_rating = float(parsed.get("seller_rating", 100.0))
	rng_log = parsed.get("rng_log", [])
	activity_log = parsed.get("activity_log", [])
	best_net_worth = float(parsed.get("best_net_worth", 0.0))
	goals_done = int(parsed.get("goals_done", 0))
	if not restored_day:
		energy = 100
		current_time_minutes = 7 * 60
		pending_special_offer = null
		reset_day_stats()
		generate_day()
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
		"special_premium": 1.0, "channel": "",
	}

func normalize_item(item):
	if typeof(item) != TYPE_DICTIONARY:
		return item_template()
	var tpl = item_template()
	for k in tpl.keys():
		if not item.has(k):
			item[k] = tpl[k]
	# JSON round-trips ints as floats; keep the fields used as ints tidy.
	for k in ["condition", "one_in", "auction_days_left", "instant_roll_day", "days_owned", "listed_day"]:
		item[k] = int(item[k])
	if not item.has("est_noise_set"):
		item["est_noise"] = rng.randfn(0.0, 1.0)
		item["est_noise_set"] = true
	return item

func load_game():
	if sim_mode:
		return false
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
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
	for c in daily_challenges:
		if not c["reward_given"] and check_daily_challenge(c):
			c["reward_given"] = true
			cash += float(c["reward_cash"])
			day_stats["other_income"] = float(day_stats.get("other_income", 0.0)) + float(c["reward_cash"])
			add_xp(int(c["reward_xp"]))
			lifetime_challenges_completed += 1
			queue_popup("Challenge complete: %s — +£%d, +%d XP" % [c["desc"], c["reward_cash"], c["reward_xp"]], "success")

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

var skills_unlocked = {}
var skill_tree = [
	{"category": "Trading", "name": "Sharp Tongue", "cost": 1, "desc": "+8% haggle success chance", "requires": ""},
	{"category": "Trading", "name": "Bulk Buyer", "cost": 1, "desc": "+1 Carry slot", "requires": ""},
	{"category": "Trading", "name": "Silver Tongue", "cost": 2, "desc": "An additional +10% haggle success chance (stacks with Sharp Tongue)", "requires": "Sharp Tongue"},
	{"category": "Appraisal", "name": "Keen Eye", "cost": 1, "desc": "+10% Inspect accuracy", "requires": ""},
	{"category": "Appraisal", "name": "Efficient Research", "cost": 1, "desc": "Condition and Research cost 20% less", "requires": ""},
	{"category": "Appraisal", "name": "Deep Pockets", "cost": 2, "desc": "+25% Deep Research rare-variant odds", "requires": "Efficient Research"},
	{"category": "Fortune", "name": "Lucky Streak", "cost": 1, "desc": "Fixer's Gamble win chance 46% -> 49%", "requires": ""},
	{"category": "Fortune", "name": "Frugal Living", "cost": 1, "desc": "-15% daily upkeep", "requires": ""},
	{"category": "Fortune", "name": "Golden Touch", "cost": 2, "desc": "+8% XP from all sources", "requires": "Frugal Living"},
]

func effective_bag_capacity():
	return int(bag_upgrades[bag_level]["capacity"]) + (1 if has_skill("Bulk Buyer") else 0)

func effective_look_accuracy():
	var acc = float(eye_upgrades[eye_level]["accuracy"])
	if has_skill("Keen Eye"):
		acc = min(0.97, acc + 0.10)
	return acc

func condition_cost():
	return 4.0 if has_skill("Efficient Research") else 5.0

func research_cost():
	return 0.8 if has_skill("Efficient Research") else 1.0

func has_skill(name):
	return skills_unlocked.has(name)

func skill_points_spent():
	var total = 0
	for s in skill_tree:
		if has_skill(s["name"]):
			total += int(s["cost"])
	return total

func skill_points_available():
	return max(0, (player_level - 1) - skill_points_spent())

func buy_skill(name):
	for s in skill_tree:
		if s["name"] != name:
			continue
		if has_skill(name):
			queue_popup("Already unlocked.")
			return
		if s["requires"] != "" and not has_skill(s["requires"]):
			queue_popup("Requires %s first." % s["requires"])
			return
		if skill_points_available() < int(s["cost"]):
			queue_popup("Not enough skill points.")
			return
		skills_unlocked[name] = true
		queue_popup("Skill unlocked: %s!" % name, "success")
		save_game()
		show_skill_tree()
		return

func xp_needed_for_level(level):
	return int(80 + (level - 1) * 40)

func add_xp(amount):
	var boosted_amount = amount
	if has_skill("Golden Touch"):
		boosted_amount = int(round(float(amount) * 1.08))
	player_xp += boosted_amount
	while player_xp >= xp_needed_for_level(player_level):
		player_xp -= xp_needed_for_level(player_level)
		player_level += 1
		var unlock_text = ""
		for tier in level_unlock_tiers:
			if int(tier["level"]) == player_level:
				unlock_text = "\nUnlocked: " + tier["desc"]
		show_big_popup("LEVEL %d" % player_level, "You earned a Skill Point — spend it in More > Skill Tree.%s" % unlock_text, "level")

func set_status(text, color = null):
	if status_label != null:
		status_label.text = str(text)
	var kind = "info"
	if color != null and typeof(color) == TYPE_COLOR:
		if color.g > color.r + 0.15:
			kind = "success"
		elif color.r > color.g + 0.2:
			kind = "error"
	add_toast(str(text), kind)

var popup_queue = []

func queue_popup(text, kind = "error"):
	add_toast(str(text), kind)
	if kind == "error":
		play_sfx("error")

func _advance_popup_queue():
	if popup_queue.size() == 0:
		return
	var next_popup = popup_queue.pop_front()
	show_blocked_popup(next_popup["text"], next_popup["kind"])

func show_blocked_popup(text, kind = "error"):
	if sim_mode:
		return
	if game_over and not on_title_screen:
		show_bankruptcy_screen()
		return
	if blocked_popup == null:
		return
	if blocked_popup_style != null:
		if kind == "success":
			blocked_popup_style.bg_color = Color(0.05,0.14,0.07,0.97)
			blocked_popup_style.border_color = Color(0.35,0.72,0.40,1.0)
		elif kind == "info":
			blocked_popup_style.bg_color = Color(0.06,0.09,0.15,0.97)
			blocked_popup_style.border_color = Color(0.35,0.55,0.80,1.0)
		else:
			blocked_popup_style.bg_color = Color(0.16,0.05,0.05,0.97)
			blocked_popup_style.border_color = Color(0.75,0.35,0.32,1.0)
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
	if popup_queue.size() > 0:
		_advance_popup_queue()

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
	check_daily_challenge_rewards()
	check_daily_challenge_bonus()
	check_milestone_achievements()
	check_goals()
	if sim_mode:
		return
	if not on_title_screen:
		set_chrome_visible(not game_over)
		save_game()
	flash_cash_if_changed()
	var listed_count = 0
	for item in inventory:
		if item["listed"] or item["auctioned"]:
			listed_count += 1
	var bag = bag_upgrades[bag_level]
	var storage = storage_upgrades[storage_level]
	stat_labels["day"].text = "Day %d  %s" % [day, format_time()]
	var tab_for = {"show_stall":"This Stall", "show_special_offer":"This Stall", "show_stall_list":"All Stalls", "show_inventory":"Inventory", "show_sold_history":"Sales", "show_shop":"Shop"}
	var more_screens = ["show_more_menu", "show_skill_tree", "show_daily_challenges", "show_level_unlocks", "show_trends", "show_collection_log", "show_achievements", "show_log_screen", "show_settings_screen", "show_patch_notes", "show_confirm_new_game"]
	var active_tab = tab_for.get(current_screen_name, "More" if current_screen_name in more_screens else "")
	for k in nav_buttons.keys():
		var nb = nav_buttons[k]
		if is_instance_valid(nb):
			nb.add_theme_color_override("font_color", Color(1.0,0.85,0.40,1.0) if k == active_tab else Color(0.85,0.88,0.92,1.0))
			nb.add_theme_color_override("font_hover_color", Color(1.0,0.90,0.55,1.0))
	stat_labels["cash"].text = "£%.2f" % cash
	if cash < 0.0:
		stat_labels["cash"].add_theme_color_override("font_color", Color(0.95,0.55,0.45,1.0))
		if stat_chip_styles.has("cash"):
			stat_chip_styles["cash"].bg_color = Color(0.20,0.07,0.08,1.0)
			stat_chip_styles["cash"].border_color = Color(0.75,0.32,0.30,1.0)
	else:
		stat_labels["cash"].add_theme_color_override("font_color", Color(0.92,0.95,1.0,1.0))
		if stat_chip_styles.has("cash"):
			stat_chip_styles["cash"].bg_color = Color(0.07,0.16,0.11,1.0)
			stat_chip_styles["cash"].border_color = Color(0.20,0.55,0.32,1.0)
	stat_labels["energy"].text = "%d/100" % energy
	if energy <= 15:
		stat_labels["energy"].add_theme_color_override("font_color", Color(0.95,0.55,0.45,1.0))
	elif energy <= 35:
		stat_labels["energy"].add_theme_color_override("font_color", Color(0.90,0.78,0.45,1.0))
	else:
		stat_labels["energy"].add_theme_color_override("font_color", Color(0.92,0.95,1.0,1.0))
	stat_labels["level"].text = "Lv %d  •  %d/%d XP" % [player_level, player_xp, xp_needed_for_level(player_level)]
	stat_labels["carry"].text = "Bag %d/%d" % [carry_used, effective_bag_capacity()]
	stat_labels["storage"].text = "Storage %d/%d" % [inventory_space_used(), storage["capacity"]]
	stat_labels["listed"].text = "For sale %d  •  ★ %.0f%%" % [listed_count, seller_rating]
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
		"start_worth": cash + inventory_book_value(),
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
		"refunds": 0.0,
		"other_income": 0.0,
		"items_bought": 0,
		"items_sold": 0,
		"items_scrapped": 0,
		"returns": 0,
		"collection_adds": 0,
		"rarest_one_in": 1,
		"condition_checks": 0,
		"researches_done": 0,
		"deep_researches_done": 0,
		"authentications_done": 0,
		"repairs_done": 0,
		"profitable_sales": 0,
		"successful_haggles": 0,
		"rng_events": []
	}

func upkeep_per_tier():
	var u = 1.75
	if player_level >= 12:
		u *= 0.9
	if has_skill("Frugal Living"):
		u *= 0.85
	return u

func compute_upkeep():
	var tier_sum = bag_level + storage_level + toolbox_level + eye_level + fee_level
	var upkeep = float(tier_sum) * 1.75
	if player_level >= 12:
		upkeep *= 0.9
	if has_skill("Frugal Living"):
		upkeep *= 0.85
	return upkeep

var trend_random = {}
var trend_rumour = {}

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
	var categories = category_knowledge.keys()
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
	if rng.randf() < 0.5:
		var shock = categories[rng.randi_range(0, categories.size() - 1)]
		trend_random[shock] = clamp(float(trend_random[shock]) * (rng.randf_range(1.08, 1.16) if rng.randf() < 0.5 else rng.randf_range(0.86, 0.93)), 0.70, 1.35)
	for category in categories:
		current_trends[category] = clamp(float(trend_random[category]) * season_factor(category, season), 0.70, 1.40)
	var sorted = categories.duplicate()
	sorted.sort_custom(func(a, b): return float(current_trends[a]) > float(current_trends[b]))
	trend_headlines.append("%s is attracting the most buyers this week." % sorted[0])
	trend_headlines.append("%s demand looks softest right now." % sorted[sorted.size() - 1])
	var rumour_cat = categories[rng.randi_range(0, categories.size() - 1)]
	var rumour_dir = "up" if rng.randf() < 0.55 else "down"
	trend_rumour = {"cat": rumour_cat, "dir": rumour_dir, "true": rng.randf() < 0.70}
	trend_headlines.append("Word round the burger van: %s prices could %s next week. (Rumours are right about 70%% of the time.)" % [rumour_cat, "jump" if rumour_dir == "up" else "slump"])

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
	generate_daily_challenges()
	mystery_packages_left = rng.randi_range(0, 2) + (1 if player_level >= 3 else 0)
	daily_expenses = min(15.0, 6.50 + float(day - 1) * 0.12)
	var seller_names = seller_profiles.keys()
	var count = rng.randi_range(6, 8)
	var used_names_today = {}
	for i in range(count):
		var seller = seller_names[rng.randi_range(0, seller_names.size() - 1)]
		var profile = seller_profiles[seller]
		var stall = {
			"seller": seller,
			"seller_display_name": pick_unique_seller_name(seller, used_names_today),
			"stock": [],
			"revealed": 0,
			"packing_minute": rng.randi_range(10 * 60 + 45, 12 * 60),
			"crowd": rng.randf_range(0.10, 0.45),
			"banned_today": false
		}
		var stock_count = rng.randi_range(max(6, int(profile["depth"] * 0.65)), profile["depth"])
		var seen_names = {}
		for j in range(stock_count):
			var it = generate_item(seller)
			var tries = 0
			while seen_names.has(it["name"]) and tries < 4:
				it = generate_item(seller)
				tries += 1
			seen_names[it["name"]] = true
			stall["stock"].append(it)
		stall["revealed"] = min(rng.randi_range(5, 7), stock_count)
		stalls.append(stall)
	current_stall_index = 0

func generate_item(seller):
	var profile = seller_profiles[seller]
	var current_season = get_season_name()
	var candidates = []
	for family in item_families:
		if family["category"] in profile["categories"]:
			if family.has("season") and family["season"] != current_season:
				continue
			candidates.append(family)
	if candidates.size() == 0:
		candidates = []
		for family in item_families:
			if not family.has("season") or family["season"] == current_season:
				candidates.append(family)
	if candidates.size() == 0:
		candidates = item_families
	var base = candidates[rng.randi_range(0, candidates.size() - 1)].duplicate(true)

	var rarity_boost = float(profile.get("rarity_boost", 1.0))
	var rarity_weights = []
	for i in range(rarity_table.size()):
		var w = float(rarity_table[i]["chance"])
		if i > 0:
			w *= rarity_boost
		rarity_weights.append(w)
	var total_weight = 0.0
	for w in rarity_weights:
		total_weight += w
	var rarity_roll = rng.randf() * total_weight
	var rarity = rarity_table[0]
	var cumulative = 0.0
	for i in range(rarity_table.size()):
		cumulative += rarity_weights[i]
		if rarity_roll <= cumulative:
			rarity = rarity_table[i]
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
	var special_premium = 1.0
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
				special_premium = rng.randf_range(1.5, 4.5)
				true_value *= special_premium

	var random_ask = rng.randf_range(base["ask"][0], base["ask"][1])
	var marketish = true_value * float(profile["pricing"]) * rng.randf_range(0.55, 1.35)
	var asking = lerp(random_ask, marketish, float(profile["knowledge"]))
	asking = max(1.0, round(asking))

	return normalize_item({
		"special_premium": special_premium,
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
		"auctioned": false,
		"auction_days_left": 0,
		"auction_current_bid": 0.0,
		"auction_final_price": 0.0,
		"auction_tier": "",
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
		"highlight_action": "",
		"highlight_color": "yellow",
		"basic_comps_max": 0.0,
		"locked_gamble_hint": 0.10,
		"dismissed": false
	})

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

func vw():
	if is_inside_tree():
		return get_viewport_rect().size.x
	return 1600.0

func cw(px):
	# Clamp a desired minimum width to what actually fits on screen (phones!).
	return min(float(px), max(160.0, vw() - 64.0))

func is_narrow():
	return vw() < 900.0

func small_label(text, size = 15, color = Color(0.62,0.68,0.76,1.0)):
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func rich_line(text, size = 15, color = Color(0.72,0.88,1.0,1.0)):
	var r = RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.add_theme_color_override("default_color", color)
	r.text = text
	return r

func action_button(text, kind, callback, tooltip = "", icon_tex = null, min_w = 0):
	var b = Button.new()
	b.text = text
	style_button(b, kind)
	b.add_theme_font_size_override("font_size", 16)
	b.custom_minimum_size = Vector2(min_w, 40)
	b.tooltip_text = tooltip
	if icon_tex != null:
		b.icon = icon_tex
		b.add_theme_constant_override("icon_max_width", 24)
		b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if callback != null:
		b.pressed.connect(callback)
	return b

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

func style_item_card(panel, item):
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.075,0.090,0.118,1.0)
	sb.border_width_left = 5
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.30,0.45,0.70,0.8)
	if item["rarity"] != "Common":
		sb.border_color = rarity_color(item["rarity"])
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 14
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	sb.shadow_color = Color(0,0,0,0.4)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 3)
	if item["rarity"] == "Grail":
		sb.bg_color = Color(0.15,0.12,0.04,1.0)
		sb.shadow_color = Color(1.0,0.84,0.35,0.45)
		sb.shadow_size = 12
		sb.shadow_offset = Vector2.ZERO
	panel.add_theme_stylebox_override("panel", sb)

func show_stall():
	if sim_mode:
		return
	if game_over and not on_title_screen:
		show_bankruptcy_screen()
		return
	on_title_screen = false
	set_chrome_visible(true)
	current_screen_name = "show_stall"
	if page_scroll != null:
		last_scroll_value = page_scroll.scroll_vertical
		call_deferred("_restore_scroll", page_scroll)
	clear_body()
	update_header()
	if game_over:
		show_bankruptcy_screen()
		return
	if pending_special_offer != null:
		show_special_offer()
		return
	if current_time_minutes >= 12 * 60:
		var card = make_card()
		body.add_child(card)
		var box = VBoxContainer.new()
		box.add_theme_constant_override("separation", 10)
		card.add_child(box)
		box.add_child(small_label("The car boot's packing up for the day.", 24, Color(0.95,0.84,0.62,1.0)))
		var hint = small_label("Head home: test, research and list what you bought in Inventory, then End Day to see what sells overnight.", 17, Color(0.78,0.83,0.90,1.0))
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(hint)
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		box.add_child(row)
		row.add_child(action_button("Go to Inventory", "action", show_inventory_fresh, "", null, 220))
		row.add_child(action_button("End Day", "danger", end_day, "", null, 160))
		return

	var stall = stalls[current_stall_index]
	var seller = stall["seller"]
	var seller_display = stall["seller_display_name"]
	var closed = current_time_minutes >= int(stall["packing_minute"]) or to_bool(stall.get("banned_today", false))

	# --- stall header
	var head = make_card()
	body.add_child(head)
	var head_box = VBoxContainer.new()
	head_box.add_theme_constant_override("separation", 6)
	head.add_child(head_box)
	var title_row = HFlowContainer.new()
	title_row.add_theme_constant_override("h_separation", 10)
	title_row.add_theme_constant_override("v_separation", 6)
	head_box.add_child(title_row)
	var st_title = small_label("Stall %d/%d — %s" % [current_stall_index + 1, stalls.size(), seller_display], 24, Color(0.95,0.96,1.0,1.0))
	title_row.add_child(st_title)
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(spacer)
	if not closed:
		var dig_left = stall["stock"].size() - int(stall["revealed"])
		var dig = action_button("Dig Deeper  •  ⚡4, 8 min" if dig_left > 0 else "Nothing left to dig", "action", browse_stall, "Rummage through the boxes under the table to reveal a few more items. Takes time — rivals may grab things meanwhile.")
		dig.disabled = dig_left <= 0
		title_row.add_child(dig)
		if mystery_packages_left > 0:
			var package_button = action_button("Mystery Package £30 (%d left)" % mystery_packages_left, "nav", buy_mystery_package, "")
			package_button.disabled = cash < 30.0
			var odds_lines = []
			var budget_ranges = {"Poor":"£5-20", "Average":"£18-35", "Good":"£35-60", "Excellent":"£60-120", "Jackpot":"£150-400", "Grail":"£500-900"}
			for row in get_package_chances():
				odds_lines.append("%s %.1f%% (%s)" % [row["tier"], row["chance"] * 100.0, budget_ranges.get(row["tier"], "")])
			package_button.tooltip_text = "A sealed box for £30: 1-2 items (30% chance of 2). On average it's worth LESS than you pay — it's a gamble.\n" + "\n".join(odds_lines)
			title_row.add_child(package_button)
	title_row.add_child(action_button(("Next Stall  >  5 min" if current_stall_index < stalls.size() - 1 else "Back to Stall 1  >  5 min"), "nav", next_stall, "Walk to the next stall. Costs 5 minutes."))

	var blurb = rich_line("[color=#e8c15a]%s[/color] — %s" % [seller, seller_blurbs.get(seller, "")], 16, Color(0.78,0.83,0.90,1.0))
	head_box.add_child(blurb)
	var info_text = "Seen %d of %d items  •  Crowd %d%% (busier = rivals grab more while you dig)  •  Packs up %s  •  Bag %d/%d  •  Tonight's costs £%.2f" % [stall["revealed"], stall["stock"].size(), int(float(stall["crowd"]) * 100.0), minute_to_clock(stall["packing_minute"]), carry_used, effective_bag_capacity(), daily_expenses + compute_upkeep()]
	if special_event_profiles.has(seller):
		info_text += "  •  [color=#e8c15a]~%.1f%% side-deal chance per purchase[/color]" % (float(seller_profiles[seller]["side"]) * 100.0)
	head_box.add_child(rich_line(info_text, 15, Color(0.62,0.68,0.76,1.0)))
	head_box.add_child(rich_line("[color=#e8c15a]>[/color] %s" % current_goal_text(), 15, Color(0.90,0.80,0.55,1.0)))

	if closed:
		var msg = "You've been kicked off %s's stall for the rest of the day." % seller_display if to_bool(stall.get("banned_today", false)) else "%s has packed up and gone home." % seller_display
		head_box.add_child(small_label(msg, 18, Color(0.95,0.60,0.50,1.0)))
		head_box.add_child(action_button("See which stalls are still open", "action", show_stall_list))
		return

	var shown = 0
	for i in range(stall["revealed"]):
		var item = stall["stock"][i]
		if item["dismissed"]:
			continue
		shown += 1
		var card_node = build_stall_item_card(item, i, seller)
		if i >= int(stall.get("new_from", 999)):
			var badge = small_label("NEW", 14, Color(0.10,0.10,0.10,1.0))
			var bsb = StyleBoxFlat.new()
			bsb.bg_color = Color(0.95,0.78,0.35,1.0)
			bsb.set_corner_radius_all(4)
			bsb.content_margin_left = 6
			bsb.content_margin_right = 6
			badge.add_theme_stylebox_override("normal", bsb)
			var top_row = card_node.get_child(0).get_child(0)
			top_row.add_child(badge)
			top_row.move_child(badge, 0)
		body.add_child(card_node)
	if shown == 0:
		body.add_child(small_label("Nothing on the table interests you. Dig deeper or move on.", 17))
	if first_day_hint_needed():
		body.add_child(make_hint_card())
	var bottom_pad = Control.new()
	bottom_pad.custom_minimum_size = Vector2(0, 140)
	body.add_child(bottom_pad)

func first_day_hint_needed():
	return day <= 2 and inventory.size() == 0 and sold_history.size() == 0

func make_hint_card():
	var card = make_card()
	var t = rich_line("[color=#e8c15a][b]First morning tip:[/b][/color] Asking prices mean nothing on their own. [b]Research[/b] (£1) shows what this item recently sold for — and what that works out to [i]after[/i] fees and postage. Only buy when there's a real gap. Cheap stuff rarely covers postage.", 16, Color(0.85,0.88,0.92,1.0))
	card.add_child(t)
	return card

func build_stall_item_card(item, i, seller):
	var panel = PanelContainer.new()
	style_item_card(panel, item)
	var card = VBoxContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_constant_override("separation", 6)
	panel.add_child(card)

	# --- line 1: rarity, name, price, dismiss
	var top = HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	card.add_child(top)
	var cat_icon_rect = make_category_icon_rect(item["category"])
	if cat_icon_rect != null:
		top.add_child(cat_icon_rect)
	if item["rarity"] != "Common":
		var rl = small_label("%s 1/%d" % [item["rarity"].to_upper(), int(item["one_in"])], 16, rarity_color(item["rarity"]))
		rl.tooltip_text = "Rarity: roughly 1 in %d items you'll see is a find like this. Rarer versions are worth more — and fill your Collection Log." % int(item["one_in"])
		rl.mouse_filter = Control.MOUSE_FILTER_PASS
		top.add_child(rl)
	var name_l = small_label(item["name"], 22, Color(0.95,0.96,1.0,1.0))
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top.add_child(name_l)
	var buy_button = Button.new()
	style_button(buy_button, "buy")
	buy_button.add_theme_font_size_override("font_size", 22)
	buy_button.custom_minimum_size = Vector2(190, 44)
	if item["haggle_result"] == "refused":
		buy_button.text = "Won't sell to you"
		buy_button.disabled = true
	else:
		buy_button.text = "BUY  £%.0f" % float(item["asking"])
		buy_button.tooltip_text = "Pay the asking price. Anything you haven't checked is a gamble."
		buy_button.pressed.connect(Callable(self, "buy_item").bind(i))
		if float(item["asking"]) > cash:
			buy_button.disabled = true
			buy_button.text = "£%.0f — can't afford" % float(item["asking"])
	top.add_child(buy_button)
	var dismiss_button = Button.new()
	dismiss_button.text = "×"
	dismiss_button.tooltip_text = "Not interested — hide it. Free."
	style_button(dismiss_button, "nav")
	dismiss_button.custom_minimum_size = Vector2(44, 44)
	dismiss_button.add_theme_font_size_override("font_size", 22)
	dismiss_button.pressed.connect(Callable(self, "dismiss_stall_item").bind(i))
	top.add_child(dismiss_button)

	# --- line 2: facts
	var condition_text = "[color=#e88c7a]Unknown[/color]"
	if item["condition_checked"]:
		condition_text = "[b]%d/10[/b]" % int(item["condition"])
	var func_text = "N/A"
	if item["testable"]:
		func_text = "Untested (electronic)"
	var trend_mult = float(current_trends.get(item["category"], 1.0))
	var trend_text = ""
	if trend_mult >= 1.10:
		trend_text = "  •  [color=#b088e8][b]TRENDING +%d%%[/b][/color]" % int(round((trend_mult - 1.0) * 100.0))
	elif trend_mult <= 0.90:
		trend_text = "  •  [color=#e88c7a]Weak demand %d%%[/color]" % int(round((trend_mult - 1.0) * 100.0))
	var fake_text = ""
	if float(item["fake_chance"]) >= 0.05:
		fake_text = "  •  Fake risk: [color=#e8c15a]%s[/color]" % fake_risk_label(float(item["fake_chance"]))
	card.add_child(rich_line("%s  •  %s  •  Condition %s  •  Function: %s%s%s" % [item["category"], size_text(item), condition_text, func_text, fake_text, trend_text], 15, Color(0.66,0.72,0.80,1.0)))

	# --- actions
	var actions = HFlowContainer.new()
	actions.add_theme_constant_override("h_separation", 6)
	actions.add_theme_constant_override("v_separation", 6)
	card.add_child(actions)
	var insp = action_button("Inspect (%d%% reliable)  •  ⚡1, 1m" % int(effective_look_accuracy() * 100.0) if not item["quick_look_done"] else "Inspected", "nav", Callable(self, "quick_look").bind(i), "A quick glance at condition. Cheap, but only %d%% reliable, and you won't know if it was right until you check properly. It never gives the exact score." % int(effective_look_accuracy() * 100.0), inspect_icon, 190)
	insp.disabled = item["quick_look_done"] or energy < 1
	actions.add_child(insp)
	var cc = action_button("Check Condition £%d  •  ⚡4, 5m" % int(condition_cost()) if not item["condition_checked"] else "Condition %d/10" % int(item["condition"]), "action", Callable(self, "check_condition").bind(i), "Reveals the exact Condition score — and hidden flaws on non-electronic items. Better condition sells for much more.", condition_icon, 250)
	cc.disabled = item["condition_checked"] or cash < condition_cost() or energy < 4
	actions.add_child(cc)
	var rb = action_button("Research £%.2f  •  ⚡2, 4m" % research_cost() if not item["basic_researched"] else "Researched", "action", Callable(self, "prebuy_research").bind(i), "Shows five recent sold prices for this kind of item, and what the middle one works out to after fees. Evidence, not a guarantee.", research_icon, 210)
	rb.disabled = item["basic_researched"] or cash < research_cost() or energy < 2
	actions.add_child(rb)

	var sep = Control.new()
	sep.custom_minimum_size = Vector2(12, 0)
	actions.add_child(sep)

	if not item["haggle_attempted"]:
		var haggle_cluster = HBoxContainer.new()
		haggle_cluster.add_theme_constant_override("separation", 4)
		var haggle_asking = max(1.0, float(item["asking"]))
		var haggle_initial = max(1.0, round(haggle_asking * 0.85))
		haggle_cluster.add_child(small_label("£", 16, Color(0.85,0.90,0.96,1.0)))
		var haggle_minus = Button.new()
		haggle_minus.text = "-"
		style_button(haggle_minus, "nav")
		haggle_minus.custom_minimum_size = Vector2(36, 40)
		haggle_cluster.add_child(haggle_minus)
		var haggle_value_edit = LineEdit.new()
		haggle_value_edit.text = str(int(haggle_initial))
		haggle_value_edit.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
		haggle_value_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
		haggle_value_edit.custom_minimum_size = Vector2(70, 40)
		haggle_value_edit.add_theme_font_size_override("font_size", 18)
		haggle_cluster.add_child(haggle_value_edit)
		var haggle_plus = Button.new()
		haggle_plus.text = "+"
		style_button(haggle_plus, "nav")
		haggle_plus.custom_minimum_size = Vector2(36, 40)
		haggle_cluster.add_child(haggle_plus)
		var haggle_chance_label = small_label("%.0f%% accept" % (compute_haggle_chance(item, seller, haggle_initial) * 100.0), 16, Color(0.88,0.62,0.85,1.0))
		haggle_chance_label.custom_minimum_size = Vector2(90, 0)
		haggle_chance_label.tooltip_text = "Chance the seller accepts this offer."
		haggle_chance_label.mouse_filter = Control.MOUSE_FILTER_PASS
		haggle_cluster.add_child(haggle_chance_label)
		haggle_minus.pressed.connect(Callable(self, "_adjust_haggle_value").bind(haggle_value_edit, -1.0, haggle_asking, haggle_chance_label, item, seller))
		haggle_plus.pressed.connect(Callable(self, "_adjust_haggle_value").bind(haggle_value_edit, 1.0, haggle_asking, haggle_chance_label, item, seller))
		haggle_value_edit.text_submitted.connect(Callable(self, "_on_haggle_value_submitted").bind(haggle_value_edit, haggle_asking, haggle_chance_label, item, seller))
		haggle_value_edit.text_changed.connect(func(_t): haggle_chance_label.text = "%.0f%% accept" % (compute_haggle_chance(item, seller, clamp(_parse_price(haggle_value_edit.text), 1.0, haggle_asking)) * 100.0))
		haggle_value_edit.focus_exited.connect(Callable(self, "_adjust_haggle_value").bind(haggle_value_edit, 0.0, haggle_asking, haggle_chance_label, item, seller))
		haggle_cluster.add_child(action_button("Offer  •  ⚡2, 2m", "nav", Callable(self, "haggle_item").bind(i, haggle_value_edit), "Make ONE offer at the price in the box. The % is the chance they accept. A cheeky lowball can get it refused for good — or get you thrown off the stall."))
		actions.add_child(haggle_cluster)
	else:
		var done = action_button("Offer made — %s" % str(item["haggle_result"]).capitalize(), "nav", null)
		done.disabled = true
		done.custom_minimum_size = Vector2(cw(300), 40)
		actions.add_child(done)

	# --- findings (below the buttons, so nothing shifts when you click)
	if item["quick_look_done"] and item["quick_look_note"] != "":
		card.add_child(rich_line(item["quick_look_note"], 15))
	if item["condition_checked"]:
		var cn = item["condition_price_note"]
		if not item["testable"]:
			if item["fault"]:
				cn += "\n[color=#e88c7a][!] Hidden flaw found: %s[/color]" % fault_label(item)
			else:
				cn += "  [color=#8cd98f]No hidden defects.[/color]"
		card.add_child(rich_line(cn, 15))
	if item["basic_researched"]:
		var hint = float(item["locked_gamble_hint"])
		if has_skill("Deep Pockets"):
			hint = min(0.45, hint * 1.25)
		card.add_child(rich_line("Sold recently for: [b]%s[/b]\n%s" % [item["basic_comps"], comps_after_fees_text(item)], 15))
	if item["haggle_note"] != "":
		card.add_child(rich_line(item["haggle_note"], 15))

	return panel

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
		set_status("You've already taken a quick look at this item.")
		return
	if energy < 1:
		queue_popup("Not enough energy. It refills tomorrow morning.")
		return
	energy -= 1
	current_time_minutes += 1
	item["quick_look_done"] = true

	var accuracy = effective_look_accuracy()
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
	item["perceived_condition"] = perceived_condition
	item["quick_look_note"] = "[color=#e08fd0]Inspect %d%%[/color]: %s" % [int(accuracy * 100.0), clue]
	# Whether the read was right stays hidden until Condition is checked.
	add_toast("Inspect (%d%% reliable): %s" % [int(accuracy * 100.0), clue], "info")
	play_sfx("reveal")
	show_stall()

func check_condition(index):
	if not valid_stall_index(index):
		return
	var item = stalls[current_stall_index]["stock"][index]
	if item["condition_checked"]:
		set_status("Condition has already been checked.")
		return
	var cc_cost = condition_cost()
	if cash < cc_cost or energy < 4:
		queue_popup("Not enough cash or energy — this needs £%d and 4 energy." % int(cc_cost))
		return
	cash -= cc_cost
	item["extra_spend"] += cc_cost
	energy -= 4
	current_time_minutes += 5
	day_stats["research"] += cc_cost
	item["condition_checked"] = true
	item["action_order"].append("condition")
	update_family_condition(item)
	day_stats["condition_checks"] += 1
	item["condition_price_note"] = condition_reveal_note(item)
	var message = "Condition %d/10." % item["condition"]
	if item["testable"]:
		message += " Function stays unknown until you test it at home."
	elif item["fault"]:
		message += " Hidden flaw found: %s." % fault_label(item)
	else:
		message += " No hidden defects."
	add_toast(message, "info")
	play_sfx("reveal")
	rival_pressure(0.05)
	show_stall()

func prebuy_research(index):
	if not valid_stall_index(index):
		return
	var item = stalls[current_stall_index]["stock"][index]
	if item["basic_researched"]:
		set_status("Basic Research is already complete. Cached comps: " + item["basic_comps"])
		return
	var rc_cost = research_cost()
	if cash < rc_cost or energy < 2:
		queue_popup("Not enough cash or energy — this needs £%.2f and 2 energy." % rc_cost)
		return
	cash -= rc_cost
	item["extra_spend"] += rc_cost
	energy -= 2
	current_time_minutes += 4
	day_stats["research"] += rc_cost
	day_stats["researches_done"] += 1
	var research_before = estimate_identified_potential(item)
	item["basic_researched"] = true
	item["basic_comps"] = make_comps(item, false)
	apply_price_highlight(item, "research", float(research_before[1]), float(item["basic_comps_max"]))
	item["locked_gamble_hint"] = gamble_hint_chance(item)
	rival_pressure(0.07)
	show_stall()

func comps_median_value(item):
	var v = item.get("comps_values", [])
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

func make_comps(item, deep):
	var values = []
	var count = 5
	if deep:
		count = 6
	var comp_base = float(item["true_value"]) * float(current_trends.get(item["category"], 1.0))
	if item["hidden_special"] != "" and not item["special_discovered"]:
		comp_base /= max(1.0, float(item.get("special_premium", 1.0)))
	for i in range(count):
		var spread = rng.randf_range(0.45, 1.60)
		if deep:
			spread = rng.randf_range(0.70, 1.30)
		values.append(max(1, int(comp_base * spread)))
	values.sort()
	item["comps_values"] = values
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
	if has_skill("Sharp Tongue"):
		base_chance += 0.08
	if has_skill("Silver Tongue"):
		base_chance += 0.10
	var penalty = pow(discount_pct, 1.3) * 3.0
	var trend_mult = float(current_trends.get(item["category"], 1.0))
	var trend_adjustment = (1.0 - trend_mult) * 0.3
	return clamp(base_chance - penalty + trend_adjustment, 0.03, 0.96)

func _adjust_haggle_value(value_edit, delta, asking, chance_label, item, seller):
	var v = clamp(_parse_price(value_edit.text) + delta, 1.0, max(1.0, asking - 1.0))
	value_edit.text = str(int(v))
	chance_label.text = "%.0f%% accept" % (compute_haggle_chance(item, seller, v) * 100.0)

func _on_haggle_value_submitted(submitted_text, value_edit, asking, chance_label, item, seller):
	_adjust_haggle_value(value_edit, 0.0, asking, chance_label, item, seller)

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

func haggle_item(index, value_edit):
	if not valid_stall_index(index) or not is_instance_valid(value_edit):
		return
	var stall = stalls[current_stall_index]
	var item = stall["stock"][index]
	var seller = stall["seller"]
	var seller_display = stall["seller_display_name"]
	if item["haggle_attempted"]:
		set_status("You already made your one haggle attempt on this item.")
		return
	if to_bool(stall.get("banned_today", false)):
		set_status("%s won't deal with you again today." % seller_display)
		return
	if energy < 2:
		queue_popup("You need 2 energy to haggle.")
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
		if discount_pct >= 0.05:
			day_stats["successful_haggles"] += 1
		add_toast("\"%s\"  Offer accepted: £%.0f (was £%.0f)." % [seller_line("accepted", seller), target_price, asking], "success")
		play_sfx("haggle_ok")
		item["haggle_note"] = "Offer £%.0f — [color=#e08fd0]Chance %.0f%% | Rolled %.2f%%[/color] — Accepted." % [target_price, chance * 100.0, roll * 100.0]
		show_stall()
		return

	play_sfx("haggle_no")
	var escalation_roll = rng.randf()
	var kicked_out = discount_pct >= 0.35 and escalation_roll < 0.35
	var item_banned = (not kicked_out) and discount_pct >= 0.20 and escalation_roll < 0.55
	record_rng("Haggle escalation chance: %.0f%% (kickout) / %.0f%% (item ban), needs %.0f%% discount | Rolled: %.2f%% | Result: %s" % [35.0 if discount_pct >= 0.35 else 0.0, 55.0 if discount_pct >= 0.20 else 0.0, discount_pct * 100.0, escalation_roll * 100.0, "STALL BAN" if kicked_out else ("ITEM REFUSED" if item_banned else "plain rejection")])
	if kicked_out:
		add_toast("\"%s\"  You've been thrown off %s's stall for the day." % [seller_line("kicked", seller), seller_display], "error")
		stall["banned_today"] = true
		item["haggle_result"] = "refused"
		item["haggle_note"] = "Offer £%.0f — [color=#e08fd0]Chance %.0f%% | Rolled %.2f%%[/color] — Refused. Kicked off the stall for today." % [target_price, chance * 100.0, roll * 100.0]
	elif item_banned:
		add_toast("\"%s\"  They won't sell you this one now." % seller_line("refused", seller), "error")
		item["seller_refuses"] = true
		item["haggle_result"] = "refused"
		item["haggle_note"] = "Offer £%.0f — [color=#e08fd0]Chance %.0f%% | Rolled %.2f%%[/color] — Refused." % [target_price, chance * 100.0, roll * 100.0]
	else:
		add_toast("\"%s\"  Offer rejected — you can still buy at £%.0f." % [seller_line("rejected", seller), asking], "warn")
		item["haggle_result"] = "rejected"
		item["haggle_note"] = "Offer £%.0f — [color=#e08fd0]Chance %.0f%% | Rolled %.2f%%[/color] — Rejected." % [target_price, chance * 100.0, roll * 100.0]
	show_stall()

func browse_stall():
	var stall = stalls[current_stall_index]
	if stall["revealed"] >= stall["stock"].size():
		set_status("You've already dug through everything at this stall.")
		return
	if energy < 4:
		queue_popup("Not enough energy. It refills tomorrow morning.")
		return
	energy -= 4
	current_time_minutes += 8
	stall["new_from"] = int(stall["revealed"])
	stall["revealed"] = min(stall["stock"].size(), stall["revealed"] + rng.randi_range(2, 4) + (1 if player_level >= 8 else 0))
	play_sfx("reveal")
	rival_pressure(float(stall["crowd"]) * 0.35)
	show_stall()
	call_deferred("_scroll_to_bottom")

func _scroll_to_bottom():
	if page_scroll != null:
		page_scroll.scroll_vertical = int(page_scroll.get_v_scroll_bar().max_value)

func next_stall():
	if stalls.size() > 0:
		stalls[current_stall_index]["new_from"] = 999
	current_time_minutes += 5
	current_stall_index += 1
	if current_stall_index >= stalls.size():
		current_stall_index = 0
	show_stall()

func show_stall_list():
	if sim_mode:
		return
	if game_over and not on_title_screen:
		show_bankruptcy_screen()
		return
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


	add_tip("stalls")
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

		var banned = to_bool(stall.get("banned_today", false))
		var packed = current_time_minutes >= stall["packing_minute"] or banned
		var here_tag = " (here now)" if i == current_stall_index else ""
		var name_line = Label.new()
		name_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_line.add_theme_font_size_override("font_size", 17)
		name_line.text = "Stall %d — %s%s" % [i + 1, stall["seller_display_name"], here_tag]
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

		if special_event_profiles.has(stall["seller"]) and not packed and not banned:
			var side_line = Label.new()
			side_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			side_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			side_line.add_theme_font_size_override("font_size", 13)
			side_line.add_theme_color_override("font_color", Color(0.95,0.78,0.35,1.0))
			var side_chance = float(seller_profiles[stall["seller"]]["side"]) * 100.0
			side_line.text = "~%.1f%% chance per purchase of a side deal: \"%s\"" % [side_chance, special_event_profiles[stall["seller"]]["title"]]
			info_box.add_child(side_line)

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

	body.add_child(build_fixer_card())
	footer_label.text = ""

func build_fixer_card():
	var panel = make_card()
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var fixer_done_today = fixer_uses_today >= fixer_max_uses()
	var fixer_win_pct = 49 if has_skill("Lucky Streak") else 46
	box.add_child(small_label("Round the back of the burger van — The Fixer", 20, Color(0.80,0.60,0.98,1.0)))
	var d = small_label("\"Double or nothing, mate. %d%% you walk away with twice the money.\"  Pure luck, and the odds are against you. %s" % [fixer_win_pct, "(Done for today.)" if fixer_done_today else "(%d/%d goes left today)" % [fixer_max_uses() - fixer_uses_today, fixer_max_uses()]], 16, Color(0.78,0.83,0.90,1.0))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(d)
	var row = HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 6)
	box.add_child(row)
	var fixer_wagers = [25, 75, 200]
	if player_level >= 5:
		fixer_wagers.append(350)
	for wager in fixer_wagers:
		var b = action_button("Bet £%d" % wager, "danger", Callable(self, "fixer_gamble").bind(wager), "%d%% chance to get £%d back. Otherwise it's gone." % [fixer_win_pct, wager * 2])
		b.disabled = fixer_done_today or cash < wager
		row.add_child(b)
	return panel

func go_to_stall(index):
	if index < 0 or index >= stalls.size():
		return
	if index == current_stall_index:
		show_stall()
		return
	stalls[current_stall_index]["new_from"] = 999
	current_time_minutes += 5
	current_stall_index = index
	show_stall()

func can_carry(item):
	return carry_used + size_units(item) <= int(effective_bag_capacity())

func can_store(item):
	return inventory_space_used() + size_units(item) <= int(storage_upgrades[storage_level]["capacity"])

func buy_item(index):
	if not valid_stall_index(index):
		return
	var stall = stalls[current_stall_index]
	if index >= stall["revealed"]:
		return
	if to_bool(stall.get("banned_today", false)):
		set_status("%s won't deal with you again today." % stall["seller_display_name"])
		return
	var item = stall["stock"][index]
	if to_bool(item.get("seller_refuses", false)):
		set_status("They won't sell you this item today.")
		return
	if cash < item["asking"]:
		queue_popup("Not enough cash.")
		return
	if not can_carry(item):
		queue_popup("Your bag's full for today (%d/%d). Bigger bags in the Shop." % [carry_used, effective_bag_capacity()])
		return
	if not can_store(item):
		queue_popup("No room at home (storage %d/%d). Sell stock or upgrade storage in the Shop." % [inventory_space_used(), int(storage_upgrades[storage_level]["capacity"])])
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
	stall["revealed"] = clamp(int(stall["revealed"]) - 1, 0, stall["stock"].size())
	register_collection(item)
	check_side_deal(stall["seller"], stall["seller_display_name"])
	add_xp(3)
	add_toast("Bought %s for £%.2f. Bag %d/%d." % [item["name"], item["paid"], carry_used, effective_bag_capacity()], "success")
	play_sfx("buy")
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

func show_special_offer():
	if sim_mode:
		return
	if game_over and not on_title_screen:
		show_bankruptcy_screen()
		return
	current_screen_name = "show_special_offer"
	clear_body()
	update_header()
	if pending_special_offer == null:
		show_stall()
		return
	var offer = pending_special_offer
	var item = offer["item"]
	var head = make_card()
	body.add_child(head)
	var hb = VBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	head.add_child(hb)
	hb.add_child(small_label("\"Actually mate, before you go...\"", 26, Color(0.95,0.84,0.62,1.0)))
	hb.add_child(small_label("%s — %s" % [offer["seller_display_name"], offer["title"]], 19, Color(0.92,0.95,1.0,1.0)))
	var fl = small_label(offer["flavor"], 18, Color(0.85,0.80,0.70,1.0))
	fl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hb.add_child(fl)
	var panel = PanelContainer.new()
	style_item_card(panel, item)
	body.add_child(panel)
	var card = VBoxContainer.new()
	card.add_theme_constant_override("separation", 8)
	panel.add_child(card)
	var top = HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	card.add_child(top)
	if item["rarity"] != "Common":
		top.add_child(small_label("%s 1/%d" % [item["rarity"].to_upper(), int(item["one_in"])], 16, rarity_color(item["rarity"])))
	var nl = small_label(item["name"], 24, Color(0.95,0.96,1.0,1.0))
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(nl)
	top.add_child(small_label("£%.0f" % float(item["asking"]), 28, Color(0.55,0.90,0.62,1.0)))
	var facts = "%s  •  %s  •  Condition [color=#e88c7a]Unknown[/color]  •  Function: %s" % [item["category"], size_text(item), "Untested (electronic)" if item["testable"] else "N/A"]
	if float(item["fake_chance"]) >= 0.05:
		facts += "  •  Fake risk: [color=#e8c15a]%s[/color]" % fake_risk_label(float(item["fake_chance"]))
	card.add_child(rich_line(facts, 16, Color(0.66,0.72,0.80,1.0)))
	var note = small_label("One-off deal, straight out of their car: no inspecting, no research, no haggling. Take it or leave it — right now.", 17, Color(0.85,0.88,0.92,1.0))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(note)
	var actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	card.add_child(actions)
	var buy_button = action_button("Take it — £%.0f" % float(item["asking"]), "buy", accept_special_offer)
	buy_button.custom_minimum_size = Vector2(cw(260), 50)
	buy_button.add_theme_font_size_override("font_size", 20)
	buy_button.disabled = float(item["asking"]) > cash
	actions.add_child(buy_button)
	var decline_button = action_button("Walk away", "nav", decline_special_offer)
	decline_button.custom_minimum_size = Vector2(200, 50)
	decline_button.add_theme_font_size_override("font_size", 20)
	actions.add_child(decline_button)
	footer_label.text = ""

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

func rival_pressure(chance):
	if rng.randf() < chance:
		var stall = stalls[current_stall_index]
		if stall["stock"].size() > stall["revealed"] and stall["stock"].size() > 0:
			var idx = rng.randi_range(stall["revealed"], stall["stock"].size() - 1)
			var gone = stall["stock"][idx]["name"]
			stall["stock"].remove_at(idx)
			add_toast("A rival reseller grabbed something from the back of this stall (%s) while you were busy." % gone, "warn")

func show_inventory_fresh():
	if sim_mode:
		return
	if game_over and not on_title_screen:
		show_bankruptcy_screen()
		return
	inventory_tab = "unlisted"
	show_inventory()

func confidence_label(item):
	var u = estimate_uncertainty(item)
	if u <= 0.10:
		return "[color=#8cd98f]Very confident[/color]"
	if u <= 0.17:
		return "[color=#b8e08f]Confident[/color]"
	if u <= 0.25:
		return "[color=#e0c96e]Rough idea[/color]"
	return "[color=#e88c7a]Guesswork[/color]"

func show_inventory():
	if sim_mode:
		return
	if game_over and not on_title_screen:
		show_bankruptcy_screen()
		return
	current_screen_name = "show_inventory"
	if page_scroll != null:
		last_scroll_value = page_scroll.scroll_vertical
		call_deferred("_restore_scroll", page_scroll)
	clear_body()
	update_header()
	var unlisted_count = 0
	var listed_count = 0
	for it in inventory:
		if it["listed"] or it["auctioned"]:
			listed_count += 1
		else:
			unlisted_count += 1

	if inventory.size() > 0:
		add_tip("for_sale" if inventory_tab == "listed" else "inventory")
	var head = make_card()
	body.add_child(head)
	var head_box = VBoxContainer.new()
	head_box.add_theme_constant_override("separation", 8)
	head.add_child(head_box)
	var title_row = HFlowContainer.new()
	title_row.add_theme_constant_override("h_separation", 10)
	head_box.add_child(title_row)
	title_row.add_child(small_label("INVENTORY", 24, Color(0.95,0.96,1.0,1.0)))
	title_row.add_child(small_label("Storage %d/%d  •  Stock cost £%.0f  •  Seller rating %.0f%%" % [inventory_space_used(), int(storage_upgrades[storage_level]["capacity"]), inventory_book_value(), seller_rating], 17, Color(0.66,0.72,0.80,1.0)))
	var sp = Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(sp)
	title_row.add_child(make_pricing_details_toggle())
	if inventory_tab == "unlisted" and unlisted_count > 0:
		var bulk_row = HFlowContainer.new()
		bulk_row.add_theme_constant_override("h_separation", 8)
		head_box.add_child(bulk_row)
		var untested = 0
		for it in inventory:
			if it["testable"] and not it["tested"]:
				untested += 1
		if untested > 0:
			bulk_row.add_child(action_button("Test all electricals (%d)  •  £2 + ⚡5 each" % untested, "buy", bulk_test_all, "Plug everything in. Same as pressing Test on each one."))
		bulk_row.add_child(action_button("List everything profitable at my estimate", "action", bulk_list_at_estimate, "Lists every unlisted item that would make a profit at the middle of your estimate. Loss-makers and untested electricals are left for you to decide."))
	var tab_row = HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 8)
	head_box.add_child(tab_row)
	var unlisted_tab = action_button("TO SORT / UNLISTED (%d)" % unlisted_count, "buy" if inventory_tab == "unlisted" else "nav", Callable(self, "_switch_inventory_tab").bind("unlisted"))
	unlisted_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_row.add_child(unlisted_tab)
	var listed_tab = action_button("FOR SALE (%d)" % listed_count, "buy" if inventory_tab == "listed" else "nav", Callable(self, "_switch_inventory_tab").bind("listed"))
	listed_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_row.add_child(listed_tab)

	if inventory.size() == 0:
		var empty = small_label("No stock yet. Buy something at the car boot first — everything you buy lands here.", 18, Color(0.78,0.83,0.90,1.0))
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_child(empty)
		return
	var showing_any = false
	var indices = []
	for i in range(inventory.size()):
		var item = inventory[i]
		var is_live = item["listed"] or item["auctioned"]
		if is_live == (inventory_tab == "listed"):
			indices.append(i)
	match inventory_sort:
		"needs_action":
			indices.sort_custom(func(a, b): return inventory_action_rank(inventory[a]) < inventory_action_rank(inventory[b]))
		"paid_high":
			indices.sort_custom(func(a, b): return float(inventory[a]["paid"]) > float(inventory[b]["paid"]))
		"oldest":
			indices.sort_custom(func(a, b): return int(inventory[a].get("days_owned", 0)) > int(inventory[b].get("days_owned", 0)))
	var pages = max(1, int(ceil(float(indices.size()) / float(INVENTORY_PAGE_SIZE))))
	inventory_page = clamp(inventory_page, 0, pages - 1)
	if indices.size() > 0:
		body.add_child(inventory_pager(pages, indices.size()))
	for k in range(inventory_page * INVENTORY_PAGE_SIZE, min(indices.size(), (inventory_page + 1) * INVENTORY_PAGE_SIZE)):
		showing_any = true
		body.add_child(build_inventory_card(inventory[indices[k]], indices[k]))
	if pages > 1:
		body.add_child(inventory_pager(pages, indices.size()))
	var inv_pad = Control.new()
	inv_pad.custom_minimum_size = Vector2(0, 140)
	body.add_child(inv_pad)
	if not showing_any:
		var empty_tab = small_label("Nothing listed yet — list items from the Unlisted tab." if inventory_tab == "listed" else "Everything you own is listed for sale. End the day to see what sells.", 18, Color(0.78,0.83,0.90,1.0))
		empty_tab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_child(empty_tab)

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

func inventory_pager(pages, count):
	var row = HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 6)
	row.add_child(small_label("Sort:", 16, Color(0.78,0.83,0.90,1.0)))
	for opt in [["needs_action", "Needs attention"], ["paid_high", "Most expensive"], ["oldest", "Held longest"]]:
		var b = action_button(opt[1], "buy" if inventory_sort == opt[0] else "nav", func():
			inventory_sort = opt[0]
			inventory_page = 0
			show_inventory()
		)
		row.add_child(b)
	if pages > 1:
		var sp = Control.new()
		sp.custom_minimum_size = Vector2(20, 0)
		row.add_child(sp)
		var prev = action_button("<  Prev", "nav", func():
			inventory_page -= 1
			last_scroll_value = 0.0
			show_inventory()
		)
		prev.disabled = inventory_page <= 0
		row.add_child(prev)
		row.add_child(small_label("Page %d of %d  (%d items)" % [inventory_page + 1, pages, count], 16, Color(0.85,0.90,0.96,1.0)))
		var nxt = action_button("Next  >", "nav", func():
			inventory_page += 1
			last_scroll_value = 0.0
			show_inventory()
		)
		nxt.disabled = inventory_page >= pages - 1
		row.add_child(nxt)
	return row

func build_inventory_card(item, i):
	var panel = PanelContainer.new()
	style_item_card(panel, item)
	var card = VBoxContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_constant_override("separation", 6)
	panel.add_child(card)

	var top = HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	card.add_child(top)
	var cat_icon_rect = make_category_icon_rect(item["category"])
	if cat_icon_rect != null:
		top.add_child(cat_icon_rect)
	if item["rarity"] != "Common":
		top.add_child(small_label("%s 1/%d" % [item["rarity"].to_upper(), int(item["one_in"])], 16, rarity_color(item["rarity"])))
	var name_l = small_label(item["name"], 22, Color(0.95,0.96,1.0,1.0))
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top.add_child(name_l)
	var spent = float(item["paid"]) + float(item.get("extra_spend", 0.0))
	top.add_child(small_label("Paid £%.2f%s" % [float(item["paid"]), ("  (+£%.2f on checks)" % float(item.get("extra_spend", 0.0))) if float(item.get("extra_spend", 0.0)) > 0.0 else ""], 17, Color(0.78,0.83,0.90,1.0)))

	var cond = "[color=#e88c7a]Unknown[/color]" if not item["condition_checked"] else "[b]%d/10[/b]" % int(item["condition"])
	var func_s = function_status(item)
	if func_s == "TEST REQUIRED":
		func_s = "[color=#e8c15a]TEST REQUIRED[/color]"
	elif item["fault"] and fault_is_known(item):
		func_s = "[color=#e88c7a]%s[/color]" % func_s
	var auth = item["auth_status"]
	if auth == "Confirmed Genuine":
		auth = "[color=#8cd98f]Genuine[/color]"
	elif auth == "Confirmed Counterfeit" or auth == "Suspected Counterfeit":
		auth = "[color=#e88c7a]%s[/color]" % auth
	elif float(item["fake_chance"]) >= 0.05:
		auth = "Unauthenticated (fake risk %s)" % fake_risk_label(float(item["fake_chance"]))
	else:
		auth = ""
	var trend_mult = float(current_trends.get(item["category"], 1.0))
	var facts = "%s  •  Condition %s  •  Function: %s" % [item["category"], cond, func_s]
	if auth != "":
		facts += "  •  " + auth
	if abs(trend_mult - 1.0) >= 0.03:
		facts += "  •  Trend [color=%s]%+d%%[/color]" % ["#b088e8" if trend_mult > 1.0 else "#e88c7a", int(round((trend_mult - 1.0) * 100.0))]
	if not item["condition_checked"] and not (item["fault"] and fault_is_known(item)) and not item["testable"]:
		pass
	card.add_child(rich_line(facts, 15, Color(0.66,0.72,0.80,1.0)))

	var potential = estimate_identified_potential(item)
	card.add_child(rich_line("Your estimate: [b]£%d – £%d[/b]   (%s — more checks narrow it down)" % [potential[0], potential[1], confidence_label(item)], 17, Color(0.85,0.90,0.96,1.0)))

	# Findings
	if item["quick_look_done"] and item["quick_look_note"] != "" and not item["condition_checked"]:
		card.add_child(rich_line(item["quick_look_note"], 15))
	if item["condition_checked"] and item["condition_price_note"] != "":
		var cn = item["condition_price_note"]
		if not item["testable"]:
			cn += ("\n[color=#e88c7a][!] Hidden flaw: %s[/color]" % fault_label(item)) if item["fault"] else "  [color=#8cd98f]No hidden defects.[/color]"
		card.add_child(rich_line(cn, 15))
	if item["basic_researched"]:
		card.add_child(rich_line("Sold recently for: [b]%s[/b]" % item["basic_comps"], 15))
	if item["deep_researched"]:
		var deep_note = item["research_note"]
		if item["rare_variant_hit"]:
			deep_note += "\n[color=#e08fd0][b]RARE VARIANT[/b] — rolled %.2f%% (%s) — value x%.1f[/color]" % [item["rare_variant_roll_pct"], item["rare_variant_tier"], item["rare_variant_mult"]]
		card.add_child(rich_line(deep_note, 15))
	if item["testable"] and item["tested"]:
		card.add_child(rich_line(item.get("test_note", ""), 15))
	if item["auth_attempted"] and item["auth_note"] != "":
		card.add_child(rich_line(item["auth_note"], 15))
	if item["repair_note"] != "":
		card.add_child(rich_line(item["repair_note"], 15))

	var is_live = item["listed"] or item["auctioned"]
	var actions = HFlowContainer.new()
	actions.add_theme_constant_override("h_separation", 6)
	actions.add_theme_constant_override("v_separation", 6)
	if not is_live and item["auth_status"] != "Confirmed Counterfeit":
		card.add_child(actions)
		if item["testable"] and not item["tested"]:
			var tb = action_button("Test it  £2  •  ⚡5   (fault chance %.0f%%)" % (float(item["fault_chance"]) * 100.0), "buy", Callable(self, "test_item").bind(i), "Plug it in and see if it works. Every electrical item must be tested before you can list it.", test_icon)
			actions.add_child(tb)
		if not item["condition_checked"]:
			actions.add_child(action_button("Check Condition £%d  •  ⚡4" % int(condition_cost()), "action", Callable(self, "inventory_check_condition").bind(i), "Exact Condition score (and hidden flaws on non-electronics). Tightens your estimate and cuts return risk.", condition_icon))
		if not item["basic_researched"]:
			actions.add_child(action_button("Research £%.2f  •  ⚡2" % research_cost(), "action", Callable(self, "inventory_basic_research").bind(i), "Five recent sold prices. Tightens your estimate.", research_icon))
		if not item["deep_researched"]:
			var deep_knowledge = float(category_knowledge.get(item["category"], 5))
			var deep_chance = clamp(0.28 + deep_knowledge / 180.0, 0.28, 0.78)
			var real_rare_chance = 0.20
			if item["basic_researched"]:
				real_rare_chance = clamp(float(item["locked_gamble_hint"]), 0.04, 0.32)
			if has_skill("Deep Pockets"):
				real_rare_chance = min(0.45, real_rare_chance * 1.25)
			actions.add_child(action_button("Deep Research £%d  •  ⚡10   (find %.0f%%, rare %.0f%%)" % [int(deep_research_cost(item)), deep_chance * 100.0, real_rare_chance * 100.0], "action", Callable(self, "deep_research").bind(i), "Pin down the exact model/edition. Chance to identify something more desirable, plus a separate chance it's a rare variant worth far more. Always tightens your estimate. One go only.", deep_research_icon))
		if not item["auth_attempted"] and (float(item["fake_chance"]) >= 0.03 or item["auth_status"] == "Suspected Counterfeit"):
			actions.add_child(action_button("Authenticate £%d  •  ⚡6   (%.0f%% accurate)" % [int(authentication_cost(item)), authentication_accuracy(item) * 100.0], "action", Callable(self, "authenticate_item").bind(i), "Checks it's genuine. Confirmed genuine sells better; confirmed fakes can't be sold. Selling unchecked risks a fake being returned — and your seller rating.", authenticate_icon))
		if toolbox_level > 0 and item["fault"] and fault_is_known(item):
			if item["repair_attempted"]:
				var rb = action_button("Repair attempt used", "nav", null)
				rb.disabled = true
				actions.add_child(rb)
			else:
				actions.add_child(action_button("Repair £%d  •  ⚡10" % int(repair_cost(item)), "buy", Callable(self, "repair_item").bind(i), "One attempt to fix the fault. Better tools = better odds. A failed attempt still costs the fee."))
		elif toolbox_level == 0 and item["fault"] and fault_is_known(item):
			actions.add_child(small_label("Buy Repair Tools in the Shop to try fixing faults.", 15))

	if item["auth_status"] == "Confirmed Counterfeit":
		var row = HBoxContainer.new()
		card.add_child(row)
		row.add_child(action_button("Scrap / sell for parts", "danger", Callable(self, "scrap_item").bind(i), "Counterfeits can't be sold. Recover a few quid for parts."))
		return panel
	add_listing_controls(card, i, item, potential)
	return panel

func _switch_inventory_tab(tab):
	inventory_tab = tab
	inventory_page = 0
	last_scroll_value = 0.0
	show_inventory()

func function_status(item):
	if not item["testable"]:
		return "N/A"
	if not item["tested"]:
		return "TEST REQUIRED"
	if item["fault"]:
		return fault_label(item)
	return "Working"

func add_listing_controls(card, index, item, potential):
	if item["auctioned"]:
		card.add_child(rich_line("[color=#e8c15a][b]AUCTION LIVE[/b][/color] — current bid £%.2f — ends in %d day%s" % [float(item["auction_current_bid"]), int(item["auction_days_left"]), "" if int(item["auction_days_left"]) == 1 else "s"], 17))
		return
	if item["listed"]:
		var live_row = HFlowContainer.new()
		live_row.add_theme_constant_override("h_separation", 10)
		card.add_child(live_row)
		var days_up = day - int(item.get("listed_day", day))
		live_row.add_child(rich_line("[color=#8cd98f][b]LISTED at £%.2f[/b][/color]  •  up %d day%s  •  expected interest [color=%s]%s[/color]" % [float(item["listing"]), days_up, "" if days_up == 1 else "s", buyer_interest_color(buyer_interest_label(item, float(item["listing"]))), buyer_interest_label(item, float(item["listing"]))], 17))
		live_row.add_child(action_button("Unlist / reprice", "danger", Callable(self, "unlist_item").bind(index), "Take the listing down so you can change the price or sell another way."))
		if days_up >= 3:
			card.add_child(rich_line("[color=#e8c15a]No bites for %d days.[/color] Could be bad luck — or buyers think it's worth less than you do. Checking condition or researching sharpens your estimate." % days_up, 15))
		var breakdown_live = rich_line(format_sale_breakdown(item, float(item["listing"])) if show_pricing_details else format_sale_summary(item, float(item["listing"])), 15, Color(0.72,0.78,0.85,1.0))
		card.add_child(breakdown_live)
		return

	var needs_test = item["testable"] and not item["tested"]
	var sell_box = VBoxContainer.new()
	sell_box.add_theme_constant_override("separation", 6)
	card.add_child(sell_box)
	if needs_test:
		sell_box.add_child(small_label("Electrical — test it before you can sell it.", 16, Color(0.90,0.78,0.40,1.0)))
		return

	var initial_value = round((float(potential[0]) + float(potential[1])) / 2.0)
	var price_min = 1.0
	var price_max = max(20.0, float(potential[1]) * 3.0)
	var row = HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 6)
	sell_box.add_child(row)
	row.add_child(small_label("List for £", 18, Color(0.85,0.90,0.96,1.0)))
	var minus_btn = Button.new()
	minus_btn.text = "-"
	style_button(minus_btn, "nav")
	minus_btn.custom_minimum_size = Vector2(40, 40)
	row.add_child(minus_btn)
	var value_edit = LineEdit.new()
	value_edit.text = str(int(initial_value))
	value_edit.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	value_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_edit.custom_minimum_size = Vector2(90, 40)
	value_edit.add_theme_font_size_override("font_size", 20)
	row.add_child(value_edit)
	var plus_btn = Button.new()
	plus_btn.text = "+"
	style_button(plus_btn, "nav")
	plus_btn.custom_minimum_size = Vector2(40, 40)
	row.add_child(plus_btn)
	var interest = rich_line("", 17)
	interest.custom_minimum_size = Vector2(cw(340), 0)
	interest.size_flags_horizontal = Control.SIZE_FILL
	row.add_child(interest)
	var list_button = action_button("List for sale", "buy", Callable(self, "create_listing").bind(index, value_edit), "Put it online at your price. Buyers roll every night; the first day also gets one quick chance of an instant sale.")
	list_button.custom_minimum_size = Vector2(170, 40)
	list_button.add_theme_font_size_override("font_size", 18)
	row.add_child(list_button)
	var breakdown = rich_line("", 15, Color(0.72,0.78,0.85,1.0))
	sell_box.add_child(breakdown)
	var step = max(1.0, round(initial_value * 0.05))
	minus_btn.pressed.connect(Callable(self, "_adjust_listing_price").bind(value_edit, -step, price_min, price_max, index, interest, breakdown))
	plus_btn.pressed.connect(Callable(self, "_adjust_listing_price").bind(value_edit, step, price_min, price_max, index, interest, breakdown))
	value_edit.text_submitted.connect(Callable(self, "_on_listing_price_submitted").bind(value_edit, price_min, price_max, index, interest, breakdown))
	value_edit.text_changed.connect(func(_t): _refresh_listing_price(value_edit, price_min, price_max, index, interest, breakdown, false))
	value_edit.focus_exited.connect(Callable(self, "_refresh_listing_price").bind(value_edit, price_min, price_max, index, interest, breakdown))
	_refresh_listing_price(value_edit, price_min, price_max, index, interest, breakdown)

	var alt = HFlowContainer.new()
	alt.add_theme_constant_override("h_separation", 8)
	sell_box.add_child(alt)
	var qc = perceived_center(item)
	var quick_sell_low = max(1.0, round(qc * 0.40))
	var quick_sell_high = max(1.0, round(qc * 0.60))
	alt.add_child(action_button("Sell to a trader now  ~£%d–£%d" % [quick_sell_low, quick_sell_high], "nav", Callable(self, "quick_sell_item").bind(index), "Cash in hand today: a trader pays roughly 40-60% of what it's really worth. No fees, postage or returns."))
	var auction_button = action_button("Auction (3 days)" if player_level >= 6 else "Auction — unlocks at Level 6", "action", Callable(self, "start_auction").bind(index), "Three-day auction. Final price swings well above or below value; rare and trending items attract bidding wars. Extra 5% auction fee, no returns.")
	auction_button.disabled = player_level < 6
	alt.add_child(auction_button)

func _parse_price(text):
	var cleaned = text.strip_edges()
	if cleaned == "" or not cleaned.is_valid_float():
		return 0.0
	return float(cleaned)

func _refresh_listing_price(value_edit, min_val, max_val, index, interest_label, breakdown_label, rewrite = true):
	var v = clamp(_parse_price(value_edit.text), min_val, max_val)
	if rewrite:
		value_edit.text = str(int(v))
	if index < 0 or index >= inventory.size():
		return
	var item = inventory[index]
	interest_label.text = "Expected interest: [color=%s]%s[/color]" % [buyer_interest_color(buyer_interest_label(item, v)), buyer_interest_label(item, v)]
	if show_pricing_details:
		breakdown_label.text = format_sale_breakdown(item, v) + "\n" + format_sale_estimate(item, v)
	else:
		breakdown_label.text = format_sale_summary(item, v)
	var costs = selling_costs(item, v)
	var prof = v - float(costs["fee"]) - float(costs["postage"]) - float(costs["insurance"]) - float(costs["packaging"]) - float(item["paid"]) - float(item.get("extra_spend", 0.0))
	if prof < 0.0:
		breakdown_label.text += "\n[color=#e88c7a][b]At this price you'd lose %s.[/b] Sometimes cutting a loss is right — but check you meant it.[/color]" % money_signed(prof)

func _on_listing_price_submitted(submitted_text, value_edit, min_val, max_val, index, interest_label, breakdown_label):
	_refresh_listing_price(value_edit, min_val, max_val, index, interest_label, breakdown_label)

func _adjust_listing_price(value_edit, delta, min_val, max_val, index, interest_label, breakdown_label):
	var v = clamp(_parse_price(value_edit.text) + delta, min_val, max_val)
	value_edit.text = str(int(v))
	_refresh_listing_price(value_edit, min_val, max_val, index, interest_label, breakdown_label)

func quick_sell_item(index):
	if index < 0 or index >= inventory.size():
		return
	var item = inventory[index]
	if item["auth_status"] == "Confirmed Counterfeit":
		set_status("Confirmed counterfeits can't be quick sold — use Scrap instead.")
		return
	var qs_roll = rng.randf_range(0.40, 0.60)
	var quick_price = max(1.0, round(true_market_value(item) * qs_roll))
	record_rng("Trader offer: %.0f%% of market value | Result: £%.0f" % [qs_roll * 100.0, quick_price])
	cash += quick_price
	current_time_minutes += 2
	var profit = record_completed_sale(item, quick_price, {"fee":0.0, "postage":0.0, "insurance":0.0, "packaging":0.0}, "trader")
	inventory.remove_at(index)
	add_toast("Sold to a trader: %s for £%.2f  —  profit [color=%s]%s£%.2f[/color]" % [item["name"], quick_price, "#8cd98f" if profit >= 0.0 else "#e88c7a", "+" if profit >= 0.0 else "-", abs(profit)], "success" if profit >= 0.0 else "warn")
	play_sfx("coin")
	save_game()
	show_inventory()

var show_pricing_details = true
var show_action_details = true

func money_signed(v):
	return ("+£%.2f" % v) if v >= 0.0 else ("-£%.2f" % abs(v))

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
	var u = 0.32
	if item["quick_look_done"]:
		u -= 0.02
	if item["condition_checked"]:
		u -= 0.07
	if item["basic_researched"]:
		u -= 0.09
	if item["deep_researched"]:
		u -= 0.09
	if item["testable"] and item["tested"]:
		u -= 0.02
	var k = float(category_knowledge.get(item["category"], 5))
	u -= clamp((k - 5.0) * 0.004, 0.0, 0.08)
	return clamp(u, 0.04, 0.40)

func perceived_center(item):
	# The player's belief. Built from what they actually know, plus a persistent
	# per-item error that shrinks as they learn more about it.
	var v = market_value(item)
	if not item["condition_checked"]:
		v /= condition_factor(int(item["condition"]))
		if item["quick_look_done"]:
			v *= condition_factor(int(item.get("perceived_condition", 6)))
	if item["hidden_special"] != "" and not item["special_discovered"]:
		v /= max(1.0, float(item.get("special_premium", 1.0)))
	var u = estimate_uncertainty(item)
	var bias = exp(clamp(float(item.get("est_noise", 0.0)), -2.2, 2.2) * u * 0.62)
	return max(1.0, v * bias)

func estimate_identified_potential(item):
	var center = perceived_center(item)
	var u = estimate_uncertainty(item)
	var low = int(max(1.0, round(center * (1.0 - u * 0.85))))
	var high = int(max(float(low) + 1.0, round(center * (1.0 + u * 0.85))))
	return [low, high]

func inventory_check_condition(index):
	if index < 0 or index >= inventory.size():
		return
	var item = inventory[index]
	if item["condition_checked"]:
		set_status("Condition has already been checked.")
		return
	var cc_cost = condition_cost()
	if cash < cc_cost or energy < 4:
		queue_popup("Not enough cash or energy — this needs £%d and 4 energy." % int(cc_cost))
		return
	cash -= cc_cost
	item["extra_spend"] += cc_cost
	energy -= 4
	current_time_minutes += 5
	day_stats["research"] += cc_cost
	var before_check = estimate_identified_potential(item)
	item["condition_checked"] = true
	item["action_order"].append("condition")
	update_family_condition(item)
	day_stats["condition_checks"] += 1
	var after_check = estimate_identified_potential(item)
	item["condition_price_note"] = condition_reveal_note(item) + "\nYour estimate: £%d–£%d -> £%d–£%d" % [before_check[0], before_check[1], after_check[0], after_check[1]]
	apply_price_highlight(item, "condition", float(before_check[1]), float(after_check[1]))
	var message = "Condition %d/10." % item["condition"]
	if item["testable"]:
		message += " Function stays unknown until you test it."
	elif item["fault"]:
		message += " Hidden flaw found: %s." % fault_label(item)
	else:
		message += " No hidden defects."
	add_toast(message, "info")
	play_sfx("reveal")
	show_inventory()

func inventory_basic_research(index):
	if index < 0 or index >= inventory.size():
		return
	var item = inventory[index]
	if item["basic_researched"]:
		set_status("Research already completed once for this item.")
		return
	var rc_cost = research_cost()
	if cash < rc_cost or energy < 2:
		queue_popup("Not enough cash or energy — this needs £%.2f and 2 energy." % rc_cost)
		return
	cash -= rc_cost
	item["extra_spend"] += rc_cost
	energy -= 2
	current_time_minutes += 4
	day_stats["research"] += rc_cost
	day_stats["researches_done"] += 1
	var research_before = estimate_identified_potential(item)
	item["basic_researched"] = true
	item["action_order"].append("research")
	item["basic_comps"] = make_comps(item, false)
	apply_price_highlight(item, "research", float(research_before[1]), float(item["basic_comps_max"]))
	item["locked_gamble_hint"] = gamble_hint_chance(item)
	play_sfx("reveal")
	show_inventory()

func deep_research(index):
	if index < 0 or index >= inventory.size():
		return
	var item = inventory[index]
	if item["deep_researched"]:
		set_status("Deep Research has already been completed once.")
		return
	var dr_cost = deep_research_cost(item)
	if cash < dr_cost or energy < 10:
		queue_popup("Deep Research needs £%d and 10 energy." % int(dr_cost))
		return
	var before = estimate_identified_potential(item)
	cash -= dr_cost
	item["extra_spend"] += dr_cost
	energy -= 10
	current_time_minutes += 20
	day_stats["research"] += dr_cost
	day_stats["deep_researches_done"] += 1
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
				if family_stats.has(item["name"]):
					family_stats[item["name"]]["specials_found"][item["hidden_special"]] = true
			else:
				item["identified_mult"] *= 0.92
			reason = "Possible hidden special: %s." % item["hidden_special"]
		else:
			var up = rng.randf() > 0.42
			if up:
				item["identified_mult"] *= rng.randf_range(1.12, 1.45)
				reason = "More desirable variant identified."
			else:
				reason = "Confirmed it's the standard version — nothing special, but you now know exactly what you've got."

	var after = estimate_identified_potential(item)
	var rare_text = ""
	var rare_roll = rng.randf()
	var rare_mult = 1.0
	var rare_tier = ""
	var total_chance = 0.20
	if item["basic_researched"]:
		total_chance = clamp(float(item["locked_gamble_hint"]), 0.04, 0.32)
	if has_skill("Deep Pockets"):
		total_chance = min(0.45, total_chance * 1.25)
	var exceptional_cut = total_chance * 0.05
	var significant_cut = total_chance * 0.20
	if rare_roll < exceptional_cut:
		rare_mult = rng.randf_range(3.5, 6.0)
		rare_tier = "EXCEPTIONAL rare variant"
	elif rare_roll < exceptional_cut + significant_cut:
		rare_mult = rng.randf_range(2.3, 3.2)
		rare_tier = "significant rare variant"
	elif rare_roll < total_chance:
		rare_mult = rng.randf_range(1.6, 2.2)
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
		add_xp(10)

	item["research_note"] = "Deep Research — [color=#e08fd0]Chance %.0f%% | Rolled %.2f%%[/color] | Result: %s%s Range £%d–£%d -> £%d–£%d." % [chance * 100.0, roll * 100.0, reason, rare_text, before[0], before[1], after[0], after[1]]
	apply_price_highlight(item, "deep_research", float(before[1]), float(after[1]))
	show_inventory()

func deep_research_cost(item):
	return max(3.0, round(max(float(item["paid"]), 1.0) * 0.18))

func test_item(index):
	if index < 0 or index >= inventory.size():
		return
	var item = inventory[index]
	if item["tested"]:
		set_status("Testing has already been completed once.")
		return
	if cash < 2.0 or energy < 5:
		queue_popup("Not enough cash or energy — testing needs £2 and 5 energy.")
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
		result_text = "FAULT — " + fault_label(item)
	var plain_line = "Fault chance: %.1f%% | Rolled: %.2f%% | Result: %s" % [item["fault_chance"] * 100.0, item["fault_roll"] * 100.0, result_text]
	record_rng(plain_line)
	var colored_line = "[color=#e08fd0]Fault chance: %.1f%% | Rolled: %.2f%%[/color] | Result: %s" % [item["fault_chance"] * 100.0, item["fault_roll"] * 100.0, result_text]
	var after = estimate_identified_potential(item)
	item["test_note"] = "Test Complete — %s. Selling price %s: £%d–£%d -> £%d–£%d." % [colored_line, ("decreased" if after[1] < before[1] else "unchanged"), before[0], before[1], after[0], after[1]]
	if not bulk_mode:
		show_inventory()

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
	var cost = 12.0
	if float(item["paid"]) > 60.0:
		cost = 22.0
	if float(item["paid"]) > 150.0:
		cost = 32.0
	if item["special_discovered"] and item["hidden_special"] != "":
		cost += 42.0
	return cost

func authentication_accuracy(item):
	var cost = authentication_cost(item)
	var accuracy = 0.80
	if cost >= 22.0:
		accuracy = 0.87
	if cost >= 32.0:
		accuracy = 0.92
	if item["special_discovered"] and item["hidden_special"] != "":
		accuracy = 0.96
	return accuracy

func authenticate_item(index):
	if index < 0 or index >= inventory.size():
		return
	var item = inventory[index]
	if item["auth_attempted"]:
		set_status("Authentication has already been attempted once.")
		return
	var cost = authentication_cost(item)
	if cash < cost or energy < 6:
		queue_popup("Not enough cash or energy — this needs £%.0f and 6 energy." % cost)
		return
	cash -= cost
	item["extra_spend"] += cost
	energy -= 6
	current_time_minutes += 15
	day_stats["authentication"] += cost
	day_stats["authentications_done"] += 1
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
			if item["listed"] or item["auctioned"]:
				item["listed"] = false
				item["auctioned"] = false
				item["listing"] = 0.0
				queue_popup("Listing pulled — you can't knowingly sell a counterfeit.", "warn")
			play_sfx("fail")
			unlock_achievement("Should've Known Better")
	else:
		item["auth_status"] = "Inconclusive"
	item["auth_note"] = "%s — %s" % [line, item["auth_status"]]
	add_xp(3)
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
	if index < 0 or index >= inventory.size():
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
		queue_popup("Not enough cash or energy — this needs £%.0f and 10 energy." % cost)
		return
	cash -= cost
	item["extra_spend"] += cost
	energy -= 10
	current_time_minutes += 30
	day_stats["repairs"] += cost
	day_stats["repairs_done"] += 1
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
	add_xp(3)
	show_inventory()

func buyer_interest_score(item, price, perceived = false):
	# perceived=true: what the player expects, based on their own estimate.
	# perceived=false: the real figure used by the sale roll.
	var reference = perceived_center(item) if perceived else market_value(item)
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
	var checks_total = 3
	if item["condition_checked"]:
		checks_done += 1
	if item["basic_researched"]:
		checks_done += 1
	if item["deep_researched"]:
		checks_done += 1
	score *= lerp(0.92, 1.10, float(checks_done) / float(checks_total))
	score *= lerp(0.70, 1.04, clamp(seller_rating / 100.0, 0.0, 1.0))
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

func start_auction(index):
	if index < 0 or index >= inventory.size():
		return
	var item = inventory[index]
	if player_level < 6:
		queue_popup("Auctions unlock at Level 6.")
		return
	if item["auth_status"] == "Confirmed Counterfeit":
		set_status("Confirmed counterfeit items cannot be auctioned.")
		return
	if item["testable"] and not item["tested"]:
		queue_popup("You need to test this item first.")
		return
	var center = true_market_value(item)

	var hype = 0.0
	if item["one_in"] >= 25:
		hype += 0.15
	if item["one_in"] >= 125:
		hype += 0.15
	if item["one_in"] >= 750:
		hype += 0.15
	if item["one_in"] >= 5000:
		hype += 0.15
	var trend_mult = float(current_trends.get(item["category"], 1.0))
	if trend_mult >= 1.10:
		hype += 0.15
	hype = clamp(hype, 0.0, 0.6)

	var weights = {"weak": 0.25, "normal": 0.50, "war": 0.18 * (1.0 + hype * 1.5), "big_war": 0.07 * (1.0 + hype * 2.0)}
	var total_weight = 0.0
	for w in weights.values():
		total_weight += w
	var roll = rng.randf() * total_weight
	var cumulative = 0.0
	var tier = "normal"
	for key in ["weak", "normal", "war", "big_war"]:
		cumulative += weights[key]
		if roll <= cumulative:
			tier = key
			break
	var final_mult = 1.0
	if tier == "weak":
		final_mult = rng.randf_range(0.60, 0.90)
	elif tier == "normal":
		final_mult = rng.randf_range(0.85, 1.10)
	elif tier == "war":
		final_mult = rng.randf_range(1.10, 1.45)
	else:
		final_mult = rng.randf_range(1.50, 2.10)
	record_rng("Auction started for %s: interest boost %.0f%% (rarity/trend). The final price stays hidden until it ends." % [item["name"], hype * 100.0])

	item["auctioned"] = true
	item["listed"] = false
	item["auction_days_left"] = 3
	item["auction_final_price"] = max(1.0, round(center * final_mult))
	item["auction_tier"] = tier
	item["auction_current_bid"] = round(center * rng.randf_range(0.25, 0.60))
	queue_popup("Auction started for %s! Ends in 3 days." % item["name"], "success")
	show_inventory()

func process_auctions():
	var to_remove = []
	for i in range(inventory.size()):
		var item = inventory[i]
		if not item["auctioned"]:
			continue
		item["auction_days_left"] -= 1
		if item["auction_days_left"] <= 0:
			var final_price = float(item["auction_final_price"])
			var sniped = rng.randf() < 0.15
			record_rng("Auction result for %s: %s | final x%.2f of its value%s" % [item["name"], str(item["auction_tier"]).replace("_", " "), float(item["auction_final_price"]) / max(1.0, market_value(item)), " + late snipe" if sniped else ""], false)
			if sniped:
				final_price = round(final_price * rng.randf_range(1.10, 1.25))
			var costs = selling_costs(item, final_price)
			costs["fee"] = float(costs["fee"]) + final_price * 0.05
			var net = final_price - costs["fee"] - costs["postage"] - costs["insurance"] - costs["packaging"]
			cash += net
			var profit = record_completed_sale(item, final_price, costs, "auction")
			add_toast("Auction ended: %s sold for £%.2f (profit %s£%.2f). %s" % [item["name"], final_price, "+" if profit >= 0.0 else "-", abs(profit), auction_flavor_text(item["auction_tier"], sniped)], "success")
			to_remove.append(i)
		else:
			var days_total = 3.0
			var progress = (days_total - float(item["auction_days_left"])) / days_total
			var approach_frac = clamp(0.35 + progress * 0.35 + rng.randf_range(-0.15, 0.15), 0.2, 0.95)
			item["auction_current_bid"] = max(float(item["auction_current_bid"]), round(true_market_value(item) * approach_frac))
	for i in range(to_remove.size() - 1, -1, -1):
		inventory.remove_at(to_remove[i])

func create_listing_quiet(index, value_edit):
	bulk_mode = true
	create_listing(index, value_edit)
	bulk_mode = false

func test_item_quiet(index):
	bulk_mode = true
	test_item(index)
	bulk_mode = false

var bulk_mode = false

func create_listing(index, value_edit):
	if not is_instance_valid(value_edit):
		return
	if index < 0 or index >= inventory.size():
		return
	var item = inventory[index]
	if item["auth_status"] == "Confirmed Counterfeit":
		set_status("Confirmed counterfeit items cannot be listed normally.")
		return
	if item["testable"] and not item["tested"]:
		queue_popup("You need to test this item first.")
		return
	var potential = estimate_identified_potential(item)
	var price = clamp(round(_parse_price(value_edit.text)), 1.0, max(20.0, float(potential[1]) * 3.0))
	item["listing"] = price
	item["listed"] = true
	item["listed_day"] = day
	var result = "no_sale"
	if int(item.get("instant_roll_day", -1)) != day:
		item["instant_roll_day"] = day
		var interest = buyer_interest_score(item, price)
		var instant_chance = clamp(0.03 + interest * 0.20, 0.02, 0.25)
		result = resolve_item_sale(item, instant_chance, "instant")
	if result == "sold_removed":
		inventory.remove_at(index)
		save_game()
	elif result == "returned":
		pass
	else:
		if not bulk_mode:
			add_toast("Listed %s at £%.0f — expected interest %s. Buyers check listings overnight." % [item["name"], price, buyer_interest_label(item, price)], "success")
			play_sfx("confirm")
			save_game()
	if not bulk_mode:
		show_inventory()

func unlist_item(index):
	if index < 0 or index >= inventory.size():
		return
	var item_name = inventory[index]["name"]
	inventory[index]["listed"] = false
	inventory[index]["listing"] = 0.0
	queue_popup("Item Delisted: %s" % item_name)
	set_status("Listing removed.")
	show_inventory()

func scrap_item(index):
	if index < 0 or index >= inventory.size():
		return
	var item = inventory[index]
	var recovery = max(1.0, round(float(item["paid"]) * rng.randf_range(0.04, 0.18)))
	cash += recovery
	day_stats["other_income"] = float(day_stats.get("other_income", 0.0)) + recovery
	day_stats["items_scrapped"] += 1
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

func record_completed_sale(item, sale_price, costs, channel):
	var net = sale_price - float(costs["fee"]) - float(costs["postage"]) - float(costs["insurance"]) - float(costs["packaging"])
	var sale_profit = net - float(item["paid"]) - float(item.get("extra_spend", 0.0))
	day_stats["sales_revenue"] += sale_price
	day_stats["fees"] += float(costs["fee"])
	day_stats["postage"] += float(costs["postage"]) + float(costs["insurance"]) + float(costs["packaging"])
	day_stats["items_sold"] += 1
	sold_history.append({"name":item["name"], "price":sale_price, "day":day, "condition":item["condition"], "condition_checked":item["condition_checked"], "paid":item["paid"], "fee":costs["fee"], "postage":costs["postage"], "insurance":costs["insurance"], "packaging":costs["packaging"], "extra_spend":float(item.get("extra_spend", 0.0)), "channel":channel, "category":item["category"], "rarity":item["rarity"], "seller":item.get("seller", ""), "source":item.get("source", "stall")})
	add_xp(5 + (5 if sale_profit > 0.0 else 0))
	if family_stats.has(item["name"]):
		var fs_sale = family_stats[item["name"]]
		fs_sale["highest_sold"] = max(float(fs_sale["highest_sold"]), sale_price)
		fs_sale["lifetime_profit"] = float(fs_sale["lifetime_profit"]) + sale_profit
	total_lifetime_profit += sale_profit
	if sale_profit > 0.0:
		day_stats["profitable_sales"] += 1
		unlock_achievement("First Flip")
	var cat = item["category"]
	if category_knowledge.has(cat) and int(category_knowledge[cat]) < 25:
		category_knowledge[cat] = int(category_knowledge[cat]) + 1
		if int(category_knowledge[cat]) >= 25:
			unlock_achievement("Specialist")
	return sale_profit

func resolve_item_sale(item, sale_chance, channel = "listing"):
	var sale_roll = rng.randf()
	var sold = sale_roll < sale_chance
	if sold:
		record_rng("%s @ £%.0f — buyer roll %.2f%% under the real chance of %.1f%% | SOLD" % [item["name"], float(item["listing"]), sale_roll * 100.0, sale_chance * 100.0])
	else:
		# The real odds depend on the item's hidden value, so they stay hidden until it sells.
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
			# The buyer finds the fault you didn't mention.
			return_chance += {"Minor": 0.08, "Moderate": 0.22, "Major": 0.42, "Dead": 0.65}.get(str(item["fault_severity"]), 0.3)
	if not item["condition_checked"]:
		return_chance += 0.06
	# Pricing well above what it's actually worth makes buyers pickier.
	var overprice = float(sale_price) / max(1.0, market_value(item))
	if overprice > 1.2:
		return_chance += min(0.10, (overprice - 1.2) * 0.2)
	return_chance = clamp(return_chance, 0.0, 0.85)
	var return_roll = rng.randf()
	var returned = return_roll < return_chance
	record_rng("%s — return chance %.1f%% | Rolled %.2f%% | %s" % [item["name"], return_chance * 100.0, return_roll * 100.0, "RETURNED" if returned else "kept"])
	if returned:
		cash -= sale_price
		day_stats["fees"] += costs["fee"]
		day_stats["postage"] += costs["postage"] + costs["insurance"] + costs["packaging"]
		day_stats["returns"] += 1
		item["listed"] = false
		item["listing"] = 0.0
		var reason = "said it wasn't as described"
		if fake_unauth:
			reason = "says it's a fake — and filed a claim"
			seller_rating = max(0.0, seller_rating - 9.0)
			item["auth_status"] = "Suspected Counterfeit"
			item["auth_attempted"] = false
		elif item["fault"] and not fault_is_known(item):
			reason = "found a fault you didn't mention"
			seller_rating = max(0.0, seller_rating - 5.0)
			if item["testable"]:
				item["tested"] = true
				item["test_note"] = "Buyer returned it with a %s fault." % item["fault_severity"]
			else:
				item["condition_checked"] = true
				item["condition_price_note"] = condition_reveal_note(item)
		else:
			seller_rating = max(0.0, seller_rating - 3.0)
		add_toast("RETURNED: %s — the buyer %s. Refunded £%.2f (fees and postage lost). Seller rating now %.0f%%." % [item["name"], reason, sale_price, seller_rating], "error")
		play_sfx("fail")
		return "returned"
	seller_rating = min(100.0, seller_rating + 1.0)
	var sale_profit = record_completed_sale(item, sale_price, costs, channel)
	add_toast("SOLD: %s for £%.2f  —  profit [color=%s]%s£%.2f[/color]" % [item["name"], sale_price, "#8cd98f" if sale_profit >= 0.0 else "#e88c7a", "+" if sale_profit >= 0.0 else "-", abs(sale_profit)], "success" if sale_profit >= 0.0 else "warn")
	play_sfx("sale")
	return "sold_removed"

func process_sales():
	var to_remove = []
	for i in range(inventory.size()):
		var item = inventory[i]
		if not item["listed"]:
			continue
		var interest = buyer_interest_score(item, float(item["listing"]))
		var chance = daily_sale_chance(interest)
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
		queue_popup("No mystery packages left today.")
		return
	if cash < 30.0:
		queue_popup("You need £30 for a mystery package.")
		return
	if inventory_space_used() + 8 > int(storage_upgrades[storage_level]["capacity"]):
		queue_popup("You need 8 free storage space before opening a package (it could hold two large items).")
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
	record_rng("Mystery Package tier | Rolled %.2f%% | %s" % [roll * 100.0, tier])

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
		# Package value is already rolled by tier; strip stall rarity/specials so it
		# can't double-dip or show a phantom stall price.
		item["rarity"] = "Common"
		item["one_in"] = 1
		item["hidden_special"] = ""
		item["special_premium"] = 1.0
		item["true_value"] = max(1.0, share / condition_factor(int(item["condition"])))
		item["paid"] = 30.0 / float(count)
		item["asking"] = item["paid"]
		item["source"] = "package"
		inventory.append(item)
		register_collection(item)
		contents.append(item["name"])
	var kind = "info"
	if tier == "Jackpot" or tier == "Grail":
		show_big_popup("MYSTERY PACKAGE — %s!" % tier.to_upper(), "Inside: %s.\nThis one could be worth a lot." % ", ".join(contents), "rare")
	else:
		add_toast("Mystery package opened: %s tier — %s. Check it in Inventory." % [tier, ", ".join(contents)], "success" if tier in ["Good", "Excellent"] else kind)
	play_sfx("buy")
	save_game()
	show_stall()

func show_trends():
	if sim_mode:
		return
	if game_over and not on_title_screen:
		show_bankruptcy_screen()
		return
	current_screen_name = "show_trends"
	clear_body()
	update_header()
	var days_left = 7 - ((day - 1) % 7)
	body.add_child(small_label("MARKET TRENDS — Week %d, %s" % [current_week, get_season_name()], 24, Color(0.95,0.96,1.0,1.0)))
	var intro = small_label("Demand shifts every week (next change in %d day%s). Trends change what buyers pay and how fast things sell. Your experience in a category sharpens your estimates and helps Deep Research." % [days_left, "" if days_left == 1 else "s"], 16, Color(0.78,0.83,0.90,1.0))
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(intro)
	var card = make_card()
	body.add_child(card)
	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 28)
	grid.add_theme_constant_override("v_separation", 6)
	card.add_child(grid)
	for h in ["Category", "Demand", "Price effect", "Your experience"]:
		grid.add_child(small_label(h, 16, Color(0.95,0.84,0.62,1.0)))
	var cats = current_trends.keys()
	cats.sort_custom(func(a, b): return float(current_trends[a]) > float(current_trends[b]))
	for category in cats:
		var mult = float(current_trends[category])
		var direction = "Steady"
		var col = Color(0.78,0.83,0.90,1.0)
		if mult >= 1.10:
			direction = "HOT"
			col = Color(0.75,0.55,0.98,1.0)
		elif mult >= 1.03:
			direction = "Rising"
			col = Color(0.55,0.88,0.58,1.0)
		elif mult <= 0.90:
			direction = "Weak"
			col = Color(0.95,0.50,0.45,1.0)
		elif mult <= 0.97:
			direction = "Cooling"
			col = Color(0.92,0.70,0.45,1.0)
		grid.add_child(small_label(category, 17, Color(0.92,0.95,1.0,1.0)))
		grid.add_child(small_label(direction, 17, col))
		grid.add_child(small_label("%+d%%" % int(round((mult - 1.0) * 100.0)), 17, col))
		var k = int(category_knowledge.get(category, 5))
		grid.add_child(small_label("%s  %d/25" % ["|".repeat(int(k / 2.5)) + ".".repeat(10 - int(k / 2.5)), k], 16, Color(0.60,0.75,0.95,1.0)))
	var chatter = make_card()
	body.add_child(chatter)
	var cb = VBoxContainer.new()
	chatter.add_child(cb)
	cb.add_child(small_label("MARKET CHATTER", 17, Color(0.95,0.84,0.62,1.0)))
	for headline in trend_headlines:
		cb.add_child(small_label("• " + headline, 16, Color(0.80,0.85,0.92,1.0)))

func show_shop():
	if sim_mode:
		return
	if game_over and not on_title_screen:
		show_bankruptcy_screen()
		return
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
	upkeep_note.text = "Current daily business upkeep: £%.2f (scales with total upgrade levels owned — a bigger operation costs more to run every day, on top of the pitch fee & fuel)." % compute_upkeep()
	upkeep_note.add_theme_color_override("font_color", Color(0.85,0.68,0.55,1.0))
	body.add_child(upkeep_note)
	add_tip("shop")
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
	add_toast("Upgrade bought.", "success")
	play_sfx("coin")
	save_game()
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
		description.text = ("Lets you attempt repairs on faulty items. Current tools add +%d%% to repair odds." % int(float(data[level]["bonus"]) * 100.0)) if level > 0 else "No tools yet — you can't attempt repairs. The first toolbox unlocks repairing."
	box.add_child(description)
	if level < data.size() - 1:
		var next = data[level + 1]
		var benefit = ""
		if kind == "bag":
			benefit = "bag %d -> %d" % [int(data[level]["capacity"]), int(next["capacity"])]
		elif kind == "storage":
			benefit = "storage %d -> %d" % [int(data[level]["capacity"]), int(next["capacity"])]
		elif kind == "eye":
			benefit = "Inspect accuracy %d%% -> %d%%" % [int(float(data[level]["accuracy"]) * 100.0), int(float(next["accuracy"]) * 100.0)]
		elif kind == "fee":
			benefit = "fee %.1f%% -> %.1f%%" % [float(data[level]["fee"]) * 100.0, float(next["fee"]) * 100.0]
		else:
			benefit = ("unlocks repairs (+%d%% odds)" % int(float(next["bonus"]) * 100.0)) if level == 0 else "repair odds +%d%% -> +%d%%" % [int(float(data[level]["bonus"]) * 100.0), int(float(next["bonus"]) * 100.0)]
		var button = Button.new()
		var cost = float(next["cost"])
		button.text = "%s:  %s  —  £%.0f   (+£%.2f/day upkeep)" % [next["name"], benefit, cost, upkeep_per_tier()]
		if cash < cost:
			button.text += "   — need £%.0f more" % (cost - cash)
		button.pressed.connect(Callable(self, "buy_upgrade").bind(kind))
		style_button(button, "buy")
		button.disabled = cash < cost
		button.add_theme_font_size_override("font_size", 16)
		button.custom_minimum_size.y = 42
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
		if bag_level >= 3:
			unlock_achievement("Van Man")
	elif kind == "storage":
		storage_level += 1
	elif kind == "eye":
		eye_level += 1
	elif kind == "fee":
		fee_level += 1
	else:
		toolbox_level += 1
	add_toast("Upgrade bought.", "success")
	play_sfx("coin")
	save_game()
	show_shop()


var seller_first_name_pools = {
	"Desperate Seller": ["Stephen", "Colin", "Trevor"],
	"House Clearance": ["Barry", "Malcolm", "Derek"],
	"Clueless Seller": ["Sandra", "Brenda", "Doreen"],
	"Regular Seller": ["Dave", "Paul", "Steve"],
	"Collector": ["Arran", "Julian", "Marcus"],
	"Dodgy Seller": ["Kyle", "Wayne", "Vinnie"],
	"Dealer": ["Will", "Terry", "Frank"],
}
var seller_name_templates = {
	"Desperate Seller": "%s the Desperate Seller",
	"House Clearance": "%s's House Clearance",
	"Clueless Seller": "%s the Clueless Seller",
	"Regular Seller": "%s the Regular Seller",
	"Collector": "%s the Collector",
	"Dodgy Seller": "%s the Dodgy Seller",
	"Dealer": "%s the Dealer",
}

func pick_unique_seller_name(seller, used_names_today):
	var pool = seller_first_name_pools.get(seller, [seller])
	var template = seller_name_templates.get(seller, "%s")
	var shuffled = pool.duplicate()
	shuffled.shuffle()
	for first_name in shuffled:
		if not used_names_today.has(first_name):
			used_names_today[first_name] = true
			return template % first_name
	var fallback_name = pool[0] + " " + str(used_names_today.size() + 1)
	used_names_today[fallback_name] = true
	return template % fallback_name

func seller_display_name(seller):
	return seller

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

func render_family_stat_card(family, force_undiscovered = false):
	var fam_name = family["name"]
	var known = family_stats.has(fam_name) and not force_undiscovered
	var panel = make_card()
	panel.custom_minimum_size = Vector2(cw(370), 0)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	if known and family_stats[fam_name]["highest_rarity"] == "Grail":
		apply_grail_glow(panel)
	var title = fam_name if known else "???"
	if family.has("season"):
		title += "  (%s only)" % family["season"]
	box.add_child(small_label(title, 19, Color(0.92,0.95,1.0,1.0) if known else Color(0.45,0.50,0.58,1.0)))
	var tiers = HFlowContainer.new()
	tiers.add_theme_constant_override("h_separation", 10)
	box.add_child(tiers)
	for tier_row in rarity_table:
		var key = family["category"] + "|" + fam_name + "|" + tier_row["tier"]
		var got = discovered_log.has(key)
		var tier_name = tier_row["tier"]
		var txt = ("%s" % tier_name) if got else ("??? 1/%d" % int(tier_row["one_in"]) if int(tier_row["one_in"]) > 1 else "??? common")
		tiers.add_child(small_label(txt, 15, rarity_color(tier_name) if got else Color(0.40,0.44,0.50,1.0)))
	if known:
		var fs = family_stats[fam_name]
		var cheapest_text = "—" if float(fs["cheapest_bought"]) < 0.0 else "£%.0f" % float(fs["cheapest_bought"])
		var l = small_label("Found %d  •  cheapest £%s  •  best sale £%.0f  •  profit %s" % [int(fs["times_found"]), cheapest_text.replace("£", ""), float(fs["highest_sold"]), money_signed(float(fs["lifetime_profit"]))], 15, Color(0.66,0.72,0.80,1.0))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(l)
	return panel

func show_collection_log():
	if sim_mode:
		return
	if game_over and not on_title_screen:
		show_bankruptcy_screen()
		return
	current_screen_name = "show_collection_log"
	clear_body()
	update_header()
	var title = Label.new()
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 24)
	title.text = "COLLECTION LOG"
	body.add_child(title)

	var total_counts = total_families_discovered()
	var total_panel = make_card()
	body.add_child(total_panel)
	var total_label = Label.new()
	total_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	total_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	total_label.add_theme_font_size_override("font_size", 18)
	total_label.text = "TOTAL LOG: %d/%d discovered" % [total_counts[0], total_counts[1]]
	total_panel.add_child(total_label)

	var grid = HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	body.add_child(grid)

	for category in get_category_list():
		var counts = category_discovery_count(category)
		var cat_button = Button.new()
		cat_button.text = "%s\n%d/%d" % [category, counts[0], counts[1]]
		style_button(cat_button, "action")
		cat_button.custom_minimum_size = Vector2(200, 64)
		cat_button.pressed.connect(Callable(self, "show_collection_category").bind(category))
		grid.add_child(cat_button)

	var grail_counts = grails_discovery_count()
	var grail_button = Button.new()
	grail_button.text = "GRAILS\n%d/%d" % [grail_counts[0], grail_counts[1]]
	style_button(grail_button, "danger")
	grail_button.custom_minimum_size = Vector2(200, 64)
	grail_button.pressed.connect(show_collection_grails)
	grid.add_child(grail_button)

func show_collection_category(category):
	if sim_mode:
		return
	if game_over and not on_title_screen:
		show_bankruptcy_screen()
		return
	current_screen_name = "show_collection_log"
	clear_body()
	update_header()
	var title = Label.new()
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 24)
	var counts = category_discovery_count(category)
	title.text = "%s — %d/%d discovered" % [category, counts[0], counts[1]]
	body.add_child(title)
	var back_button = Button.new()
	back_button.text = "Back to Collection Log"
	style_button(back_button, "nav")
	back_button.pressed.connect(show_collection_log)
	body.add_child(back_button)
	var grid = HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	body.add_child(grid)
	for family in item_families:
		if family["category"] == category:
			grid.add_child(render_family_stat_card(family))

func show_collection_grails():
	if sim_mode:
		return
	if game_over and not on_title_screen:
		show_bankruptcy_screen()
		return
	current_screen_name = "show_collection_log"
	clear_body()
	update_header()
	var title = Label.new()
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 24)
	var grail_counts = grails_discovery_count()
	title.text = "GRAILS — %d/%d found" % [grail_counts[0], grail_counts[1]]
	body.add_child(title)
	var back_button = Button.new()
	back_button.text = "Back to Collection Log"
	style_button(back_button, "nav")
	back_button.pressed.connect(show_collection_log)
	body.add_child(back_button)
	var grid = HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	body.add_child(grid)
	for family in item_families:
		var hit_grail = family_stats.has(family["name"]) and family_stats[family["name"]]["highest_rarity"] == "Grail"
		grid.add_child(render_family_stat_card(family, not hit_grail))

func sort_log(a, b):
	return int(a["one_in"]) > int(b["one_in"])

func make_progress_bar_section(title_text, current_value, max_value, milestones, fill_color = Color(0.35,0.75,0.40,1.0)):
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)

	var title_label = Label.new()
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", 15)
	title_label.text = title_text
	container.add_child(title_label)

	var bar = ProgressBar.new()
	bar.min_value = 0
	bar.max_value = max_value
	bar.value = clamp(current_value, 0, max_value)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 22)
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = fill_color
	fill_style.corner_radius_top_left = 6
	fill_style.corner_radius_top_right = 6
	fill_style.corner_radius_bottom_left = 6
	fill_style.corner_radius_bottom_right = 6
	bar.add_theme_stylebox_override("fill", fill_style)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.10,0.12,0.15,1.0)
	bg_style.corner_radius_top_left = 6
	bg_style.corner_radius_top_right = 6
	bg_style.corner_radius_bottom_left = 6
	bg_style.corner_radius_bottom_right = 6
	bar.add_theme_stylebox_override("background", bg_style)
	container.add_child(bar)

	var milestone_row = HFlowContainer.new()
	milestone_row.add_theme_constant_override("h_separation", 16)
	milestone_row.add_theme_constant_override("v_separation", 4)
	milestone_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(milestone_row)
	for m in milestones:
		var reached = current_value >= m
		var label_text = "£%d" % int(m) if m < 1000.0 else "£%dk" % int(m / 1000.0)
		var m_label = Label.new()
		m_label.add_theme_font_size_override("font_size", 12)
		m_label.text = ("X " if reached else "- ") + label_text
		m_label.add_theme_color_override("font_color", fill_color if reached else Color(0.50,0.55,0.62,1.0))
		milestone_row.add_child(m_label)
	return container

const ALL_ACHIEVEMENTS = {
	"First Flip": "Sell an item for more than you paid.",
	"Against the Odds": "Buy something 1-in-100 rare or rarer.",
	"Should've Known Better": "Have an authentication confirm a counterfeit.",
	"Better Than Nothing": "Scrap a confirmed counterfeit for parts.",
	"Actually Mate...": "Get offered a seller's side deal.",
	"Level Headed": "Reach Level 10.",
	"Challenge Crusher": "Complete 30 daily challenges.",
	"High Roller": "Win the Fixer's Gamble 5 times.",
	"Grand Day Out": "Make £250+ cash profit in a single day.",
	"Survivor": "Climb out of the red after going overdrawn.",
	"Specialist": "Reach category knowledge 25 in any category.",
	"Grail Hunter": "Buy a Grail-tier item.",
	"Van Man": "Upgrade to Van Crates carrying.",
	"Car Boot King": "Hold £50,000 in cash.",
}

func unlock_achievement(name):
	if achievements.has(name):
		return
	achievements[name] = true
	show_big_popup("ACHIEVEMENT UNLOCKED", "%s\n\n%s" % [name, ALL_ACHIEVEMENTS.get(name, "")], "achievement")

func record_rng(line, toast = true):
	last_rng_line = line
	if footer_label != null:
		footer_label.text = "Last RNG: " + last_rng_line
	day_stats["rng_events"].append(line)
	if day_stats["rng_events"].size() > 12:
		day_stats["rng_events"].pop_front()
	rng_log.append("Day %d %s  %s" % [day, format_time(), line])
	while rng_log.size() > 150:
		rng_log.pop_front()
	if toast and not in_end_day and show_rng_toasts:
		add_toast("[color=#e08fd0]RNG[/color]  " + line, "rng", false)

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
	if pending_special_offer != null:
		pending_special_offer = null
	var closing_day = day
	var start_cash = float(day_stats["start_cash"])
	var cash_before_resolution = cash
	process_sales()
	process_auctions()
	for item in inventory:
		item["days_owned"] = int(item.get("days_owned", 0)) + 1
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
		if negative_days_streak > 0:
			unlock_achievement("Survivor")
		negative_days_streak = 0
	if cash - start_cash >= 250.0:
		unlock_achievement("Grand Day Out")
	# Sales resolved overnight still count toward today's challenges.
	check_daily_challenge_rewards()
	check_daily_challenge_bonus()
	var summary = {
		"start_worth": float(day_stats.get("start_worth", start_cash)),
		"end_worth": cash + inventory_book_value(),
		"day": closing_day,
		"start_cash": start_cash,
		"end_cash": cash,
		"overnight_cash": cash - cash_before_resolution,
		"stats": day_stats.duplicate(true),
		"challenges_done": daily_challenges_completed_count(),
		"challenges_total": daily_challenges.size(),
		"streak": negative_days_streak,
	}
	best_net_worth = max(best_net_worth, cash + inventory_book_value())
	if cash >= 50000:
		unlock_achievement("Car Boot King")
	in_end_day = false
	if negative_days_streak >= 4:
		game_over = true
		save_game()
		play_sfx("fail")
		show_bankruptcy_screen()
		return
	day += 1
	energy = 100
	current_time_minutes = 7 * 60
	if (day - 1) % 7 == 0:
		generate_weekly_trends()
	reset_day_stats()
	generate_day()
	save_game()
	update_header()
	show_day_summary(summary)

func show_bankruptcy_screen():
	if sim_mode:
		return
	current_screen_name = "show_bankruptcy_screen"
	clear_body()
	set_chrome_visible(false)
	var panel = make_card()
	body.add_child(panel)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var title = Label.new()
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(0.95,0.50,0.45,1.0))
	title.text = "BANKRUPT"
	box.add_child(title)
	var msg = Label.new()
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	msg.add_theme_font_size_override("font_size", 18)
	msg.text = "Four days in the red and the overdraft finally caught up with you. The bank has taken the stock, the van and the spare room.\n\nFinal cash: £%.2f on Day %d." % [cash, day]
	box.add_child(msg)
	var stats = Label.new()
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.add_theme_font_size_override("font_size", 16)
	stats.add_theme_color_override("font_color", Color(0.72,0.78,0.85,1.0))
	stats.text = "Days survived: %d\nItems sold: %d\nLifetime profit: £%.2f\nBest net worth: £%.2f\nLevel reached: %d\nCollection: %d discovered\nAchievements: %d/%d" % [day, sold_history.size(), total_lifetime_profit, best_net_worth, player_level, discovered_log.size(), achievements.size(), ALL_ACHIEVEMENTS.size()]
	box.add_child(stats)
	var restart = Button.new()
	restart.text = "Start a New Run"
	style_button(restart, "buy")
	restart.custom_minimum_size.y = 52
	restart.add_theme_font_size_override("font_size", 20)
	restart.pressed.connect(start_new_game)
	box.add_child(restart)
	var title_btn = Button.new()
	title_btn.text = "Back to Title"
	style_button(title_btn, "nav")
	title_btn.pressed.connect(show_title_screen)
	box.add_child(title_btn)

func start_new_game():
	init_new_run()
	save_game()
	has_save = true
	on_title_screen = false
	set_chrome_visible(true)
	update_header()
	play_sfx("confirm")
	if not tutorial_seen:
		tutorial_slide_index = 0
		show_tutorial()
	else:
		show_stall()

func restart_game():
	start_new_game()

func summary_line(parent, left_text, value, positive_good = true, size = 17):
	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(row)
	var l = Label.new()
	l.text = left_text
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(0.78,0.83,0.90,1.0))
	row.add_child(l)
	var r = Label.new()
	r.add_theme_font_size_override("font_size", size)
	if typeof(value) == TYPE_STRING:
		r.text = value
		r.add_theme_color_override("font_color", Color(0.92,0.95,1.0,1.0))
	else:
		var v = float(value)
		r.text = ("+£%.2f" % v) if v > 0.004 else (("-£%.2f" % abs(v)) if v < -0.004 else "£0.00")
		var good = (v >= 0.0) == positive_good
		if abs(v) < 0.005:
			r.add_theme_color_override("font_color", Color(0.60,0.65,0.72,1.0))
		else:
			r.add_theme_color_override("font_color", Color(0.55,0.88,0.58,1.0) if good else Color(0.95,0.55,0.45,1.0))
	row.add_child(r)

func show_day_summary(summary):
	if sim_mode:
		return
	current_screen_name = "show_day_summary"
	update_header()
	if game_over and not on_title_screen:
		show_bankruptcy_screen()
		return
	current_screen_name = "show_day_summary"
	clear_body()
	last_scroll_value = 0.0
	if page_scroll != null:
		page_scroll.scroll_vertical = 0
	var s = summary["stats"]
	var closing_day = int(summary["day"])
	var profit_today = float(summary["end_cash"]) - float(summary["start_cash"])

	add_tip("summary")
	var head = make_card()
	body.add_child(head)
	var head_box = VBoxContainer.new()
	head_box.add_theme_constant_override("separation", 6)
	head.add_child(head_box)
	var title = Label.new()
	title.add_theme_font_size_override("font_size", 30)
	title.text = "DAY %d COMPLETE" % closing_day
	head_box.add_child(title)
	var profit_line = Label.new()
	profit_line.add_theme_font_size_override("font_size", 26)
	var worth_delta = float(summary.get("end_worth", 0.0)) - float(summary.get("start_worth", 0.0))
	profit_line.text = "Change in business value today: %s" % money_signed(worth_delta)
	profit_line.add_theme_color_override("font_color", Color(0.55,0.88,0.58,1.0) if worth_delta >= 0.0 else Color(0.95,0.55,0.45,1.0))
	head_box.add_child(profit_line)
	var worth_change = float(summary.get("end_worth", 0.0)) - float(summary.get("start_worth", 0.0))
	var worth_line = rich_line("Business value = cash + stock at what you paid: [b]£%.2f[/b]   •   cash on its own %s" % [float(summary.get("end_worth", 0.0)), money_signed(profit_today)], 18, Color(0.85,0.90,0.96,1.0))
	head_box.add_child(worth_line)
	if inventory.size() > 0:
		var est = inventory_estimated_net()
		var paid = inventory_book_value()
		var diff = est - paid
		head_box.add_child(rich_line("Your stock cost £%.0f. At your own estimates it'd bring in about [b]£%.0f[/b] after fees — [color=%s]%s[/color] if it all sells." % [paid, est, "#8cd98f" if diff >= 0.0 else "#e88c7a", money_signed(diff)], 17, Color(0.78,0.83,0.90,1.0)))
	var cash_line = Label.new()
	cash_line.add_theme_font_size_override("font_size", 17)
	cash_line.add_theme_color_override("font_color", Color(0.72,0.78,0.85,1.0))
	cash_line.text = "Cash £%.2f -> £%.2f   •   Stock on hand: %d items (paid £%.0f)   •   Seller rating %.0f%%" % [float(summary["start_cash"]), float(summary["end_cash"]), inventory.size(), inventory_book_value(), seller_rating]
	cash_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head_box.add_child(cash_line)
	head_box.add_child(rich_line("[color=#e8c15a]>[/color] %s" % current_goal_text(), 16, Color(0.90,0.80,0.55,1.0)))
	if int(summary["challenges_total"]) > 0:
		var ch = Label.new()
		ch.add_theme_font_size_override("font_size", 16)
		ch.add_theme_color_override("font_color", Color(0.90,0.78,0.40,1.0))
		ch.text = "Daily challenges: %d/%d complete" % [int(summary["challenges_done"]), int(summary["challenges_total"])]
		head_box.add_child(ch)
	if float(summary["end_cash"]) < 0.0:
		var warning = Label.new()
		warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		warning.add_theme_font_size_override("font_size", 18)
		warning.add_theme_color_override("font_color", Color(0.98,0.45,0.40,1.0))
		warning.text = "[!] IN THE RED — day %d of 4. Overdraft interest is 6%% a day. Sell stock or the business goes under." % int(summary["streak"])
		head_box.add_child(warning)

	var columns = HFlowContainer.new()
	columns.add_theme_constant_override("h_separation", 10)
	columns.add_theme_constant_override("v_separation", 10)
	body.add_child(columns)

	var money_card = make_card()
	money_card.custom_minimum_size = Vector2(cw(520), 0)
	money_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(money_card)
	var money = VBoxContainer.new()
	money.add_theme_constant_override("separation", 3)
	money_card.add_child(money)
	var mt = Label.new()
	mt.text = "MONEY"
	mt.add_theme_font_size_override("font_size", 19)
	money.add_child(mt)
	summary_line(money, "Sales revenue", float(s.get("sales_revenue", 0.0)))
	summary_line(money, "Stock bought", -float(s.get("buy_spend", 0.0)))
	summary_line(money, "Selling fees", -float(s.get("fees", 0.0)))
	summary_line(money, "Postage, packaging & insurance", -float(s.get("postage", 0.0)))
	summary_line(money, "Checks & research", -float(s.get("research", 0.0)))
	summary_line(money, "Authentication", -float(s.get("authentication", 0.0)))
	summary_line(money, "Repairs", -float(s.get("repairs", 0.0)))
	if float(s.get("refunds", 0.0)) > 0.0:
		summary_line(money, "Refunds on returns", -float(s.get("refunds", 0.0)))
	summary_line(money, "Pitch fee & fuel", -float(s.get("rent", 0.0)))
	summary_line(money, "Business upkeep", -float(s.get("upkeep", 0.0)))
	if float(s.get("interest", 0.0)) > 0.0:
		summary_line(money, "Overdraft interest", -float(s.get("interest", 0.0)))
	if float(s.get("other_income", 0.0)) != 0.0:
		summary_line(money, "Other (challenges, scrap, gambles)", float(s.get("other_income", 0.0)))

	var act_card = make_card()
	act_card.custom_minimum_size = Vector2(cw(420), 0)
	act_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(act_card)
	var act = VBoxContainer.new()
	act.add_theme_constant_override("separation", 3)
	act_card.add_child(act)
	var at = Label.new()
	at.text = "ACTIVITY"
	at.add_theme_font_size_override("font_size", 19)
	act.add_child(at)
	summary_line(act, "Items bought", str(int(s.get("items_bought", 0))))
	summary_line(act, "Items sold", str(int(s.get("items_sold", 0))))
	summary_line(act, "Returns", str(int(s.get("returns", 0))))
	summary_line(act, "Scrapped", str(int(s.get("items_scrapped", 0))))
	summary_line(act, "New collection entries", str(int(s.get("collection_adds", 0))))
	summary_line(act, "Rarest find", "1/%d" % int(s.get("rarest_one_in", 1)) if int(s.get("rarest_one_in", 1)) > 1 else "—")
	summary_line(act, "Level", "%d  (XP %d/%d)" % [player_level, player_xp, xp_needed_for_level(player_level)])

	var sold_today = []
	for sale in sold_history:
		if int(sale["day"]) == closing_day:
			sold_today.append(sale)
	if sold_today.size() > 0:
		var sold_card = make_card()
		body.add_child(sold_card)
		var sold_box = VBoxContainer.new()
		sold_box.add_theme_constant_override("separation", 4)
		sold_card.add_child(sold_box)
		var sold_title = Label.new()
		sold_title.add_theme_font_size_override("font_size", 19)
		sold_title.text = "SOLD TODAY (%d)" % sold_today.size()
		sold_box.add_child(sold_title)
		for sale in sold_today:
			var net = float(sale["price"]) - float(sale.get("fee", 0.0)) - float(sale.get("postage", 0.0)) - float(sale.get("insurance", 0.0)) - float(sale.get("packaging", 0.0))
			var profit = net - float(sale["paid"]) - float(sale.get("extra_spend", 0.0))
			var sold_line = RichTextLabel.new()
			sold_line.bbcode_enabled = true
			sold_line.fit_content = true
			sold_line.scroll_active = false
			sold_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			sold_line.add_theme_font_size_override("normal_font_size", 16)
			sold_line.text = "%s  —  sold £%.2f (%s), paid £%.2f, net £%.2f  ->  [color=%s]%s£%.2f[/color]" % [sale["name"], float(sale["price"]), channel_name(str(sale.get("channel", "listing"))), float(sale["paid"]), net, "#8cd98f" if profit >= 0.0 else "#e88c7a", "+" if profit >= 0.0 else "-", abs(profit)]
			sold_box.add_child(sold_line)

	var rng_events = s.get("rng_events", [])
	if rng_events.size() > 0:
		var rng_card = make_card()
		body.add_child(rng_card)
		var rng_box = VBoxContainer.new()
		rng_card.add_child(rng_box)
		var rt = Label.new()
		rt.add_theme_font_size_override("font_size", 17)
		rt.text = "LAST ROLLS OF THE DAY"
		rng_box.add_child(rt)
		for event in rng_events:
			var event_line = Label.new()
			event_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			event_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			event_line.add_theme_font_size_override("font_size", 14)
			event_line.add_theme_color_override("font_color", Color(0.88,0.62,0.85,1.0))
			event_line.text = "• " + str(event)
			rng_box.add_child(event_line)

	var cont = Button.new()
	cont.text = "Continue to Day %d  >" % day
	style_button(cont, "buy")
	cont.custom_minimum_size.y = 56
	cont.add_theme_font_size_override("font_size", 22)
	cont.pressed.connect(func(): show_stall())
	body.add_child(cont)
	if worth_delta >= 0.0:
		play_sfx("day_good")
	else:
		play_sfx("day_bad")

# ---------------------------------------------------------------------------
# Feedback: toasts, big popups, activity log
# ---------------------------------------------------------------------------
var sim_mode = false
var last_toast_text = ""
var last_toast_time = 0.0

func log_activity(text):
	var clean = str(text)
	var re = RegEx.new()
	re.compile("\\[/?[a-z]+(=[^\\]]*)?\\]")
	clean = re.sub(clean, "", true)
	activity_log.append("Day %d %s  %s" % [day, format_time(), clean])
	while activity_log.size() > 150:
		activity_log.pop_front()

func clear_toasts():
	if toast_box == null:
		return
	for c in toast_box.get_children():
		toast_box.remove_child(c)
		c.queue_free()

func add_toast(text, kind = "info", log_it = true):
	if log_it:
		log_activity(text)
	if sim_mode or toast_box == null:
		return
	var now = Time.get_ticks_msec() / 1000.0
	if text == last_toast_text and now - last_toast_time < 1.0:
		return
	last_toast_text = text
	last_toast_time = now
	var panel = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb = StyleBoxFlat.new()
	var bg = Color(0.07,0.09,0.13,0.96)
	var border = Color(0.35,0.55,0.85,1.0)
	match kind:
		"success":
			bg = Color(0.05,0.15,0.08,0.96)
			border = Color(0.35,0.80,0.45,1.0)
		"error":
			bg = Color(0.18,0.06,0.06,0.96)
			border = Color(0.90,0.40,0.35,1.0)
		"rng":
			bg = Color(0.10,0.06,0.12,0.94)
			border = Color(0.80,0.50,0.80,0.9)
		"warn":
			bg = Color(0.17,0.13,0.04,0.96)
			border = Color(0.95,0.75,0.30,1.0)
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = 4
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 7
	sb.content_margin_bottom = 7
	sb.shadow_color = Color(0,0,0,0.5)
	sb.shadow_size = 6
	panel.add_theme_stylebox_override("panel", sb)
	var lbl = RichTextLabel.new()
	lbl.bbcode_enabled = true
	lbl.fit_content = true
	lbl.scroll_active = false
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.custom_minimum_size = Vector2(cw(400) - 30.0, 0)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("normal_font_size", 17)
	lbl.text = text
	panel.add_child(lbl)
	toast_box.add_child(panel)
	while toast_box.get_child_count() > 2:
		var oldest = toast_box.get_child(0)
		toast_box.remove_child(oldest)
		oldest.queue_free()
	var hold = clamp(2.2 + float(text.length()) / 50.0, 2.6, 6.0)
	var tw = panel.create_tween()
	tw.tween_interval(hold)
	tw.tween_property(panel, "modulate:a", 0.0, 0.45)
	tw.tween_callback(panel.queue_free)

func build_overlays():
	toast_box = VBoxContainer.new()
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_box.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	toast_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	toast_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	toast_box.offset_right = -18
	toast_box.offset_bottom = -18
	toast_box.alignment = BoxContainer.ALIGNMENT_END
	toast_box.add_theme_constant_override("separation", 6)
	toast_box.z_index = 90
	add_child(toast_box)

	big_popup = Control.new()
	big_popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	big_popup.visible = false
	big_popup.z_index = 120
	big_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(big_popup)
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	big_popup.add_child(dim)
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	big_popup.add_child(center)
	var panel = PanelContainer.new()
	panel.name = "BigPanel"
	panel.custom_minimum_size = Vector2(cw(560), 0)
	center.add_child(panel)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	big_popup_title = Label.new()
	big_popup_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big_popup_title.add_theme_font_size_override("font_size", 36)
	box.add_child(big_popup_title)
	big_popup_body = Label.new()
	big_popup_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big_popup_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	big_popup_body.custom_minimum_size = Vector2(cw(560) - 60.0, 0)
	big_popup_body.add_theme_font_size_override("font_size", 20)
	box.add_child(big_popup_body)
	var ok = Button.new()
	ok.text = "Nice"
	ok.name = "OkButton"
	style_button(ok, "buy")
	ok.custom_minimum_size = Vector2(0, 48)
	ok.add_theme_font_size_override("font_size", 20)
	ok.pressed.connect(_close_big_popup)
	box.add_child(ok)

func show_big_popup(title, text, kind = "info"):
	if sim_mode:
		return
	if game_over and not on_title_screen:
		show_bankruptcy_screen()
		return
	log_activity("%s — %s" % [title, text.replace("\n", " ")])
	if sim_mode or big_popup == null:
		return
	big_popup_queue.append({"title": title, "text": text, "kind": kind})
	if not big_popup.visible:
		_show_next_big_popup()

func _show_next_big_popup():
	if big_popup_queue.size() == 0:
		big_popup.visible = false
		return
	var p = big_popup_queue.pop_front()
	var accent = Color(0.45,0.70,1.0,1.0)
	var sfx = "confirm"
	var ok_text = "OK"
	match p["kind"]:
		"level":
			accent = Color(0.70,0.55,1.0,1.0)
			sfx = "levelup"
			ok_text = "Nice"
		"achievement":
			accent = Color(0.95,0.78,0.35,1.0)
			sfx = "levelup"
			ok_text = "Nice"
		"rare":
			accent = Color(0.90,0.55,0.95,1.0)
			sfx = "rare"
			ok_text = "Keep going"
		"grail":
			accent = Color(1.0,0.84,0.35,1.0)
			sfx = "grail"
			ok_text = "Unbelievable"
		"bad":
			accent = Color(0.95,0.45,0.40,1.0)
			sfx = "fail"
			ok_text = "Ouch"
	var panel = big_popup.get_node("CenterContainer/BigPanel") if big_popup.has_node("CenterContainer/BigPanel") else null
	if panel == null:
		for c in big_popup.get_children():
			if c is CenterContainer:
				panel = c.get_child(0)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06,0.07,0.10,0.99)
	sb.border_color = accent
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 24
	sb.content_margin_bottom = 22
	sb.shadow_color = Color(accent.r, accent.g, accent.b, 0.35)
	sb.shadow_size = 18
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(cw(560), 0)
	big_popup_body.custom_minimum_size = Vector2(cw(560) - 60.0, 0)
	big_popup_title.text = p["title"]
	big_popup_title.add_theme_color_override("font_color", accent)
	big_popup_body.text = p["text"]
	var ok = panel.find_child("OkButton", true, false)
	if ok != null:
		ok.text = ok_text
		call_deferred("_safe_focus", ok)
	big_popup.visible = true
	big_popup.move_to_front()
	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2(0.85, 0.85)
	var tw = panel.create_tween()
	tw.tween_property(panel, "scale", Vector2(1, 1), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	play_sfx(sfx)

func _close_big_popup():
	play_sfx("click")
	_show_next_big_popup()

func show_log_screen(kind = "activity"):
	if sim_mode:
		return
	current_screen_name = "show_log_screen"
	clear_body()
	update_header()
	var title = Label.new()
	title.add_theme_font_size_override("font_size", 24)
	title.text = "ACTIVITY LOG" if kind == "activity" else "RNG LOG — every roll, newest first"
	body.add_child(title)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	body.add_child(row)
	var a = Button.new()
	a.text = "Activity"
	style_button(a, "buy" if kind == "activity" else "nav")
	a.pressed.connect(func(): show_log_screen("activity"))
	row.add_child(a)
	var r = Button.new()
	r.text = "RNG Rolls"
	style_button(r, "buy" if kind == "rng" else "nav")
	r.pressed.connect(func(): show_log_screen("rng"))
	row.add_child(r)
	var src = activity_log if kind == "activity" else rng_log
	if src.size() == 0:
		var empty = Label.new()
		empty.text = "Nothing yet."
		body.add_child(empty)
		return
	var card = make_card()
	body.add_child(card)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	card.add_child(box)
	for i in range(src.size() - 1, -1, -1):
		var l = Label.new()
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.add_theme_font_size_override("font_size", 15)
		l.add_theme_color_override("font_color", Color(0.85,0.65,0.85,1.0) if kind == "rng" else Color(0.80,0.85,0.92,1.0))
		l.text = str(src[i])
		box.add_child(l)

# ---------------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------------
const SETTINGS_PATH = "user://settings.cfg"
var master_volume = 0.8
var sfx_enabled = true
var ui_scale = 1.0
var fullscreen = false
var show_rng_toasts = true

func load_settings():
	var cfg = ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		ui_scale = 1.0 if OS.has_feature("web") else 1.25
		return
	master_volume = float(cfg.get_value("audio", "master_volume", 0.8))
	sfx_enabled = to_bool(cfg.get_value("audio", "sfx_enabled", true))
	ui_scale = float(cfg.get_value("display", "ui_scale", 1.25))
	fullscreen = to_bool(cfg.get_value("display", "fullscreen", false))
	show_rng_toasts = to_bool(cfg.get_value("gameplay", "show_rng_toasts", true))
	music_volume = float(cfg.get_value("audio", "music_volume", 0.5))
	var ts = cfg.get_value("gameplay", "tips_seen", {})
	tips_seen = ts if typeof(ts) == TYPE_DICTIONARY else {}

func save_settings():
	var cfg = ConfigFile.new()
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("audio", "sfx_enabled", sfx_enabled)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("display", "ui_scale", ui_scale)
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("gameplay", "show_rng_toasts", show_rng_toasts)
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

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
			fullscreen = not fullscreen
			save_settings()
			apply_settings()
			get_viewport().set_input_as_handled()
		elif not on_title_screen and not game_over and current_screen_name != "show_tutorial" and (big_popup == null or not big_popup.visible) and not (get_viewport().gui_get_focus_owner() is LineEdit):
			var handled = true
			match event.keycode:
				KEY_1:
					show_stall()
				KEY_2:
					show_stall_list()
				KEY_3:
					show_inventory_fresh()
				KEY_4:
					show_sold_history()
				KEY_5:
					show_shop()
				KEY_6:
					show_more_menu()
				KEY_N:
					if current_screen_name == "show_stall":
						next_stall()
				KEY_D:
					if current_screen_name == "show_stall":
						browse_stall()
				_:
					handled = false
			if handled:
				clear_toasts()
				get_viewport().set_input_as_handled()
				return
		if event.keycode == KEY_ESCAPE:
			if big_popup != null and big_popup.visible:
				_close_big_popup()
			elif not on_title_screen and current_screen_name != "show_tutorial":
				show_more_menu()
			get_viewport().set_input_as_handled()

func show_settings_screen():
	if sim_mode:
		return
	current_screen_name = "show_settings_screen"
	clear_body()
	if not on_title_screen:
		update_header()
	var title = Label.new()
	title.add_theme_font_size_override("font_size", 26)
	title.text = "SETTINGS"
	body.add_child(title)
	var card = make_card()
	body.add_child(card)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	card.add_child(box)

	var vol_label = Label.new()
	vol_label.add_theme_font_size_override("font_size", 18)
	vol_label.text = "Master volume (everything): %d%%" % int(master_volume * 100.0)
	box.add_child(vol_label)
	var vol = HSlider.new()
	vol.min_value = 0.0
	vol.max_value = 1.0
	vol.step = 0.05
	vol.value = master_volume
	vol.custom_minimum_size = Vector2(cw(420), 28)
	vol.value_changed.connect(func(v):
		master_volume = v
		vol_label.text = "Master volume: %d%%" % int(v * 100.0)
		apply_settings()
		save_settings()
	)
	vol.drag_ended.connect(func(_c): play_sfx("coin"))
	box.add_child(vol)

	var mus_label = Label.new()
	mus_label.add_theme_font_size_override("font_size", 18)
	mus_label.text = "Music: %d%%" % int(music_volume * 100.0)
	box.add_child(mus_label)
	var mus = HSlider.new()
	mus.min_value = 0.0
	mus.max_value = 1.0
	mus.step = 0.05
	mus.value = music_volume
	mus.custom_minimum_size = Vector2(cw(420), 28)
	mus.value_changed.connect(func(v):
		music_volume = v
		mus_label.text = "Music: %d%%" % int(v * 100.0)
		apply_music_volume()
		save_settings()
	)
	box.add_child(mus)

	var scale_label = Label.new()
	scale_label.add_theme_font_size_override("font_size", 18)
	scale_label.text = "Interface size: %d%%" % int(ui_scale * 100.0)
	box.add_child(scale_label)
	var scale_row = HFlowContainer.new()
	scale_row.add_theme_constant_override("h_separation", 8)
	box.add_child(scale_row)
	for s in [0.9, 1.0, 1.1, 1.25, 1.4, 1.6]:
		var b = Button.new()
		b.text = "%d%%" % int(s * 100.0)
		style_button(b, "buy" if abs(s - ui_scale) < 0.01 else "nav")
		b.custom_minimum_size = Vector2(80, 40)
		b.pressed.connect(func():
			ui_scale = s
			save_settings()
			apply_settings()
			show_settings_screen()
		)
		scale_row.add_child(b)

	if not OS.has_feature("web"):
		var fs = CheckButton.new()
		fs.text = "Fullscreen (F11)"
		fs.button_pressed = fullscreen
		fs.add_theme_font_size_override("font_size", 18)
		fs.toggled.connect(func(on):
			fullscreen = on
			save_settings()
			apply_settings()
		)
		box.add_child(fs)

	var rt = CheckButton.new()
	rt.text = "Show dice-roll (RNG) pop-ups as they happen"
	rt.button_pressed = show_rng_toasts
	rt.add_theme_font_size_override("font_size", 18)
	rt.toggled.connect(func(on):
		show_rng_toasts = on
		save_settings()
	)
	box.add_child(rt)

	var reset_tips = action_button("Show first-time tips again", "nav", func():
		tips_seen = {}
		save_settings()
		add_toast("Tips will show again as you play.", "success")
	)
	box.add_child(reset_tips)
	var keys = small_label("Keyboard: 1-6 switch tabs  •  N next stall  •  D dig deeper  •  Esc menu / close popup  •  F11 fullscreen", 16, Color(0.66,0.72,0.80,1.0))
	keys.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(keys)
	var back = Button.new()
	back.text = "Back"
	style_button(back, "nav")
	back.custom_minimum_size.y = 44
	back.pressed.connect(func():
		if on_title_screen:
			show_title_screen()
		else:
			show_more_menu()
	)
	body.add_child(back)

# ---------------------------------------------------------------------------
# Title screen
# ---------------------------------------------------------------------------
func set_chrome_visible(v):
	if header_row_ref != null:
		header_row_ref.visible = v
	if nav_panel_ref != null:
		nav_panel_ref.visible = v

func show_title_screen():
	if sim_mode:
		return
	on_title_screen = true
	current_screen_name = "show_title_screen"
	set_chrome_visible(false)
	clear_body()
	last_scroll_value = 0.0
	if ResourceLoader.exists("res://banner.png"):
		var banner_rect = TextureRect.new()
		banner_rect.texture = load("res://banner.png")
		banner_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		banner_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		banner_rect.custom_minimum_size = Vector2(0, 380)
		banner_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		body.add_child(banner_rect)
	var tag = Label.new()
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", 22)
	tag.add_theme_color_override("font_color", Color(0.95,0.84,0.62,1.0))
	tag.text = "Buy cheap. Work out what it's really worth. Don't go skint."
	tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(tag)
	var center = CenterContainer.new()
	body.add_child(center)
	var col = VBoxContainer.new()
	col.custom_minimum_size = Vector2(cw(440), 0)
	col.add_theme_constant_override("separation", 10)
	center.add_child(col)
	if has_save and not game_over:
		var cont = Button.new()
		cont.text = "Continue — Day %d, £%.2f" % [day, cash]
		style_button(cont, "buy")
		cont.custom_minimum_size.y = 56
		cont.add_theme_font_size_override("font_size", 22)
		cont.pressed.connect(func():
			play_sfx("confirm")
			on_title_screen = false
			set_chrome_visible(true)
			update_header()
			show_stall()
		)
		col.add_child(cont)
		call_deferred("_safe_focus", cont)
	var ng = Button.new()
	ng.text = "New Game"
	style_button(ng, "buy" if not has_save or game_over else "action")
	ng.custom_minimum_size.y = 50
	ng.add_theme_font_size_override("font_size", 20)
	ng.pressed.connect(func():
		if has_save and not game_over:
			show_confirm_new_game()
		else:
			start_new_game()
	)
	col.add_child(ng)
	if not has_save or game_over:
		call_deferred("_safe_focus", ng)
	var how = Button.new()
	how.text = "How to Play"
	style_button(how, "nav")
	how.custom_minimum_size.y = 44
	how.add_theme_font_size_override("font_size", 18)
	how.pressed.connect(func():
		tutorial_slide_index = 0
		show_tutorial()
	)
	col.add_child(how)
	var st = Button.new()
	st.text = "Settings"
	style_button(st, "nav")
	st.custom_minimum_size.y = 44
	st.add_theme_font_size_override("font_size", 18)
	st.pressed.connect(show_settings_screen)
	col.add_child(st)
	if not OS.has_feature("web"):
		var q = Button.new()
		q.text = "Quit"
		style_button(q, "danger")
		q.custom_minimum_size.y = 44
		q.add_theme_font_size_override("font_size", 18)
		q.pressed.connect(func():
			if has_save and not game_over:
				save_game()
			get_tree().quit()
		)
		col.add_child(q)
	var ver = Label.new()
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.add_theme_font_size_override("font_size", 14)
	ver.add_theme_color_override("font_color", Color(0.50,0.56,0.64,1.0))
	ver.text = "Playtest build %s  •  Progress saves automatically" % GAME_VERSION
	ver.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(ver)

func show_confirm_new_game():
	if sim_mode:
		return
	current_screen_name = "show_confirm_new_game"
	clear_body()
	var card = make_card()
	body.add_child(card)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	card.add_child(box)
	var t = Label.new()
	t.add_theme_font_size_override("font_size", 26)
	t.text = "Start a new run?"
	box.add_child(t)
	var m = Label.new()
	m.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	m.add_theme_font_size_override("font_size", 18)
	m.text = "Your current run (Day %d, £%.2f, %d items in stock) will be wiped. This can't be undone. Settings are kept." % [day, cash, inventory.size()]
	box.add_child(m)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	var yes = Button.new()
	yes.text = "Yes, wipe it and start fresh"
	yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	style_button(yes, "danger")
	yes.pressed.connect(start_new_game)
	row.add_child(yes)
	var no = Button.new()
	no.text = "Keep my run"
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	style_button(no, "nav")
	no.pressed.connect(func():
		if on_title_screen:
			show_title_screen()
		else:
			show_more_menu()
	)
	row.add_child(no)
	call_deferred("_safe_focus", no)

# ---------------------------------------------------------------------------
# Audio: tiny procedural synth so the game needs no audio assets
# ---------------------------------------------------------------------------
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

func show_more_menu():
	if sim_mode:
		return
	if game_over and not on_title_screen:
		show_bankruptcy_screen()
		return
	current_screen_name = "show_more_menu"
	clear_body()
	update_header()
	body.add_child(small_label("MORE", 24, Color(0.95,0.96,1.0,1.0)))

	var grid = HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	body.add_child(grid)
	var entries = [
		["Skill Tree  (%d pts)" % skill_points_available(), Callable(self, "show_skill_tree"), "action"],
		["Daily Challenges  %d/%d" % [daily_challenges_completed_count(), daily_challenges.size()], Callable(self, "show_daily_challenges"), "action"],
		["Market Trends", Callable(self, "show_trends"), "action"],
		["Collection Log", Callable(self, "show_collection_log"), "action"],
		["Achievements  %d/%d" % [achievements.size(), ALL_ACHIEVEMENTS.size()], Callable(self, "show_achievements"), "action"],
		["Level Unlocks", Callable(self, "show_level_unlocks"), "action"],
		["Activity & RNG Log", Callable(self, "show_log_screen").bind("activity"), "nav"],
		["How to Play", func(): tutorial_slide_index = 0; show_tutorial(), "nav"],
		["Settings", Callable(self, "show_settings_screen"), "nav"],
		["Playtest Notes & Feedback", Callable(self, "show_patch_notes"), "nav"],
	]
	for e in entries:
		var b = action_button(e[0], e[2], e[1])
		b.custom_minimum_size = Vector2(cw(290), 52)
		b.add_theme_font_size_override("font_size", 18)
		grid.add_child(b)

	var save_card = make_card()
	body.add_child(save_card)
	var save_box = VBoxContainer.new()
	save_box.add_theme_constant_override("separation", 8)
	save_card.add_child(save_box)
	save_box.add_child(small_label("SAVE", 19, Color(0.95,0.96,1.0,1.0)))
	save_box.add_child(small_label(("Auto-saved %s. The game saves after every purchase, sale and day." % last_save_time) if last_save_time != "" else "The game saves automatically as you play.", 16, Color(0.55,0.85,0.58,1.0)))
	var save_row = HFlowContainer.new()
	save_row.add_theme_constant_override("h_separation", 8)
	save_box.add_child(save_row)
	save_row.add_child(action_button("Save now", "buy", Callable(self, "manual_save")))
	save_row.add_child(action_button("Save & quit to title", "nav", func():
		save_game()
		show_title_screen()
	))
	save_row.add_child(action_button("Start a new run...", "danger", Callable(self, "show_confirm_new_game")))

	var code_card = make_card()
	body.add_child(code_card)
	var code_box = VBoxContainer.new()
	code_box.add_theme_constant_override("separation", 8)
	code_card.add_child(code_box)
	code_box.add_child(small_label("SAVE CODES — move a run between devices, or attach one to a bug report", 17, Color(0.85,0.90,0.96,1.0)))
	var export_field = LineEdit.new()
	export_field.placeholder_text = "Press Export to generate your save code"
	var import_field = LineEdit.new()
	import_field.placeholder_text = "Paste a save code here"
	var code_row = HFlowContainer.new()
	code_row.add_theme_constant_override("h_separation", 8)
	code_box.add_child(code_row)
	code_row.add_child(action_button("Export save code", "action", func():
		var code = export_save_code()
		export_field.text = code
		DisplayServer.clipboard_set(code)
		add_toast("Save code copied to clipboard.", "success")
	))
	code_row.add_child(action_button("Load save code", "danger", func():
		if import_save_code(import_field.text):
			add_toast("Save loaded.", "success")
			show_stall()
		else:
			queue_popup("That save code didn't work.")
	, "Replaces your CURRENT run with the pasted one."))
	code_box.add_child(export_field)
	code_box.add_child(import_field)

func show_patch_notes():
	if sim_mode:
		return
	current_screen_name = "show_patch_notes"
	clear_body()
	update_header()
	body.add_child(small_label("PLAYTEST NOTES — build %s" % GAME_VERSION, 24, Color(0.95,0.96,1.0,1.0)))
	var fb = make_card()
	body.add_child(fb)
	var fb_box = VBoxContainer.new()
	fb_box.add_theme_constant_override("separation", 8)
	fb.add_child(fb_box)
	fb_box.add_child(small_label("Thanks for playtesting!", 20, Color(0.95,0.84,0.62,1.0)))
	var fbt = rich_line("We'd love to hear what felt good, what felt unfair, and where you got stuck or confused. If something breaks, press [b]Copy bug report info[/b] and paste it into your report — it includes your save code so we can reproduce it exactly.", 16, Color(0.85,0.88,0.92,1.0))
	fb_box.add_child(fbt)
	fb_box.add_child(action_button("Copy bug report info", "buy", func():
		DisplayServer.clipboard_set(bug_report_text())
		add_toast("Bug report info copied — paste it into your feedback.", "success")
	))
	for entry in patch_notes:
		var panel = make_card()
		body.add_child(panel)
		var box = VBoxContainer.new()
		box.add_theme_constant_override("separation", 4)
		panel.add_child(box)
		box.add_child(small_label(entry["version"], 18, Color(0.95,0.96,1.0,1.0)))
		for note in entry["notes"]:
			var l = small_label("• " + note, 16, Color(0.78,0.83,0.90,1.0))
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			box.add_child(l)

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
	{"version": "What's in this playtest", "notes": [
		"Full loop: browse stalls, inspect/check/research, haggle once, buy — then test, research, authenticate, repair, price and list at home. Buyers roll overnight.",
		"Your price estimate on stock is YOUR estimate. It has real error in it that shrinks as you check condition, research and gain experience in a category. Sales roll against what the item is really worth.",
		"Returns hit harder now: selling untested faults, unchecked condition or unauthenticated fakes risks refunds and damages your seller rating, which slows future sales.",
		"Selling experience in a category makes your estimates sharper and Deep Research more likely to find something.",
		"Mid-day saving: quit any time and carry on exactly where you left off.",
	]},
	{"version": "Known rough edges", "notes": [
		"Balance is still being tuned — we especially want to know if the first few days feel too harsh or too easy.",
		"Late-game progression (vans, lock-ups, staff, auctions as a sourcing method) is planned but not in this build.",
		"Category artwork for items is placeholder text for now.",
	]},
]

func show_sold_history():
	if sim_mode:
		return
	if game_over and not on_title_screen:
		show_bankruptcy_screen()
		return
	current_screen_name = "show_sold_history"
	clear_body()
	update_header()
	body.add_child(small_label("SALES HISTORY", 24, Color(0.95,0.96,1.0,1.0)))
	if sold_history.size() == 0:
		body.add_child(small_label("No sales yet. List items from Inventory, then End Day — buyers turn up overnight.", 18, Color(0.78,0.83,0.90,1.0)))
		return
	var total_profit = 0.0
	var wins = 0
	for sale in sold_history:
		var p = sale_profit_of(sale)
		total_profit += p
		if p > 0.0:
			wins += 1
	var sum_card = make_card()
	body.add_child(sum_card)
	sum_card.add_child(rich_line("%d sales  •  %d%% profitable  •  total profit [color=%s][b]%s[/b][/color]  •  seller rating %.0f%%" % [sold_history.size(), int(round(100.0 * wins / max(1, sold_history.size()))), "#8cd98f" if total_profit >= 0.0 else "#e88c7a", money_signed(total_profit), seller_rating], 18, Color(0.85,0.90,0.96,1.0)))
	var card = make_card()
	body.add_child(card)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	card.add_child(box)
	var shown = 0
	for i in range(sold_history.size() - 1, -1, -1):
		var sale = sold_history[i]
		var p = sale_profit_of(sale)
		var cond = "%d/10" % int(sale["condition"]) if sale["condition_checked"] else "unknown"
		box.add_child(rich_line("Day %d  •  %s  •  cond %s  •  paid £%.2f  ->  sold £%.2f via %s  ->  [color=%s][b]%s[/b][/color]" % [int(sale["day"]), sale["name"], cond, float(sale["paid"]), float(sale["price"]), channel_name(str(sale.get("channel", "listing"))), "#8cd98f" if p >= 0.0 else "#e88c7a", money_signed(p)], 16, Color(0.80,0.85,0.92,1.0)))
		shown += 1
		if shown >= 200:
			break

func channel_name(c):
	return {"listing": "online listing", "instant": "online, first-day buyer", "trader": "trader", "auction": "auction"}.get(c, c)

func sale_profit_of(sale):
	var costs_total = float(sale.get("fee", 0.0)) + float(sale.get("postage", 0.0)) + float(sale.get("insurance", 0.0)) + float(sale.get("packaging", 0.0))
	return float(sale["price"]) - costs_total - float(sale.get("paid", 0.0)) - float(sale.get("extra_spend", 0.0))

func show_achievements():
	if sim_mode:
		return
	if game_over and not on_title_screen:
		show_bankruptcy_screen()
		return
	current_screen_name = "show_achievements"
	clear_body()
	update_header()
	body.add_child(small_label("ACHIEVEMENTS  %d/%d" % [achievements.size(), ALL_ACHIEVEMENTS.size()], 24, Color(0.95,0.96,1.0,1.0)))
	body.add_child(make_progress_bar_section("Total haggled savings: £%.2f" % total_haggled_savings, total_haggled_savings, 5000, [50.0, 100.0, 250.0, 500.0, 1000.0, 2500.0, 5000.0], Color(0.88,0.56,0.82,1.0)))
	body.add_child(make_progress_bar_section("Lifetime profit: £%.2f" % total_lifetime_profit, max(0.0, total_lifetime_profit), 50000, [250.0, 1000.0, 2500.0, 5000.0, 10000.0, 25000.0, 50000.0], Color(0.91,0.76,0.35,1.0)))
	var progress_text = {
		"Level Headed": "Level %d/10" % player_level,
		"Challenge Crusher": "%d/30" % lifetime_challenges_completed,
		"High Roller": "%d/5 wins" % lifetime_fixer_wins,
		"Car Boot King": "£%.0f / £50,000" % cash,
	}
	var grid = HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	body.add_child(grid)
	for a in ALL_ACHIEVEMENTS.keys():
		var got = achievements.has(a)
		var panel = make_card()
		panel.custom_minimum_size = Vector2(cw(380), 0)
		grid.add_child(panel)
		var box = VBoxContainer.new()
		panel.add_child(box)
		box.add_child(small_label(("★ " if got else "") + a, 19, Color(0.95,0.84,0.40,1.0) if got else Color(0.60,0.65,0.72,1.0)))
		var d = small_label(ALL_ACHIEVEMENTS[a] + ((" (%s)" % progress_text[a]) if not got and progress_text.has(a) else ""), 15, Color(0.80,0.85,0.92,1.0) if got else Color(0.52,0.57,0.64,1.0))
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(d)

# ---------------------------------------------------------------------------
# Business goals: a simple chain that gives new players direction
# ---------------------------------------------------------------------------
var goals_done = 0
var business_goals = [
	{"text": "Make your first sale", "xp": 15},
	{"text": "Sell 5 items at a profit", "xp": 20},
	{"text": "Buy a bigger bag (Shop)", "xp": 20},
	{"text": "Reach £500 business value", "xp": 30},
	{"text": "Reach Level 3", "xp": 25},
	{"text": "Sell 25 items", "xp": 30},
	{"text": "Upgrade your home storage", "xp": 30},
	{"text": "Reach £1,000 business value", "xp": 40},
	{"text": "Find something Rare (1/125) or better", "xp": 40},
	{"text": "Reach £2,500 business value", "xp": 60},
	{"text": "Get Van Crates for carrying", "xp": 60},
	{"text": "Reach £5,000 business value", "xp": 80},
	{"text": "Reach £10,000 business value", "xp": 100},
	{"text": "Reach £25,000 business value", "xp": 150},
	{"text": "Hold £50,000 cash — Car Boot King", "xp": 250},
]

func profitable_sales_count():
	var n = 0
	for sale in sold_history:
		if sale_profit_of(sale) > 0.0:
			n += 1
	return n

func goal_met(index):
	var worth = cash + inventory_book_value()
	match index:
		0:
			return sold_history.size() >= 1
		1:
			return profitable_sales_count() >= 5
		2:
			return bag_level >= 1
		3:
			return worth >= 500.0
		4:
			return player_level >= 3
		5:
			return sold_history.size() >= 25
		6:
			return storage_level >= 1
		7:
			return worth >= 1000.0
		8:
			var best = 1
			for k in discovered_log.keys():
				best = max(best, int(discovered_log[k].get("one_in", 1)))
			return best >= 125
		9:
			return worth >= 2500.0
		10:
			return bag_level >= 3
		11:
			return worth >= 5000.0
		12:
			return worth >= 10000.0
		13:
			return worth >= 25000.0
		14:
			return cash >= 50000.0
	return false

func check_goals():
	var guard = 0
	while goals_done < business_goals.size() and goal_met(goals_done) and guard < 20:
		guard += 1
		var g = business_goals[goals_done]
		goals_done += 1
		add_xp(int(g["xp"]))
		var next_text = ("Next goal: " + business_goals[goals_done]["text"]) if goals_done < business_goals.size() else "That's every goal. You're the Car Boot King."
		show_big_popup("GOAL COMPLETE", "%s\n+%d XP\n\n%s" % [g["text"], int(g["xp"]), next_text], "achievement")

func current_goal_text():
	if goals_done >= business_goals.size():
		return "All goals complete"
	return "Goal %d/%d: %s" % [goals_done + 1, business_goals.size(), business_goals[goals_done]["text"]]

# ---------------------------------------------------------------------------
# Inventory bulk actions
# ---------------------------------------------------------------------------
func bulk_list_at_estimate():
	var listed = 0
	var skipped = 0
	var loss_skipped = 0
	for i in range(inventory.size() - 1, -1, -1):
		if i >= inventory.size():
			continue
		var item = inventory[i]
		if item["listed"] or item["auctioned"]:
			continue
		if (item["testable"] and not item["tested"]) or item["auth_status"] == "Confirmed Counterfeit":
			skipped += 1
			continue
		var pot = estimate_identified_potential(item)
		var mid = round((float(pot[0]) + float(pot[1])) / 2.0)
		var c2 = selling_costs(item, mid)
		var prof2 = mid - float(c2["fee"]) - float(c2["postage"]) - float(c2["insurance"]) - float(c2["packaging"]) - float(item["paid"]) - float(item.get("extra_spend", 0.0))
		if prof2 < 0.0:
			loss_skipped += 1
			continue
		var le = LineEdit.new()
		le.text = str(int(mid))
		create_listing_quiet(i, le)
		le.free()
		listed += 1
	add_toast("Listed %d item%s at the middle of your estimate.%s%s" % [listed, "" if listed == 1 else "s", (" Skipped %d that need testing first." % skipped) if skipped > 0 else "", (" Left %d that would sell at a loss — price those yourself." % loss_skipped) if loss_skipped > 0 else ""], "success")
	save_game()
	show_inventory()

func bulk_test_all():
	var n = 0
	for i in range(inventory.size()):
		var item = inventory[i]
		if item["testable"] and not item["tested"]:
			if cash < 2.0 or energy < 5:
				queue_popup("Ran out of cash or energy after testing %d." % n)
				break
			test_item_quiet(i)
			n += 1
	if n > 0:
		add_toast("Tested %d item%s — check the results on each card." % [n, "" if n == 1 else "s"], "info")
	show_inventory()

var cash_last_shown = -999999.0

func flash_cash_if_changed():
	if not stat_labels.has("cash"):
		return
	if cash_last_shown > -999998.0 and abs(cash - cash_last_shown) >= 0.01:
		var lbl = stat_labels["cash"]
		var up = cash > cash_last_shown
		lbl.pivot_offset = lbl.size / 2.0
		var tw = lbl.create_tween()
		lbl.modulate = Color(0.55, 1.0, 0.6, 1.0) if up else Color(1.0, 0.55, 0.5, 1.0)
		lbl.scale = Vector2(1.15, 1.15)
		tw.set_parallel(true)
		tw.tween_property(lbl, "modulate", Color(1, 1, 1, 1), 0.6)
		tw.tween_property(lbl, "scale", Vector2(1, 1), 0.25)
	cash_last_shown = cash

# Debug helpers used by the screenshot tool (not reachable from the UI)
func _debug_force_offer():
	pending_special_offer = generate_special_offer("Collector", "Arran the Collector")
	show_special_offer()

func _debug_popup(kind):
	show_big_popup("GRAIL FIND" if kind == "grail" else "LEVEL 3", "Vintage Wristwatch — a 1 in 5000 find.\nNew Collection Log entry.\n\nMost players never see one of these." if kind == "grail" else "You earned a Skill Point.", kind)

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

func tip_card(key):
	if sim_mode or tips_seen.has(key) or not TIPS.has(key):
		return null
	var card = make_card()
	var sb = card.get_theme_stylebox("panel").duplicate()
	sb.border_color = Color(0.95,0.78,0.35,0.95)
	sb.bg_color = Color(0.12,0.10,0.05,1.0)
	card.add_theme_stylebox_override("panel", sb)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var t = rich_line("[color=#e8c15a][b]Tip:[/b][/color] " + TIPS[key], 17, Color(0.92,0.90,0.84,1.0))
	row.add_child(t)
	var ok = action_button("Got it", "gold", func():
		tips_seen[key] = true
		save_settings()
		card.queue_free()
	)
	ok.custom_minimum_size = Vector2(110, 40)
	row.add_child(ok)
	return card

func add_tip(key):
	var c = tip_card(key)
	if c != null:
		body.add_child(c)
