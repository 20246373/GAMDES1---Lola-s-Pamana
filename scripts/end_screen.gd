extends Control
## Win and lose screens. The good ending shows Lola's full page and the
## bittersweet ending shows the torn page (7.3). A Breakdown or a Breach offers
## Retry from the 6 PM checkpoint with the retry floor (6.4).

@onready var title: Label = $Title
@onready var body: Label = $Page/Body
@onready var page: TextureRect = $Page
@onready var stats: Label = $Stats
@onready var retry_button: Button = $Buttons/RetryButton
@onready var menu_button: Button = $Buttons/MenuButton

var mode := ""


func show_mode(m: String) -> void:
	mode = m
	match m:
		"good":
			title.text = "Good ending. The debt is paid."
			body.text = Story.ENDING_GOOD
			retry_button.visible = false
		"bittersweet":
			title.text = "Bittersweet ending. The page is torn."
			body.text = Story.ENDING_BITTERSWEET
			retry_button.visible = false
		"breakdown":
			title.text = "Breakdown"
			body.text = "Your Sanity reached 0. The counter goes dark and the night wins.\n\nRetry from 6 PM. Anything below 3 Salt, 70% UV battery, or 50 Sanity is raised to that floor."
			retry_button.visible = true
		"breach":
			title.text = "Breach"
			body.text = "Three refused entities gathered at the window, and the grille gave way.\n\nRetry from 6 PM. Anything below 3 Salt, 70% UV battery, or 50 Sanity is raised to that floor."
			retry_button.visible = true
	if m in ["good", "bittersweet"]:
		stats.text = "Correct calls: %d of %d    Sanity before the last dawn rest: %d    Pesos: %d" % [
			GameState.correct_calls, GameState.TOTAL_CALLS, GameState.sanity_before_rest, GameState.pesos]
		Sfx.play(self, "bell", -2.0)
		if m == "bittersweet":
			page.modulate = Color(0.85, 0.8, 0.75)
	else:
		stats.text = "Night %d    Sanity %d    Presence %d" % [GameState.night, GameState.sanity, GameState.presence]
		Sfx.play(self, "heartbeat")
	if retry_button.visible:
		retry_button.grab_focus()
	else:
		menu_button.grab_focus()
