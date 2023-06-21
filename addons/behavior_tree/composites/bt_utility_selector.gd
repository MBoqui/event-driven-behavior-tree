@tool
class_name BTUtilitySelector
extends BTCompositeUtility

## This node is very similar to [BTSelector], but instead of ticking its children according to
## their [member sibling_index] order, it ticks them according to their utility values, in
## decreasing order. If two children have the same utility value, their sibling_index breaks ties.



var _children_utility_order : PackedInt32Array
var _current_order_index := 0



func _get_bt_type_name() -> String:
	return "Utility Selector"


func _execute_tick(agent : BTAgent) -> void:
	_save_memory(agent)
	var child_index = _children_utility_order[_current_order_index]
	children[child_index].tick(agent)


func _execute_response(agent : BTAgent, result : BTState) -> void:
	if result != BTState.FAILURE:
		_report_result(agent, result)
		return

	_current_order_index += 1

	if _current_order_index >= len(_children_utility_order):
		_report_result(agent, BTState.FAILURE)
		return

	_save_memory(agent)
	var child_index = _children_utility_order[_current_order_index]
	children[child_index].tick(agent)


func _interrupt(agent : BTAgent, trigger_child : BTNode) -> void:
	if trigger_child == null:
		_children_utility_order = get_children_utility_order(agent)
		_current_order_index = 0
	else:
		_current_order_index = _children_utility_order.find(trigger_child.sibling_index)

	_save_memory(agent)


func _setup_execution(agent : BTAgent) -> void:
	if agent.has_node_memory(self):
		var memory = agent.get_node_memory(self)

		_children_utility_order = memory[0]
		_current_order_index = memory[1]
		return

	_children_utility_order = get_children_utility_order(agent)
	_current_order_index = 0


func _save_memory(agent : BTAgent) -> void:
	agent.set_node_memory(self, [_children_utility_order, _current_order_index])
