@tool
class_name BTCondition
extends BTItem



signal interrupted(agent, try_abort)


@export var monitor_type : BTMonitorType


func _check_condition(_agent : BTAgent) -> bool:
	return true


func _initialize() -> void:
	pass


func _register_monitored_keys(_root : BTNode) -> void:
	pass


func interrupt(agent : BTAgent) -> void:
	interrupted.emit(agent, true)


func get_monitor_value(agent : BTAgent) -> Variant:
	return _check_condition(agent)
