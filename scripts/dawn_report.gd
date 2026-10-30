extends Control
## The dawn report. Lists each call by name, marks each wrong call and the clue
## that was missed or misread, and shows correct calls, Sanity, Pesos, and
## repaid utang, plus one page of Lola's story (1.4 and Table 18).

const VERBS := {"serve": "served", "serve_utang": "gave utang to", "refuse": "refused", "banish": "banished"}

@onready var call_list: VBoxContainer = $CallList
@onready var lola_page: TextureRect = $LolaPage
@onready var page_text: Label = $LolaPage/PageText
@onready var next_button: Button = $NextButton
@onready var title: Label = $Title
@onready var summary: Label = $Summary
@onready var star: Label = $Star


## One call in plain words, such as "You served Mang Ador, who ordered
## Sardins." Entities are named once the night is over.
func _describe(e: Dictionary) -> String:
	var who: String = "a stranger" if e["name"] == "Stranger" else e["name"]
	var text := "You %s %s, who ordered %s." % [VERBS.get(e["decision"], e["decision"]), who, e["item"]]
	if e["is_entity"]:
		var kind: String = e.get("entity_type", "")
		text += " It was %s." % (("an " if kind == "aswang" else "a ") + kind) if kind != "" else " It was an entity."
	return text


func _ready() -> void:
	if not can_process():
		return
	var r: Dictionary = GameState.last_report
	if r.is_empty():
		return
	title.text = "6 AM. Night %d survived." % r["night"]
	for e in r["calls"]:
		var row := Label.new()
		row.text = "%s    %s" % ["RIGHT" if e["correct"] else "WRONG", _describe(e)]
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.custom_minimum_size = Vector2(620, 0)
		row.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7) if e["correct"] else Color(1.0, 0.62, 0.55))
		row.add_theme_font_size_override("font_size", 17)
		call_list.add_child(row)
		if not e["correct"] and e["clue"] != "":
			var clue := Label.new()
			clue.text = e["clue"]
			clue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			clue.custom_minimum_size = Vector2(580, 0)
			clue.add_theme_font_size_override("font_size", 15)
			clue.add_theme_color_override("font_color", Color(1.0, 0.85, 0.75))
			var indent := MarginContainer.new()
			indent.add_theme_constant_override("margin_left", 66)
			indent.add_child(clue)
			call_list.add_child(indent)
	var repaid := ""
	if r["repaid"].size() > 0:
		var names: Array = []
		for d in r["repaid"]:
			names.append("%s PHP %d" % [d["name"], d["amount"]])
		repaid = "Utang repaid: " + ", ".join(names)
	else:
		repaid = "Utang repaid: none"
	summary.text = "Correct calls tonight: %d of %d\nCorrect calls so far: %d of %d\nSanity at 6 AM: %d. After the dawn rest: %d.\nPesos: %d\n%s" % [
		r["correct_tonight"], r["calls"].size(), r["correct_total"], GameState.TOTAL_CALLS,
		r["sanity_before"], r["sanity_after"], r["pesos"], repaid]
	star.visible = r["star"]
	if r["last"]:
		page_text.text = "Behind the last page of Lola's ledger, one more page is folded shut.\n\nYou kept the counter for five nights."
		next_button.text = "Read the last page"
	else:
		page_text.text = "Lola's page %d\n\n%s" % [r["night"], r["page"]]
		next_button.text = "Start Day %d" % (r["night"] + 1)
	if int(r.get("saved_slot", -1)) > 0:
		var saved := Label.new()
		saved.text = "Progress saved to Slot %d." % int(r["saved_slot"])
		saved.position = Vector2(724, 596)
		saved.size = Vector2(526, 24)
		saved.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		saved.add_theme_font_size_override("font_size", 16)
		saved.add_theme_color_override("font_color", Color(1.0, 0.92, 0.7))
		saved.add_theme_constant_override("outline_size", 6)
		saved.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02))
		add_child(saved)
	next_button.grab_focus()
	Sfx.play(self, "bell", -3.0)
