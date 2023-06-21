@tool
class_name BTInverter
extends BTModifier



func _get_bt_type_name() -> String:
	return "Inverter"


func _apply_modifier(_agent : BTAgent, result : BTState) -> BTState:
	match result:
		BTState.SUCCESS:
			return BTState.FAILURE
		BTState.FAILURE:
			return BTState.SUCCESS

	return BTState.RUNNING
