class_name InteractionComponent extends Area3D

var picked_item: InteractableComponent
var highlighted_item: InteractableComponent


func interact() -> void:
	if highlighted_item == null:
		return
	
	highlighted_item.toggle_highlight(false)
	
	var picked_item_type: Enums.Inspection
	if picked_item != null:
		picked_item.unmount()
		picked_item_type = picked_item.pickup_type
		picked_item = null
	
	if highlighted_item.type == Enums.InteractableType.PICKUP:
		picked_item = highlighted_item
		picked_item.mount(get_parent_node_3d())
		highlighted_item = null
	elif highlighted_item.type == Enums.InteractableType.INTERACTION:
		highlighted_item.interact(owner, picked_item_type)
		highlighted_item = null
	else:
		highlighted_item.start_conversation()


func _on_area_entered(area: Area3D) -> void:
	if area is InteractableComponent and (area.type != Enums.InteractableType.INTERACTION or picked_item != null) and area != picked_item:
		highlighted_item = area
		highlighted_item.toggle_highlight(true)


func _on_area_exited(area: Area3D) -> void:
	if highlighted_item == area:
		highlighted_item.toggle_highlight(false)
		highlighted_item = null
	
	if area == owner.pick_up_area and picked_item != null:
		picked_item.unmount()
		picked_item = null
