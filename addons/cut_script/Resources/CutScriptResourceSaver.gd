tool
extends ResourceFormatSaver
class_name CutScriptResourceSaver

# This is a Resource Saver for the CutScriptResource resource.

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
# Preloading to avoid issues with project.godot
const CSRT = preload("res://addons/cut_script/Resources/CutScriptResource.gd")

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func get_recognized_extensions(resource : Resource) -> PoolStringArray:
	if resource is CutScriptResource:
		return PoolStringArray(["cut"])
	return PoolStringArray()

func recognize(resource : Resource) -> bool:
	# Cast instead of using "is" keyword in case is a subclass
	resource = resource as CSRT
	if resource:
		return true
	return false

func save(path : String, resource : Resource, flags : int) -> int:
	# NOTE: I feel I need to handle those flags... which I'm ignoring at the moment
	#  This could bite me in the ass
	var res : int = OK
	if resource is CSRT:
		var file : File = File.new()
		res = file.open(path, File.WRITE)
		if res == OK:
			file.store_string(resource.source)
		file.close()
	return res

