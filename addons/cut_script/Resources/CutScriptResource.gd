tool
extends Resource
class_name CutScriptResource

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal parse_succeeded()
signal parse_failed(err_id, err_msg, line, column)

# ------------------------------------------------------------------------------
# "Export" Variables
# ------------------------------------------------------------------------------
var _source : String = ""

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _dirty : bool = true # True if the source has not been passed through the Lexer
var _tokens : TokenSet = null
var _error : Dictionary = {"err":OK, "msg":"OK", "line":-1, "col":-1}

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _init(src : String = "") -> void:
	parse_source(src)


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
				parse_source(value)
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
func set_source(src : String) -> void:
	_dirty = true
	_source = src
	emit_changed()

func get_tokens() -> TokenSet:
	if _dirty:
		parse()
	
	if _tokens:
		return _tokens.clone()
	return null

func get_error() -> int:
	return _error.err

func get_error_info() -> Dictionary:
	return _error

func parse_source(src : String) -> void:
	_source = src
	parse()

func parse() -> void:
	var lexer : CSLexer = CSLexer.new()
	_tokens = lexer.parse(_source)
	_error = lexer.get_error()
	_dirty = false
	if _error.err != OK:
		printerr("[", _error.err, "] ", _error.msg, " | (line: ", _error.line, ", col: ", _error.col, ")")
		emit_signal("parse_failed", _error.err, _error.msg, _error.line, _error.col)
	emit_signal("parse_succeeded")
	emit_changed()
