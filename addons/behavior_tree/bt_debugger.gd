@tool
class_name BTDebugger
extends EditorDebuggerPlugin



const PLUGIN_MESSAGE := "behavior_tree"
const DEBUG_TREE_MESSAGE := PLUGIN_MESSAGE + ":debug_tree"


signal debug_tree(data)
signal debug_mode_changed(value)


func _has_capture(prefix : String) -> bool:
	return prefix == PLUGIN_MESSAGE


func _capture(message : String, data : Array, session_id : int) -> bool:
	match message:
		DEBUG_TREE_MESSAGE:
			debug_tree.emit(data)
			return true

	return false


func _setup_session(session_id: int) -> void:
	var session = get_session(session_id)
	session.started.connect(_on_session_started)
	session.stopped.connect(_on_session_ended.bind(session))



func _on_session_started() -> void:
	for session in get_sessions():
		if session.is_active():
			debug_mode_changed.emit(true)
			return


func _on_session_ended(ended_session : EditorDebuggerSession) -> void:
	for session in get_sessions():
		if session.is_active():
			return

	debug_mode_changed.emit(false)
