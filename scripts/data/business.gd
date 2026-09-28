extends RefCounted
# Business progression data: premises, vehicles, workshop equipment, seller accounts, staff, perks.

const PREMISES = [
	{"id":"box_room","name":"Box Room","storage":18,"slots":1,"listings":8,"cost":0,"rent":0.0,
		"desc":"A spare room with a wobbly shelf. Everything smells faintly of old cardboard."},
	{"id":"garage","name":"Rented Garage","storage":40,"slots":2,"listings":14,"cost":450,"rent":3.0,
		"desc":"A lock-up garage behind the flats. Room for a proper bench and a strip light."},
	{"id":"lockup","name":"Industrial Lock-up","storage":80,"slots":3,"listings":22,"cost":1600,"rent":8.0,
		"desc":"A unit on the trading estate with a roller door and a kettle. Now you're a business."},
	{"id":"shop","name":"High Street Shop","storage":140,"slots":4,"listings":32,"cost":5500,"rent":20.0,
		"desc":"A little shop with a bell over the door. Walk-in customers buy straight off the shelf.",
		"unlocks":["Shop floor: display stock for walk-in customers (no fees or postage)"]},
	{"id":"warehouse","name":"Warehouse","storage":320,"slots":6,"listings":50,"cost":16000,"rent":45.0,
		"desc":"Racking to the ceiling, a loading bay and a forklift you're not insured to drive.",
		"unlocks":["Trade buyers take bulk stock at fair prices", "Space for a full team"]},
]

const VEHICLES = [
	{"id":"foot","name":"On Foot","carry":6,"cost":0,"fuel":0.0,"desc":"Two hands and a bag for life."},
	{"id":"trolley","name":"Shopping Trolley","carry":10,"cost":60,"fuel":0.0,"desc":"A folding tartan trolley. Squeaks, but holds a surprising amount."},
	{"id":"estate","name":"Old Estate Car","carry":18,"cost":700,"fuel":3.0,"desc":"Rear seats down, boot full. Gets you to the Collectors' Fairs out of town.",
		"unlocks":["Collectors' Fairs"]},
	{"id":"van","name":"Panel Van","carry":30,"cost":2400,"fuel":6.0,"desc":"A second-hand van with somebody else's logo half-scraped off.",
		"unlocks":["House clearances"]},
	{"id":"luton","name":"Luton Box Van","carry":48,"cost":7000,"fuel":10.0,"desc":"A tail-lift and a box the size of a bedroom.",
		"unlocks":["Large house clearances"]},
]

# Workshop equipment. Each level takes one workshop slot (upgrading an existing machine doesn't take another).
const EQUIPMENT = {
	"shelving": {"name":"Heavy-Duty Shelving","icon":"shelf","levels":[
		{"name":"Heavy-Duty Shelving","cost":100,"desc":"+12 storage space."},
		{"name":"Racking","cost":450,"desc":"+30 storage space in total."}]},
	"cleaning": {"name":"Cleaning Station","icon":"clean","levels":[
		{"name":"Cleaning Station","cost":120,"desc":"Clean items at home: fixes grime and tarnish, can reveal marks hidden under dirt, sometimes improves condition."}]},
	"repair": {"name":"Repair Bench","icon":"repair","levels":[
		{"name":"Repair Bench","cost":90,"desc":"Attempt repairs on faults and broken parts."},
		{"name":"Electronics Bench","cost":320,"desc":"Better repair odds, especially on electrical faults."},
		{"name":"Full Workshop","cost":950,"desc":"Best repair odds. Major faults become realistic to fix."}]},
	"test_rig": {"name":"Test Rig","icon":"test","levels":[
		{"name":"Test Rig","cost":160,"desc":"Testing is free and takes half the time and energy."}]},
	"photo": {"name":"Photo Corner","icon":"photo","levels":[
		{"name":"Photo Corner","cost":80,"desc":"Clean backdrop and a lamp: listings attract more buyers."},
		{"name":"Light-Box Studio","cost":420,"desc":"Proper product photos: listings attract a lot more buyers, +4 listing slots."}]},
	"auth": {"name":"Authentication Kit","icon":"auth","levels":[
		{"name":"Authentication Kit","cost":350,"desc":"UV lamp, loupe and scales. Authenticate in-house for £2, and run UV checks that expose repaints, restorations and fake signatures."}]},
	"parts": {"name":"Parts Bin","icon":"parts","levels":[
		{"name":"Parts Bin","cost":60,"desc":"Drawers of knobs, caps, keys and battery doors. Fixes items with missing small parts."}]},
	"packing": {"name":"Packing Station","icon":"pack","levels":[
		{"name":"Packing Station","cost":260,"desc":"Bulk boxes and bubble wrap: no packaging costs, postage 15% cheaper."}]},
	"library": {"name":"Reference Library","icon":"book","levels":[
		{"name":"Reference Library","cost":220,"desc":"Price guides and back issues: Research is free and teaches you twice as much. Deep Research is 30% cheaper."}]},
}

