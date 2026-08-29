class_name ConstructionMaterial extends Resource

@export_category("General")
@export var material_type: Enums.ItemType:
	set(value):
		if _is_valid_material_type(value):
			material_type = value
		else:
			material_type = Enums.ItemType.BRICK
@export var inspecion_options: Array[Enums.Inspection]
@export var material_scene: PackedScene
@export var condition: Enums.MaterialClue = Enums.MaterialClue.NONE

@export_category("Value properties")
@export var market_price: int
@export var current_price: int

@export_category("Physical properties")
@export var rotation: Vector3

@export_category("Radiation")
@export var is_radioactive: bool = true

@export_range(0.0, 1.0, 0.01)
var radiation_strength: float = 1.0


func get_scene() -> PackedScene:
	return material_scene #make diferences for variations?


func _is_valid_material_type(type: Enums.ItemType) -> bool:
	return type in [
		Enums.ItemType.BRICK,
		Enums.ItemType.BEAM,
		Enums.ItemType.PLANK,
		Enums.ItemType.CONCREATE
	]
