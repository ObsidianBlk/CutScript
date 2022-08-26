extends Reference
class_name CSInterpreter


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal interpreter_failed(err, msg, line, col)
signal parser_failed(err, msg, line, col)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const RESERVED : Dictionary = {
	"true": true,
	"false": false,
	"pi": PI
}

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _instructions : Dictionary = {}
var _env : Dictionary = {}
var _error : Dictionary = {"id":OK, "msg":"", "line":-1, "column":-1}


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _Err(id : int, msg : String, line : int = -1, column : int = -1) -> void:
	  if _error.id == OK:
		  _error.id = id
		  _error.msg = msg
		  _error.line = line
		  _error.column = column

func _StripQuotes(s : String) -> String:
	  var l = s.substr(0, 1)
	  var r = s.substr(s.length() - 1, 1)
	  if l == r and (l == "\"" or l == "'"):
		  return s.substr(1, s.length() - 2)
	  return s

func _Is_Instruction(ts : TokenSet) -> bool:
	if ts.is_type(TokenSet.TOKEN.LABEL):
		return _instructions.keys().find(ts.get_symbol()) >= 0
	return false

# ------------------------------------------------------------------------------
# Binary Operation Methods
# ------------------------------------------------------------------------------

func _Bin_Add(l_value, r_value, line : int, column : int):
	match typeof(l_value):
		TYPE_INT:
			match typeof(r_value):
				TYPE_INT:
					return l_value + r_value
				TYPE_REAL:
					return float(l_value) + r_value
				TYPE_STRING:
					if r_value.is_valid_integer():
						return l_value + l_value.to_int()
					elif r_value.is_valid_float():
						return float(l_value) + r_value.to_float()
					_Err(ERR_INVALID_PARAMETER, "Cannot add operators INT + STRING.", line, column)
				TYPE_VECTOR2, TYPE_VECTOR3:
					_Err(ERR_INVALID_PARAMETER, "Cannot add operators INT + VECTOR.", line, column)
		TYPE_REAL:
			match typeof(r_value):
				TYPE_INT:
					return l_value + float(r_value)
				TYPE_REAL:
					return l_value + r_value
				TYPE_STRING:
					if r_value.is_valid_float():
						return l_value + r_value.to_float()
					_Err(ERR_INVALID_PARAMETER, "Cannot add operators FLOAT + STRING.", line, column)
				TYPE_VECTOR2, TYPE_VECTOR3:
					_Err(ERR_INVALID_PARAMETER, "Cannot add operators INT + VECTOR.", line, column)
		TYPE_STRING:
			match typeof(r_value):
				TYPE_INT, TYPE_REAL:
					return l_value + String(r_value)
				TYPE_STRING:
					return l_value + r_value
				TYPE_VECTOR2:
					return l_value + ("(%s, %s)"%[r_value.x, r_value.y])
				TYPE_VECTOR3:
					return l_value + ("(%s, %s, %s)"%[r_value.x, r_value.y, r_value.z])
		TYPE_VECTOR2:
			match typeof(r_value):
				TYPE_INT:
					_Err(ERR_INVALID_PARAMETER, "Cannot add operators VECTOR2 + INT.", line, column)
				TYPE_REAL:
					_Err(ERR_INVALID_PARAMETER, "Cannot add operators VECTOR2 + FLOAT.", line, column)
				TYPE_STRING:
					_Err(ERR_INVALID_PARAMETER, "Cannot add operators VECTOR2 + STRING.", line, column)
				TYPE_VECTOR2:
					return l_value + r_value
				TYPE_VECTOR3:
					_Err(ERR_INVALID_PARAMETER, "Cannot add operators VECTOR2 + VECTOR3.", line, column)
		TYPE_VECTOR3:
			match typeof(r_value):
				TYPE_INT:
					_Err(ERR_INVALID_PARAMETER, "Cannot add operators VECTOR3 + INT.", line, column)
				TYPE_REAL:
					_Err(ERR_INVALID_PARAMETER, "Cannot add operators VECTOR3 + FLOAT.", line, column)
				TYPE_STRING:
					_Err(ERR_INVALID_PARAMETER, "Cannot add operators VECTOR3 + STRING.", line, column)
				TYPE_VECTOR2:
					_Err(ERR_INVALID_PARAMETER, "Cannot add operators VECTOR3 + VECTOR.", line, column)
				TYPE_VECTOR3:
					return l_value + r_value
		_:
			_Err(ERR_INVALID_PARAMETER, "Left-hand operand type unsupported.", line, column)
	return null

