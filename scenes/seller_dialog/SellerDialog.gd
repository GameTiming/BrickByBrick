class_name SellerDialog
extends Control


signal buy_requested(construction_material: ConstructionMaterial, price: int)
signal report_requested(construction_material: ConstructionMaterial)
signal dialog_closed


@onready var seller_title: Label = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SellerTitle
@onready var price_label: Label = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PriceLabel
@onready var seller_text: RichTextLabel = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SellerText

@onready var questions: VBoxContainer = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Questions

@onready var negotiation_panel: VBoxContainer = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/NegotiationPanel
@onready var negotiation_label: Label = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/NegotiationPanel/NegotiationLabel
@onready var negotiation_options: HBoxContainer = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/NegotiationPanel/NegotiationOptions

@onready var negotiate_button: Button = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Actions/NegotiationButton
@onready var buy_button: Button = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Actions/BuyButton
@onready var report_button: Button = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Actions/ReportButton
@onready var leave_button: Button = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Actions/LeaveButton


var construction_material: ConstructionMaterial
var asking_price: int

var available_questions: Array[Dictionary] = []
var asked_question_ids: Array[String] = []

var negotiation_round: int = 0

const MAX_NEGOTIATION_ROUNDS: int = 2
var seller_personality: Enums.SellerPersonality


@export_category("Debug")
@export var test_material: ConstructionMaterial
@export var test_has_defects: bool = false


func _ready() -> void:
	negotiate_button.pressed.connect(_on_negotiate_pressed)
	buy_button.pressed.connect(_on_buy_pressed)
	report_button.pressed.connect(_on_report_pressed)
	leave_button.pressed.connect(_on_leave_pressed)

	negotiation_panel.visible = false

	# Allows SellerDialog scene to be tested directly with F6.
	if construction_material == null and test_material != null:
		construction_material = test_material.duplicate(true)

	if construction_material != null:
		_start_dialog()


func setup(dialog_material: ConstructionMaterial) -> void:
	construction_material = dialog_material
	_start_dialog()


func _start_dialog() -> void:
	if construction_material == null:
		return

	asking_price = construction_material.current_price

	asked_question_ids.clear()
	negotiation_round = 0

	negotiate_button.disabled = false
	negotiation_panel.visible = false

	seller_title.text = "Seller"

	_update_price()

	seller_text.text = (
		"I've got some construction materials for sale.\n"
		+ "They're in good condition. I'm asking %d € for them."
		% asking_price
	)

	available_questions = _get_initial_questions()

	_refresh_questions()

	show()


func _get_initial_questions() -> Array[Dictionary]:
	return [
		{
			"id": "condition",
			"text": "Are there any defects?"
		},
		{
			"id": "storage",
			"text": "How were these materials stored?"
		},
		{
			"id": "reason_for_sale",
			"text": "Why are you selling them?"
		},
		{
			"id": "price",
			"text": "Why are you asking this price?"
		}
	]


func _refresh_questions() -> void:
	for child in questions.get_children():
		child.queue_free()

	for question in available_questions:
		var question_id: String = question["id"]

		if question_id in asked_question_ids:
			continue

		var button := Button.new()
		button.text = question["text"]

		button.pressed.connect(
			_on_question_pressed.bind(question_id)
		)

		questions.add_child(button)


func _on_question_pressed(question_id: String) -> void:
	if question_id in asked_question_ids:
		return

	asked_question_ids.append(question_id)

	var answer := _get_seller_answer(question_id)

	seller_text.text = answer

	_add_follow_up_questions(question_id)
	_refresh_questions()


