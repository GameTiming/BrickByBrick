class_name ConstructionMaterial extends Resource

@export_category("General")
@export var material_type: Enums.ItemType
@export var inspecion_options: Array[Enums.Inspection]
@export var material_scene: PackedScene

@export_category("Value properties")
@export var market_price: int
@export var current_price: int

@export_category("Physical properties")
@export var rotation: Vector3


func get_scene() -> PackedScene:
	return material_scene #make diferences for variations?
