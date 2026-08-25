class_name Shop extends Node3D

const VISUAL_INVESTIGATION_TOOL = preload("uid://dcer6kqlbs3pu")

@export var material: ConstructionMaterial

@onready var material_location: Node3D = $MaterialLocation
@onready var visual_investigation_tool_location: Node3D = $Tools/VisualInvestigationToolLocation


func _ready() -> void:
	var material_scene: PackedScene = material.get_scene()
	var material_instance: Node3D = material_scene.instantiate()
	
	material_location.add_child(material_instance)
	material_instance.rotation = material.rotation
	
	for option in material.inspecion_options:
		match option:
			Enums.Inspection.VISUAL:
				var visual = VISUAL_INVESTIGATION_TOOL.instantiate()
				visual_investigation_tool_location.add_child(visual)
