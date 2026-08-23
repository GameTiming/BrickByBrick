class_name NewspaperFrame extends TextureRect

@onready var newspaper_frame_scene: NewspaperFrameScene = $SubViewport/NewspaperFrameScene


func display(item_type: Enums.ItemType) -> void:
	newspaper_frame_scene.display(item_type)
