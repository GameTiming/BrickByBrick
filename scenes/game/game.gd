class_name Game extends Node

@export var game_state: Enums.GameState = Enums.GameState.NEWSPAPER
@export var game_data: GameData

@export var newspaper_scene: PackedScene
var newspaper: NewspaperPage

@export var shop_scene: PackedScene
var shop: Shop


func _ready() -> void:
	_set_up_game_start()


func _process(_delta: float) -> void:
	#debug
	if Input.is_action_just_pressed("debug_specific_level"):
		_set_up_game()
	elif Input.is_action_just_pressed("debug_flow"):
		change_state()


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
	newspaper = newspaper_scene.instantiate()
	add_child(newspaper)
	
	#newspaper set up steps


func _set_up_shop() -> void:
	shop = shop_scene.instantiate()
	add_child(shop)
	
	#shop set up steps


func _set_up_construction() -> void:
	pass


func _set_up_endgame() -> void:
	pass


func _clean_up() -> void:
	if newspaper != null:
		newspaper.queue_free()
	if shop != null:
		shop.queue_free()
