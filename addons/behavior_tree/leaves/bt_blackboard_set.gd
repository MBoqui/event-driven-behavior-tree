@tool
class_name BTBlackboardSet
extends BTLeaf



@export var key : String = "":
	set(value):
		key = value

@export_multiline var expression : String = "":
	set(value):
		if value == expression: return

		expression = value
		_expression.text = expression



var _expression := BTExpression.new()



func _get_bt_type_name() -> String:
	return "Blackboard Set"


func _execute_tick(agent : BTAgent) -> void:
	var value = _expression.execute(agent)
	agent.blackboard.set_value(key, value)

	_report_result(agent, BTState.SUCCESS)


func _check_string_validity(value : String) -> bool:
	return value != null and not value.is_empty()
