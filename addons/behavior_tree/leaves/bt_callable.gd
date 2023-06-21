@tool
class_name BTCallable
extends BTLeaf



@export var method_name : String = "":
	set(value):
		method_name = value

#@export var method_arguments : Array[String]:
#	set(value):
#		method_arguments = value
#		_arguments_dirty = true

@export_multiline var expression : String = "": # Temporary while multiple args disabled
	set(value):
		if value == expression: return

		expression = value
		_expression.text = expression



#var _arguments_expressions : Array[BTExpression]
var _arguments_dirty := true



var _expression := BTExpression.new() # Temporary while multiple args disabled



func _get_bt_type_name() -> String:
	return "Callable"


func _execute_tick(agent : BTAgent) -> void:
#	_update_arguments_expressions()
#
#	var arguments := _get_arguments(agent)
#
#	var result : Variant = agent.callv(method_name, arguments)

	var argument = _expression.execute(agent) # Temporary while multiple args disabled
	var result : Variant # Temporary while multiple args disabled
	if argument == null:
		result = agent.call(method_name) # Temporary while multiple args disabled
	else:
		result = agent.call(method_name, argument) # Temporary while multiple args disabled

	if result is bool:
		_report_result(agent, result as int)
		return
	if result is int:
		_report_result(agent, result)
		return

	_report_result(agent, BTState.SUCCESS)


func _check_validity(prop) -> bool:
	return prop != null and not prop.is_empty()


#func _update_arguments_expressions() -> void:
#	if not _arguments_dirty: return
#
#	_arguments_expressions.clear()
#	for text_argument in method_arguments:
#		var expression := BTExpression.new()
#		expression.text = text_argument
#		_arguments_expressions.append(expression)
#
#	_arguments_dirty = false
#
#
#func _get_arguments(agent : BTAgent) -> Array[Variant]:
#	var get_argument := func(agent : BTAgent, expression : BTExpression) -> Variant:
#		return expression.execute(agent)
#	return _arguments_expressions.map(get_argument)
