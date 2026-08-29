class_name ConstructionObject extends Node3D

@export var type: Enums.ItemType
@export var conditions: Array[Condition]
@export var main_model: Node3D


func interact(_interactor: Node3D, tool: Enums.Inspection) -> void:
	get_parent().get_parent().start_investigation(tool) #fuck its horrible... but it's gamejam and I am on low energy


func set_condition(clue_type: Enums.MaterialClue, inspection_type: Enums.Inspection) -> void:
	for condition in conditions:
		if condition.type == clue_type and condition.inspections.has(inspection_type):
			condition.visible = true
			main_model.visible = false
			return
