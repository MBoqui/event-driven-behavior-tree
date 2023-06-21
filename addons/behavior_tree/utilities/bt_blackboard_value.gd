@tool
extends BTUtility
class_name BTBlackboardValue



@export var key : String = ""



func _get_bt_type_name() -> String:
	return "Blackboard Value"


func _get_utility_value(agent : BTAgent) -> float:
	if not agent.blackboard.has_key(key):
		return 0

	return agent.blackboard.get_value(key) as float


func _register_monitored_keys(monitor : BTNode, root : BTNode) -> void:
	root.register_key_monitor(monitor, key)
