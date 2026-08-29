class_name Shop extends Node3D

const VISUAL_INVESTIGATION_TOOL = preload("uid://dcer6kqlbs3pu")
const GEIGER_INVESTIGATION_TOOL = preload("uid://ds1lh5ktbldln")

const SELLER_DIALOG_SCENE = preload("res://scenes/seller_dialog/SellerDialog.tscn")


@export var material: ConstructionMaterial
@onready var seller: Seller = $Seller

@onready var material_location: Node3D = $MaterialLocation
@onready var visual_investigation_tool_location: Node3D = $Tools/VisualInvestigationToolLocation
@onready var geiger_investigation_tool_location: Node3D = $Tools/GeigerInvestigationToolLocation

@onready var player: Player = $Player

var game: Game
var offer: MarketOffer #nezinau ar cia reikes rr selleri det ?
var seller_dialog: SellerDialog
 

func _ready() -> void:
	seller.conversation_started.connect(_on_seller_conversation_started)
	var material_scene: PackedScene = material.get_scene()
	var material_instance: Node3D = material_scene.instantiate()
	
	material_location.add_child(material_instance)
	material_instance.rotation = material.rotation
	
	for option in material.inspecion_options:
		match option:
			Enums.Inspection.VISUAL:
				var visual = VISUAL_INVESTIGATION_TOOL.instantiate()
				visual_investigation_tool_location.add_child(visual)
			Enums.Inspection.GEIGER:
				var geiger = GEIGER_INVESTIGATION_TOOL.instantiate()
				geiger_investigation_tool_location.add_child(geiger)


func start_investigation(tool: Enums.Inspection) -> void:
	game.enter_inspection_scene(tool)


func _on_seller_conversation_started() -> void:
	if offer == null:
		return

	if seller_dialog == null:
		seller_dialog = SELLER_DIALOG_SCENE.instantiate() as SellerDialog
		add_child(seller_dialog)
		
		seller_dialog.dialog_closed.connect(_on_seller_dialog_closed)
	
	game.toggle_circle_cursor(false)
	player.set_dialog_open(true)
	seller_dialog.setup(offer)


func _on_seller_dialog_closed() -> void:
	game.toggle_circle_cursor(true)
	player.set_dialog_open(false)
