tool
extends ResourceFormatLoader
class_name CutScriptResourceLoader

# Based on...
# https://github.com/AnidemDex/Godot-CustomResource/blob/main/addons/custom_resource/plain_text_resource_loader.gd
# Trying to solve issue with Bug  #46288
# https://github.com/godotengine/godot/issues/46288


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
# Preloading to avoid issues with project.godot
const CSRT = preload("res://addons/cut_script/Resources/CutScriptResource.gd")

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func get_recognized_extensions() -> PoolStringArray:
	return PoolStringArray(["cut"])

func get_resource_type(path: String) -> String:
	var ext = path.get_extension().to_lower()
	if ext == "cut":
		return "Resource" # Regardless of custom resource type.
	return ""

func handles_type(type_name: String) -> bool:
	# Always use this line for custom resources... not sure exactly why at this time.
	return ClassDB.is_parent_class(type_name, "Resource")

func load(path: String, original_path: String):
	var file : File = File.new()
	var err : int = file.open(path, File.READ)
	if err != OK:
		return err
	
	var text : String = file.get_as_text(true)
	file.close()
	
	var csr : Resource = CSRT.new(text)
	return csr

