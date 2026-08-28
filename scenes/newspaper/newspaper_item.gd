extends PanelContainer

@onready var hbox_container: HBoxContainer = $MarginContainer/HBoxContainer
@onready var image: NewspaperFrame = $MarginContainer/HBoxContainer/NewspaperFrame

@onready var title_label: Label = $MarginContainer/HBoxContainer/VBoxContainer/TtitleLabel
@onready var summary_label: Label = $MarginContainer/HBoxContainer/VBoxContainer/SummaryLabel
@onready var price_label: Label = $MarginContainer/HBoxContainer/VBoxContainer/PriceLabel
@onready var highlight_border: Panel = $HighlightBorder

@export var item_type: Enums.ItemType = Enums.ItemType.NONE

enum FakeNewsType {
	DAD_JOKE,
	MISSING_CAT,
	MISSING_DOG,
	MAN_SEEKING_WOMAN,
	WOMAN_SEEKING_MAN
}

signal offer_selected(offer: MarketOffer)

var offer: MarketOffer

var fonts: Array[Font] = [
	preload("res://assets/fonts/Arimo-Regular.ttf"),
	preload("res://assets/fonts/Tinos-Regular.ttf"),
	preload("res://assets/fonts/NotoSans_Condensed-Regular.ttf"),
	
	preload("res://assets/fonts/NotoSans_Condensed-Bold.ttf"),
	preload("res://assets/fonts/Tinos-Bold.ttf"),
	preload("res://assets/fonts/Arimo-Bold.ttf"),
]

var fake_titles: Array[String] = [
	"Missing Cat",
	"Missing Dog",
	"Man Seeking Woman",
	"Woman Seeking Man",
	"Dad Joke of the Day",
	"Neighbour Has Seen Everything",
	"Local Mystery"
]

var missing_cat_texts: Array[String] = [
	"Fluffy disappeared Tuesday evening. May respond to food, compliments, or absolutely nothing.",
	"Orange cat missing. Last seen judging the neighbours from a windowsill.",
	"Small black cat missing. Owner insists she is friendly. Postman disagrees."
]

var missing_dog_texts: Array[String] = [
	"Golden retriever missing. Extremely friendly and probably already living with another family.",
	"Small dog missing. Answers to Bruno, sausage, dinner, and the sound of a refrigerator opening.",
	"Dog escaped garden again. Owner says this is becoming a weekly newspaper column."
]

var dad_jokes: Array[String] = [
	"I only know 25 letters of the alphabet. I don't know y.",
	"I used to hate facial hair, but then it grew on me.",
	"What do you call fake spaghetti? An impasta.",
	"I told my wife she should embrace her mistakes. She hugged me.",
	"I don't trust stairs. They're always up to something."
]

var man_seeking_woman: Array[String] = [
	"Single man, 42, enjoys fishing, quiet evenings, and explaining why his lawn mower is better than yours.",
	"Man seeks kind woman. Must tolerate bad jokes and an unreasonable number of power tools.",
	"Local gentleman seeks companionship. Owns house, car, and several extension cords."
]

var woman_seeking_man: Array[String] = [
	"Woman seeks gentleman who can cook, laugh, and locate objects directly in front of him.",
	"Single woman seeks reliable man. Must like dogs. Dog approval required.",
	"Woman, 38, seeks someone for walks, coffee, and pretending to understand furniture instructions."
]

var normal_style := StyleBoxFlat.new()
var highlight_style := StyleBoxFlat.new()

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	highlight_border.visible = false

	if item_type == Enums.ItemType.FAKE_NEWS:
		setup_fake_news()
	else:
		setup_normal_item(offer)
	
	randomize_image_position()
	randomize_font()


func setup_normal_item(new_offer: MarketOffer) -> void:
	if new_offer == null:
		push_error("Real NewspaperItem has no MarketOffer")
		return

	offer = new_offer
	
	image.visible = true
	price_label.visible = true
	
	image.display(item_type)
	
	price_label.text = "%d €" % offer.negotiated_price
	
	mouse_filter = Control.MOUSE_FILTER_STOP


func randomize_image_position() -> void:
	var image_on_left := randi() % 2 == 0

	if image_on_left:
		hbox_container.move_child(image, 0)
	else:
		hbox_container.move_child(image, 1)

func randomize_font() -> void:
	var random_font: Font = fonts.pick_random()

	title_label.add_theme_font_override("font", random_font)
	summary_label.add_theme_font_override("font", random_font)
	price_label.add_theme_font_override("font", random_font)
	
	title_label.add_theme_color_override("font_color", Color.BLACK)
	summary_label.add_theme_color_override("font_color", Color.BLACK)
	price_label.add_theme_color_override("font_color", Color.BLACK)


func setup_fake_news() -> void:
	offer = null
	item_type = Enums.ItemType.FAKE_NEWS

	image.visible = false
	price_label.visible = false

	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var fake_type: FakeNewsType = FakeNewsType.values().pick_random()

	match fake_type:
		FakeNewsType.DAD_JOKE:
			setup_dad_joke()

		FakeNewsType.MISSING_CAT:
			setup_missing_cat()

		FakeNewsType.MISSING_DOG:
			setup_missing_dog()

		FakeNewsType.MAN_SEEKING_WOMAN:
			setup_man_seeking_woman()

		FakeNewsType.WOMAN_SEEKING_MAN:
			setup_woman_seeking_man()


func _gui_input(event: InputEvent) -> void:
	if item_type == Enums.ItemType.FAKE_NEWS:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT \
				and event.pressed \
				and event.double_click:

			if offer == null:
				return

			offer_selected.emit(offer)


func setup_dad_joke() -> void:
	image.visible = false

	title_label.text = "Dad Joke of the Day"
	summary_label.text = dad_jokes.pick_random()

func setup_missing_cat() -> void:
	image.visible = false

	title_label.text = "Missing Cat"
	summary_label.text = missing_cat_texts.pick_random()

	# Later:
	# image.texture = random cat image

func setup_missing_dog() -> void:
	image.visible = false

	title_label.text = "Missing Dog"
	summary_label.text = missing_dog_texts.pick_random()

	# Later:
	# image.texture = random dog image

func setup_man_seeking_woman() -> void:
	image.visible = false

	title_label.text = "Man Seeking Woman"
	summary_label.text = man_seeking_woman.pick_random()

	# Later:
	# image.texture = random man portrait

func setup_woman_seeking_man() -> void:
	image.visible = false

	title_label.text = "Woman Seeking Man"
	summary_label.text = woman_seeking_man.pick_random()

	# Later:
	# image.texture = random woman portrait


func _on_mouse_entered():
	if item_type == Enums.ItemType.FAKE_NEWS:
		return

	highlight_border.visible = true
	modulate = Color(1.1, 1.1, 1.1, 1.1)


func _on_mouse_exited():
	highlight_border.visible = false
	modulate = Color.WHITE
