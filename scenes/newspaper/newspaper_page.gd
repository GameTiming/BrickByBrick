extends Control

const NEWSPAPER_ITEM = preload("res://scenes/newspaper/NewspaperItem.tscn")

@onready var content_area: Control = $MarginContainer/VBoxContainer/ContentArea
@onready var items_container: HFlowContainer = $MarginContainer/VBoxContainer/ContentArea/HFlowContainer

@onready var previous_button: Button = $MarginContainer/VBoxContainer/NavigatorContainer/PreviousPageButton
@onready var next_button: Button = $MarginContainer/VBoxContainer/NavigatorContainer/NextPageButton
@onready var page_number_label: Label = $MarginContainer/VBoxContainer/HeaderContainer/PageNumberLabel

@export var item_width: float = 300.0
@export var item_height: float = 180.0
@export var horizontal_gap: float = 8.0
@export var vertical_gap: float = 8.0

var current_page: int = 0
var all_item_types: Array[int] = []


func _ready() -> void:
	previous_button.pressed.connect(_on_previous_page_pressed)
	next_button.pressed.connect(_on_next_page_pressed)

	generate_newspaper()

	await get_tree().process_frame

	show_page()


func generate_newspaper() -> void:
	all_item_types.clear()

	for i in range(10):
		all_item_types.append(0)

	for i in range(6):
		all_item_types.append(1)

	all_item_types.shuffle()

	current_page = 0


func get_items_per_page() -> int:
	var available_width: float = content_area.size.x
	var available_height: float = content_area.size.y

	if available_width <= 0.0 or available_height <= 0.0:
		return 1

	var columns: int = floori(
		(available_width + horizontal_gap) /
		(item_width + horizontal_gap)
	)

	var rows: int = floori(
		(available_height + vertical_gap) /
		(item_height + vertical_gap)
	)

	columns = maxi(columns, 1)
	rows = maxi(rows, 1)

	return columns * rows


func get_page_count() -> int:
	var items_per_page: int = get_items_per_page()

	if all_item_types.is_empty():
		return 1

	return ceili(
		float(all_item_types.size()) /
		float(items_per_page)
	)


func show_page() -> void:
	clear_page()

	var items_per_page: int = get_items_per_page()
	var page_count: int = get_page_count()

	current_page = clampi(
		current_page,
		0,
		page_count - 1
	)

	var start_index: int = current_page * items_per_page

	var end_index: int = mini(
		start_index + items_per_page,
		all_item_types.size()
	)

	for i in range(start_index, end_index):
		var item = NEWSPAPER_ITEM.instantiate()

<<<<<<< Updated upstream
		if item_type_value == 1:
			item.item_type = Enums.ItemType.FAKE_NEWS
=======
		if all_item_types[i] == 1:
			item.item_type = item.ItemType.FAKE_NEWS
>>>>>>> Stashed changes
		else:
			item.item_type = randi_range(1,4) #temporary before proper logic

		item.custom_minimum_size = Vector2(
			item_width,
			item_height
		)

		items_container.add_child(item)

	update_navigation()


func clear_page() -> void:
	for child in items_container.get_children():
		items_container.remove_child(child)
		child.queue_free()


func update_navigation() -> void:
	var page_count: int = get_page_count()

	page_number_label.text = "Page %d / %d" % [
		current_page + 1,
		page_count
	]

	previous_button.disabled = current_page == 0
	next_button.disabled = current_page >= page_count - 1


func _on_previous_page_pressed() -> void:
	if current_page <= 0:
		return

	current_page -= 1
	show_page()


func _on_next_page_pressed() -> void:
	var page_count: int = get_page_count()

	if current_page >= page_count - 1:
		return

	current_page += 1
	show_page()
