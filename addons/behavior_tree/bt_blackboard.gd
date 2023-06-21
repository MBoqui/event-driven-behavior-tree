@tool
class_name BTBlackboard
extends RefCounted



signal dirty_key_reported(key)


var _blackboard: Dictionary = {}


func set_value(key: Variant, value: Variant) -> void:
	_blackboard[key] = value
	dirty_key_reported.emit(key)


func get_value(key: Variant, default_value: Variant = null) -> Variant:
	return _blackboard.get(key, default_value)


func has_value(key: Variant) -> bool:
	if not _blackboard.has(key): return false

	return _blackboard[key] != null


func has_key(key: Variant) -> bool:
	return _blackboard.has(key)


func erase_value(key: Variant) -> void:
	if _blackboard.has(key):
		_blackboard[key] = null
		dirty_key_reported.emit(key)


func erase_key(key: Variant) -> void:
	_blackboard.erase(key)
	dirty_key_reported.emit(key)
