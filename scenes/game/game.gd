class_name Game extends Node

@onready var cursor_layer: CanvasLayer = $CursorLayer

@export var game_state: Enums.GameState = Enums.GameState.NEWSPAPER
@export var game_data: GameData

@export var newspaper_scene: PackedScene
var newspaper: NewspaperPage

@export var shop_scene: PackedScene
var shop: Shop

var available_materials: Array = [
	preload("uid://dbcqutu8hbltw"),
	preload("uid://cvoiapirg68jv"),
	preload("uid://c7ate0n7bodx"),
	preload("uid://b0x3xvhim3i6n")
]

func _ready() -> void:
	_set_up_game_start()


func _input(event: InputEvent) -> void:
	#debug
	if event.is_action_pressed("debug_specific_level"):
		_set_up_game()
	elif event.is_action_pressed("debug_flow"):
		change_state()
	elif event.is_action_pressed("ui_cancel"):
		toggle_circle_cursor(false)


func toggle_circle_cursor(enabled: bool) -> void:
	cursor_layer.visible = enabled
	
	if enabled:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else: 
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func change_state() -> void:
	match game_state:
		Enums.GameState.START:
			game_state = Enums.GameState.NEWSPAPER
		Enums.GameState.NEWSPAPER:
			game_state = Enums.GameState.SHOP
		Enums.GameState.SHOP:
			game_state = Enums.GameState.CONSTRUCTION
		Enums.GameState.CONSTRUCTION:
			if game_data.is_game_over():
				game_state = Enums.GameState.ENDGAME
			else:
				game_state = Enums.GameState.NEWSPAPER
	
	_set_up_game()


func _set_up_game() -> void:
	_clean_up()
	
	match game_state:
		Enums.GameState.START:
			_set_up_game_start()
		Enums.GameState.NEWSPAPER:
			_set_up_newspaper()
		Enums.GameState.SHOP:
			_set_up_shop()
		Enums.GameState.CONSTRUCTION:
			_set_up_construction()
		Enums.GameState.ENDGAME:
			_set_up_game()


func _set_up_game_start() -> void:
	game_data.initiate()
	change_state()


func _set_up_newspaper() -> void:
	var material = _set_construction_material()
	game_data.current_material = material
	
	newspaper = (newspaper_scene.instantiate() as NewspaperPage)
	
	newspaper.construction_item_count = 10 #TODO: think how to variate this while game progresses
	newspaper.total_item_count = 20 #TODO: think how to variate this while game progresses
	newspaper.construction_item = material
	
	add_child(newspaper)


func _set_construction_material() -> ConstructionMaterial:
	var material = (available_materials.pick_random()) as ConstructionMaterial
	return material.duplicate(true)


func _set_up_shop() -> void:
	shop = shop_scene.instantiate()
	
	shop.material = game_data.current_material
	toggle_circle_cursor(true)
	
	add_child(shop)


func _set_up_construction() -> void:
	pass


func _set_up_endgame() -> void:
	pass


func _clean_up() -> void:
	toggle_circle_cursor(false)
	
	if newspaper != null:
		newspaper.queue_free()
	if shop != null:
		shop.queue_free()
