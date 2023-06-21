@tool
class_name BTGraphEdit
extends GraphEdit



signal loaded_changed(number_pages)


enum OpenTreeMode{
	NEW,
	BACK,
	LOAD,
	SUBTREE,
	DEBUG,
}


const _PORT := 0
const _GraphNode = preload("graph_node.tscn")

const _UNTICKED_COLOR := Color.WHITE
const _FAILURE_COLOR := Color.RED
const _SUCCESS_COLOR := Color.GREEN
const _RUNNING_COLOR := Color.YELLOW


var plugin : BTEditorPlugin
var debug_mode : bool:
	set = _set_debug_mode
var current_path : String:
	set = _set_current_path

## Holds a BTNode to BTGraphNode reference.
## Used for drawing and debugging.
var _nodes_reference : Dictionary
## Pages are Array of the format [tree_path, subtree_index, debug_draw_results, debug_subtree_pages]
var _graph_pages : Array[Array]



func _ready() -> void:
	connection_request.connect(_on_connection_request)
	disconnection_request.connect(_on_disconnection_request)
	node_selected.connect(_on_node_selected)
	connection_to_empty.connect(_on_connection_to_empty)
	connection_from_empty.connect(_on_connection_from_empty)
	delete_nodes_request.connect(_on_delete_nodes_request)
	popup_request.connect(_on_popup_request)

	open_tree(OpenTreeMode.NEW)



func add_node(bt_node : BTNode, position := Vector2.ZERO) -> BTGraphNode:
	var graph_node := _GraphNode.instantiate() as BTGraphNode
	add_child(graph_node)

	graph_node.bt_node = bt_node
	graph_node.position_offset = position

	_nodes_reference[bt_node] = graph_node

	graph_node.draggable = not debug_mode
	graph_node.show_close = not debug_mode

	graph_node.close_request.connect(_on_BTGraphNode_close_requested.bind(graph_node))

	return graph_node


func open_tree(mode : OpenTreeMode, tree_data = null) -> void:
	match mode:
		OpenTreeMode.NEW:
			_graph_pages = [["", null, {}, {}]]
			_clear_graph()

		OpenTreeMode.BACK:
			_graph_pages.pop_back()
			_load_tree(_graph_pages[-1][0])
			_draw_debug(_graph_pages[-1][2])

		OpenTreeMode.LOAD:
			_graph_pages = [[tree_data, null, {}, {}]]
			_load_tree(tree_data)

		OpenTreeMode.SUBTREE:
			var subtrees : Dictionary = _graph_pages[-1][3]

			var debug_data = subtrees.get(tree_data[1])

			var new_page : Array
			if debug_data == null:
				new_page = [tree_data[0], tree_data[1], {}, {}]
			else:
				new_page = [debug_data[0], tree_data[1], debug_data[1], debug_data[2]]

			_graph_pages.append(new_page)
			_load_tree(_graph_pages[-1][0])
			_draw_debug(_graph_pages[-1][2])

		OpenTreeMode.DEBUG:
			var debug_data = tree_data
			var i := 0
			var page = _graph_pages[i]
			while true:
				var is_same_subtree : bool = debug_data != null
				var is_same_tree : bool = is_same_subtree and page[0] == debug_data[0]

				if not is_same_tree:
					if i == 0:
						_graph_pages = [[debug_data[0], null, debug_data[1], debug_data[2]]]
						break

					_graph_pages.resize(i)
					break

				_graph_pages[i][2] = debug_data[1]
				_graph_pages[i][3] = debug_data[2]

				i += 1
				if i >= len(_graph_pages):
					break

				page = _graph_pages[i]
				var subtree_index = page[1]
				debug_data = debug_data[2].get(subtree_index)

			_load_tree(_graph_pages[-1][0])
			_draw_debug(_graph_pages[-1][2])

	loaded_changed.emit(len(_graph_pages))


func compile_tree() -> BTNode:
	var root : BTNode
	for child in get_children():
		child = child as BTGraphNode
		if child == null: continue

		var bt_node = child.bt_node

		if bt_node is BTComposite:
			if bt_node.children.is_empty():
				push_error("Behavior Tree: all BTComposites should have at least one child.")
				return

		if bt_node.parent != null: continue

		if root != null:
			push_error("Behavior Tree: Trees should have only one root.")
			return

		root = bt_node

	if root == null:
		push_error("Behavior Tree: Trees should have at least one node.")
		return

	root.recalculate_tree_index()

	return root.duplicate_deep()



func _clear_graph() -> void:
	current_path = ""
	_nodes_reference.clear()
	clear_connections()
	for child in get_children():
		if child is BTGraphNode:
			child.queue_free()


func _load_tree(path : String) -> void:
	if not ResourceLoader.exists(path):
		push_warning("Behavior Tree: load path does not exist.")
		return

	var tree_template := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as BTNode
	if tree_template == null:
		push_warning("Behavior Tree: load path is not a Behavior Tree.")
		return

	_clear_graph()

	current_path = path

	var root := tree_template.duplicate_deep()

	_load_node_recursive(root)

	for child in get_children():
		if child.is_queued_for_deletion(): continue
		if child is BTGraphNode:
			_draw_connections(child)


