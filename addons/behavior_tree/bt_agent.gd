@tool
class_name BTAgent
extends Node



@export var target_tree : BTNode


var blackboard := BTBlackboard.new()

var active_tree : BTRunningTree:
	set = _set_active_tree
var debug := false

var _running_tree := BTRunningTree.new()



func _ready() -> void:
	_running_tree.initialize(self, target_tree)



func tick():
	_running_tree.result_reported.connect(_on_tree_result_reported)

	_running_tree.tick()

	active_tree = null

	_running_tree.result_reported.disconnect(_on_tree_result_reported)


func set_active_subtree(subtree : BTRunningTree, subtree_node : BTNode = null) -> void:
	active_tree.set_active_subtree(subtree, subtree_node)


func has_node_memory(node : BTNode) -> bool:
	return active_tree.has_node_memory(node)


func set_node_memory(node : BTNode, value : Variant) -> void:
	active_tree.set_node_memory(node, value)


func get_node_memory(node : BTNode) -> Variant:
	return active_tree.get_node_memory(node)


func set_running_node(node : BTNode) -> void:
	active_tree.set_running_node(node)


func remove_single_running_node(node : BTNode) -> void:
	active_tree.remove_single_running_node(node)


func try_abort_running_node(node : BTNode) -> bool:
	return active_tree.try_abort_running_node(node)


func get_monitor_is_dirty(monitor) -> bool:
	return active_tree.get_monitor_is_dirty(monitor)


func set_active_monitor(monitor, value : Variant) -> void:
	active_tree.set_active_monitor(monitor, value)


func remove_active_monitor(monitor) -> void:
	active_tree.remove_active_monitor(monitor)


func register_debug_return(node_index : int, result : BTItem.BTState) -> void:
	active_tree.register_debug_return(node_index, result)



func _on_tree_result_reported(_agent : BTAgent, result : BTItem.BTState) -> void:
	if result != BTItem.BTState.RUNNING:
		_running_tree.clear()


	if OS.is_debug_build() and debug:
		var debug_values = _running_tree.get_debug_return()

		EngineDebugger.send_message(BTDebugger.DEBUG_TREE_MESSAGE, debug_values)

		_running_tree.clear_debug_return()



func _set_active_tree(tree : BTRunningTree) -> void:
	if active_tree != null:
		active_tree.activate(false)

	active_tree = tree

	if active_tree != null:
		active_tree.activate(true)
