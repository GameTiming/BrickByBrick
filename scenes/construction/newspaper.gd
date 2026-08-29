extends Node3D

@export var construction: Construction
@onready var collision_shape_3d: CollisionShape3D = $InteractableComponent/CollisionShape3D


func start_conversation(_interactor) -> void:
	construction.game.change_state()


func enable_interaction() -> void:
	collision_shape_3d.disabled = false
