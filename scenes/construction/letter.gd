class_name Letter extends Node3D

@onready var letter_content: Control = $LetterContent

var game: Game
@export var player: Player


func _ready() -> void:
	game = get_tree().get_first_node_in_group("Game")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("exit_scene"):
		letter_content.visible = false
		game.toggle_circle_cursor(true)
		player.is_dialog_open = false


func start_conversation(_interactor) -> void:
	letter_content.visible = true
	owner.set_letter_position(false)
	game.toggle_circle_cursor(false)
	player.is_dialog_open = true
