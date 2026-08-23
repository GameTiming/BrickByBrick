class_name NewspaperFrameScene extends Node3D

@export var items: Array[ConstructionObject]

func display(type: Enums.ItemType) -> void:
	var selectedItems = items.filter(func(item): return item.type == type)
	
	if selectedItems.size() > 0:
		selectedItems[0].visible = true
