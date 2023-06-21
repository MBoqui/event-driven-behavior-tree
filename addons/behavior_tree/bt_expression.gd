@tool
class_name BTExpression



var text : String = "":
	set(value):
		if value == text: return

		text = value
		_parse_expression(text)


var _expression : Expression



func is_valid() -> bool:
	return _expression != null


func execute(agent : BTAgent) -> Variant:
	var arguments : Array[Variant] = [agent, agent.blackboard]
	return _execute_expression(arguments)



func _parse_expression(input : String) -> void:
	if input == "": input = "null"

	var new_expression := Expression.new()
	var error_code := new_expression.parse(input, ["agent", "blackboard"])

	if error_code != OK:
		printerr("BTExpression: Unable to parse expression '%s' : %s" % [input, new_expression.get_error_text()])
		_expression = null
		return

	_expression = new_expression


func _execute_expression(arguments : Array[Variant]) -> Variant:
	if _expression == null:
		_parse_expression(text)

	if _expression == null: return null

	var result = _expression.execute(arguments, self, true)
	if _expression.has_execute_failed():
		printerr("BTExpression: Unable to execute expression '%s' : %s" % [text, _expression.get_error_text()])

	return result
