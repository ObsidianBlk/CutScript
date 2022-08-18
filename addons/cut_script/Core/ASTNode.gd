extends Object
class_name ASTNode

# -----------------------------------------------------------------------------
# Constants and ENUMs
# -----------------------------------------------------------------------------
enum TYPE {
	NUMBER,
	STRING,
	VECTOR,
	LABEL,
	DIRECTIVE,
	BLOCK,
	INST,
	HILO,
	BINARY,
	ASSIGNMENT,
	CALL
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _type : int = -1
var _expr : Array = []
var _meta : Dictionary = {}
var _debug_line : int = -1
var _debug_column : int = -1

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _init(type : int, line : int = -1, column : int = -1, meta : Dictionary = {}) -> void:
	if TYPE.values().find(type) >= 0:
		_type = type
		_meta = meta
		set_debug(line, column)
	else:
		printerr("ASTNode assigned unknown type. Node invalid.")

# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func is_valid() -> bool:
	return _type >= 0

func is_type(type : int) -> bool:
	if _type >= 0:
		return type == _type
	return false

func one_of_type(types : Array) -> bool:
	if _type >= 0:
		for type in types:
			if typeof(type) == TYPE_INT and type == _type:
				return true
	return false

func node_count() -> int:
	return _expr.size()

func append_node(node : ASTNode) -> void:
	_expr.append(node)

func clear_child_nodes() -> void:
	_expr.clear()

func get_node(idx : int) -> ASTNode:
	if idx >= 0 and idx < _expr.size():
		return _expr[idx]
	return null

func set_left(v : ASTNode) -> void:
	if _expr.size() <= 0:
		_expr.append(v)
	elif _expr[0] == null:
		_expr[0] = v
	else:
		printerr("Overwriting expressions not allowed.")

func set_right(v : ASTNode) -> void:
	if _expr.size() == 0:
		_expr = [null, v]
	elif _expr.size() == 1:
		_expr.append(v)
	elif _expr[1] == null:
		_expr[1] = v
	else:
		printerr("Overwriting expressions not allowed.")

func get_left() -> ASTNode:
	return get_node(0)

func get_right() -> ASTNode:
	return get_node(1)

func has_left() -> bool:
	return _expr.size() >= 1 and _expr[0] != null

func has_right() -> bool:
	return _expr.size() >= 2 and _expr[1] != null

func has_meta_key(key : String) -> bool:
	return key in _meta

func has_meta_keys(keys : Array) -> bool:
	for key in keys:
		if not (key in _meta):
			return false
	return true

func get_meta_value(key : String):
	if key in _meta:
		return _meta[key]
	return null

func get_meta_values(keys : Array) -> Dictionary:
	var res : Dictionary = {}
	for key in keys:
		if key in _meta:
			res[key] = _meta[key]
	return res

func set_debug(line : int, column : int) -> void:
	_debug_line = line
	_debug_column = column

func get_debug() -> Dictionary:
	return {
		"line": _debug_line,
		"column": _debug_column
	}

func get_line() -> int:
	return _debug_line

func get_column() -> int:
	return _debug_column

func to_string(full_tree : bool = false, depth : int = 0) -> String:
	if _type < 0:
		return "INVALID AST NODE"
	
	var s : String = "%s[Type: %s] [Meta: %s] [line: %d, column: %d]"%[
		"" if depth <= 0 else " ".repeat(depth),
		_type,
		_meta,
		_debug_line,
		_debug_column
	]
	if full_tree:
		for e in _expr:
			s = "%s\n%s"%[s, e.to_string(true, depth + 1)]
	return s

