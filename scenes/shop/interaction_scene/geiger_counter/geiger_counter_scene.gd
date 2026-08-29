class_name GeigerCounterScene extends InspectionScene

const MOUSE_SENSITIVITY: float = 0.005

@onready var camera_arm: SpringArm3D = $CameraArmPivot/CameraArm
@onready var camera_arm_pivot: Node3D = $CameraArmPivot
@onready var camera: Camera3D = $CameraArmPivot/Camera

@export var maximum_distance: float = 10.0
@export var minimum_distance: float = 2.0
@export var radiation_detection_distance: float = 10.0

var radiation_intensity: float = 0.0
var inspected_object: ConstructionObject
var radiation_light: OmniLight3D


func _ready() -> void:
	investigation_type = Enums.Inspection.GEIGER

	super._ready()

	inspected_object = _get_inspected_object()

	if inspected_object == null:
		push_error("GeigerCounterScene: ConstructionObject not found.")
		return
	
	if inspected_object.radiation_point != null:
		radiation_light = inspected_object.radiation_point.get_node_or_null(
			"RadiationLight"
		) as OmniLight3D

	position = Vector3(
		position.x,
		position.y,
		-camera_arm.spring_length
	)

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _process(_delta: float) -> void:
	if inspected_object == null:
		return

	radiation_intensity = _get_radiation_intensity()
	_update_radiation_light()


func _update_radiation_light() -> void:
	if radiation_light == null:
		return
	
	print("light")

	radiation_light.light_energy = lerpf(0.0, 8.0, radiation_intensity)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		camera_arm_pivot.rotation.y -= event.relative.x * MOUSE_SENSITIVITY
		camera_arm_pivot.rotation.x -= event.relative.y * MOUSE_SENSITIVITY

	if event.is_action_pressed("zoom_in") and camera_arm.spring_length > minimum_distance:
		camera_arm.spring_length -= 1

	if event.is_action_pressed("zoom_out") and camera_arm.spring_length < maximum_distance:
		camera_arm.spring_length += 1

	if event.is_action_pressed("exit_scene"):
		_finish_inspection()


func _get_inspected_object() -> ConstructionObject:
	for child in get_children():
		if child is ConstructionObject:
			return child as ConstructionObject

	return null


func _get_radiation_intensity() -> float:
	var material: ConstructionMaterial = game.game_data.current_material

	if material == null:
		return 0.0

	if not material.is_radioactive:
		return 0.0

	if inspected_object.radiation_point == null:
		return 0.0

	var distance: float = camera.global_position.distance_to(
		inspected_object.radiation_point.global_position
	)

	var intensity: float = 1.0 - (
		distance / radiation_detection_distance
	)

	return clamp(intensity,0.0,1.0) * material.radiation_strength