func _Bin_Subtract(l_value, r_value, line : int, column : int):
	match typeof(l_value):
		TYPE_INT:
			match typeof(r_value):
				TYPE_INT:
					return l_value - r_value
				TYPE_REAL:
					return float(l_value) - r_value
				TYPE_STRING:
					if r_value.is_valid_integer():
						return l_value - l_value.to_int()
					elif r_value.is_valid_float():
						return float(l_value) - r_value.to_float()
					_Err(ERR_INVALID_PARAMETER, "Cannot subtract operators INT - STRING.", line, column)
				TYPE_VECTOR2, TYPE_VECTOR3:
					_Err(ERR_INVALID_PARAMETER, "Cannot subtract operators INT - VECTOR.", line, column)
		TYPE_REAL:
			match typeof(r_value):
				TYPE_INT:
					return l_value - float(r_value)
				TYPE_REAL:
					return l_value - r_value
				TYPE_STRING:
					if r_value.is_valid_float():
						return l_value - r_value.to_float()
					_Err(ERR_INVALID_PARAMETER, "Cannot subtract operators FLOAT - STRING.", line, column)
				TYPE_VECTOR2, TYPE_VECTOR3:
					_Err(ERR_INVALID_PARAMETER, "Cannot subtract operators INT - VECTOR.", line, column)
		TYPE_VECTOR2:
			match typeof(r_value):
				TYPE_INT:
					_Err(ERR_INVALID_PARAMETER, "Cannot subtract operators VECTOR2 - INT.", line, column)
				TYPE_REAL:
					_Err(ERR_INVALID_PARAMETER, "Cannot subtract operators VECTOR2 - FLOAT.", line, column)
				TYPE_STRING:
					_Err(ERR_INVALID_PARAMETER, "Cannot subtract operators VECTOR2 - STRING.", line, column)
				TYPE_VECTOR2:
					return l_value - r_value
				TYPE_VECTOR3:
					_Err(ERR_INVALID_PARAMETER, "Cannot subtract operators VECTOR2 - VECTOR3.", line, column)
		TYPE_VECTOR3:
			match typeof(r_value):
				TYPE_INT:
					_Err(ERR_INVALID_PARAMETER, "Cannot subtract operators VECTOR3 - INT.", line, column)
				TYPE_REAL:
					_Err(ERR_INVALID_PARAMETER, "Cannot subtract operators VECTOR3 - FLOAT.", line, column)
				TYPE_STRING:
					_Err(ERR_INVALID_PARAMETER, "Cannot subtract operators VECTOR3 - STRING.", line, column)
				TYPE_VECTOR2:
					_Err(ERR_INVALID_PARAMETER, "Cannot subtract operators VECTOR3 - VECTOR.", line, column)
				TYPE_VECTOR3:
					return l_value + r_value
		_:
			_Err(ERR_INVALID_PARAMETER, "Left-hand operand type unsupported.", line, column)
	return null


