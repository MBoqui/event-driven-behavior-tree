@tool
class_name BTComposite
extends BTNode



## Use the children utility values as the utilities of this node.
## Ignored if any utility is set for this node.
## Ignores children that have no [BTUtility], unless inherit_children_utility is true for the child.
## CAUTION: activating this mode can cause performance problems since the same BTUtility will be
## called every time a node with inherit_children_utility == true above it is called.
## This will be optimized sometime in the future, but for now, beware of using this too much or
## nesting nodes with this mode on.
@export var inherit_children_utility := false

var children : Array[BTNode] = []


func _get_property_list() -> Array:
	var properties = []

	properties.append({
		"name": "children",
		"type": TYPE_ARRAY,
		"usage": PROPERTY_USAGE_STORAGE,
		"hint": PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string": "BTNode",
		})

	return properties



func _execute_response(_agent : BTAgent, _result : BTState) -> void:
	pass



func duplicate_deep() -> BTNode:
	var new_node := super.duplicate_deep()

	for i in len(children):
		var child := children[i]
		new_node.children[i] = child.duplicate_deep()

	return new_node


func initialize(is_root := true) -> void:
	if _is_initialized: return

	super.initialize(is_root)

	for child in children:
		child.interrupted.connect(_on_interrupted)
		child.result_reported.connect(_on_child_result_reported)

		child.root = self.root

		child.initialize(false)


func abort(agent : BTAgent) -> void:
	super.abort(agent)

	for child in children:
		child.abort(agent)



func get_utility_value(agent : BTAgent) -> float:
	if not inherit_children_utility or (utilities != null and not utilities.is_empty()):
		return super.get_utility_value(agent)

	var utility_values : PackedFloat64Array

	for child in children:
		var value := child.get_utility_value(agent)
		value = clampf(value, 0, 1)
		utility_values.append(value)

	var result := compound_utilities(utility_compound_mode, utility_values)

	return clamp(result, 0, 1)


func recalculate_tree_index(value := 0) -> int:
	var next_index = super.recalculate_tree_index(value)

	for child in children:
		next_index = child.recalculate_tree_index(next_index)

	return next_index


func reorder_children() -> void:
	children.sort_custom(func(a : BTNode, b : BTNode): return a.graph_position.y < b.graph_position.y)

	for i in len(children):
		children[i].sibling_index = i



func _on_child_result_reported(agent : BTAgent, result : BTState) -> void:
	_setup_execution(agent)

	_execute_response(agent, result)
