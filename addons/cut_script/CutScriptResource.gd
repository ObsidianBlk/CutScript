tool
extends Resource
class_name CutScriptResource

# ------------------------------------------------------------------------------
# "Export" Variables
# ------------------------------------------------------------------------------
var _source : String = ""

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _tokens : TokenSet = null
var _error : Dictionary = {"err":OK, "msg":"OK", "line":-1, "col":-1}

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _init(src : String = "") -> void:
	parse(src)


func _get(property : String):
	match property:
		"source":
			return _source
	return null


func _set(property : String, value) -> bool:
	var success : bool = true
	match property:
		"source":
			if typeof(value) == TYPE_STRING:
				parse(value)
			else : success = false
		_:
			success = false
	
	if success:
		property_list_changed_notify()
		
	return success


func _get_property_list() -> Array:
	return [
		{
			name="source",
			type=TYPE_STRING,
			usage=PROPERTY_USAGE_DEFAULT
		},
	]

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func get_tokens() -> TokenSet:
	if _tokens:
		return _tokens.clone()
	return null

func get_error() -> int:
	return _error.err

func get_error_info() -> Dictionary:
	return _error

func parse(src : String) -> void:
	_source = src
	var lexer : CSLexer = CSLexer.new()
	_tokens = lexer.parse(src)
	_error = lexer.get_error()
	if _error.err != OK:
		printerr("[", _error.err, "] ", _error.msg, " | (line: ", _error.line, ", col: ", _error.col, ")")

