class_name Player extends CharacterBody3D

@onready var interaction_component: InteractionComponent = $Camera3D/InteractionComponent
@onready var camera: Camera3D = $Camera3D

@export var speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.001

@export var pick_up_area: Area3D

var camera_rotation: Vector2 = Vector2.ZERO


func _ready() -> void:
	camera.current = true


func _input(event) -> void:
	if event.is_action_pressed("action"):
		interaction_component.interact()
	
	if event is InputEventMouseMotion:
		var mouse_event = event.relative * mouse_sensitivity
		_camera_look(mouse_event)


func _camera_look(movement: Vector2) -> void:
	camera_rotation += movement
	camera_rotation.y = clamp(camera_rotation.y, -1.5, 1.2)
	
	transform.basis = Basis()
	camera.transform.basis = Basis()
	
	rotate_object_local(Vector3.UP, -camera_rotation.x)
	camera.rotate_object_local(Vector3.RIGHT, -camera_rotation.y)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	move_and_slide()
