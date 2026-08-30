class_name Construction extends Node3D

var game: Game

@onready var newspaper: Node3D = %Newspaper
@onready var letter: Letter = %Letter
@onready var first_letter_position: Node3D = %FirstLetterPosition
@onready var second_letter_position: Node3D = %SecondLetterPosition
@onready var player: Player = $Player

@export var crane_picup_marker: Node3D
@export var construction_site: StaticBody3D


func _ready() -> void:
	if game.construction_site == null:
		game.construction_site = construction_site
	else: 
		construction_site = game.construction_site
	
	if game.game_data.current_material == null:
		return
	
	#crane, and all shit in it positions
	$Crane.global_position.y += construction_site.height
	first_letter_position.global_position.y += construction_site.height
	second_letter_position.global_position.y += construction_site.height
	player.global_position.y += construction_site.height
	newspaper.global_position.y += construction_site.height
	
	
	var wall = game.game_data.current_material.building_block_scene.instantiate()
	construction_site.add_child(wall)
	wall.global_position = crane_picup_marker.global_position
	wall.global_rotation = crane_picup_marker.global_rotation


func set_letter_position(first: bool) -> void:
	if first:
		letter.reparent(first_letter_position, false)
	else:
		letter.reparent(second_letter_position, false)
		newspaper.enable_interaction()
