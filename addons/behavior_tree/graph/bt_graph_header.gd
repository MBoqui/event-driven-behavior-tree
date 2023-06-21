@tool
class_name  BTGraphHeader
extends ColorRect



var _node : BTGraphNode


func _ready() -> void:
	_find_graph_node()


func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return

	if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		_node.node_selected.emit()



func update(title : String, color : Color) -> void:
	$Title.text = title
	self.color = color



func _find_graph_node() -> void:
	var parent = get_parent()

	if parent is BTGraphNode:
		_node = parent

	var grandparent = parent.get_parent()

	if grandparent is BTGraphNode:
		_node = grandparent
