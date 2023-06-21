@tool
class_name BTEditorPlugin
extends EditorPlugin



var bt_node_resources : Array[BTNode]


var _paths : Array[String] = [
		"res://addons/behavior_tree",
		]

var _editor : BTEditor = preload ("graph/editor.tscn").instantiate()
var _bottom_panel_button : Button

var _file_dialog : EditorFileDialog
var _type_popup : PopupMenu

var _debugger : BTDebugger
var _editor_interface : EditorInterface



func _enter_tree():
	_debugger = BTDebugger.new()
	_debugger.debug_tree.connect(_on_Debugger_debug_tree)
	_debugger.debug_mode_changed.connect(_on_Debugger_debug_mode_changed)
	add_debugger_plugin(_debugger)

	_bottom_panel_button = add_control_to_bottom_panel(_editor, "Behavior Tree")

	_file_dialog = EditorFileDialog.new()
	_file_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_file_dialog.add_filter("*.tres, *.res", "Resources")
	_file_dialog.get_cancel_button().pressed.connect(_on_FileDialog_canceled)

	_type_popup = PopupMenu.new()
	_type_popup.close_requested.connect(_on_TypePopup_close_requested)

	_load_bt_resources()

	_editor_interface = get_editor_interface()
	var base_control = _editor_interface.get_base_control()
	base_control.add_child(_file_dialog)
	base_control.add_child(_type_popup)

	_editor.plugin = self


func _exit_tree():
	remove_debugger_plugin(_debugger)
	remove_control_from_bottom_panel(_editor)

	_file_dialog.queue_free()
	_type_popup.queue_free()



func inspect_object(object : Object, for_property := "", inspector_only := false) -> void:
	_editor_interface.inspect_object(object, for_property, inspector_only)


func request_file_path(load_mode : bool) -> String:
	_file_dialog.visible = true

	var screen_size : Vector2i = get_viewport().get_visible_rect().end

	_file_dialog.size = Vector2i(700, 400)
	_file_dialog.position = (screen_size - _file_dialog.size) / 2

	if load_mode:
		_file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
		_file_dialog.title = "Load Behavior Tree"
	else:
		_file_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
		_file_dialog.title = "Save Behavior Tree as"

	var path : String = await _file_dialog.file_selected

	return path


func request_bt_node_type(position : Vector2, has_leaves := true) -> BTNode:
	_type_popup.visible = true
	_type_popup.position = position

	_reload_type_popup(has_leaves)

	var index : int = await _type_popup.index_pressed

	if index == -1: return null

	return bt_node_resources[index].duplicate()



func _load_bt_resources():
	bt_node_resources = []

	for path in _paths:
		_load_resources_in_folder(path)


func _load_resources_in_folder(folder_path : String):
	if not DirAccess.dir_exists_absolute(folder_path):
		push_error("Behavior Tree: path %s was not found." %folder_path)
		return

	var dir = DirAccess.open(folder_path)
	dir.list_dir_begin()
	var file_name = dir.get_next()

	while(file_name!=""):
		var full_path = folder_path+"/"+file_name

		if dir.current_is_dir():
			_load_resources_in_folder(full_path)
			file_name = dir.get_next()
			continue

		if not ResourceLoader.exists(full_path):
			file_name = dir.get_next()
			continue

		var file = load(full_path)

		if not file.has_method("new"):
			file_name = dir.get_next()
			continue

		var resource = file.new()

		if (resource as BTNode) == null:
			file_name = dir.get_next()
			continue

		var is_valid_type : bool = resource.get_bt_type_name() != ""

		if is_valid_type:
			bt_node_resources.append(resource)

		file_name = dir.get_next()


func _reload_type_popup(has_leaves : bool) -> void:
	_type_popup.clear()

	for bt_node in bt_node_resources:
		var node_name = bt_node.get_bt_type_name()

		if bt_node is BTLeaf and not has_leaves: continue

		_type_popup.add_item(node_name)



func _on_FileDialog_canceled() -> void:
	_file_dialog.file_selected.emit("")


func _on_TypePopup_close_requested() -> void:
	_type_popup.index_pressed.emit(-1)


func _on_Debugger_debug_tree(data : Array) -> void:
	_editor.debug_tree(data)


func _on_Debugger_debug_mode_changed(value : bool) -> void:
	_editor.debug_mode = value
