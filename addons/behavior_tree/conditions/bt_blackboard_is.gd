@tool
class_name BTBlackboardIs
extends BTCondition


@export var key : String = ""

@export_multiline var expression : String = "":
	set(value):
		if value == expression: return

		expression = value
		_expression.text = expression



var _expression := BTExpression.new()



func _get_bt_type_name() -> String:
	return "Blackboard Is"


func _check_condition(agent : BTAgent) -> bool:
	var stored_value = agent.blackboard.get_value(key)
	var target_value = _expression.execute(agent)

	if stored_value == target_value:
		return true

	return false


func _initialize() -> void:
	if not _expression.is_valid():
		push_error("Expression is not valid")
	if key == null or key.is_empty():
		push_error("Key must be set")


func _register_monitored_keys(root : BTNode) -> void:
	root.register_key_monitor(self, key)
