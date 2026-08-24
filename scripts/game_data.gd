class_name GameData extends Resource

@export var starting_balance: int

var balance: int
var current_material: ConstructionMaterial


func initiate() -> void:
	balance = starting_balance


func is_game_over() -> bool:
	return balance <= 0
