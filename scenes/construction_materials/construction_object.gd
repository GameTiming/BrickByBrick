class_name ConstructionObject extends Node3D

@export var type: Enums.ItemType


func interact(_interactor: Node3D, tool: Enums.Inspection) -> void:
	get_parent().get_parent().start_investigation(tool) #fuck its horrible... but it's gamejam and I am on low energy
