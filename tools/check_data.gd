extends SceneTree
# Validates content data files.
# Usage: godot --headless --path . --script tools/check_data.gd -- [file ...]
# With no args, checks every scripts/data/cat_*.gd file.

const CATEGORIES = ["Clothing","Games","Trading Cards","Vinyl","Cameras","Tools","Electronics","Collectables","Jewellery","Books","Home","Musical Instruments","Garden & Outdoor"]
const REVEALS = ["look","eye","condition","test","research","deep","expert","uv","clean","sort","sale"]
const KINDS = ["good","bad","fixable","hidden_item"]
const SIZES = ["small","medium","large"]
const SEASONS = ["","Winter","Spring","Summer","Autumn"]
const FIXES = ["clean","repair","parts"]

var errors = 0
var warnings = 0

func err(msg):
	errors += 1
	print("ERROR: ", msg)

func warn(msg):
	warnings += 1
	print("warn: ", msg)

func _initialize():
	var files = OS.get_cmdline_user_args()
	if files.size() == 0:
		var d = DirAccess.open("res://scripts/data")
		for f in d.get_files():
			if f.begins_with("cat_") and f.ends_with(".gd"):
				files.append("res://scripts/data/" + f)
	var all_family_names = {}
	var all_families = []
	var all_traits = {}
	for f in files:
		var path = f if f.begins_with("res://") else "res://" + f
		var s = load(path)
		if s == null:
			err("could not load %s (parse error?)" % path)
			continue
		var consts = s.get_script_constant_map()
		if not consts.has("FAMILIES") or not consts.has("TRAITS"):
			err("%s must define const FAMILIES and const TRAITS" % path)
			continue
		for fam in consts["FAMILIES"]:
			all_families.append(fam)
			var n = str(fam.get("name", ""))
			if n == "":
				err("%s: family with no name" % path)
				continue
			if all_family_names.has(n):
				err("duplicate family name: %s" % n)
			all_family_names[n] = fam
		for tid in consts["TRAITS"]:
			if all_traits.has(tid):
				err("duplicate trait id: %s" % tid)
			all_traits[tid] = consts["TRAITS"][tid]
	var tags_seen = {}
	var per_cat = {}
	for fam in all_families:
		var n = fam["name"]
		for k in ["category","value","ask","fake","size","testable","tags","lot","blurb"]:
			if not fam.has(k):
				err("family %s missing field %s" % [n, k])
		if not CATEGORIES.has(fam.get("category", "")):
			err("family %s bad category %s" % [n, fam.get("category", "")])
		per_cat[fam.get("category","?")] = per_cat.get(fam.get("category","?"), 0) + 1
		for k in ["value","ask"]:
			var r = fam.get(k, [0,0])
			if typeof(r) != TYPE_ARRAY or r.size() != 2 or float(r[0]) <= 0 or float(r[1]) < float(r[0]):
				err("family %s bad %s range %s" % [n, k, str(r)])
		if float(fam.get("ask",[0,0])[1]) > float(fam.get("value",[0,1])[1]) * 1.05:
			warn("family %s ask max above value max" % n)
		if not SIZES.has(fam.get("size", "")):
			err("family %s bad size" % n)
		if not SEASONS.has(str(fam.get("season", ""))):
			err("family %s bad season" % n)
		if str(fam.get("blurb","")).length() > 90:
			warn("family %s blurb long (%d)" % [n, str(fam["blurb"]).length()])
		for t in fam.get("tags", []):
			tags_seen[t] = tags_seen.get(t, 0) + 1
	for tid in all_traits:
		var t = all_traits[tid]
		for k in ["name","cats","kind","weight","mult","reveal","found"]:
			if not t.has(k):
				err("trait %s missing %s" % [tid, k])
		if not KINDS.has(t.get("kind", "")):
			err("trait %s bad kind %s" % [tid, t.get("kind","")])
		if not REVEALS.has(t.get("reveal", "")):
			err("trait %s bad reveal %s" % [tid, t.get("reveal","")])
		if t.has("clue_by") and not REVEALS.has(t["clue_by"]):
			err("trait %s bad clue_by %s" % [tid, t["clue_by"]])
		if t.has("clue_by") and not t.has("clue"):
			err("trait %s has clue_by but no clue" % tid)
		if t.get("reveal", "") in ["eye","expert"] and not t.has("tier"):
			err("trait %s reveal %s needs tier" % [tid, t["reveal"]])
		for c in t.get("cats", []):
			if not CATEGORIES.has(c):
				err("trait %s bad cat %s" % [tid, c])
		var fams = t.get("families", [])
		for fn in fams:
			if not all_family_names.has(fn):
				err("trait %s references unknown family %s" % [tid, fn])
		var tags_any = t.get("tags_any", [])
		for tg in tags_any:
			if not tags_seen.has(tg):
				err("trait %s references tag %s that no family has" % [tid, tg])
		var m = t.get("mult", [1,1])
		if typeof(m) != TYPE_ARRAY or m.size() != 2 or float(m[1]) < float(m[0]):
			err("trait %s bad mult" % tid)
		var kind = t.get("kind","")
		if kind == "good" and float(m[0]) < 1.0:
			err("trait %s good but mult < 1" % tid)
		if kind in ["bad","fixable"] and float(m[1]) > 1.0:
			err("trait %s bad but mult > 1" % tid)
		if kind == "fixable":
			if not FIXES.has(t.get("fix","")):
				err("trait %s fixable needs fix in %s" % [tid, str(FIXES)])
			if not t.has("fix_mult"):
				err("trait %s fixable needs fix_mult" % tid)
		if kind == "hidden_item":
			var sp = t.get("spawn", {})
			if typeof(sp) != TYPE_DICTIONARY or not sp.has("families"):
				err("trait %s hidden_item needs spawn.families" % tid)
			else:
				for fn in sp["families"]:
					if not all_family_names.has(fn):
						err("trait %s spawn references unknown family %s" % [tid, fn])
			if t.get("reveal","") != "sort":
				warn("trait %s hidden_item usually uses reveal sort" % tid)
		# eligibility: at least one family can get this trait
		var eligible = 0
		for fam in all_families:
			if not t.get("cats", []).has(fam["category"]):
				continue
			if fams.size() > 0 and not fams.has(fam["name"]):
				continue
			if tags_any.size() > 0:
				var ok = false
				for tg in tags_any:
					if fam.get("tags", []).has(tg):
						ok = true
				if not ok:
					continue
			if kind == "hidden_item" and not fam.get("lot", false):
				continue
			if t.get("reveal","") == "test" and not fam.get("testable", false):
				continue
			eligible += 1
		if eligible == 0:
			err("trait %s applies to no family" % tid)
		for k in ["clue","found","missed"]:
			if str(t.get(k, "")).length() > 110:
				warn("trait %s %s long (%d chars)" % [tid, k, str(t[k]).length()])
	# per-family trait coverage
	for fam in all_families:
		var good = 0
		var bad = 0
		for tid in all_traits:
			var t = all_traits[tid]
			if not t.get("cats", []).has(fam["category"]):
				continue
			var fams = t.get("families", [])
			if fams.size() > 0 and not fams.has(fam["name"]):
				continue
			var tags_any = t.get("tags_any", [])
			if tags_any.size() > 0:
				var ok = false
				for tg in tags_any:
					if fam.get("tags", []).has(tg):
						ok = true
				if not ok:
					continue
			if t["kind"] == "good" or t["kind"] == "hidden_item":
				good += 1
			else:
				bad += 1
		if good < 2 or bad < 2:
			warn("family %s has few traits (good %d, bad %d)" % [fam["name"], good, bad])
	print("families: %d  traits: %d  per category: %s" % [all_families.size(), all_traits.size(), str(per_cat)])
	print("RESULT errors=%d warnings=%d" % [errors, warnings])
	quit(1 if errors > 0 else 0)
