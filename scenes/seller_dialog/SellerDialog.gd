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

	hide()

	if current_offer != null:
		_start_dialog()
		return

	if test_material != null:
		setup(_create_debug_offer())


func setup(new_offer: MarketOffer) -> void:
	if new_offer == null:
		return

	if new_offer.material == null:
		return

	if new_offer.seller == null:
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
	var result: Array[Dictionary] = [
		{
			"id": "condition",
			"text": "Anything wrong with these?"
		},
		{
			"id": "storage",
			"text": "How were these stored?"
		},
		{
			"id": "reason_for_sale",
			"text": "Why are you selling them?"
		},
		{
			"id": "price",
			"text": "Why this price?"
		}
	]
	
	result.append_array(_get_revealed_material_questions())

	#match construction_material.material_type:
		#Enums.ItemType.PLANK:
			#result.append_array(_get_plank_questions())
#
		#Enums.ItemType.BEAM:
			#result.append_array(_get_beam_questions())
#
		#Enums.ItemType.BRICK:
			#result.append_array(_get_brick_questions())
#
		#Enums.ItemType.CONCREATE:
			#result.append_array(_get_concrete_questions())

	return result


func _get_revealed_material_questions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	if current_offer == null:
		return result

	for clue in current_offer.revealed_clues:
		var question := _get_material_question(clue)

		if not question.is_empty():
			result.append(question)

	return result


func _get_material_question(clue: Enums.MaterialClue) -> Dictionary:
	match clue:
		Enums.MaterialClue.PLANK_TERMITES:
			return {
				"id": "plank_termites",
				"text": "These planks look like they have termites."
			}

		Enums.MaterialClue.PLANK_ROT:
			return {
				"id": "plank_rot",
				"text": "Why are some of these planks darker?"
			}

		Enums.MaterialClue.PLANK_WARPED:
			return {
				"id": "plank_warped",
				"text": "Are these supposed to be this bent?"
			}

		Enums.MaterialClue.BEAM_CRACKS:
			return {
				"id": "beam_cracks",
				"text": "That beam has a pretty big crack. That's normal?"
			}

		Enums.MaterialClue.BEAM_RUST:
			return {
				"id": "beam_insects",
				"text": "What's with all these tiny holes?"
			}

		Enums.MaterialClue.BEAM_WARPED:
			return {
				"id": "beam_warped",
				"text": "This beam is shaped like a banana."
			}

		Enums.MaterialClue.BRICK_CRACKS:
			return {
				"id": "brick_cracks",
				"text": "Why are some of these bricks cracked?"
			}

		Enums.MaterialClue.BRICK_WHITE_MARKS:
			return {
				"id": "brick_white_marks",
				"text": "What's that white stuff all over them?"
			}

		Enums.MaterialClue.BRICK_CHIPPED:
			return {
				"id": "brick_chipped",
				"text": "Half of these look like they lost a fight."
			}

		Enums.MaterialClue.CONCRETE_RADIATION:
			return {
				"id": "concrete_glow",
				"text": "Why is it glowing?"
			}

		Enums.MaterialClue.CONCRETE_CRUMBLING:
			return {
				"id": "concrete_crumbling",
				"text": "Why does this crumble when I touch it?"
			}

		Enums.MaterialClue.CONCRETE_WATER_DAMAGE:
			return {
				"id": "concrete_water",
				"text": "Was this stuff sitting in water?"
			}

	return {}


func _get_plank_questions() -> Array[Dictionary]:
	return [
		{
			"id": "plank_termites",
			"text": "These planks look like they have termites."
		},
		{
			"id": "plank_rot",
			"text": "Why are some of these planks darker?"
		},
		{
			"id": "plank_warped",
			"text": "Are these supposed to be this bent?"
		}
	]


