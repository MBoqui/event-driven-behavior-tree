@tool
class_name BTSubtree
extends BTLeaf

## The Subtree node runs another tree saved to disk on the same agent and reports
## the result of the subtree to the parent of this node.


#@export var key : String = "" # Adding subtrees set dynamically from blackboard key is planned.
@export_file var path : String = ""

var subtree : BTNode:
	get:
		return load(path)

var _running_tree : BTRunningTree



func _get_bt_type_name() -> String:
	return "Subtree"


func _execute_tick(agent : BTAgent) -> void:
	_running_tree.tick()


func _abort(agent : BTAgent) -> void:
	_running_tree = agent.active_tree.subtrees[self]

	var current_tree = agent.active_tree

	agent.set_active_subtree(_running_tree, self)
	agent.active_tree = _running_tree

	_running_tree.try_abort_running_node(_running_tree.tree)

	agent.active_tree = current_tree
	agent.set_active_subtree(null)


func _setup_execution(agent : BTAgent) -> void:
	_running_tree = agent.active_tree.subtrees.get(self)

	if _running_tree == null:
		_running_tree = BTRunningTree.new()
		_running_tree.initialize(agent, subtree)

	agent.set_active_subtree(_running_tree, self)
	agent.set_active_monitor(self, _running_tree)


func _terminate(agent : BTAgent, result : BTState) -> void:
	super._terminate(agent, result)

	if result == BTState.RUNNING: return

	if not _running_tree.has_active_monitors():
		agent.remove_active_monitor(self)



func subtree_response(agent : BTAgent, result : BTState) -> void:
	_setup_execution(agent)

	_report_result(agent, result)


func check_monitor_interrupt(agent : BTAgent, running_tree : BTRunningTree) -> bool:
	var current_tree = agent.active_tree

	agent.set_active_subtree(running_tree, self)
	agent.active_tree = running_tree

	var was_interrupted = running_tree._check_monitors_interrupts()

	agent.active_tree = current_tree
	agent.set_active_subtree(null)

	return was_interrupted
