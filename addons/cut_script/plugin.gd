tool
extends EditorPlugin

# ------------------------------------------------------------------------------
# Variable
# ------------------------------------------------------------------------------
var _cut_importer : EditorImportPlugin = null


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _enter_tree():
	_cut_importer = preload("res://addons/cut_script/importer.gd").new()
	add_import_plugin(_cut_importer)


func _exit_tree():
	remove_import_plugin(_cut_importer)
	_cut_importer = null