func _get_beam_questions() -> Array[Dictionary]:
	return [
		{
			"id": "beam_cracks",
			"text": "That beam has a pretty big crack. That's normal?"
		},
		{
			"id": "beam_insects",
			"text": "What's with all these tiny holes?"
		},
		{
			"id": "beam_warped",
			"text": "This beam is shaped like a banana."
		}
	]


func _get_brick_questions() -> Array[Dictionary]:
	return [
		{
			"id": "brick_cracks",
			"text": "Why are some of these bricks cracked?"
		},
		{
			"id": "brick_white_marks",
			"text": "What's that white stuff all over them?"
		},
		{
			"id": "brick_chipped",
			"text": "Half of these look like they lost a fight."
		}
	]

func _get_concrete_questions() -> Array[Dictionary]:
	return [
		{
			"id": "concrete_glow",
			"text": "Why is it glowing?"
		},
		{
			"id": "concrete_crumbling",
			"text": "Why does this crumble when I touch it?"
		},
		{
			"id": "concrete_water",
			"text": "Was this stuff sitting in water?"
		}
	]


func _restore_follow_up_questions() -> void:
	for question_id in asked_question_ids:
		_add_follow_up_questions(question_id)


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
			return _get_condition_answer(defective)

		"storage":
			return _get_storage_answer(defective)

		"reason_for_sale":
			return _get_reason_answer(defective)

		"price":
			return _get_price_answer(defective)

		"condition_follow_up":
			return _get_condition_follow_up_answer(defective)

		"storage_follow_up":
			return _get_storage_follow_up_answer(defective)

		"plank_termites":
			return _get_plank_termites_answer(defective)

		"plank_rot":
			return _get_plank_rot_answer(defective)

		"plank_warped":
			return _get_plank_warped_answer(defective)

		"beam_cracks":
			return _get_beam_cracks_answer(defective)

		"beam_insects":
			return _get_beam_insects_answer(defective)

		"beam_warped":
			return _get_beam_warped_answer(defective)

		"brick_cracks":
			return _get_brick_cracks_answer(defective)

		"brick_white_marks":
			return _get_brick_white_marks_answer(defective)

		"brick_chipped":
			return _get_brick_chipped_answer(defective)

		"concrete_glow":
			return _get_concrete_glow_answer(defective)

		"concrete_crumbling":
			return _get_concrete_crumbling_answer(defective)

		"concrete_water":
			return _get_concrete_water_answer(defective)

		# FOLLOW UPS
		"plank_termites_follow_up":
			return _get_plank_termites_follow_up_answer(defective)

		"beam_cracks_follow_up":
			return _get_beam_cracks_follow_up_answer(defective)

		"brick_chipped_follow_up":
			return _get_brick_chipped_follow_up_answer(defective)

		"concrete_glow_follow_up":
			return _get_concrete_glow_follow_up_answer(defective)

		"concrete_crumbling_follow_up":
			return _get_concrete_crumbling_follow_up_answer(defective)

	return "That's a strangely specific question."


func _get_plank_termites_answer(defective: bool) -> String:
	if defective:
		return _pick([
			"Termites? No. Those are ventilation holes.",
			"They're not termites. They're very small wood inspectors.",
			"I haven't seen any termites. Holes, yes. Termites, no.",
			"If there were termites, wouldn't they have finished eating it already?",
			"The termites are not included in the price.",
			"Could be termites. Could be artisanal texture.",
			"They're probably gone. Probably."
		])

	return _pick([
		"Those aren't termite holes.",
		"No insects. The wood is clean.",
		"Just old marks from previous use.",
		"Nothing alive in there. I checked.",
		"No termites. You'll have to bring your own."
	])


func _get_plank_rot_answer(defective: bool) -> String:
	if defective:
		return _pick([
			"Rotten? That's premium aged timber.",
			"It's not rotten. It's just... softer than usual.",
			"That's where the wood has the most personality.",
			"A little moisture builds character.",
			"Rot is such an ugly word. I prefer 'organic recycling'.",
			"Dark wood costs more in furniture stores."
		])

	return _pick([
		"That's just natural colour variation.",
		"The wood is dry.",
		"Nothing rotten there.",
		"Different boards age differently.",
		"Looks worse than it is."
	])


