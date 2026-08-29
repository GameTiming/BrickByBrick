class_name MainMenu extends Control

signal start_game_pressed
signal continue_game_pressed

@onready var start_game_button: Button = $MarginContainer/VBoxContainer/StartGameButton
@onready var continue_button: Button = $MarginContainer/VBoxContainer/ContinueGameButton
@onready var score_button: Button = $MarginContainer/VBoxContainer/ScoreButton
@onready var quit_game_button: Button = $MarginContainer/VBoxContainer/QuitGameButton

@onready var score_panel: Control = $PanelContainer
@onready var scores_container: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/ScoresContainer
@onready var menu_margin: MarginContainer = $MarginContainer

const MENU_EDGE_MARGIN: int = 80


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	start_game_button.pressed.connect(_on_start_game_pressed)
	continue_button.pressed.connect(_on_continue_game_pressed)
	score_button.pressed.connect(_on_score_pressed)
	quit_game_button.pressed.connect(_on_quit_game_pressed)

	score_panel.hide()
	
	continue_button.visible = false


func show_pause_menu() -> void:
	score_panel.hide()

	menu_margin.set_anchors_and_offsets_preset(
		Control.PRESET_CENTER,
		Control.PRESET_MODE_KEEP_SIZE
	)

	start_game_button.hide()
	continue_button.show()

	show()


func show_start_menu() -> void:
	show()

	start_game_button.show()
	continue_button.hide()


func _update_scores() -> void:
	for child in scores_container.get_children():
		child.queue_free()

	var scores: Array = _get_scores()

	var amount: int = min(scores.size(), 10)

	for i in range(amount):
		var label := Label.new()

		label.text = "%d. %s - %d" % [
			i + 1,
			scores[i].player_name,
			scores[i].score
		]

		scores_container.add_child(label)


func _get_scores() -> Array:
	return [ #laikinai kol neturim sistemos 
		{
			"player_name": "John",
			"score": 12500
		},
		{
			"player_name": "Anna",
			"score": 9800
		},
		{
			"player_name": "Mike",
			"score": 7400
		}
	]


func _on_start_game_pressed() -> void:
	start_game_pressed.emit()


func _on_continue_game_pressed() -> void:
	continue_game_pressed.emit()


func _on_score_pressed() -> void:
	if score_panel.visible:
		score_panel.hide()

		menu_margin.set_anchors_and_offsets_preset(
			Control.PRESET_CENTER,
			Control.PRESET_MODE_KEEP_SIZE
		)
		return

	_update_scores()

	menu_margin.set_anchors_and_offsets_preset(
		Control.PRESET_CENTER_LEFT,
		Control.PRESET_MODE_KEEP_SIZE,
		MENU_EDGE_MARGIN
	)

	score_panel.set_anchors_and_offsets_preset(
		Control.PRESET_CENTER_RIGHT,
		Control.PRESET_MODE_KEEP_SIZE,
		MENU_EDGE_MARGIN * 5
	)

	score_panel.show()


func _on_quit_game_pressed() -> void:
	get_tree().quit()