const ACCOUNTS = [
	{"name":"Casual Seller","fee":0.115,"cost":0,"sales":0,"rating":0},
	{"name":"Registered Seller","fee":0.095,"cost":300,"sales":20,"rating":0},
	{"name":"Business Account","fee":0.075,"cost":1200,"sales":60,"rating":85},
	{"name":"Trade Account","fee":0.055,"cost":3500,"sales":150,"rating":90},
	{"name":"Power Seller","fee":0.040,"cost":9000,"sales":300,"rating":95},
]

const STAFF = {
	"assistant": {"name":"Assistant","wage":22.0,"needs":2,"desc":"Works your stock overnight: tests untested electricals, cleans grimy items (if you have a Cleaning Station) and trims 10% off listings that have sat for a week."},
	"shopkeeper": {"name":"Shop Keeper","wage":28.0,"needs":3,"desc":"Keeps the shop open all day: doubles walk-in customers on the shop floor."},
	"picker": {"name":"Picker","wage":35.0,"needs":4,"desc":"Works the car boot for you before you arrive: reveals extra items at every stall and keeps the rival honest."},
}

# Perks: one skill point per level. Mechanical, not +x% filler where possible.
const PERKS = [
	{"id":"early_bird","branch":"Buying","name":"Early Bird","cost":1,"requires":"","desc":"Arrive at 6:30 instead of 7:00: half an hour before most rivals."},
	{"id":"silver_tongue","branch":"Buying","name":"Silver Tongue","cost":1,"requires":"","desc":"When a seller rejects your offer, they come back with a counter-offer you can take."},
	{"id":"regulars_rate","branch":"Buying","name":"Regular's Rate","cost":2,"requires":"silver_tongue","desc":"Sellers who count you as a regular knock 10% off everything on their table."},
	{"id":"poker_face","branch":"Buying","name":"Poker Face","cost":1,"requires":"","desc":"Lowball offers never get you thrown off a stall, and cost half the goodwill."},
	{"id":"charmer","branch":"Buying","name":"Charmer","cost":2,"requires":"poker_face","desc":"Regulars warm to you twice as fast."},
	{"id":"keen_eye","branch":"Knowing","name":"Keen Eye","cost":1,"requires":"","desc":"+12% Inspect reliability in every category."},
	{"id":"hunch","branch":"Knowing","name":"Hunch","cost":2,"requires":"keen_eye","desc":"Inspecting tells you whether there's anything hidden about an item, good or bad."},
	{"id":"quick_study","branch":"Knowing","name":"Quick Study","cost":1,"requires":"","desc":"Earn expertise 50% faster in every category."},
	{"id":"polymath","branch":"Knowing","name":"Polymath","cost":3,"requires":"quick_study","desc":"Count as at least Enthusiast (tier 1) in every category."},
	{"id":"good_photos","branch":"Selling","name":"Good Photos","cost":1,"requires":"","desc":"Listings attract more buyers (stacks with the Photo Corner)."},
	{"id":"trade_contacts","branch":"Selling","name":"Trade Contacts","cost":1,"requires":"","desc":"Traders offer 55–75% of value instead of 40–60%."},
	{"id":"auctioneer","branch":"Selling","name":"Auctioneer","cost":2,"requires":"","desc":"Auctions unlock straight away and the auction house fee drops to 2%."},
	{"id":"thick_skin","branch":"Selling","name":"Thick Skin","cost":1,"requires":"","desc":"Returns only knock your seller rating half as much."},
	{"id":"frugal","branch":"Selling","name":"Frugal","cost":2,"requires":"","desc":"Rent, fuel, wages and pitch fees cost 15% less."},
]
