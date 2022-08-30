tool
extends EditorPlugin

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const CUTSCRIPTEDITOR : PackedScene = preload("res://addons/cut_script/UI/CutScriptEditor/CutScriptEditor.tscn")

# ------------------------------------------------------------------------------
# Variable
# ------------------------------------------------------------------------------
var _cut_importer : EditorImportPlugin = null
var _cut_editor : Control = null
var _cut_editor_button : ToolButton = null
var _cut_script_resource : Resource = null


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _enter_tree():
	_cut_importer = preload("res://addons/cut_script/importer.gd").new()
	add_import_plugin(_cut_importer)
	_cut_editor = CUTSCRIPTEDITOR.instance()
	_cut_editor_button = add_control_to_bottom_panel(_cut_editor, "CutScript Editor")
	#_cut_editor.visible = false
	_cut_editor_button.visible = false


func _exit_tree():
	remove_import_plugin(_cut_importer)
	_cut_importer = null
	if _cut_editor_button != null:
		remove_control_from_bottom_panel(_cut_editor)
		_cut_editor_button = null
	_cut_editor.queue_free()
	_cut_editor = null

func handles(obj : Object) -> bool:
	return obj is CutScriptResource

func make_visible(visible : bool) -> void:
	if _cut_editor_button != null:
		_cut_editor_button.visible = visible
		if visible:
			_cut_editor.set_cutscript_resource(_cut_script_resource)
			#_cut_editor.visible = true
			#_cut_editor_button.pressed = true
		else:
			_cut_editor.set_cutscript_resource(null)
			#_cut_editor.visible = false
			#_cut_editor_button.pressed = false

func edit(obj : Object) -> void:
	if obj is CutScriptResource:
		_cut_script_resource = obj
		_cut_editor_button.pressed = true

func clear() -> void:
	if _cut_script_resource != null:
		_cut_script_resource = null

func apply_changes() -> void:
	var _res : int = _SaveCutScript()

func save_external_data() -> void:
	var _res : int = _SaveCutScript()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _SaveCutScript() -> int:
	if _cut_script_resource:
		var res : int = ResourceSaver.save(_cut_script_resource.resource_path, _cut_script_resource)
		if res != OK:
			printerr("Failed to save CutScript: ", res, " for resource \"", _cut_script_resource, "\"")
		else:
			var rfs = get_editor_interface().get_resource_filesystem()
			rfs.scan()
		return res
	return OK


