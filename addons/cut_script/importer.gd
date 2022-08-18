tool 
extends EditorImportPlugin

# ------------------------------------------------------------------------------
# Constant
# ------------------------------------------------------------------------------
var CUTSCRIPTRESOURCE = preload("res://addons/cut_script/CutScriptResource.gd")

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func get_importer_name():
    return "obs.cutscript.plugin"

func get_visible_name():
    return "Cut-Script"

func get_recognized_extensions():
    return ["CUT", "cut"]

func get_save_extension():
    return "cut"

func get_resource_type():
    return "Resource"

func get_preset_count():
    return 1

func get_preset_name(preset):
    return "Default"

func get_import_options(preset):
    return []

func import(source_file : String, save_path : String, options : Dictionary, r_platform_variants : Array, r_gen_files : Array) -> int:
	var file : File = File.new()
	var err : int = file.open(source_file, File.READ)
	if err != OK:
		return err
	
	var text : String = file.get_as_text(true)
	file.close()
	
	var csr : Resource = CUTSCRIPTRESOURCE.new(text)
	return ResourceSaver.save("%s.%s" % [save_path, get_save_extension()], csr)

