extends Node
## Autoload. Loads the 30 customer rows from the data table Resource file and
## builds each night's customers. It also holds the fixed content the rows
## refer to: the nine goods, the six regulars, the day visitors, and the looks.
## It never changes a resource. Only GameState does that (Section 8.5).

const TABLE_PATH := "res://data/customer_table.tres"

const NIGHT_COUNT := 5

## The nine goods on the store's price list, Section II and Table 23.
const ITEMS := {
	"piyatos": {"name": "Piyatos", "price": 15, "icon": "res://art/Items/Piyatos.png"},
	"chipis": {"name": "Chipis", "price": 15, "icon": "res://art/Items/Chipi.png"},
	"robisco": {"name": "Robisco", "price": 10, "icon": "res://art/Items/Robisco.png"},
	"kornbip": {"name": "Kornbip", "price": 25, "icon": "res://art/Items/Kornbip.png"},
	"sardins": {"name": "Sardins", "price": 30, "icon": "res://art/Items/Sardins.png"},
	"7down": {"name": "7-Down", "price": 10, "icon": "res://art/Items/7Down.png"},
	"kola": {"name": "Kola", "price": 10, "icon": "res://art/Items/Kola.png"},
	"surp": {"name": "Surp", "price": 10, "icon": "res://art/Items/Surp.png"},
	"palmolib": {"name": "Palmolib", "price": 40, "icon": "res://art/Items/Palmolib.png"},
}

## Day catalogue, Section II. Slot order matches buy_1 to buy_3 in Table 21.
const CATALOGUE := [
	{"id": "salt", "name": "Salt", "price": 15},
	{"id": "battery", "name": "Battery pack", "price": 25},
	{"id": "salabat", "name": "Salabat", "price": 20},
]

const ASSETS := "res://art/"

## Sprite looks. bbox is the drawn area in the source image, in source pixels.
## Face anchors are fractions of the bbox: eye centre and half the eye gap,
## mouth, and neck. height is the drawn height on the 1280 x 720 screen.
const LOOKS := {
	"mang_ador": {"tex": ASSETS + "Civilian Sprites/OldGeezer5.png", "talk": "", "src": 4096,
		"bbox": Rect2(179, 768, 3333, 3328), "height": 225.0,
		"eyes": Vector2(0.62, 0.30), "eye_gap": 0.07, "mouth": Vector2(0.62, 0.41), "neck": Vector2(0.60, 0.56)},
	"aling_bebang": {"tex": ASSETS + "Civilian Sprites/OldHag6.png", "talk": ASSETS + "Civilian Sprites/OldHag6 Yapping.png", "src": 4096,
		"bbox": Rect2(773, 479, 2677, 3617), "height": 280.0,
		"eyes": Vector2(0.52, 0.36), "eye_gap": 0.10, "mouth": Vector2(0.52, 0.47), "neck": Vector2(0.52, 0.56)},
	"aling_nena": {"tex": ASSETS + "Civilian Sprites/FS2.png", "talk": ASSETS + "Civilian Sprites/FS2 Yapping.png", "src": 4096,
		"bbox": Rect2(607, 97, 2943, 3999), "height": 285.0,
		"eyes": Vector2(0.52, 0.37), "eye_gap": 0.09, "mouth": Vector2(0.51, 0.47), "neck": Vector2(0.50, 0.55)},
	"kuya_migo": {"tex": ASSETS + "Civilian Sprites/MS4.png", "talk": ASSETS + "Civilian Sprites/MS4 Yapping.png", "src": 4096,
		"bbox": Rect2(287, 404, 3632, 3692), "height": 235.0,
		"eyes": Vector2(0.50, 0.42), "eye_gap": 0.12, "mouth": Vector2(0.48, 0.57), "neck": Vector2(0.48, 0.68)},
	"ate_joy": {"tex": ASSETS + "Civilian Sprites/FS1.png", "talk": ASSETS + "Civilian Sprites/FS1 Yapping.png", "src": 4096,
		"bbox": Rect2(526, 430, 3060, 3666), "height": 262.0,
		"eyes": Vector2(0.54, 0.38), "eye_gap": 0.11, "mouth": Vector2(0.55, 0.50), "neck": Vector2(0.53, 0.62)},
	"pia": {"tex": ASSETS + "Civilian Sprites/KidSpr3.png", "talk": ASSETS + "Civilian Sprites/KidSpr3 Yapping.png", "src": 4096,
		"bbox": Rect2(864, 997, 2306, 3099), "height": 215.0,
		"eyes": Vector2(0.51, 0.45), "eye_gap": 0.11, "mouth": Vector2(0.51, 0.55), "neck": Vector2(0.51, 0.63)},
	"stranger": {"tex": ASSETS + "Civilian Sprites/maleSprite.png", "talk": "", "src": 1280,
		"bbox": Rect2(362, 130, 436, 844), "height": 300.0,
		"eyes": Vector2(0.53, 0.34), "eye_gap": 0.13, "mouth": Vector2(0.52, 0.45), "neck": Vector2(0.52, 0.56)},
}

