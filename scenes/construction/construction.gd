class_name Construction extends Node3D

var game: Game

@onready var newspaper: Node3D = $Newspaper
@onready var letter: Node3D = $Letter
@onready var first_letter_position: Node3D = $FirstLetterPosition
@onready var second_letter_position: Node3D = $SecondLetterPosition


func set_letter_position(first: bool) -> void:
	if first:
		letter.reparent(first_letter_position, false)
	else:
		letter.reparent(second_letter_position, false)
		newspaper.enable_interaction()
