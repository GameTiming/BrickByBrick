class_name Seller extends Node3D

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_timer: Timer = $AnimationTimer


func _ready() -> void:
	animation_timer.start(randf_range(1, 5)) #rate at which animations are played


func start_conversation(interactor: Node3D) -> void:
	var tween = create_tween()
	var direction = global_position - interactor.global_position
	direction.y = 0.0
	direction = direction.normalized()
	var target_rotation = Vector3(0.0, atan2(-direction.x, -direction.z), 0.0)
	
	tween.tween_property(self, "rotation", target_rotation, .4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK)
	
	var animation = "parameters/conditions/talk" + str(randi_range(1, 2))
	animation_tree.set(animation, true)
	
	animation_timer.stop()


func _on_animation_tree_animation_started(anim_name: StringName) -> void:
	if anim_name == "idle":
		return
	
	animation_tree.set("parameters/conditions/look1", false)
	animation_tree.set("parameters/conditions/look2", false)
	animation_tree.set("parameters/conditions/look3", false)
	animation_tree.set("parameters/conditions/talk1", false)
	animation_tree.set("parameters/conditions/talk2", false)


func _on_animation_tree_animation_finished(_anim_name: StringName) -> void:
	animation_timer.start(randf_range(5, 10)) #rate at which animations are played


func _on_animation_timer_timeout() -> void:
	var animation = "parameters/conditions/look" + str(randi_range(1, 3))
	animation_tree.set(animation, true)