func _Bin_Multiply(l_value, r_value, line : int, column : int):
	match typeof(l_value):
		TYPE_INT:
			match typeof(r_value):
				TYPE_INT:
					return l_value * r_value
				TYPE_REAL:
					return float(l_value) * r_value
				TYPE_STRING:
					if r_value.is_valid_integer():
						return l_value * l_value.to_int()
					elif r_value.is_valid_float():
						return float(l_value) * r_value.to_float()
					_Err(ERR_INVALID_PARAMETER, "Cannot multiply operators INT * STRING.", line, column)
				TYPE_VECTOR2, TYPE_VECTOR3:
					return float(l_value) * r_value
		TYPE_REAL:
			match typeof(r_value):
				TYPE_INT:
					return l_value * float(r_value)
				TYPE_REAL, TYPE_VECTOR2, TYPE_VECTOR3:
					return l_value * r_value
				TYPE_STRING:
					if r_value.is_valid_float():
						return l_value * r_value.to_float()
					_Err(ERR_INVALID_PARAMETER, "Cannot multiply operators FLOAT * STRING.", line, column)
		TYPE_VECTOR2:
			match typeof(r_value):
				TYPE_INT:
					return l_value * float(r_value)
				TYPE_REAL, TYPE_VECTOR2:
					return l_value * r_value
				TYPE_STRING:
					if r_value.is_valid_float():
						return l_value * r_value.to_float()
					_Err(ERR_INVALID_PARAMETER, "Cannot multiply operators VECTOR2 * STRING.", line, column)
				TYPE_VECTOR3:
					_Err(ERR_INVALID_PARAMETER, "Cannot multiply operators VECTOR2 * VECTOR3.", line, column)
		TYPE_VECTOR3:
			match typeof(r_value):
				TYPE_INT:
					return l_value * float(r_value)
				TYPE_REAL, TYPE_VECTOR3:
					return l_value + r_value
				TYPE_STRING:
					if r_value.is_valid_float():
						return l_value * r_value.to_float()
					_Err(ERR_INVALID_PARAMETER, "Cannot multiply operators VECTOR3 * STRING.", line, column)
				TYPE_VECTOR2:
					_Err(ERR_INVALID_PARAMETER, "Cannot multiply operators VECTOR3 * VECTOR2.", line, column)
		_:
			_Err(ERR_INVALID_PARAMETER, "Left-hand operand type unsupported.", line, column)
	return null

