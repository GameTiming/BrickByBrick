class_name SellerDialog
extends Control


signal buy_requested(offer: MarketOffer, price: int)
signal report_requested(offer: MarketOffer)
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


var current_offer: MarketOffer
var construction_material: ConstructionMaterial
var seller_data: SellerData

var asking_price: int

var available_questions: Array[Dictionary] = []
var asked_question_ids: Array[String] = []

var negotiation_round: int = 0

const MAX_NEGOTIATION_ROUNDS: int = 2


@export_category("Debug")
@export var test_material: ConstructionMaterial
@export var test_has_defects: bool = false


func _ready() -> void:
	negotiate_button.pressed.connect(_on_negotiate_pressed)
	buy_button.pressed.connect(_on_buy_pressed)
	report_button.pressed.connect(_on_report_pressed)
	leave_button.pressed.connect(_on_leave_pressed)

	negotiation_panel.visible = false

	# Dialog should normally be hidden until Seller interaction.
	hide()

	# Offer may have been assigned before entering the tree.
	if current_offer != null:
		_start_dialog()
		return

	# Allows direct F6 testing of SellerDialog.
	if test_material != null:
		setup(_create_debug_offer())


func setup(new_offer: MarketOffer) -> void:
	if new_offer == null:
		push_error("SellerDialog received null MarketOffer")
		return

	if new_offer.material == null:
		push_error("MarketOffer has no ConstructionMaterial")
		return

	if new_offer.seller == null:
		push_error("MarketOffer has no SellerData")
		return

	current_offer = new_offer
	construction_material = current_offer.material
	seller_data = current_offer.seller

	if is_node_ready():
		_start_dialog()


func _start_dialog() -> void:
	if current_offer == null:
		return

	if construction_material == null:
		return

	if seller_data == null:
		return

	# IMPORTANT:
	# Use MarketOffer price, not ConstructionMaterial.current_price.
	# This keeps negotiated price when returning to this seller.
	asking_price = current_offer.negotiated_price

	# Restore conversation state.
	asked_question_ids.clear()
	asked_question_ids.assign(
		current_offer.asked_question_ids
	)

	# Restore negotiation state.
	negotiation_round = current_offer.negotiation_round

	negotiate_button.disabled = current_offer.negotiation_closed
	negotiation_panel.visible = false

	seller_title.text = "Seller"

	_update_price()

	seller_text.text = _get_intro_text()

	available_questions = _get_initial_questions()

	_restore_follow_up_questions()

	_refresh_questions()

	show()


func _get_intro_text() -> String:
	match seller_data.personality:
		Enums.SellerPersonality.CALM:
			return (
				"Take your time. I've got some construction materials "
				+ "for sale. I'm asking %d €."
				% asking_price
			)

		Enums.SellerPersonality.NERVOUS:
			return (
				"Yeah... I've got these materials for sale. "
				+ "They're fine. I'm asking %d €."
				% asking_price
			)

		Enums.SellerPersonality.FRIENDLY:
			return (
				"Hey! Good timing. I've got some decent materials here. "
				+ "I'm asking %d €."
				% asking_price
			)

		Enums.SellerPersonality.RUDE:
			return (
				"They're %d €. If you're interested, ask. "
				+ "If not, don't waste my time."
				% asking_price
			)

		Enums.SellerPersonality.TALKATIVE:
			return (
				"These came from a job I was working on. "
				+ "Long story. Anyway, I'm asking %d € for the lot."
				% asking_price
			)

	return (
		"I've got some construction materials for sale. "
		+ "I'm asking %d €."
		% asking_price
	)


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


func _restore_follow_up_questions() -> void:
	if "condition" in asked_question_ids:
		_add_question_if_missing(
			"condition_follow_up",
			"Are you sure there is no hidden damage?"
		)

	if "storage" in asked_question_ids:
		_add_question_if_missing(
			"storage_follow_up",
			"Were they ever left outside?"
		)


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

	_save_asked_questions()

	var answer := _get_seller_answer(question_id)

	seller_text.text = answer

	_add_follow_up_questions(question_id)
	_refresh_questions()


