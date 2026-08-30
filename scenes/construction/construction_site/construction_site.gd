class_name ConstructionSite extends StaticBody3D

@export var height: float = 0
@export var story_height: float = 2.0

var game: Game


func _ready() -> void:
	game = get_tree().get_first_node_in_group("Game")


func _process(_delta: float) -> void:
	var heighest_story: float = 0.0
	var building_blocks = get_children()
	for block in building_blocks:
		heighest_story = maxf(heighest_story, (block as Node3D).position.y)
	
	if height != heighest_story + story_height:
		height = heighest_story + story_height
		game.game_data.height = height