func _Bin_Divide(l_value, r_value, line : int, column : int):
	match typeof(l_value):
		TYPE_INT:
			match typeof(r_value):
				TYPE_INT:
					if r_value != 0:
						return l_value / r_value
					_Err(ERR_INVALID_PARAMETER, "Divide by zero!", line, column)
				TYPE_REAL:
					if r_value != 0.0:
						return float(l_value) / r_value
					_Err(ERR_INVALID_PARAMETER, "Divide by zero!", line, column)
				TYPE_STRING:
					if r_value.is_valid_integer():
						var val : int = l_value.to_int()
						if val != 0:
							return l_value / l_value.to_int()
						_Err(ERR_INVALID_PARAMETER, "Divide by zero!", line, column)
					elif r_value.is_valid_float():
						var val : float = r_value.to_float()
						if val != 0.0:
							return float(l_value) / r_value.to_float()
						_Err(ERR_INVALID_PARAMETER, "Divide by zero!", line, column)
					else:
						_Err(ERR_INVALID_PARAMETER, "Cannot divide operators INT / STRING.", line, column)
				TYPE_VECTOR2:
					_Err(ERR_INVALID_PARAMETER, "Cannot divide operators INT / VECTOR2.", line, column)
				TYPE_VECTOR3:
					_Err(ERR_INVALID_PARAMETER, "Cannot divide operators INT / VECTOR3.", line, column)
		TYPE_REAL:
			match typeof(r_value):
				TYPE_INT:
					if r_value != 0.0:
						return l_value / float(r_value)
					_Err(ERR_INVALID_PARAMETER, "Divide by zero!", line, column)
				TYPE_REAL:
					if r_value != 0.0:
						return l_value * r_value
					_Err(ERR_INVALID_PARAMETER, "Divide by zero!", line, column)
				TYPE_STRING:
					if r_value.is_valid_float():
						var val : float = r_value.to_float()
						if val != 0.0:
							return l_value * r_value.to_float()
						_Err(ERR_INVALID_PARAMETER, "Divide by zero!", line, column)
					else:
						_Err(ERR_INVALID_PARAMETER, "Cannot divide operators FLOAT / STRING.", line, column)
				TYPE_VECTOR2:
					_Err(ERR_INVALID_PARAMETER, "Cannot divide operators FLOAT / VECTOR2.", line, column)
				TYPE_VECTOR3:
					_Err(ERR_INVALID_PARAMETER, "Cannot divide operators FLOAT / VECTOR3.", line, column)
		TYPE_VECTOR2:
			match typeof(r_value):
				TYPE_INT:
					if r_value != 0:
						return l_value / float(r_value)
					_Err(ERR_INVALID_PARAMETER, "Divide by zero!", line, column)
				TYPE_REAL, TYPE_VECTOR2:
					if r_value != 0.0:
						return l_value / r_value
					_Err(ERR_INVALID_PARAMETER, "Divide by zero!", line, column)
				TYPE_STRING:
					if r_value.is_valid_float():
						var val : float = r_value.to_float()
						if val != 0.0:
							return l_value * r_value.to_float()
						_Err(ERR_INVALID_PARAMETER, "Divide by zero!", line, column)
					else:
						_Err(ERR_INVALID_PARAMETER, "Cannot divide operators VECTOR2 / STRING.", line, column)
				TYPE_VECTOR3:
					_Err(ERR_INVALID_PARAMETER, "Cannot divide operators VECTOR2 / VECTOR3.", line, column)
		TYPE_VECTOR3:
			match typeof(r_value):
				TYPE_INT:
					if r_value != 0:
						return l_value * float(r_value)
					_Err(ERR_INVALID_PARAMETER, "Divide by zero!", line, column)
				TYPE_REAL:
					if r_value != 0.0:
						return l_value + r_value
					_Err(ERR_INVALID_PARAMETER, "Divide by zero!", line, column)
				TYPE_STRING:
					if r_value.is_valid_float():
						var val : float = r_value.to_float()
						if val != 0.0:
							return l_value * val
						_Err(ERR_INVALID_PARAMETER, "Divide by zero!", line, column)
					else:
						_Err(ERR_INVALID_PARAMETER, "Cannot divide operators VECTOR3 / STRING.", line, column)
				TYPE_VECTOR2:
					_Err(ERR_INVALID_PARAMETER, "Cannot divide operators VECTOR3 * VECTOR2.", line, column)
				TYPE_VECTOR3:
					if r_value.length() != 0.0:
						return l_value / r_value
					_Err(ERR_INVALID_PARAMETER, "Divide by zero!", line, column)
		_:
			_Err(ERR_INVALID_PARAMETER, "Left-hand operand type unsupported.", line, column)
	return null

