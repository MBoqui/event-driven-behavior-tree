@tool
class_name BTItem
extends Resource



enum BTState {
	FAILURE,
	SUCCESS,
	RUNNING,
}

enum BTMonitorType {
	NONE,
	BOTH,
	SELF,
	LOWER_PRIORITY,
}

enum BTUtilityCompoundMode{
	MULTIPLY,
	AVERAGE,
	MIN,
	MAX,
}


@export var name : String = "":
	set(value):
		name = value
		emit_changed()



func _init() -> void:
	name = get_bt_type_name()



func get_bt_type_name() -> String:
	return _get_bt_type_name()



func _get_bt_type_name() -> String:
	return ""
