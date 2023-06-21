@tool
class_name BTGraphNode
extends GraphNode



const Header := preload("header.tscn")

const _MAIN_COLOR := Color.DARK_GRAY
const _UTILITY_COLOR := Color.DODGER_BLUE
const _CONDITION_COLOR := Color.DARK_ORANGE
const _MODIFIER_COLOR := Color.DARK_OLIVE_GREEN


var bt_node : BTNode:
	set = _set_bt_node


func _ready() -> void:
	close_request.connect(_on_close_request)
	position_offset_changed.connect(_on_position_offset_changed)


func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return

	if event.button_index == MOUSE_BUTTON_LEFT and event.double_click and bt_node is BTSubtree:
		get_parent().open_tree(BTGraphEdit.OpenTreeMode.SUBTREE, [bt_node.subtree.resource_path, bt_node.tree_index])


func delete_node():
	bt_node.parent = null

	if bt_node is BTComposite:
		for child in bt_node.children.duplicate():
			child.parent = null

	queue_free()


func has_point(point : Vector2) -> bool:
	return Rect2(position_offset, size).has_point(point)



func _refresh_visuals() -> void:
	title = "%s - %s" % [bt_node.sibling_index, bt_node.get_bt_type_name()]
	$Main.update(bt_node.name, _MAIN_COLOR)

	_refresh_decorator_container($Utilities, bt_node.utilities, _UTILITY_COLOR)
	_refresh_decorator_container($Conditions, bt_node.conditions, _CONDITION_COLOR)
	_refresh_decorator_container($Modifiers, bt_node.modifiers, _MODIFIER_COLOR)


func _refresh_decorator_container(container : Node, elements : Array, color : Color) -> void:
	var i := 0
	var current_list = container.get_children()
	while i < len(current_list):
		var header := current_list[i] as BTGraphHeader

		if i >= len(elements):
			header.queue_free()
		else:
			var decorator = elements[i]
			header.update(decorator.name, color)
		i += 1

	while i < len(elements):
		if elements[i] == null: break

		var header := Header.instantiate()
		container.add_child(header)
		var decorator = elements[i]
		header.update(decorator.name, color)
		i += 1



func _on_close_request() -> void:
	delete_node()


func _on_position_offset_changed() -> void:
	bt_node.graph_position = position_offset



func _set_bt_node(value : BTNode) -> void:
	if value == null:
		delete_node()
		return

	if bt_node != null:
		bt_node.changed.disconnect(_refresh_visuals)

		value.parent = bt_node.parent
		bt_node.parent = null
		value.conditions = bt_node.conditions
		value.modifiers = bt_node.modifiers

		if (value is BTComposite and bt_node is BTComposite):
			for child in bt_node.children.duplicate():
				child.parent = value

	bt_node = value

	set_slot_enabled_right(2, bt_node is BTComposite)

	if (bt_node is BTComposite):
		bt_node.reorder_children()

	bt_node.changed.connect(_refresh_visuals, CONNECT_DEFERRED)
	_refresh_visuals()