func _Bin_GT(l_value, r_value, line : int, column : int, eq : bool = false):
	match typeof(l_value):
		TYPE_INT:
			match typeof(r_value):
				TYPE_INT:
					if eq:
						return l_value >= r_value
					return l_value > r_value
				TYPE_REAL:
					if eq:
						return float(l_value) >= r_value
					return float(l_value) > r_value
				TYPE_STRING:
					if r_value.is_valid_float():
						if eq:
							return float(l_value) >= r_value.to_float()
						return float(l_value) > r_value.to_float()
					else:
						_Err(ERR_INVALID_PARAMETER, "Cannot test equality on operators INT > STRING.", line, column)
				_:
					_Err(ERR_INVALID_PARAMETER, "Right-hand operand type unsupported.", line, column)
		TYPE_REAL:
			match typeof(r_value):
				TYPE_INT:
					if eq:
						return float(l_value) >= r_value
					return float(l_value) > r_value
				TYPE_REAL:
					if eq:
						return l_value >= r_value
					return l_value > r_value
				TYPE_STRING:
					if r_value.is_valid_float():
						if eq:
							return l_value >= r_value.to_float()
						return l_value > r_value.to_float()
					else:
						_Err(ERR_INVALID_PARAMETER, "Cannot test equality on operators FLOAT > STRING.", line, column)
				_:
					_Err(ERR_INVALID_PARAMETER, "Right-hand operand type unsupported.", line, column)
		TYPE_STRING:
			if l_value.is_valid_float():
				match typeof(r_value):
					TYPE_INT:
						if eq:
							return l_value.to_float() >= float(r_value)
						return l_value.to_float() > float(r_value)
					TYPE_REAL:
						if eq:
							return l_value.to_float() >= r_value
						return l_value.to_float() > r_value
					_:
						_Err(ERR_INVALID_PARAMETER, "Right-hand operand type unsupported.", line, column)
			else:
				_Err(ERR_INVALID_PARAMETER, "Left-hand operand type unsupported.", line, column)
		TYPE_VECTOR2:
			if typeof(r_value) == TYPE_VECTOR2:
				if eq:
					return l_value.length_squared() >= r_value.length_squared()
				return l_value.length_squared() > r_value.length_squared()
			else:
				_Err(ERR_INVALID_PARAMETER, "Right-hand operand type unsupported.", line, column)
		TYPE_VECTOR3:
			if typeof(r_value) == TYPE_VECTOR3:
				if eq:
					return l_value.length_squared() >= r_value.length_squared()
				return l_value.length_squared() > r_value.length_squared()
			else:
				_Err(ERR_INVALID_PARAMETER, "Right-hand operand type unsupported.", line, column)
		_:
			_Err(ERR_INVALID_PARAMETER, "Left-hand operand type unsupported.", line, column)
	return null

func _Bin_LT(l_value, r_value, line : int, column : int, eq : bool = false):
	match typeof(l_value):
		TYPE_INT:
			match typeof(r_value):
				TYPE_INT:
					if eq:
						return l_value <= r_value
					return l_value < r_value
				TYPE_REAL:
					if eq:
						return float(l_value) <= r_value
					return float(l_value) < r_value
				TYPE_STRING:
					if r_value.is_valid_float():
						if eq:
							return float(l_value) <= r_value.to_float()
						return float(l_value) < r_value.to_float()
					else:
						_Err(ERR_INVALID_PARAMETER, "Cannot test equality on operators INT < STRING.", line, column)
				_:
					_Err(ERR_INVALID_PARAMETER, "Right-hand operand type unsupported.", line, column)
		TYPE_REAL:
			match typeof(r_value):
				TYPE_INT:
					if eq:
						return float(l_value) <= r_value
					return float(l_value) < r_value
				TYPE_REAL:
					if eq:
						return l_value <= r_value
					return l_value < r_value
				TYPE_STRING:
					if r_value.is_valid_float():
						if eq:
							return l_value <= r_value.to_float()
						return l_value < r_value.to_float()
					else:
						_Err(ERR_INVALID_PARAMETER, "Cannot test equality on operators FLOAT < STRING.", line, column)
				_:
					_Err(ERR_INVALID_PARAMETER, "Right-hand operand type unsupported.", line, column)
		TYPE_STRING:
			if l_value.is_valid_float():
				match typeof(r_value):
					TYPE_INT:
						if eq:
							return l_value.to_float() <= float(r_value)
						return l_value.to_float() < float(r_value)
					TYPE_REAL:
						if eq:
							return l_value.to_float() <= r_value
						return l_value.to_float() < r_value
					_:
						_Err(ERR_INVALID_PARAMETER, "Right-hand operand type unsupported.", line, column)
			else:
				_Err(ERR_INVALID_PARAMETER, "Left-hand operand type unsupported.", line, column)
		TYPE_VECTOR2:
			if typeof(r_value) == TYPE_VECTOR2:
				if eq:
					return l_value.length_squared() <= r_value.length_squared()
				return l_value.length_squared() < r_value.length_squared()
			else:
				_Err(ERR_INVALID_PARAMETER, "Right-hand operand type unsupported.", line, column)
		TYPE_VECTOR3:
			if typeof(r_value) == TYPE_VECTOR3:
				if eq:
					return l_value.length_squared() <= r_value.length_squared()
				return l_value.length_squared() < r_value.length_squared()
			else:
				_Err(ERR_INVALID_PARAMETER, "Right-hand operand type unsupported.", line, column)
		_:
			_Err(ERR_INVALID_PARAMETER, "Left-hand operand type unsupported.", line, column)
	return null