func _get_plank_warped_answer(defective: bool) -> String:
	if defective:
		return _pick([
			"Straight is subjective.",
			"It'll straighten out when you nail it hard enough.",
			"That's aerodynamic timber.",
			"You wanted planks, not rulers.",
			"Turn it around. Now it bends the other way. Problem solved.",
			"That's a feature. Makes curved walls easier."
		])

	return _pick([
		"Natural wood is never perfectly straight.",
		"They're straight enough.",
		"Nothing unusual for timber.",
		"Maybe one or two moved slightly while drying."
	])


func _get_beam_cracks_answer(defective: bool) -> String:
	if defective:
		return _pick([
			"That's not a crack. That's an expansion feature.",
			"It's still one beam, isn't it?",
			"Put the cracked side toward the wall.",
			"Cracks make it lighter. Easier installation.",
			"I've seen worse beams holding actual houses.",
			"Once the roof is on top, it'll have motivation to stay together."
		])

	return _pick([
		"Small surface cracks are normal.",
		"Nothing structural there.",
		"The beam is solid.",
		"That's mostly cosmetic."
	])


func _get_beam_insects_answer(defective: bool) -> String:
	if defective:
		return _pick([
			"Tiny holes? Factory ventilation.",
			"I haven't personally met the insects.",
			"Maybe something lived there once. Past tense is important.",
			"Those are speed holes.",
			"If they're still inside, you're basically getting free pets.",
			"They haven't complained about the wood quality."
		])

	return _pick([
		"Just old nail holes.",
		"No insect damage.",
		"Nothing living inside.",
		"Those marks aren't from bugs."
	])


func _get_beam_warped_answer(defective: bool) -> String:
	if defective:
		return _pick([
			"It's shaped like a banana because bananas are structurally excellent.",
			"Curved architecture is very fashionable.",
			"Once you put enough weight on it, it'll reconsider.",
			"Technically it still connects point A to point B.",
			"Perfect for anyone building a Viking ship."
		])

	return _pick([
		"There's only minor movement.",
		"Wood changes shape a little while drying.",
		"It should be fine once installed.",
		"Nothing serious."
	])


func _get_brick_cracks_answer(defective: bool) -> String:
	if defective:
		return _pick([
			"Cracked? I call them pre-separated bricks.",
			"Mortar exists for a reason.",
			"It's still a brick if you don't pull it apart.",
			"Those are stress-relief lines.",
			"You'll put them inside a wall. Nobody will know.",
			"Half a crack is still mostly a brick."
		])

	return _pick([
		"Mostly superficial marks.",
		"They're solid.",
		"I haven't noticed any serious cracking.",
		"Nothing that should affect construction."
	])


func _get_brick_white_marks_answer(defective: bool) -> String:
	if defective:
		return _pick([
			"White stuff? Brick dandruff.",
			"That's free decoration.",
			"It probably washes off.",
			"Could be salts. Could be personality.",
			"I wouldn't lick it, but otherwise you'll be fine.",
			"That's how you know they're authentic."
		])

	return _pick([
		"Just harmless surface residue.",
		"It should clean off.",
		"Pretty normal after storage.",
		"The bricks themselves are fine."
	])


func _get_brick_chipped_answer(defective: bool) -> String:
	if defective:
		return _pick([
			"They didn't lose a fight. They survived one.",
			"Those corners weren't doing anything useful anyway.",
			"Free rustic finish.",
			"Just rotate the bad side toward the wall.",
			"You pay for the brick, not all four corners.",
			"Architects charge extra for this kind of texture."
		])

	return _pick([
		"A few chipped corners are normal.",
		"Nothing serious.",
		"They're still perfectly usable.",
		"Mostly cosmetic damage."
	])


