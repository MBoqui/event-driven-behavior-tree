@tool
class_name BTCompositeUtility
extends BTComposite



@export var monitor_type : BTMonitorType


func tick(agent : BTAgent) -> void:
	agent.set_running_node(self)

	_setup_execution(agent)

	if not _conditions_satisfied(agent):
		_report_result(agent, BTState.FAILURE)
		return

	if (monitor_type == BTMonitorType.BOTH or monitor_type == BTMonitorType.SELF):
		agent.set_active_monitor(self, get_monitor_value(agent))

	_execute_tick(agent)


func initialize(is_root := true) -> void:
	super.initialize(is_root)

	if monitor_type == BTMonitorType.NONE: return

	for child in children:
		for utility in child.utilities:
			utility._register_monitored_keys(self, root)


func interrupt(agent : BTAgent) -> void:
	_on_interrupted(agent, true)


func get_monitor_value(agent : BTAgent) -> Variant:
	return get_children_utility_order(agent)


func get_children_utility_order(agent : BTAgent) -> PackedInt32Array:
	var children_utilities : PackedFloat64Array = []

	for child in children:
		var value : float = child.get_utility_value(agent)
		children_utilities.append(value)

	var utilities_sorted := children_utilities.duplicate()
	utilities_sorted.sort()

	var children_utility_order : PackedInt32Array = []

	for utility in utilities_sorted:
		var child_index := children_utilities.rfind(utility)

		while children_utility_order.has(child_index):
			child_index = children_utilities.rfind(utility, child_index - 1)

			if child_index == -1:
				push_error("Behavior Tree: something went wrong calculating utility order.")
				return []

		children_utility_order.append(child_index)

	children_utility_order.reverse()

	return children_utility_order



func _terminate(agent : BTAgent, result : BTState) -> void:
	super._terminate(agent, result)

	if result == BTState.RUNNING: return

	match monitor_type:
		BTMonitorType.SELF:
			agent.remove_active_monitor(self)
		BTMonitorType.LOWER_PRIORITY:
			agent.set_active_monitor(self, get_monitor_value(agent))
