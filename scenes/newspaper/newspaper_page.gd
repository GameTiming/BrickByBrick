extends Control

const NEWSPAPER_ITEM = preload("res://scenes/newspaper/NewspaperItem.tscn")

@onready var grid_container: GridContainer = $MarginContainer/VBoxContainer/GridContainer

@export var keyboard_scroll_speed: float = 500.0
@export var mouse_edge_scroll_speed: float = 350.0
@export var mouse_edge_size: float = 100.0


func _ready() -> void:
	make_children_ignore_mouse(self)
	generate_test_page()


func generate_test_page() -> void:
	clear_page()

	var item_types: Array[int] = []

	for i in range(10):
		item_types.append(0)

	for i in range(6):
		item_types.append(1)

	item_types.shuffle()

	for item_type_value in item_types:
		var item = NEWSPAPER_ITEM.instantiate()

		if item_type_value == 1:
			item.item_type = item.ItemType.FAKE_NEWS
		else:
			item.item_type = item.ItemType.NORMAL

		grid_container.add_child(item)


func clear_page() -> void:
	for child in grid_container.get_children():
		child.queue_free()


func make_children_ignore_mouse(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE

		make_children_ignore_mouse(child)