func _draw_debug(results : Dictionary) -> void:
	for child in get_children():
		child = child as BTGraphNode

		var index = child.bt_node.tree_index
		var result = results.get(index)

		var color : Color
		match result:
			null:
				color = _UNTICKED_COLOR
			BTItem.BTState.FAILURE:
				color = _FAILURE_COLOR
			BTItem.BTState.SUCCESS:
				color = _SUCCESS_COLOR
			BTItem.BTState.RUNNING:
				color = _RUNNING_COLOR

		child.set_slot_color_left(2, color)


func _load_node_recursive(bt_node : BTNode) -> void:
	add_node(bt_node, bt_node.graph_position)

	if not bt_node is BTComposite: return

	for child in bt_node.children:
		_load_node_recursive(child)
		child.parent = bt_node

	bt_node.reorder_children()


func _add_bt_parent_by_name(parent_name : String, child_name : String) -> void:
	var parent := get_node(parent_name) as BTGraphNode
	var child := get_node(child_name) as BTGraphNode
	child.bt_node.parent = parent.bt_node


func _draw_connections(graph_node : BTGraphNode):
	var bt_node := graph_node.bt_node
	var parent := bt_node.parent

	if parent != null:
		var graph_parent = _nodes_reference[parent]
		connect_node(graph_parent.name, _PORT, graph_node.name, _PORT)

	if not bt_node is BTComposite: return
	bt_node = bt_node as BTComposite

	for child in bt_node.children:
		var graph_child = _nodes_reference[child]
		connect_node(graph_node.name, _PORT, graph_child.name, _PORT)


func _clear_node_connections(node : BTGraphNode, parent_only := false) -> void:
	var connections = get_connection_list()
	for connection in connections:
		var clear_parent = connection.to == node.name
		var clear_children = not parent_only and connection.from == node.name
		if clear_parent or clear_children:
			disconnect_node(connection.from, connection.from_port, connection.to, connection.to_port)



func _on_connection_request(from : String, from_slot : int, to : String, to_slot : int) -> void:
	if debug_mode: return

	var graph_node := get_node(to) as BTGraphNode

	_clear_node_connections(graph_node, true)

	connect_node(from, from_slot, to, to_slot)
	_add_bt_parent_by_name(from, to)


func _on_disconnection_request(from : String, from_slot : int, to : String, to_slot : int) -> void:
	if debug_mode: return

	disconnect_node(from, from_slot, to, to_slot)
	var node := get_node(to) as BTGraphNode
	node.bt_node.parent = null


func _on_node_selected(node : GraphNode) -> void:
	plugin.inspect_object(node.bt_node)


func _on_connection_to_empty(from : String, from_slot : int, release_position : Vector2) -> void:
	if debug_mode: return

	var mouse_position := get_viewport().get_mouse_position()
	var bt_node := await plugin.request_bt_node_type(mouse_position)
	if bt_node == null: return

	var node := add_node(bt_node)
	node.position_offset = release_position - Vector2(0, node.size.y/2)
	connect_node(from, from_slot, node.name, 0)
	_add_bt_parent_by_name(from, node.name)


func _on_connection_from_empty(to : String, to_slot : int, release_position : Vector2) -> void:
	if debug_mode: return

	var mouse_position := get_viewport().get_mouse_position()
	var bt_node := await plugin.request_bt_node_type(mouse_position, false)
	if bt_node == null: return

	var new_node := add_node(bt_node)
	new_node.position_offset = release_position - Vector2(new_node.size.x, new_node.size.y/2)
	connect_node(new_node.name, 0, to, to_slot)
	_add_bt_parent_by_name(new_node.name, to)


func _on_delete_nodes_request(nodes : Array) -> void:
	if debug_mode: return

	for child in get_children():
		if nodes.has(child.name):
			child.delete_node()
			_clear_node_connections(child)
			_nodes_reference.erase(child.bt_node)


func _on_popup_request(position : Vector2) -> void:
	if debug_mode: return

	var mouse_position := get_viewport().get_mouse_position()
	var bt_node : BTNode = await plugin.request_bt_node_type(mouse_position)

	if bt_node == null: return

	for child in get_children():
		child = child as BTGraphNode

		if child == null: continue
		if not child.has_point(position): continue

		_clear_node_connections(child)
		_nodes_reference.erase(bt_node)
		child.bt_node = bt_node
		_nodes_reference[bt_node] = child
		_draw_connections(child)
		return

	add_node(bt_node, position)


func _on_BTGraphNode_close_requested(graph_node : BTGraphNode) -> void:
	_clear_node_connections(graph_node)
	_nodes_reference.erase(graph_node.bt_node)



func _set_current_path(value : String) -> void:
	current_path = value
	loaded_changed.emit(len(_graph_pages))


func _set_debug_mode(value : bool) -> void:
	if debug_mode == value: return

	debug_mode = value

	for child in get_children():
		child = child as BTGraphNode
		if child == null: continue

		child.draggable = not debug_mode
		child.show_close = not debug_mode

		if debug_mode: continue

		child.set_slot_color_left(2, _UNTICKED_COLOR)
