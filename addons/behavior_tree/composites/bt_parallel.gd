@tool
class_name BTParallel
extends BTComposite

## The Parallel node runs all its children in their sibling_index order every frame.
## It only returns a result after all its children have been run.
## The result it returns depends on the [member parallel_mode] chosen.



enum BTParallelMode {
	FIRST_RETURN, ## Returns the result of the first child. When the first child terminates execution, aborts other children.
	HAS_SUCCESS, ## Return RUNNING if any child returns running. Otherwise, return SUCCESS if at least one child returns SUCCESS.
	HAS_FAILURE, ## Return RUNNING if any child returns running. Otherwise, return SUCCESS if at least one child returns FAILURE.
	ALL_SUCCESS, ## Return RUNNING if any child returns running. Otherwise, return FAILURE if at least one child returns FAILURE.
	ALL_FAILURE, ## Return RUNNING if any child returns running. Otherwise, return FAILURE if at least one child returns SUCCESS.
}

@export var parallel_mode : BTParallelMode

var _children_results : PackedInt32Array = []
var _current_child_index := 0


func _get_bt_type_name() -> String:
	return "Parallel"


func _execute_tick(agent : BTAgent) -> void:
	_save_memory(agent)
	children[_current_child_index].tick(agent)


func _execute_response(agent : BTAgent, result : BTState) -> void:
	_children_results[_current_child_index] = result

	_current_child_index += 1

	while _current_child_index < len(children):
		if _children_results[_current_child_index] != BTState.RUNNING:
			_current_child_index += 1
			continue

		_save_memory(agent)
		children[_current_child_index].tick(agent)
		return

	var final_result : BTState
	match parallel_mode:
		BTParallelMode.FIRST_RETURN:
			final_result = _children_results[0]

			if final_result != BTState.RUNNING:
				for i in len(children):
					var child := children[i]
					var child_result := _children_results[i]
					if child_result == BTState.RUNNING:
						child.abort(agent)

		BTParallelMode.HAS_SUCCESS:
			final_result = BTState.FAILURE

			for child_result in _children_results:
				if child_result == BTState.RUNNING:
					final_result = BTState.RUNNING
					break

				if child_result == BTState.SUCCESS:
					final_result = BTState.SUCCESS

		BTParallelMode.HAS_FAILURE:
			final_result = BTState.FAILURE

			for child_result in _children_results:
				if child_result == BTState.RUNNING:
					final_result = BTState.RUNNING
					break

				if child_result == BTState.FAILURE:
					final_result = BTState.SUCCESS

		BTParallelMode.ALL_SUCCESS:
			final_result = BTState.SUCCESS

			for child_result in _children_results:
				if child_result == BTState.RUNNING:
					final_result = BTState.RUNNING
					break

				if child_result == BTState.FAILURE:
					final_result = BTState.FAILURE

		BTParallelMode.ALL_FAILURE:
			final_result = BTState.SUCCESS

			for child_result in _children_results:
				if child_result == BTState.RUNNING:
					final_result = BTState.RUNNING
					break

				if child_result == BTState.SUCCESS:
					final_result = BTState.FAILURE

	if final_result != BTState.RUNNING:
		_report_result(agent, final_result)
		return

	for i in len(_children_results):
		if _children_results[i] == BTState.RUNNING:
			_current_child_index = i
			break

	_report_result(agent, BTState.RUNNING)



func _interrupt(agent : BTAgent, trigger_child : BTNode) -> void:
	if trigger_child == null: return

	_children_results[trigger_child.sibling_index] = -1
	_save_memory(agent)


func _setup_execution(agent : BTAgent) -> void:
	if agent.has_node_memory(self):
		var memory = agent.get_node_memory(self)
		_children_results = memory[0]
		_current_child_index = memory[1]
	else:
		_current_child_index = 0
		_children_results = []

		for child in children:
			_children_results.append(BTState.RUNNING)


func _save_memory(agent : BTAgent) -> void:
	agent.set_node_memory(self, [_children_results, _current_child_index])