func _get_concrete_glow_answer(defective: bool) -> String:
	if defective:
		return _pick([
			"Glowing? That's premium concrete.",
			"It's not radiation. It's... enthusiasm.",
			"That's the deluxe night-visibility package.",
			"If it was dangerous, would I be standing this close?",
			"It only glows a little.",
			"Radiation is such a negative word. I prefer 'energy efficient'.",
			"Probably just some spicy minerals.",
			"At least you won't need lights in the basement."
		])

	return _pick([
		"Glowing? Must be the lighting.",
		"I don't see anything.",
		"Some minerals reflect light strangely.",
		"Maybe you've been staring at it too long."
	])


func _get_concrete_crumbling_answer(defective: bool) -> String:
	if defective:
		return _pick([
			"Stop touching it so hard.",
			"It only crumbles when people keep poking it.",
			"That's the optional gravel feature.",
			"Once it's inside the building, who's going to touch it?",
			"Everything becomes dust eventually.",
			"That's just the concrete shedding its winter coat.",
			"A little crumble proves it's real concrete."
		])

	return _pick([
		"Probably just loose material on the surface.",
		"The main structure is solid.",
		"I haven't noticed any serious crumbling.",
		"It should be fine."
	])


func _get_concrete_water_answer(defective: bool) -> String:
	if defective:
		return _pick([
			"Water? Concrete loves water. That's how they make it.",
			"It may have experienced some weather.",
			"Only a little rain. Maybe several little rains.",
			"It wasn't underwater if that's what you're asking.",
			"There was a tarp. Then there wasn't.",
			"Technically every puddle eventually dries.",
			"It had an outdoor phase."
		])

	return _pick([
		"No, it was kept dry.",
		"It wasn't sitting in water.",
		"It was protected from rain.",
		"No moisture problems that I know of."
	])


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

		"plank_termites":
			_add_question_if_missing(
				"plank_termites_follow_up",
				"Then what made all those holes?"
			)

		"beam_cracks":
			_add_question_if_missing(
				"beam_cracks_follow_up",
				"Would you actually put this in your own roof?"
			)

		"brick_chipped":
			_add_question_if_missing(
				"brick_chipped_follow_up",
				"How many corners does a brick need according to you?"
			)

		"concrete_glow":
			_add_question_if_missing(
				"concrete_glow_follow_up",
				"Then why is my Geiger counter screaming?"
			)

		"concrete_crumbling":
			_add_question_if_missing(
				"concrete_crumbling_follow_up",
				"Then why is it literally falling apart?"
			)




func _get_condition_answer(defective: bool) -> String:
	if defective:
		match seller_data.personality:
			Enums.SellerPersonality.CALM:
				return _pick([
					"Defects is a very dramatic word.",
					"I prefer the term 'experienced materials'.",
					"They've got character. Character is expensive these days.",
					"Nothing structural. Probably. Most likely."
				])

			Enums.SellerPersonality.NERVOUS:
				return _pick([
					"Defects? Haha. No. Why? Did you see something?",
					"Nope. Absolutely not. Next question.",
					"They're fine. Fine-ish. Construction fine.",
					"Look, everything breaks eventually. That's philosophy, not a defect."
				])

			Enums.SellerPersonality.FRIENDLY:
				return _pick([
					"A few little imperfections. Free personality included.",
					"They're not showroom materials, but neither am I.",
					"Nothing a confident builder can't ignore.",
					"A scratch here, a questionable spot there. Keeps life interesting."
				])

			Enums.SellerPersonality.RUDE:
				return _pick([
					"If you want perfect, go pay perfect prices.",
					"They're building materials, not a wedding cake.",
					"You buying them or interviewing them?",
					"Defects? I've seen worse houses still standing."
				])

			Enums.SellerPersonality.TALKATIVE:
				return _pick([
					"Funny story about that crack actually... anyway, it's probably fine.",
					"They've been through a lot. Haven't we all?",
					"There was this one incident, but honestly we don't need to get into that.",
					"My cousin checked them. He's watched a lot of construction videos."
				])

	return _pick([
		"Nope. They're surprisingly decent.",
		"Nothing wrong with them. Boring, I know.",
		"They're solid. Unlike my financial decisions.",
		"No defects that I know of.",
		"They're good. I would use them myself. Probably."
	])


