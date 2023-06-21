@tool
class_name BTAlwaysSucceed
extends BTModifier



func _get_bt_type_name() -> String:
	return "Always Succeed"


func _apply_modifier(_agent : BTAgent, result : BTState) -> BTState:
	if result == BTState.RUNNING:
		return BTState.RUNNING

	return BTState.SUCCESS
