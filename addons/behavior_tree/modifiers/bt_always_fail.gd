@tool
class_name BTAlwaysFail
extends BTModifier



func _get_bt_type_name() -> String:
	return "Always Fail"


func _apply_modifier(_agent : BTAgent, result : BTState) -> BTState:
	if result == BTState.RUNNING:
		return BTState.RUNNING

	return BTState.FAILURE