# ------------------------------------------------------------------------------
# Interpreter Methods
# ------------------------------------------------------------------------------

func _Interpret_Atomic(ast : ASTNode):
	match ast.get_type():
		ASTNode.TYPE.NUMBER, ASTNode.TYPE.STRING, ASTNode.TYPE.VECTOR:
			return ast.get_meta_value("value")
		ASTNode.TYPE.BINARY:
			return _Interpret_Binary(ast)
		ASTNode.TYPE.LABEL:
			var var_name : String = ast.get_meta_value(("value"))
			if not var_name.is_valid_identifier():
				_Err(ERR_INVALID_DECLARATION, "Symbol expected to be valid variable declaration.", ast.get_line(), ast.get_column())
				return null
			if not var_defined(var_name):
				_Err(ERR_DOES_NOT_EXIST, "Variable \"%s\" undefined."%[var_name], ast.get_line(), ast.get_column())
				return null
			return get_var_value(var_name)
		_:
			_Err(ERR_INVALID_DECLARATION, "Unexpected declaration [%s]."%[ast.get_type_name()], ast.get_line(), ast.get_column())
	return null

func _Interpret_Assignment(ast : ASTNode) -> int:
	var left : ASTNode = ast.get_left()
	if not left.is_type(ASTNode.TYPE.LABEL):
		_Err(ERR_INVALID_DECLARATION, "Missing expected variable declaration", ast.get_line(), ast.get_column())
		return ERR_INVALID_DECLARATION
	
	var label_name : String = left.get_meta_value("value")
	if not label_name.is_valid_identifier():
		_Err(ERR_INVALID_DECLARATION, "Symbol invalid variable name.", ast.get_line(), ast.get_column())
		return ERR_INVALID_DECLARATION
	if label_name in RESERVED:
		_Err(ERR_ALREADY_IN_USE, "Symbol \"%s\" is reserved keyword.", ast.get_line(), ast.get_column())
		return ERR_ALREADY_IN_USE
	
	# TODO: Finish this section
	var right : ASTNode = ast.get_right()
	var r_value = _Interpret_Atomic(right)
	if r_value == null:
		return _error.id
	var res : int = define_var(label_name, r_value)
	if res != OK:
		match res:
			ERR_LOCKED:
				_Err(res, "Constant variable cannot be changed.", ast.get_line(), ast.get_column())
			_:
				_Err(res, "Failed to define variable.", ast.get_line(), ast.get_column())
	
	return res

func _Interpret_Binary(ast : ASTNode):
	var operator : String = ast.get_meta_value("operator")
	var left : ASTNode = ast.get_left()
	var right : ASTNode = ast.get_right()
	
	var l_value = _Interpret_Atomic(left)
	if l_value == null:
		return null
	var r_value = _Interpret_Atomic(right)
	if r_value == null:
		return null
	
	match operator:
		"+":
			return _Bin_Add(l_value, r_value, ast.get_line(), ast.get_column())
		"-":
			return _Bin_Subtract(l_value, r_value, ast.get_line(), ast.get_column())
		"*":
			return _Bin_Multiply(l_value, r_value, ast.get_line(), ast.get_column())
		"/":
			return _Bin_Divide(l_value, r_value, ast.get_line(), ast.get_column())
		"==":
			return l_value == r_value
		"!=":
			return l_value != r_value
		">":
			return _Bin_GT(l_value, r_value, ast.get_line(), ast.get_column())
		"<":
			return _Bin_LT(l_value, r_value, ast.get_line(), ast.get_column())
		">=":
			return _Bin_GT(l_value, r_value, ast.get_line(), ast.get_column(), true)
		"<=":
			return _Bin_LT(l_value, r_value, ast.get_line(), ast.get_column(), true)

