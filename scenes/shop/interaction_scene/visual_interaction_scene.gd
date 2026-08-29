class_name VisualInteractionScene extends InspectionScene

const mouse_sensitivity: float = 0.005

@onready var camera_arm: SpringArm3D = $CameraArmPivot/CameraArm
@onready var camera_arm_pivot: Node3D = $CameraArmPivot

@export var maximum_distance = 10
@export var minimum_distance = 2


func _ready() -> void:
	investigation_type = Enums.Inspection.VISUAL #butina daryt pries supperi
	super._ready()
	
	#nuo cia custom logika
	position = Vector3(position.x, position.y, -camera_arm.spring_length)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		camera_arm_pivot.rotation.y -= event.relative.x * mouse_sensitivity
		camera_arm_pivot.rotation.x -= event.relative.y * mouse_sensitivity
	
	if event.is_action_pressed("zoom_in") and camera_arm.spring_length > minimum_distance:
		camera_arm.spring_length -= 1
	if event.is_action_pressed("zoom_out") and camera_arm.spring_length < maximum_distance:
		camera_arm.spring_length += 1
	
	if event.is_action_pressed("exit"):
		_finish_inspection()
