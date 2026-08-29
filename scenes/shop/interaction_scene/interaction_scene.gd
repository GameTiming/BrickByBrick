class_name InspectionScene extends Node3D

signal clue_found(clue: Enums.MaterialClue)

var game: Game
var material_instance: ConstructionObject
var investigation_type: Enums.Inspection

func _ready() -> void:
	var material_scene: PackedScene = game.game_data.current_material.get_scene()
	material_instance = material_scene.instantiate()
	add_child(material_instance)
	material_instance.set_condition(game.game_data.current_material.condition, investigation_type)


func _finish_inspection() -> void:
	game.leave_inspection_scene()
