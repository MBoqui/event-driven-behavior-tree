@tool
class_name BTNode
extends BTItem



signal result_reported(agent, result)
signal interrupted(agent, try_abort, trigger_child)


@export var utilities : Array[BTUtility] = []:
	set = _set_utilities
@export var conditions : Array[BTCondition] = []:
	set = _set_conditions
@export var modifiers : Array[BTModifier] = []:
	set = _set_modifiers
@export var utility_compound_mode : BTUtilityCompoundMode



var parent : BTComposite:
	set = _set_parent
var graph_position : Vector2:
	set = _set_graph_position

var root : BTNode = null


var sibling_index : int:
	set = _set_sibling_index
var tree_index : int = -1

## Stores an array of the monitors affected by a blackboard key.
## Compiled at initialization time. Monitors can be BTCompositeUtility or BTCondition.
var _keys_monitors : Dictionary = {}
var _is_initialized := false



func _get_property_list() -> Array:
	var properties = []

	properties.append({
		"name": "graph_position",
		"type": TYPE_VECTOR2,
		"usage": PROPERTY_USAGE_STORAGE,
		})

	properties.append({
		"name": "sibling_index",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_STORAGE,
		})

	properties.append({
		"name": "tree_index",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_STORAGE,
		})

	return properties



func duplicate_deep() -> BTNode:
	var new_node := duplicate(true)

	for i in len(conditions):
		var condition := conditions[i]
		new_node.conditions[i] = condition.duplicate(true)

	for i in len(modifiers):
		var modifier := modifiers[i]
		new_node.modifiers[i] = modifier.duplicate(true)

	return new_node



## Executed when node is called to tick.
func _execute_tick(_agent : BTAgent) -> void:
	pass


## Executed when there is an interruption on a monitor or in parallel nodes in First Return mode.
## Use this method to cleanly close the execution of running nodes in case of interruptions or erly parallel return.
## Outside of these cases this cleanup should occur in the _execute_... methods.
## You need to load the node memory inside your abort code if you need those values,
## they will not be loaded and may cause unexpected behavior.
func _abort(_agent : BTAgent) -> void:
	pass


## Executed when there is an interruption on a monitor.
## Executed only on the nodes on the path from root to the node with the monitor that triggered the interruption.
func _interrupt(_agent : BTAgent, _trigger_child : BTNode) -> void:
	pass


## Called before a node is ticked.
## Use this method to setup the necessary variables for execution of the node.
func _setup_execution(_agent : BTAgent) -> void:
	pass


## Called when a node is ending its execution for this tick but is still running.
## Use this to store the current running variables of the node.
## This is necessary because this Resource might be reused in other trees and any value might be overriden.
func _save_memory(_agent : BTAgent) -> void:
	pass



func tick(agent : BTAgent) -> void:
	agent.set_running_node(self)

	_setup_execution(agent)

	if not _conditions_satisfied(agent):
		_report_result(agent, BTState.FAILURE)
		return

	_execute_tick(agent)


func abort(agent : BTAgent) -> void:
	_abort(agent)
	agent.remove_single_running_node(self)


func initialize(is_root := true) -> void:
	if _is_initialized: return
	_is_initialized = true

	if is_root:
		root = self

	for condition in conditions:
		if condition.monitor_type != BTMonitorType.NONE:
			condition._register_monitored_keys(root)

		condition.interrupted.connect(_on_interrupted)
		condition._initialize()

	for utility in utilities:
		utility._initialize()


func recalculate_tree_index(value := 0) -> int:
	tree_index = value
	return tree_index + 1


func get_keys_monitors() -> Dictionary:
	return _keys_monitors


func register_key_monitor(monitor, key : Variant) -> void:
	if not _keys_monitors.has(key):
		_keys_monitors[key] = []

	_keys_monitors[key].append(monitor)


