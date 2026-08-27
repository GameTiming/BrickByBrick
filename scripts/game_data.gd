class_name GameData extends Resource

@export var starting_balance: int

var balance: int
var current_material: ConstructionMaterial
var current_offer: MarketOffer

var newspaper_offers: Array[MarketOffer] = []


func initiate() -> void:
	balance = starting_balance
	
	current_material = null
	current_offer = null
	newspaper_offers.clear()


func is_game_over() -> bool:
	return balance <= 0