## Shared variant set for every stranger, human or entity (6.4).
const STRANGER_VARIANTS := [
	{"tint": Color(1, 1, 1), "flip": false},
	{"tint": Color(0.82, 0.88, 1.0), "flip": true},
	{"tint": Color(1.0, 0.9, 0.76), "flip": false},
	{"tint": Color(0.84, 1.0, 0.86), "flip": true},
	{"tint": Color(1.0, 0.84, 0.86), "flip": false},
	{"tint": Color(0.9, 0.86, 1.0), "flip": true},
]

## True forms for jump scares and banishing.
const TRUE_FORMS := {
	"aswang": ASSETS + "Kapre-Dugang Entities/Aswang Baseform s3.png",
	"tiktik": ASSETS + "Kapre-Dugang Entities/Tiktik Baseform s1.png",
	"kapre": ASSETS + "Kapre-Dugang Entities/Kapre Baseform s4.png",
	"manananggal": ASSETS + "Kapre-Dugang Entities/mananaggal s2.png",
}

## Drawn area of each true form in its source image, for sizing.
const TRUE_FORM_BBOX := {
	"aswang": {"src": 912, "bbox": Rect2(176, 63, 557, 1102)},
	"tiktik": {"src": 912, "bbox": Rect2(159, 48, 609, 1117)},
	"kapre": {"src": 912, "bbox": Rect2(71, 80, 728, 1085)},
	"manananggal": {"src": 4096, "bbox": Rect2(1083, 374, 1956, 2927)},
}

## Each entity type's folklore sign, its face tell under the UV lamp (Section II).
const SIGNS := {
	"aswang": "fangs and a stitched neck",
	"tiktik": "red eyes",
	"kapre": "a lit cigar",
	"manananggal": "a split at the waist",
}

## The six regulars. One personal detail each, learned by one day chat.
## past_debts are Lola's old ledger lines. They are story only.
const REGULARS := {
	"mang_ador": {"name": "Mang Ador", "usual": "sardins", "detail": "Wife is Aling Rosa",
		"chat": "Your Lola and my wife Rosa played cards here every Friday. Rosa still keeps her deck.",
		"past_debts": ["Sardins, PHP 35, paid"]},
	"aling_bebang": {"name": "Aling Bebang", "usual": "palmolib", "detail": "Grandson Toto serves at the chapel",
		"chat": "Your Lola always set a Palmolib aside for me. My grandson Toto serves at the chapel now. I might try a new brand soon, apo.",
		"past_debts": ["Palmolib, PHP 45, paid"]},
	"aling_nena": {"name": "Aling Nena", "usual": "kola", "detail": "Son is Migo",
		"chat": "Your Lola always saved the last Piyatos for my son Migo.",
		"past_debts": []},
	"kuya_migo": {"name": "Kuya Migo", "usual": "7down", "detail": "Works the night oven at the bakery",
		"chat": "Lola let me pay for my 7-Down when the bakery paid me. I work the night oven.",
		"past_debts": ["7-Down, PHP 15, paid", "7-Down, PHP 15, paid", "Piyatos, PHP 20, paid", "7-Down, PHP 15, paid", "Kola, PHP 15, paid"]},
	"ate_joy": {"name": "Ate Joy", "usual": "chipis", "detail": "Studies nursing",
		"chat": "Lola gave me Chipis on credit all through my first year of nursing school.",
		"past_debts": ["Chipis, PHP 20, paid"]},
	"pia": {"name": "Pia", "usual": "robisco", "detail": "Her cat is Mingming",
		"chat": "Lola always saved a little Robisco for Mingming. Mingming is my cat.",
		"past_debts": []},
}

## Three regulars visit each day. Day 2's first visitor is always Aling Bebang.
const DAY_VISITORS := {
	1: ["ate_joy", "pia", "kuya_migo"],
	2: ["aling_bebang", "aling_nena", "mang_ador"],
	3: ["kuya_migo", "mang_ador", "ate_joy"],
	4: ["pia", "aling_nena", "aling_bebang"],
	5: ["ate_joy", "mang_ador", "kuya_migo"],
}