func get_utility_value(agent : BTAgent) -> float:
	if utilities == null or utilities.is_empty():
		return 0

	var utility_values : PackedFloat64Array

	for utility in utilities:
		var value := utility._get_utility_value(agent)
		value = clampf(value, 0, 1)
		utility_values.append(value)

	var result := compound_utilities(utility_compound_mode, utility_values)

	return clamp(result, 0, 1)


func compound_utilities(mode : BTUtilityCompoundMode, utilities : PackedFloat64Array) -> float:
	var result : float

	match mode:
		BTUtilityCompoundMode.MULTIPLY:
			result = 1

			for value in utilities:
				result *= value

				if result == 0:
					break

		BTUtilityCompoundMode.AVERAGE:
			result = 0

			for value in utilities:
				result += value

			result /= len(utilities)

		BTUtilityCompoundMode.MIN:
			result = 1

			for value in utilities:
				if value < result:
					result = value

				if result == 0:
					break

		BTUtilityCompoundMode.MAX:
			result = 0

			for value in utilities:
				if value > result:
					result = value

				if result == 1:
					break

	return result



func _conditions_satisfied(agent : BTAgent) -> bool:
	var result : bool
	for condition in conditions:
		result = condition._check_condition(agent)

		if (
				condition.monitor_type == BTMonitorType.BOTH
				or condition.monitor_type == BTMonitorType.SELF
		):
			agent.set_active_monitor(condition, result)

		if not result:
			return false

	return true


func _apply_modifiers(agent : BTAgent, result : BTState) -> BTState:
	for modifier in modifiers:
		result = modifier._apply_modifier(agent, result)
	return result


func _report_result(agent : BTAgent, result : BTState) -> void:
	result = _apply_modifiers(agent, result)

	_terminate(agent, result)

	if OS.is_debug_build() and agent.debug:
		agent.register_debug_return(tree_index, result)

	result_reported.emit(agent, result)


func _terminate(agent : BTAgent, result : BTState) -> void:
	if result == BTState.RUNNING:
		_save_memory(agent)
		return

	agent.remove_single_running_node(self)

	for condition in conditions:
		match condition.monitor_type:
			BTMonitorType.SELF:
				agent.remove_active_monitor(condition)
			BTMonitorType.LOWER_PRIORITY:
				agent.set_active_monitor(condition, condition._check_condition(agent))



func _on_interrupted(agent : BTAgent, try_abort : bool, trigger_child : BTNode = null) -> void:
	if try_abort:
		# if managed to abort at this node, stop trying to abort
		try_abort = not agent.try_abort_running_node(self)

	_interrupt(agent, trigger_child)

	interrupted.emit(agent, try_abort, self)



func _set_utilities(value : Array[BTUtility]) -> void:
	for utility in utilities:
		if utility == null: continue
		utility.changed.disconnect(emit_changed)

	utilities = value

	for utility in utilities:
		if utility == null: continue
		utility.changed.connect(emit_changed)

	emit_changed()


func _set_conditions(value : Array[BTCondition]):
	for condition in conditions:
		if condition == null: continue
		condition.changed.disconnect(emit_changed)

	conditions = value

	for condition in conditions:
		if condition == null: continue
		condition.changed.connect(emit_changed)

	emit_changed()


func _set_modifiers(value : Array[BTModifier]):
	for modifier in modifiers:
		if modifier == null: continue
		modifier.changed.disconnect(emit_changed)

	modifiers = value

	for modifier in modifiers:
		if modifier == null: continue
		modifier.changed.connect(emit_changed)

	emit_changed()


func _set_parent(value : BTComposite) -> void:
	if parent == value: return

	if parent != null:
		parent.children.erase(self)
		parent.reorder_children()

	parent = value

	if parent != null:
		if not parent.children.has(self):
			parent.children.append(self)
			parent.reorder_children()
	else:
		tree_index = -1

	emit_changed()


func _set_graph_position(value : Vector2) -> void:
	graph_position = value

	if parent != null:
		parent.reorder_children()
	else:
		sibling_index = -1

	emit_changed()


func _set_sibling_index(value):
		sibling_index = value
		emit_changed()
