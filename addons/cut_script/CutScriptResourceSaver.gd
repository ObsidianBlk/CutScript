tool
extends ResourceFormatSaver
class_name CutScriptResourceSaver

# This is a Resource Saver for the CutScriptResource resource.

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func get_recognized_extensions(resource : Resource) -> PoolStringArray:
	if resource is CutScriptResource:
		return PoolStringArray(["cut"])
	return PoolStringArray()

func recognize(resource : Resource) -> bool:
	return resource is CutScriptResource

func save(path : String, resource : Resource, flags : int) -> int:
	# NOTE: I feel I need to handle those flags... which I'm ignoring at the moment
	#  This could bite me in the ass
	var res : int = OK
	if resource is CutScriptResource:
		var file : File = File.new()
		res = file.open(path, File.WRITE)
		if res == OK:
			file.store_string(resource.source)
			print("Resource Save Successful")
		file.close()
	return res

