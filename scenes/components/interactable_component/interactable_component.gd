class_name InteractableComponent extends Area3D

const PICK_UP_DURATION: float = .4
const OUTLINE_MATERIAL = preload("uid://bfdym8swfwpng")

@export var type: Enums.InteractableType

@export_category("Pickup")
@export var pickup_anchor: Vector3
@export var pickup_rotation: Vector3
@export var pickup_type: Enums.Inspection

var parent: Node3D
var starting_parent: Node3D
var starting_position: Vector3
var starting_rotation: Vector3

var all_geometries: Array[GeometryInstance3D]


func _ready() -> void:
	parent = get_parent_node_3d()
	
	starting_parent = parent.get_parent_node_3d()
	starting_position = parent.position
	starting_rotation = parent.rotation
	
	all_geometries.assign(parent.find_children("*", "GeometryInstance3D", true))


func interact(interactor: Node3D, tool: Enums.Inspection) -> void:
	owner.interact(interactor, tool)


func start_conversation(interactor: Node3D) -> void:
	owner.start_conversation(interactor)


func mount(interactor: Node3D) -> void:
	parent.reparent(interactor)
	_animate_pick_up(pickup_anchor, pickup_rotation)


func unmount() -> void:
	parent.reparent(starting_parent)
	_animate_pick_up(starting_position, starting_rotation)


func toggle_highlight(turn_on: bool) -> void:
	for geometry: GeometryInstance3D in all_geometries:
		if turn_on:
			geometry.material_overlay = OUTLINE_MATERIAL
		else:
			geometry.material_overlay = null


func _animate_pick_up(new_position: Vector3, new_rotation: Vector3) -> void:
	var tween = create_tween()
	
	tween.tween_property(parent, "position", new_position, PICK_UP_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.parallel()
	tween.tween_property(parent, "rotation", new_rotation, PICK_UP_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
