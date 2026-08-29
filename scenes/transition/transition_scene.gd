class_name TransitionScene
extends CanvasLayer

@onready var overlay: ColorRect = $ColorRect

@export var fade_duration: float = 0.45
@export var black_hold_duration: float = 0.1

var is_transitioning: bool = false


func _ready() -> void:
	overlay.color.a = 0.0
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE


func fade_to_black() -> void:
	is_transitioning = true
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween := create_tween()

	tween.tween_property(
		overlay,
		"color:a",
		1.0,
		fade_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)

	await tween.finished


func fade_from_black() -> void:
	# Trumpas momentas pilnai juodame ekrane.
	if black_hold_duration > 0.0:
		await get_tree().create_timer(
			black_hold_duration
		).timeout

	var tween := create_tween()

	tween.tween_property(
		overlay,
		"color:a",
		0.0,
		fade_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	await tween.finished

	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false
