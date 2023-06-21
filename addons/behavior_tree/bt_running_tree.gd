@tool
class_name BTRunningTree
extends RefCounted



signal result_reported(agent, result)
signal interrupted(agent, try_abort, trigger_child)
signal monitors_have_dirtied()


var tree : BTNode

var _running_nodes : Array = []
var _running_nodes_memory : Dictionary = {}
var _running_leaves : Array = []

var _active_monitors : Array = []
var _monitor_memory : Dictionary = {}
var _keys_monitors : Dictionary
var _monitors_is_dirty : Dictionary = {}

var subtrees : Dictionary = {}

## Runtime dictionary of values returned from each node in the tree. Used for debugging tree.
var _debug_return_values : Dictionary = {}


var _agent : BTAgent
var _active_subtree : BTRunningTree
var _active_subtree_node : BTNode



func initialize(agent : BTAgent, target_tree : BTNode) -> void:
	tree = target_tree
	tree.initialize()
	_keys_monitors = tree.get_keys_monitors()

	_agent = agent
	_agent.blackboard.dirty_key_reported.connect(_on_blackboard_dirty_key_reported)


func activate(value : bool) -> void:
	if value:
		tree.result_reported.connect(_on_tree_result_reported)
		tree.interrupted.connect(_on_tree_interrupted)
	else:
		tree.result_reported.disconnect(_on_tree_result_reported)
		tree.interrupted.disconnect(_on_tree_interrupted)


func set_active_subtree(subtree : BTRunningTree, subtree_node : BTNode = null) -> void:
	if _active_subtree != null:
		_active_subtree.result_reported.disconnect(_on_subtree_result_reported)
		_active_subtree.interrupted.disconnect(_on_subtree_interrupted)

	_active_subtree = subtree
	if subtree_node != null:
		_active_subtree_node = subtree_node

		if subtrees.get(subtree_node) != null:
			subtree.monitors_have_dirtied.disconnect(_set_monitor_is_dirty.bind(subtree_node))

		subtrees[subtree_node] = subtree
		subtree.monitors_have_dirtied.connect(_set_monitor_is_dirty.bind(subtree_node))

	if _active_subtree != null:
		_active_subtree.result_reported.connect(_on_subtree_result_reported)
		_active_subtree.interrupted.connect(_on_subtree_interrupted)


func tick():
	_agent.active_tree = self

	_check_monitors_interrupts()

	if _running_leaves.is_empty():
		tree.tick(_agent)
	else:
		_running_leaves[0].tick(_agent)


func has_node_memory(node : BTNode) -> bool:
	return _running_nodes_memory.has(node)


func set_node_memory(node : BTNode, value : Variant) -> void:
	_running_nodes_memory[node] = value


func get_node_memory(node : BTNode) -> Variant:
	return _running_nodes_memory[node]


func set_running_node(node : BTNode) -> void:
	if _running_nodes.has(node): return

	_running_nodes.append(node)

	if not node is BTLeaf: return

	if _running_leaves.has(node): return

	_running_leaves.append(node)


func remove_single_running_node(node : BTNode) -> void:
	_running_nodes.erase(node)

	_running_nodes_memory.erase(node)

	if node is BTLeaf:
		_running_leaves.erase(node)


func try_abort_running_node(node : BTNode) -> bool:
	var index = _running_nodes.find(node)
	if index == -1 : return false

	var i = index + 1
	while i < len(_running_nodes):
		node = _running_nodes[i]
		node._abort(_agent)

		_running_nodes_memory.erase(node)
		if node is BTLeaf:
			_running_leaves.erase(node)

		i += 1
	_running_nodes.resize(index + 1)

	return true


func get_monitor_is_dirty(monitor) -> bool:
	return _monitors_is_dirty[monitor] as bool


func set_active_monitor(monitor, value : Variant) -> void:
	if not _active_monitors.has(monitor):
		_active_monitors.append(monitor)

	_monitor_memory[monitor] = value
	_set_monitor_is_dirty(monitor, false)


func remove_active_monitor(monitor) -> void:
	_active_monitors.erase(monitor)
	_monitor_memory.erase(monitor)


func has_active_monitors() -> bool:
	return not _active_monitors.is_empty()


func register_debug_return(node_index : int, result : BTItem.BTState) -> void:
	_debug_return_values[node_index] = result


func get_debug_return() -> Array:
	var subtrees_debug : Dictionary = {}
	for subtree_node in subtrees:
		var subtree = subtrees[subtree_node] as BTRunningTree
		subtrees_debug[subtree_node.tree_index] = subtree.get_debug_return()

	return [tree.resource_path, _debug_return_values, subtrees_debug]


func clear_debug_return() -> void:
	_debug_return_values = {}

	for subtree_node in subtrees:
		subtrees[subtree_node].clear_debug_return()


func clear() -> void:
	for subtree in subtrees:
		subtrees[subtree].clear()

	_active_monitors.clear()
	_monitor_memory.clear()

	subtrees.clear()


func _check_monitors_interrupts() -> bool:
	var local_active_monitors := _active_monitors.duplicate()
	var local_monitor_memory := _monitor_memory.duplicate()

	for i in len(local_active_monitors):
		var monitor = local_active_monitors[i]

		if not get_monitor_is_dirty(monitor): continue

		if monitor is BTSubtree:
			if monitor.check_monitor_interrupt(_agent, local_monitor_memory[monitor]):
				return true
			else:
				continue

		var new_value = monitor.get_monitor_value(_agent)
		var old_value = local_monitor_memory[monitor]

		if old_value != new_value:
			_interrupt_monitor(i)
			if (
				monitor.monitor_type == BTItem.BTMonitorType.BOTH
				or monitor.monitor_type == BTItem.BTMonitorType.SELF
			):
				set_active_monitor(monitor, new_value)
			return true
		else:
			_set_monitor_is_dirty(monitor, false)

	return false


func _interrupt_monitor(index : int) -> void:
	var i = index
	while i < len(_active_monitors):
		var monitor = _active_monitors[i]
		_monitor_memory.erase(monitor)
		i += 1

	var monitor = _active_monitors[index]
	_active_monitors.resize(index)
	monitor.interrupt(_agent)


func _set_monitor_is_dirty(monitor, dirty := true) -> void:
	_monitors_is_dirty[monitor] = dirty



func _on_blackboard_dirty_key_reported(key : Variant) -> void:
	if not _keys_monitors.has(key): return

	for monitor in _keys_monitors[key]:
		_set_monitor_is_dirty(monitor, true)

	monitors_have_dirtied.emit()


func _on_tree_result_reported(agent : BTAgent, result : BTItem.BTState) -> void:
	result_reported.emit(agent, result)


func _on_tree_interrupted(agent : BTAgent, try_abort : bool, trigger_child : BTNode = null) -> void:
	interrupted.emit(agent, try_abort)


func _on_subtree_result_reported(agent : BTAgent, result : BTItem.BTState) -> void:
	_agent.active_tree = self

	set_active_subtree(null)

	_active_subtree_node.subtree_response(agent, result)


func _on_subtree_interrupted(agent : BTAgent, try_abort : bool, trigger_child : BTNode = null) -> void:
	_agent.active_tree = self

	set_active_subtree(null)

	_active_subtree_node._on_interrupted(agent, try_abort)
