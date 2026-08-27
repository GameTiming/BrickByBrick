class_name InspectionScene extends Node3D

var game: Game


func _ready() -> void:
	var material_scene: PackedScene = game.game_data.current_material.get_scene()
	var material_instance: Node3D = material_scene.instantiate()
	add_child(material_instance)


func _finish_inspection() -> void:
	game.leave_inspection_scene()
