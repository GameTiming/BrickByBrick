class_name Game extends Node

const VISUAL_INTERACTION_SCENE = preload("uid://djrd6bmfavp5b")

var inspection: InspectionScene

@onready var cursor_layer: CanvasLayer = $CursorLayer
@onready var transition: TransitionScene = $TransitionScene

@export var game_state: Enums.GameState = Enums.GameState.START
@export var game_data: GameData

@export var newspaper_scene: PackedScene
var newspaper: NewspaperPage

@export var shop_scene: PackedScene
var shop: Shop

@export var construction_scene: PackedScene
var construction: Construction
var game_start: bool = true

var available_materials: Array[ConstructionMaterial] = [
	preload("uid://dbcqutu8hbltw"),
	preload("uid://cvoiapirg68jv"),
	preload("uid://c7ate0n7bodx"),
	preload("uid://b0x3xvhim3i6n")
]


func _ready() -> void:
	_set_up_game_start()


func _input(event: InputEvent) -> void:
	# Debug.
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
			game_state = Enums.GameState.CONSTRUCTION
			await _transition_to_state(game_state)

		Enums.GameState.NEWSPAPER:
			if game_data.current_offer == null:
				push_warning("Cannot enter SHOP without selected MarketOffer.")
				return

			game_state = Enums.GameState.SHOP
			await _transition_to_state(game_state)

		Enums.GameState.SHOP:
			game_state = Enums.GameState.CONSTRUCTION

		Enums.GameState.CONSTRUCTION:
			if game_data.is_game_over():
				game_state = Enums.GameState.ENDGAME
				await _transition_to_state(game_state)
			else:
				game_state = Enums.GameState.NEWSPAPER
				await _transition_to_state(game_state)

		Enums.GameState.ENDGAME:
			return


func enter_inspection_scene(tool: Enums.Inspection) -> void:
	toggle_circle_cursor(false)

	match tool:
		Enums.Inspection.VISUAL:
			inspection = VISUAL_INTERACTION_SCENE.instantiate()
			inspection.clue_found.connect(_on_clue_found)

	if inspection == null:
		return

	inspection.game = self

	add_child(inspection)
	remove_child(shop)


func leave_inspection_scene() -> void:
	toggle_circle_cursor(true)

	add_child(shop)

	if is_instance_valid(inspection):
		inspection.queue_free()

	inspection = null


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
			_set_up_endgame()


func _set_up_game_start() -> void:
	game_data.initiate()
	game_start = true
	change_state()


func _set_up_newspaper() -> void:
	newspaper = newspaper_scene.instantiate() as NewspaperPage

	newspaper.construction_item_count = 10
	newspaper.total_item_count = 20

	if game_data.newspaper_offers.is_empty():
		game_data.newspaper_offers = _generate_newspaper_offers(
			newspaper.construction_item_count
		)

	newspaper.offers = game_data.newspaper_offers

	newspaper.offer_selected.connect(
		_on_newspaper_offer_selected
	)

	add_child(newspaper)


func _set_up_shop() -> void:
	if game_data.current_offer == null:
		push_error("Cannot setup Shop without current MarketOffer.")
		return

	if game_data.current_material == null:
		push_error("Cannot setup Shop without current ConstructionMaterial.")
		return

	shop = shop_scene.instantiate() as Shop
 
	shop.material = game_data.current_material

	shop.offer = game_data.current_offer
	
	shop.game = self

	toggle_circle_cursor(true)

	add_child(shop)


func _set_up_construction() -> void:
	construction = construction_scene.instantiate()
	add_child(construction)
	
	construction.set_letter_position(game_start)
	construction.game = self
	game_start = false
	toggle_circle_cursor(true)


func _set_up_endgame() -> void:
	pass


func _clean_up() -> void:
	toggle_circle_cursor(false)

	if is_instance_valid(newspaper):
		newspaper.queue_free()
	newspaper = null

	if is_instance_valid(shop):
		shop.queue_free()
	shop = null

	if is_instance_valid(construction):
		construction.queue_free()
	construction = null


func _generate_newspaper_offers(
	count: int
) -> Array[MarketOffer]:
	var generated_offers: Array[MarketOffer] = []

	if available_materials.is_empty():
		push_error("No available construction materials.")
		return generated_offers

	for i in range(count):
		var offer := _create_market_offer(i)

		if offer != null:
			generated_offers.append(offer)

	return generated_offers


func _create_market_offer(index: int) -> MarketOffer:
	var material_template: ConstructionMaterial = (
		available_materials.pick_random()
	)

	var material := (
		material_template.duplicate(true)
		as ConstructionMaterial
	)
	
	#TODO: temporary, veliau idet logika su materialu sudinumu
	if material.material_type == Enums.ItemType.PLANK:
		material.condition = randi_range(1, 3)

	var seller := SellerData.new()

	seller.personality = (Enums.SellerPersonality.values().pick_random())

	seller.deception_skill = randi_range(20, 90)
	seller.negotiation_skill = randi_range(20, 90)
	seller.patience = randi_range(2, 5)
	
	material.current_price = _generate_offer_price(material.market_price)

	var offer := MarketOffer.new()

	offer.id = "%s_%s" % [
		Time.get_ticks_usec(),
		index
	]

	offer.material = material
	offer.seller = seller
	offer.negotiated_price = material.current_price

	offer.negotiated_price = material.current_price

	return offer


func _generate_offer_price(market_price: int) -> int:
	if market_price <= 0:
		push_error("ConstructionMaterial market_price must be greater than 0.")
		return 1

	var multiplier := randf_range(1, 10) # reikia sugalvot del kainu setinimo pagal daikto kokybes 

	return roundi(market_price * multiplier)


func _transition_to_state(new_state: Enums.GameState) -> void:
	if transition.is_transitioning:
		return

	await transition.fade_to_black()

	game_state = new_state
	_set_up_game()

	await get_tree().process_frame

	await transition.fade_from_black()


func _on_newspaper_offer_selected(offer: MarketOffer) -> void:
	if offer == null:
		return

	if offer.material == null:
		push_error("Selected MarketOffer has no ConstructionMaterial.")
		return

	game_data.current_offer = offer
	
	
	#kolkas palieku kaip tu darei bet manu reiketu sudet i offer :) 
	game_data.current_material = offer.material

	await change_state()


func _on_inspection_clue_found(clue: Enums.MaterialClue) -> void:
	if game_data.current_offer == null:
		return

	if clue in game_data.current_offer.revealed_clues:
		return

	game_data.current_offer.revealed_clues.append(clue)


func _on_clue_found(clue: Enums.MaterialClue) -> void:
	if game_data.current_offer == null:
		return

	if clue in game_data.current_offer.revealed_clues:
		return

	game_data.current_offer.revealed_clues.append(clue)