func _Interpret_Block(ast : ASTNode) -> int:
	for i in range(ast.node_count()):
		var node : ASTNode = ast.get_node(i)
		match node.get_type():
			ASTNode.TYPE.ASSIGNMENT:
				var res = _Interpret_Assignment(node)
				if res != OK:
					return res
			ASTNode.TYPE.BINARY:
				var val = _Interpret_Binary(node) # Honestly, this doesn't do a damn thing... but there you go!
				if val == null:
					return FAILED
			ASTNode.TYPE.INST:
				pass
			ASTNode.TYPE.DIRECTIVE:
				print("DIRECTIVES ARE NOT YET A THING. Nice try though.")
			ASTNode.TYPE.BLOCK:
				return _Interpret_Block(node)
	return OK

func _Interpret(ast : ASTNode) -> int:
	#print(ast.to_string(true))
	if not ast.is_type(ASTNode.TYPE.BLOCK):
		return ERR_PARSE_ERROR
	return _Interpret_Block(ast)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func identifier_defined(ident_name : String) -> bool:
	return ident_name in RESERVED or ident_name in _env or ident_name in _instructions


func define_inst(inst_name : String, owner : Object, method : String, args : Array = []) -> int:
	if not inst_name.is_valid_identifier():
		return ERR_INVALID_DECLARATION
	if identifier_defined(inst_name):
		return ERR_ALREADY_EXISTS
	if not owner.has_method(method):
		return ERR_METHOD_NOT_FOUND
	
	var def : Dictionary = {
		"owner": weakref(owner),
		"method": method,
		"args": []
	}
	for arg in args:
		if typeof(arg) != TYPE_INT:
			return ERR_INVALID_PARAMETER
		if CSParser.SUPPORTED_TYPES.find(arg) < 0:
			return ERR_INVALID_DECLARATION
		def.args.append(arg)
	_instructions[inst_name] = def
	return OK

func define_var(var_name : String, value, constant : bool = false) -> int:
	if CSParser.SUPPORTED_TYPES.find(typeof(value)) < 0:
		return ERR_INVALID_DATA
	if not var_name.is_valid_identifier():
		return ERR_INVALID_DECLARATION
	if var_name in RESERVED:
		return ERR_ALREADY_IN_USE
	if var_name in _env:
		if _env[var_name].constant:
			return ERR_LOCKED
	_env[var_name] = {"value": value, "constant": constant}
	return OK

func var_defined(var_name : String) -> bool:
	return var_name in RESERVED or var_name in _env

func get_var_value(var_name : String):
	if var_name.is_valid_identifier():
		if var_name in RESERVED:
			return RESERVED[var_name]
		if var_name in _env:
			return _env[var_name].value
	return null

func execute(csr : CutScriptResource) -> void:
	if csr == null:
		return
	var parser : CSParser = CSParser.new(_instructions.keys())
	parser.connect("parser_failed", self, "_on_parser_failed")
	var ast : ASTNode = parser.parse(csr)
	if ast == null:
		return
	if not ast.is_type(ASTNode.TYPE.BLOCK):
		printerr("Parsed CutScript does not start with a block node.")
		return
	print(ast.to_string(true))
	_Interpret_Block(ast)
	print(_env)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_parser_failed(id : int, msg : String, line : int, column : int) -> void:
	emit_signal("parser_failed", id, msg, line, column)