## Fixed counts per night from 6.4. Night 1 has none.
const WARN_ENTITIES := {2: 1, 3: 1, 4: 2, 5: 2}
const WARN_HUMANS := {2: 0, 3: 1, 4: 1, 5: 1}
const DECOYS := {2: 1, 3: 1, 4: 1, 5: 2}

var rows: Array = []


func _ready() -> void:
	var table: CustomerTable = load(TABLE_PATH)
	rows = table.rows
	assert(rows.size() == 30, "The data table must hold 30 customer rows.")


func rows_for_night(night: int) -> Array:
	var out: Array = []
	for r in rows:
		if r.night == night:
			out.append(r)
	out.sort_custom(func(a, b): return a.slot < b.slot)
	return out


func item_name(item_id: String) -> String:
	return ITEMS[item_id]["name"] if ITEMS.has(item_id) else item_id


func item_price(item_id: String) -> int:
	return ITEMS[item_id]["price"] if ITEMS.has(item_id) else 0


## Shuffles from 6.4, made once per run from the seed. A retry uses the same
## seed, so it replays the same shuffle. Returns row id -> {warned, decoy, ...}.
func make_plan(run_seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = run_seed
	var plan := {}
	for r in rows:
		plan[r.id] = {"warned": r.warn == "fixed", "decoy": "", "variant": 0, "alt_order": ""}
		if r.decoy in ["order", "face", "cash"]:
			plan[r.id]["decoy"] = r.decoy
		if r.kind == "stranger":
			plan[r.id]["variant"] = rng.randi_range(0, STRANGER_VARIANTS.size() - 1)
	for night in range(2, NIGHT_COUNT + 1):
		var night_rows := rows_for_night(night)
		var entities := night_rows.filter(func(r): return r.is_entity)
		var humans := night_rows.filter(func(r): return not r.is_entity)
		# Entity warnings: fixed ones first, then shuffled pool rows to the count.
		var need: int = WARN_ENTITIES[night] - entities.filter(func(r): return r.warn == "fixed").size()
		var pool := _shuffled(entities.filter(func(r): return r.warn == "pool"), rng)
		for i in range(min(need, pool.size())):
			plan[pool[i].id]["warned"] = true
		# Human warnings. A human never gets more than one decoy, warning, or smear.
		need = WARN_HUMANS[night] - humans.filter(func(r): return r.warn == "fixed").size()
		pool = _shuffled(humans.filter(func(r): return r.warn == "pool" and r.tampered_usual == ""), rng)
		for i in range(min(need, pool.size())):
			plan[pool[i].id]["warned"] = true
		# Decoys on humans who carry no other misleading signal.
		need = DECOYS[night] - humans.filter(func(r): return r.decoy in ["order", "face", "cash"]).size()
		pool = _shuffled(humans.filter(func(r): return r.decoy == "pool" and not plan[r.id]["warned"] and r.tampered_usual == ""), rng)
		for i in range(min(need, pool.size())):
			var r: CustomerRow = pool[i]
			var spots := ["face", "cash", "order"] if r.kind == "regular" else ["face", "cash"]
			var spot: String = spots[rng.randi_range(0, spots.size() - 1)]
			plan[r.id]["decoy"] = spot
			if spot == "face":
				plan[r.id]["decoy_sign"] = SIGNS.keys()[rng.randi_range(0, SIGNS.size() - 1)]
			if spot == "order":
				var options := ITEMS.keys().filter(func(k): return k != REGULARS[r.regular_id]["usual"])
				plan[r.id]["alt_order"] = options[rng.randi_range(0, options.size() - 1)]
	return plan


func _shuffled(arr: Array, rng: RandomNumberGenerator) -> Array:
	var a := arr.duplicate()
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = a[i]
		a[i] = a[j]
		a[j] = t
	return a


## Builds tonight's customers as plain dictionaries the scenes can read.
## known: regular ids whose personal detail is in the ledger.
## returning: entities served on utang last night, in the order served.
func build_night(night: int, plan: Dictionary, known: Dictionary, returning: Array) -> Array:
	var out: Array = []
	var queue := returning.duplicate()
	var night_rows := rows_for_night(night)
	# Returning entities take the replaceable slots in order 1 then 2.
	var slot_map := {}
	for want in [1, 2]:
		if queue.is_empty():
			break
		for r in night_rows:
			if r.replaceable == want:
				slot_map[r.id] = queue.pop_front()
				break
	var index := 0
	for r in night_rows:
		var c: Dictionary
		if slot_map.has(r.id):
			c = _returning_customer(slot_map[r.id], r, plan)
		else:
			c = _resolve(r, plan.get(r.id, {}), known)
		c["index"] = index
		out.append(c)
		index += 1
	return out


func _resolve(r: CustomerRow, p: Dictionary, known: Dictionary) -> Dictionary:
	var c := {
		"id": r.id, "night": r.night, "slot": r.slot, "kind": r.kind,
		"regular_id": r.regular_id, "is_entity": r.is_entity, "entity_type": r.entity_type,
		"order": r.order, "payment": r.payment, "line": r.line, "teach": r.teach,
		"warned": p.get("warned", false), "decoy": p.get("decoy", ""), "returning": false,
		"face_tell": "", "cash_tell": false, "ledger_mismatch": "", "smeared": r.tampered_usual != "",
	}
	if r.kind == "regular":
		var reg: Dictionary = REGULARS[r.regular_id]
		c["name"] = reg["name"]
		c["look"] = r.regular_id
		c["ledger"] = {
			"name": reg["name"],
			"usual": r.tampered_usual if r.tampered_usual != "" else reg["usual"],
			"detail": reg["detail"] if known.has(r.regular_id) else "",
			"past_debts": reg["past_debts"],
			"smeared": r.tampered_usual != "",
		}
	else:
		c["name"] = "Stranger"
		c["look"] = "stranger"
		c["variant"] = p.get("variant", 0)
		c["ledger"] = {"name": "", "usual": "", "detail": "", "past_debts": [], "smeared": false}
	if r.is_entity:
		if r.ledger_tell and r.tampered_usual == "":
			# A copy of a regular the player chatted with gets the personal
			# detail wrong. A copy of any other regular gets the order wrong.
			if known.has(r.regular_id):
				c["order"] = r.known_order
				c["line"] = r.known_line
				c["ledger_mismatch"] = "detail"
			else:
				c["ledger_mismatch"] = "order"
			if "face" in r.uv_tells:
				c["face_tell"] = r.entity_type
			else:
				c["cash_tell"] = true
		else:
			# No usable ledger tell, so both tells show under the UV lamp.
			c["face_tell"] = r.entity_type
			c["cash_tell"] = true
	else:
		match c["decoy"]:
			"face":
				c["face_tell"] = p.get("decoy_sign", "tiktik")
			"cash":
				c["cash_tell"] = true
			"order":
				if r.decoy == "pool":
					c["order"] = p.get("alt_order", r.order)
					c["line"] = "%s tonight, please. Just this once." % item_name(c["order"])
	c["price"] = item_price(c["order"])
	c["item_name"] = item_name(c["order"])
	return c


func _returning_customer(prev: Dictionary, slot_row: CustomerRow, plan: Dictionary) -> Dictionary:
	var c := prev.duplicate(true)
	c["id"] = slot_row.id
	c["night"] = slot_row.night
	c["slot"] = slot_row.slot
	c["returning"] = true
	c["warned"] = plan.get(slot_row.id, {}).get("warned", false)
	c["decoy"] = ""
	c["teach"] = "returning"
	# Table 11: both tells show at once under the UV lamp.
	c["face_tell"] = c["entity_type"]
	c["cash_tell"] = true
	c["ledger_mismatch"] = ""
	return c


## Clue text for the dawn report, 6.3. Names the clue that was missed or misread.
func clue_for(c: Dictionary, decision: String) -> String:
	var correct: bool = (decision in ["serve", "serve_utang"]) != c["is_entity"]
	if correct:
		return ""
	if c["is_entity"]:
		var parts: Array = []
		match c["ledger_mismatch"]:
			"order":
				parts.append("the order: it was %s, but the ledger says %s" % [c["item_name"], item_name(c["ledger"]["usual"])])
			"detail":
				parts.append("the personal detail: the ledger says %s, but the customer said otherwise" % c["ledger"]["detail"].to_lower())
		if c["face_tell"] != "":
			parts.append("%s on the face under the UV lamp" % SIGNS[c["face_tell"]])
		if c["cash_tell"]:
			parts.append("cash that turned into leaves under the UV lamp")
		var text := "You missed " + " and ".join(parts) + "."
		if c["returning"]:
			text += " It came back for its debt."
		return text
	# A human was turned away. Name what was misread.
	if c["smeared"]:
		return "The ledger entry had fresh ink, so the wrong order was not a tell."
	match c["decoy"]:
		"face":
			return "One sign on the face was only a decoy. A human never shows two tells."
		"cash":
			return "Leaves in the cash were only a decoy. A human never shows two tells."
		"order":
			return "One odd order was only a decoy. A human never shows two tells."
	if c["warned"]:
		return "The warning sound was false. A warning is a hint, not proof."
	return "This neighbor showed no tells at all."
