@tool
class_name BTSequence
extends BTComposite


var _current_child_index := 0



func _get_bt_type_name() -> String:
	return "Sequence"


func _execute_tick(agent : BTAgent) -> void:
	_save_memory(agent)
	children[_current_child_index].tick(agent)


func _execute_response(agent : BTAgent, result : BTState) -> void:
	if result != BTState.SUCCESS:
		_report_result(agent, result)
		return

	_current_child_index += 1

	if _current_child_index >= len(children):
		_report_result(agent, BTState.SUCCESS)
		return

	_save_memory(agent)
	children[_current_child_index].tick(agent)


func _interrupt(agent : BTAgent, trigger_child : BTNode) -> void:
	if trigger_child == null: return

	_current_child_index = trigger_child.sibling_index
	_save_memory(agent)


func _setup_execution(agent : BTAgent) -> void:
	if agent.has_node_memory(self):
		_current_child_index = agent.get_node_memory(self)
	else:
		_current_child_index = 0


func _save_memory(agent : BTAgent) -> void:
	agent.set_node_memory(self, _current_child_index)
