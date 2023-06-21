@tool
class_name BTEditor
extends VBoxContainer



var plugin : BTEditorPlugin:
	set(value):
		plugin = value
		_graph_edit.plugin = value

var debug_mode := false:
	set = _set_debug_mode


@onready var _graph_edit := $GraphEdit as BTGraphEdit
@onready var _title := $TopBar/Title as Label
@onready var _new_button := $TopBar/Right/NewButton as Button
@onready var _load_button := $TopBar/Right/LoadButton as Button
@onready var _save_button := $TopBar/Right/SaveButton as Button
@onready var _save_as_button := $TopBar/Right/SaveAsButton as Button
@onready var _back_button := $TopBar/Left/BackButton as Button



func _ready() -> void:
	_save_button.pressed.connect(_on_SaveButton_pressed)
	_save_as_button.pressed.connect(_on_SaveAsButton_pressed)
	_load_button.pressed.connect(_on_LoadButton_pressed)
	_new_button.pressed.connect(_on_NewButton_pressed)
	_back_button.pressed.connect(_on_BackButton_pressed)

	_graph_edit.loaded_changed.connect(_on_GraphEdit_loaded_changed)



func debug_tree(data : Array) -> void:
	_graph_edit.open_tree(BTGraphEdit.OpenTreeMode.DEBUG, data)



func _save(path := "") -> void:
	var compiled_tree = _graph_edit.compile_tree()

	if compiled_tree == null: return

	if path == "":
		path = await plugin.request_file_path(false)

	if path == "": return

	ResourceSaver.save(compiled_tree, path)
	_graph_edit.current_path = path


func _on_SaveButton_pressed() -> void:
	_save(_graph_edit.current_path)



func _on_SaveAsButton_pressed() -> void:
	_save()


func _on_LoadButton_pressed() -> void:
	var path : String = await plugin.request_file_path(true)

	if path == "": return

	_graph_edit.open_tree(BTGraphEdit.OpenTreeMode.LOAD, path)


func _on_NewButton_pressed() -> void:
	_graph_edit.open_tree(BTGraphEdit.OpenTreeMode.NEW)


func _on_BackButton_pressed() -> void:
	_graph_edit.open_tree(BTGraphEdit.OpenTreeMode.BACK)


func _on_GraphEdit_loaded_changed(number_pages : int) -> void:
	var text : String = _graph_edit.current_path

	if text == "":
		text = "new Behavior Tree"

	_title.text = text

	_back_button.visible = number_pages > 1



func _set_debug_mode(value : bool) -> void:
	if debug_mode == value: return

	debug_mode = value

	_save_button.disabled = debug_mode
	_save_as_button.disabled = debug_mode
	_load_button.disabled = debug_mode
	_new_button.disabled = debug_mode

	_graph_edit.debug_mode = debug_mode
