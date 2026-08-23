extends Control

const NEWSPAPER_ITEM = preload("res://scenes/newspaper/NewspaperItem.tscn")

@onready var content_area: Control = $MarginContainer/VBoxContainer/ContentArea
@onready var items_container: HFlowContainer = $MarginContainer/VBoxContainer/ContentArea/HFlowContainer
@onready var newspaper_title_label: Label = $MarginContainer/VBoxContainer/HeaderContainer/NespaperTitleLabel

@onready var previous_button: Button = $MarginContainer/VBoxContainer/NavigatorContainer/PreviousPageButton
@onready var next_button: Button = $MarginContainer/VBoxContainer/NavigatorContainer/NextPageButton
@onready var page_number_label: Label = $MarginContainer/VBoxContainer/HeaderContainer/PageNumberLabel

@export var item_width: float = 300.0
@export var item_height: float = 180.0
@export var bottom_safety_margin: float = 60.0

var current_page: int = 0
var page_start_indices: Array[int] = []

var available_construction_types: Array[Enums.ItemType] = [
	Enums.ItemType.BRICK,
	Enums.ItemType.BEAM,
	Enums.ItemType.PLANK,
	Enums.ItemType.CONCREATE
]

var newspaper_items: Array[Enums.ItemType] = []


func _ready() -> void:
	previous_button.pressed.connect(_on_previous_page_pressed)
	next_button.pressed.connect(_on_next_page_pressed)
	
	newspaper_title_label.add_theme_color_override("font_color", Color.BLACK)
	page_number_label.add_theme_color_override("font_color", Color.BLACK)
	next_button.add_theme_color_override("font_color", Color.BLACK)
	previous_button.add_theme_color_override("font_color", Color.BLACK)

	modulate.a = 0.0

	generate_newspaper()

	await get_tree().process_frame
	await rebuild_pages()

	show_page()

	await get_tree().process_frame

	fade_in()


func fade_in() -> void:
	var tween := create_tween()

	tween.tween_property(
		self,
		"modulate:a",
		1.0,
		0.25
	)


func generate_newspaper() -> void:
	newspaper_items.clear()

	# 10 real construction advertisements.
	for i in range(10):
		newspaper_items.append(
			available_construction_types.pick_random()
		)

	# 6 fake newspaper advertisements.
	for i in range(6):
		newspaper_items.append(
			Enums.ItemType.FAKE_NEWS
		)

	newspaper_items.shuffle()

	current_page = 0


func rebuild_pages() -> void:
	page_start_indices.clear()

	if newspaper_items.is_empty():
		return

	var index: int = 0

	while index < newspaper_items.size():
		page_start_indices.append(index)

		clear_page()

		var page_item_count: int = 0

		while index < newspaper_items.size():
			var item = NEWSPAPER_ITEM.instantiate()

			item.item_type = newspaper_items[index]
			item.custom_minimum_size = Vector2(
				item_width,
				item_height
			)

			items_container.add_child(item)

			await get_tree().process_frame
			
			var max_content_height: float = (
				content_area.size.y - bottom_safety_margin
			)

			if items_container.size.y > max_content_height:
				items_container.remove_child(item)
				item.queue_free()
				break

			page_item_count += 1
			index += 1

		if page_item_count == 0:
			index += 1

	clear_page()


func show_page() -> void:
	clear_page()

	if page_start_indices.is_empty():
		update_navigation()
		return

	current_page = clampi(
		current_page,
		0,
		page_start_indices.size() - 1
	)

	var start_index: int = page_start_indices[current_page]
	var end_index: int = newspaper_items.size()

	if current_page + 1 < page_start_indices.size():
		end_index = page_start_indices[current_page + 1]

	for i in range(start_index, end_index):
		var item = NEWSPAPER_ITEM.instantiate()

		item.item_type = newspaper_items[i]
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
	var page_count: int = maxi(
		page_start_indices.size(),
		1
	)

	page_number_label.text = str(current_page + 1)

	previous_button.disabled = current_page <= 0
	next_button.disabled = current_page >= page_count - 1


func _on_previous_page_pressed() -> void:
	if current_page <= 0:
		return

	current_page -= 1
	show_page()


func _on_next_page_pressed() -> void:
	if current_page >= page_start_indices.size() - 1:
		return

	current_page += 1
	show_page()
