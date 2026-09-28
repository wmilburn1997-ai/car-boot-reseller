extends RefCounted
# Loads and indexes all item families and discovery traits from scripts/data/cat_*.gd.

const FILES = [
	"res://scripts/data/cat_vinyl_books_cards.gd",
	"res://scripts/data/cat_tech.gd",
	"res://scripts/data/cat_collect_games.gd",
	"res://scripts/data/cat_wear.gd",
	"res://scripts/data/cat_house.gd",
]
const World = preload("res://scripts/data/world.gd")

var families = []            # Array of family dicts
var family_by_name = {}      # name -> family
var families_by_cat = {}     # category -> [family]
var traits = {}              # id -> trait dict (with "id" added)
var family_traits = {}       # family name -> {"good":[ids], "bad":[ids], "hidden":[ids]}

func _init():
	for path in FILES:
		var s = load(path)
		if s == null:
			push_error("Content: failed to load " + path)
			continue
		var c = s.get_script_constant_map()
		for fam in c["FAMILIES"]:
			var f = fam.duplicate(true)
			if not f.has("season"):
				f["season"] = ""
			families.append(f)
			family_by_name[f["name"]] = f
			if not families_by_cat.has(f["category"]):
				families_by_cat[f["category"]] = []
			families_by_cat[f["category"]].append(f)
		for tid in c["TRAITS"]:
			var t = c["TRAITS"][tid].duplicate(true)
			t["id"] = tid
			traits[tid] = t
	for f in families:
		var entry = {"good": [], "bad": [], "hidden": []}
		for tid in traits:
			var t = traits[tid]
			if trait_applies(t, f):
				match t["kind"]:
					"good":
						entry["good"].append(tid)
					"bad", "fixable":
						entry["bad"].append(tid)
					"hidden_item":
						entry["hidden"].append(tid)
		family_traits[f["name"]] = entry

func trait_applies(t, f):
	if not t.get("cats", []).has(f["category"]):
		return false
	var fams = t.get("families", [])
	if fams.size() > 0 and not fams.has(f["name"]):
		return false
	var tags_any = t.get("tags_any", [])
	if tags_any.size() > 0:
		var ok = false
		for tg in tags_any:
			if f.get("tags", []).has(tg):
				ok = true
				break
		if not ok:
			return false
	if t["kind"] == "hidden_item" and not f.get("lot", false):
		return false
	if t.get("reveal", "") == "test" and not f.get("testable", false):
		return false
	return true

func get_trait(tid):
	return traits.get(tid, null)

func family(name):
	return family_by_name.get(name, null)
