extends PanelContainer
## How to Play page, from the main menu and the pause menu.

@onready var text: RichTextLabel = $Box/Text
@onready var back: Button = $Box/Back


func _ready() -> void:
	back.pressed.connect(close)
	text.text = _build()


func open() -> void:
	Sfx.play(self, "click")
	visible = true
	text.scroll_to_line(0)
	back.grab_focus()


func close() -> void:
	Sfx.play(self, "click")
	visible = false


func _build() -> String:
	var t := "[font_size=30][b]How to Play[/b][/font_size]\n\n"
	t += "[b]Goal[/b]\nKeep Lola's store open for five nights. You win when you reach 6 AM on Night 5 with Sanity above 0 and fewer than 3 refused entities waiting at the window.\n\n"
	t += "[b]By day[/b]\nBuy Salt, battery packs, or salabat from the catalogue. Three regulars come to the window. Click up to two of them to chat. Each chat writes one personal detail about that regular into Lola's ledger. Press Open at 6 PM when you are ready.\n\n"
	t += "[b]By night[/b]\nClick the shutter rope to open the store. Customers come to the grille one at a time, and some of them are entities in disguise. The aswang copies a regular. The tiktik, kapre, and manananggal pretend to be strangers.\n\n"
	t += "[b]Checking a customer[/b]\n"
	t += "1. Read the ledger. It opens to the customer's page. Compare their order and what they say with Lola's entry. A wrong order or a wrong personal detail is a tell.\n"
	t += "2. Scan with the UV lamp. Point the mouse at the customer's face, then hold the right mouse button or Space for 2 seconds. Clicking and holding on the face works too. Then do the same on their cash. A ring fills while you scan, and the UV scan box at the top right shows what you found.\n"
	t += "3. From Night 4, scan the open ledger page as well. Fresh ink means someone changed the entry, so a wrong order on that page is not a tell.\n"
	t += "The tells under the UV lamp are fangs and a stitched neck, red eyes, a lit cigar, a split at the waist, and cash that turns into leaves. The lamp uses 2% of its battery each second.\n\n"
	t += "[color=#ffd27a]An entity always shows exactly two tells. A human shows one at most. One tell means doubt. Two tells mean an entity.[/color]\n\n"
	t += "[b]The radio[/b]\nTurn the radio off to hear warning sounds. A warning is only a hint, never proof. While the radio is off, your Sanity drops by 1 every 30 seconds.\n\n"
	t += "[b]Your four choices[/b]\nClick a glowing object to decide.\n[table=3]"
	t += "[cell][b]Choice[/b]    [/cell][cell][b]If human[/b]    [/cell][cell][b]If entity[/b][/cell]"
	t += "[cell]Serve: the cash drawer    [/cell][cell]You earn the price    [/cell][cell]You lose 30 Sanity[/cell]"
	t += "[cell]Utang: the pen in the ledger    [/cell][cell]They pay the price plus PHP 5 at dawn    [/cell][cell]It comes back the next night[/cell]"
	t += "[cell]Refuse: the shutter rope    [/cell][cell]You lose 10 Sanity    [/cell][cell]It waits at the window, and Presence goes up by 1[/cell]"
	t += "[cell]Banish: the salt jar    [/cell][cell]You lose 20 Sanity    [/cell][cell]It is gone for good, and you gain 5 Sanity[/cell]"
	t += "[/table]\nClick the shutter rope twice to refuse, or drag it down. Utang works twice a night at most, and never on Night 5. Each Banish uses 1 Salt.\n\n"
	t += "[b]Losing and winning[/b]\nIf Sanity reaches 0, it is a Breakdown. If 3 refused entities wait at the window, it is a Breach. Either way, you retry the night from 6 PM. For the good ending, finish Night 5 with at least 60 Sanity before the dawn rest and at least 24 correct calls.\n\n"
	t += "[b]Controls[/b]\n[table=2]"
	for row in [
		["UV lamp", "Point at a face, cash, or the open ledger, then hold the right mouse button or Space. Or click and hold on it."],
		["Ledger", "Click the ledger, or press L"],
		["Serve", "Click the cash drawer, or press S"],
		["Serve on utang", "Click the pen on the ledger's utang page, or press U"],
		["Refuse", "Click the shutter rope twice or drag it down, or press R"],
		["Banish", "Click the salt jar, or press B"],
		["Radio", "Click the radio, or press T"],
		["Buy by day", "Click an item, or press 1, 2, or 3"],
		["Chat by day", "Click a regular, or press Tab and then Enter"],
		["Menus", "Click a button, or press Tab and then Enter"],
		["Pause", "Press Esc or P"],
	]:
		t += "[cell]%s      [/cell][cell]%s[/cell]" % [row[0], row[1]]
	t += "[/table]\n\nTo play without on-screen help, turn off Control hints in Settings."
	return t
