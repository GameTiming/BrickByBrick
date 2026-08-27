extends Camera3D

@export var camera_arm: Node3D
@export var lerp_power: float = 1.0


func _process(delta: float) -> void:
	position = lerp(position, camera_arm.position, delta * lerp_power)
