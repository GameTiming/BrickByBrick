class_name Shop extends Node3D

@export var material: ConstructionMaterial

@onready var material_location: Node3D = $MaterialLocation


func _ready() -> void:
	var material_scene: PackedScene = material.get_scene()
	var material_instance: Node3D = material_scene.instantiate()
	
	material_location.add_child(material_instance)
	material_instance.rotation = material.rotation