func _get_storage_answer(defective: bool) -> String:
	if defective:
		match seller_data.personality:
			Enums.SellerPersonality.CALM:
				return _pick([
					"Mostly indoors.",
					"They had a roof above them for the important parts.",
					"Protected from most weather events.",
					"Let's just say the weather did not completely win."
				])

			Enums.SellerPersonality.NERVOUS:
				return _pick([
					"Inside. Mostly. Define inside.",
					"Dry place. Very dry. Except when it rained.",
					"Why does everyone keep asking me about storage?",
					"They definitely weren't underwater."
				])

			Enums.SellerPersonality.FRIENDLY:
				return _pick([
					"Mostly covered. They got a little fresh air.",
					"They spent some quality time outdoors.",
					"Nothing crazy. A little sun, a little rain, a little adventure.",
					"We gave them the premium garage-adjacent package."
				])

			Enums.SellerPersonality.RUDE:
				return _pick([
					"On the ground. Where else would I put them, the fridge?",
					"They survived. That's what matters.",
					"Storage was storage.",
					"They weren't stored on the moon if that's what you're asking."
				])

			Enums.SellerPersonality.TALKATIVE:
				return _pick([
					"First garage, then shed, then outside, then garage again. Long story.",
					"They moved around more than I did last year.",
					"There was a tarp. Excellent tarp. Until the wind disagreed.",
					"My brother was responsible for storage. That should tell you enough."
				])

	return _pick([
		"Dry storage, protected from the weather.",
		"Inside the whole time.",
		"Covered and kept off the wet ground.",
		"Properly stored. Nothing exciting happened."
	])


func _get_reason_answer(defective: bool) -> String:
	if defective:
		return _pick([
			"I need the space. Preferably today.",
			"Let's just say I no longer have plans for them.",
			"My wife said either the materials leave or I do.",
			"They've been sitting here long enough to start paying rent.",
			"I've recently developed a strong interest in having them somewhere else.",
			"Project changed. Materials didn't get the memo."
		])

	return _pick([
		"Bought too much. Classic construction mathematics.",
		"Project's finished and these are just sitting around.",
		"I apparently measured everything using optimism.",
		"Ordered extra because somebody said 'better safe than sorry'.",
		"I don't need them anymore and my garage would like its floor back."
	])


func _get_price_answer(defective: bool) -> String:
	if defective:
		return _pick([
			"Because that's the number that felt right this morning.",
			"I checked the market. Briefly. Very briefly.",
			"It's already discounted for... reasons.",
			"You're not paying for perfection. You're paying for opportunity.",
			"Inflation. Economy. Global events. Pick one.",
			"Because I wrote that number in the newspaper and now we're committed."
		])

	return _pick([
		"That's around what they're worth.",
		"I checked similar listings and then added confidence.",
		"Good materials aren't free. Sadly.",
		"I started higher, then remembered I actually want to sell them.",
		"Supply, demand, and my electricity bill."
	])


func _get_condition_follow_up_answer(defective: bool) -> String:
	if defective:
		return _pick([
			"Why are you looking at me like that?",
			"I said they're fine. Let's not ruin a beautiful business relationship.",
			"Hidden damage can't hurt you if you don't find it.",
			"Look, technically everything is damaged on a molecular level.",
			"You're asking an impressive number of questions for someone who hasn't paid yet.",
			"Fine. There may be one or two... cosmetic adventures."
		])

	return _pick([
		"Yes, I'm sure.",
		"You can inspect them yourself if you don't trust my beautiful face.",
		"No hidden surprises.",
		"As far as I know, they're clean."
	])