func _get_seller_answer(question_id: String) -> String:
	var defective := _material_has_defects()

	match question_id:
		"condition":
			if defective:
				return (
					"Defects? Nothing I'd call a real defect. "
					+ "They're construction materials, not furniture. "
					+ "A few marks here and there are perfectly normal."
				)

			return (
				"No. They're in good condition. "
				+ "I haven't noticed anything wrong with them."
			)

		"storage":
			if defective:
				return (
					"They were stored properly. "
					+ "Maybe they spent a little time outside, "
					+ "but nothing that would cause any real problems."
				)

			return (
				"They were kept in proper storage "
				+ "and protected from the weather."
			)

		"reason_for_sale":
			if defective:
				return (
					"I just need them gone. "
					+ "They're taking up space and I don't need them anymore."
				)

			return (
				"I bought more than I needed for the job, "
					+ "so I'm selling what's left."
			)

		"price":
			if defective:
				return (
					"It's a fair price. "
					+ "I'm not trying to get rich here, "
					+ "I just want a quick sale."
				)

			return (
				"I checked what materials like these usually sell for. "
					+ "I think the price is reasonable."
			)

		"condition_follow_up":
			if defective:
				return (
					"I already told you, there's nothing serious. "
					+ "If you're expecting brand-new materials, "
					+ "you should buy them from a store."
				)

			return (
				"Yes, I'm sure. "
					+ "As far as I know there are no hidden problems."
			)

		"storage_follow_up":
			if defective:
				return (
					"I don't remember exactly how long they were outside. "
					+ "A few days maybe. Why does it matter?"
				)

			return (
				"They weren't left exposed to rain or moisture."
			)

		_:
			return "What exactly do you want to know?"


func _add_follow_up_questions(question_id: String) -> void:
	match question_id:
		"condition":
			_add_question_if_missing(
				"condition_follow_up",
				"Are you sure there is no hidden damage?"
			)

		"storage":
			_add_question_if_missing(
				"storage_follow_up",
				"Were they ever left outside?"
			)


func _add_question_if_missing(id: String, text: String) -> void:
	for question in available_questions:
		if question["id"] == id:
			return

	available_questions.append({
		"id": id,
		"text": text
	})


func _on_negotiate_pressed() -> void:
	negotiation_panel.visible = not negotiation_panel.visible

	if negotiation_panel.visible:
		_show_negotiation_options()


func _show_negotiation_options() -> void:
	for child in negotiation_options.get_children():
		child.queue_free()

	negotiation_label.text = "Make an offer:"

	var offers: Array[int] = [
		int(asking_price * 0.9),
		int(asking_price * 0.8),
		int(asking_price * 0.7)
	]

	for offer in offers:
		var button := Button.new()
		button.text = "%d €" % offer

		button.pressed.connect(
			_on_offer_pressed.bind(offer)
		)

		negotiation_options.add_child(button)


func _on_offer_pressed(offer: int) -> void:
	negotiation_round += 1

	var minimum_price := _get_seller_minimum_price()

	if offer >= minimum_price:
		asking_price = offer

		seller_text.text = (
			"Fine. %d €. You've got a deal."
			% asking_price
		)

		negotiation_panel.visible = false

	else:
		if negotiation_round >= MAX_NEGOTIATION_ROUNDS:
			seller_text.text = (
				"No. That's too low. "
				+ "My price is %d €."
				% asking_price
			)

			negotiate_button.disabled = true
			negotiation_panel.visible = false

		else:
			var counter_offer := int(
				(asking_price + minimum_price) / 2.0
			)

			asking_price = counter_offer

			seller_text.text = (
				"No, that's too low. "
				+ "I could do %d €."
				% asking_price
			)

			_update_price()
			_show_negotiation_options()

	_update_price()


func _get_seller_minimum_price() -> int:
	if construction_material == null:
		return 0

	if _material_has_defects():
		return int(construction_material.current_price * 0.70)

	return int(construction_material.current_price * 0.85)


func _update_price() -> void:
	price_label.text = "Price: %d €" % asking_price


func _on_buy_pressed() -> void:
	if construction_material == null:
		return

	buy_requested.emit(
		construction_material,
		asking_price
	)

	hide()


func _on_report_pressed() -> void:
	if construction_material == null:
		return

	report_requested.emit(construction_material)

	hide()


func _on_leave_pressed() -> void:
	hide()
	dialog_closed.emit()


func _material_has_defects() -> bool:
	# Temporary debug implementation.
	# Later this will check actual defects from ConstructionMaterial.
	return test_has_defects
