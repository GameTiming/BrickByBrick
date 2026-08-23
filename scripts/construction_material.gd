class_name ConstructionMaterial extends Resource

enum type {PLANK, BRICK, CONCREATE, BEAM}
enum inspection {VISUAL, DRILL, GEIGER}

@export var material_type: type
@export var inspecion_options: Array[inspection]
@export var material_scene: PackedScene