func _get_storage_follow_up_answer(defective: bool) -> String:
	if defective:
		return _pick([
			"Outside is such a broad concept.",
			"Define 'left'. And define 'outside'.",
			"For a while. Time is subjective.",
			"There was a tarp involved.",
			"Maybe. But rain is basically just aggressive humidity.",
			"Only when the garage was full."
		])

	return _pick([
		"No. They were properly covered.",
		"Not exposed to rain.",
		"They stayed dry.",
		"No outdoor adventures for these."
	])


func _pick(lines: Array[String]) -> String:
	return lines.pick_random()


func _add_question_if_missing(id: String, text: String) -> void:
	for question in available_questions:
		if question["id"] == id:
			return

	available_questions.append({
		"id": id,
		"text": text
	})


func _get_plank_termites_follow_up_answer(defective: bool) -> String:
	if defective:
		return _pick([
			"Woodpeckers. Very small woodpeckers.",
			"I sell wood, not insect crime investigations.",
			"Maybe the plank had acne.",
			"Could be old holes. Could be new holes. Holes are complicated.",
			"If something lived there, I'm pretty sure it moved out.",
			"Look, I haven't personally seen a termite carrying a suitcase."
		])

	return _pick([
		"Probably old nail holes.",
		"Just marks from previous use.",
		"Nothing living in there.",
		"They're surface marks, that's all.",
		"I checked them. No insects."
	])


func _get_beam_cracks_follow_up_answer(defective: bool) -> String:
	if defective:
		return _pick([
			"Would I put it in my roof? That's a very personal question.",
			"My roof already has beams.",
			"Absolutely. Somewhere near the edge.",
			"Sure. Maybe not directly above my bed.",
			"I've seen worse holding up entire garages.",
			"If it falls, technically that's the roof's problem."
		])

	return _pick([
		"Yes, I'd use it.",
		"The crack is superficial.",
		"I wouldn't be worried about it.",
		"It's still structurally sound.",
		"Yes. Nothing serious there."
	])


func _get_brick_chipped_follow_up_answer(defective: bool) -> String:
	if defective:
		return _pick([
			"Three corners is basically four if you use enough mortar.",
			"Depends how ambitious your wall is.",
			"Nobody counts the corners once it's inside the wall.",
			"You're paying for bricks, not geometry.",
			"Two good corners and a positive attitude.",
			"Mortar can create any corner you believe in."
		])

	return _pick([
		"Four is ideal, obviously.",
		"Those chips are only cosmetic.",
		"The important parts are intact.",
		"They'll still lay normally.",
		"Nothing that mortar won't hide."
	])


func _get_concrete_glow_follow_up_answer(defective: bool) -> String:
	if defective:
		return _pick([
			"Cheap Geiger counter.",
			"Have you tried turning it off and on again?",
			"Geiger counters are very dramatic.",
			"That's probably background radiation. Very foreground background radiation.",
			"Okay... maybe don't sleep next to it.",
			"I sell concrete, not nuclear physics.",
			"Fine. There may be a tiny amount of spicy rock in there.",
			"Maybe stand a little further away while we negotiate."
		])

	return _pick([
		"Your counter probably needs calibration.",
		"Try testing it somewhere else.",
		"Could be interference nearby.",
		"I'd check the batteries first.",
		"The material shouldn't be radioactive."
	])


func _get_concrete_crumbling_follow_up_answer(defective: bool) -> String:
	if defective:
		return _pick([
			"Because you keep touching it.",
			"Stop testing it and it'll stop falling apart.",
			"It's just removing unnecessary concrete.",
			"That's surface-level crumbling. Mostly.",
			"Gravity is being unusually aggressive today.",
			"It'll be stronger once nobody touches it.",
			"Look, some concrete is more emotionally fragile than others."
		])

	return _pick([
		"That's probably just loose material on the surface.",
		"The main body is still solid.",
		"It shouldn't keep crumbling.",
		"Brush the loose material off and check again.",
		"I haven't seen any deeper damage."
	])


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