func _save_asked_questions() -> void:
	if current_offer == null:
		return

	current_offer.asked_question_ids.clear()
	current_offer.asked_question_ids.assign(
		asked_question_ids
	)


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
	if current_offer == null:
		return

	if current_offer.negotiation_closed:
		return

	negotiation_panel.visible = not negotiation_panel.visible

	if negotiation_panel.visible:
		_show_negotiation_options()


func _show_negotiation_options() -> void:
	for child in negotiation_options.get_children():
		child.queue_free()

	negotiation_label.text = "Make an offer:"

	var offer_prices: Array[int] = [
		int(asking_price * 0.9),
		int(asking_price * 0.8),
		int(asking_price * 0.7)
	]

	for offered_price in offer_prices:
		var button := Button.new()

		button.text = "%d €" % offered_price

		button.pressed.connect(
			_on_offer_pressed.bind(offered_price)
		)

		negotiation_options.add_child(button)


func _on_offer_pressed(offered_price: int) -> void:
	if current_offer == null:
		return

	negotiation_round += 1
	current_offer.negotiation_round = negotiation_round

	var minimum_price := _get_seller_minimum_price()

	if offered_price >= minimum_price:
		asking_price = offered_price

		current_offer.negotiated_price = asking_price
		current_offer.negotiation_closed = true

		negotiate_button.disabled = true
		negotiation_panel.visible = false

		seller_text.text = (
			"Fine. %d €. You've got a deal."
			% asking_price
		)

	else:
		if negotiation_round >= MAX_NEGOTIATION_ROUNDS:
			current_offer.negotiation_closed = true

			negotiate_button.disabled = true
			negotiation_panel.visible = false

			seller_text.text = (
				"No. That's too low. "
				+ "My price is %d €."
				% asking_price
			)

		else:
			var counter_offer := int(
				(asking_price + minimum_price) / 2.0
			)

			asking_price = counter_offer

			# Seller's counter offer becomes the new remembered price.
			current_offer.negotiated_price = asking_price

			seller_text.text = (
				"No, that's too low. "
				+ "I could do %d €."
				% asking_price
			)

			_show_negotiation_options()

	_update_price()


func _get_seller_minimum_price() -> int:
	if construction_material == null:
		return 0

	if _material_has_defects():
		return int(
			construction_material.current_price * 0.70
		)

	return int(
		construction_material.current_price * 0.85
	)


func _update_price() -> void:
	price_label.text = "Price: %d €" % asking_price


func _on_buy_pressed() -> void:
	if current_offer == null:
		return

	current_offer.negotiated_price = asking_price

	buy_requested.emit(
		current_offer,
		asking_price
	)

	hide()
	dialog_closed.emit()


func _on_report_pressed() -> void:
	if current_offer == null:
		return

	report_requested.emit(current_offer)

	hide()
	dialog_closed.emit()


func _on_leave_pressed() -> void:
	_save_asked_questions()

	hide()

	dialog_closed.emit()


func _material_has_defects() -> bool:
	# Temporary.
	# Later this should come from:
	# current_offer.material / ConstructionMaterial defects.
	return test_has_defects


func _create_debug_offer() -> MarketOffer:
	var debug_offer := MarketOffer.new()

	debug_offer.id = "debug"
	debug_offer.material = test_material.duplicate(true)
	debug_offer.negotiated_price = debug_offer.material.current_price

	var debug_seller := SellerData.new()

	debug_seller.personality = Enums.SellerPersonality.CALM
	debug_seller.deception_skill = 50
	debug_seller.negotiation_skill = 50
	debug_seller.patience = 3

	debug_offer.seller = debug_seller

	return debug_offer
