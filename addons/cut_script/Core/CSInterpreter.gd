extends Reference
class_name CSInterpreter

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal parser_failed(err, msg, line, col)
signal interpreter_failed(err, msg, line, col)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const SUPPORTED_TYPES : Array = [
	TYPE_INT,
	TYPE_REAL,
	TYPE_BOOL,
	TYPE_VECTOR2,
	TYPE_VECTOR3,
	TYPE_STRING,
]

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
# Override Methods
# ------------------------------------------------------------------------------
func _init() -> void:
	pass

# ------------------------------------------------------------------------------
# Interpreter Methods
# ------------------------------------------------------------------------------

func _Interpret_Atomic(ast : ASTNode):
	match ast.get_type():
		ASTNode.TYPE.NUMBER, ASTNode.TYPE.STRING, ASTNode.TYPE.VECTOR:
			return ast.get_meta("value")
		ASTNode.TYPE.BINARY:
			return _Interpret_Binary(ast)
		ASTNode.TYPE.LABEL:
			# TODO: Should this verify a return value and create an error itself
			# or let the caller do that if a null is returned? Unsure.
			return get_var_value(ast.get_meta("value"))
	return null

func _Interpret_Assignment(ast : ASTNode) -> int:
	var left : ASTNode = ast.get_left()
	if not left.is_type(ASTNode.TYPE.LABEL):
		_Err(ERR_INVALID_DECLARATION, "Missing expected variable declaration", ast.get_line(), ast.get_column())
		return ERR_INVALID_DECLARATION
	
	var label_name : String = left.get_meta("value")
	if not label_name.is_valid_identifier():
		_Err(ERR_INVALID_DECLARATION, "Symbol invalid variable name.", ast.get_line(), ast.get_column())
		return ERR_INVALID_DECLARATION
	
	# TODO: Finish this section
	var right : ASTNode = ast.get_right()
	var r_value = _Interpret_Atomic(right)
	if r_value == null:
		return ERR_INVALID_DECLARATION
	
	return OK

func _Interpret_Binary(ast : ASTNode):
	var operator : String = ast.get_meta("operator")
	var left : ASTNode = ast.get_left()
	var right : ASTNode = ast.get_right()
	
	match operator:
		"+":
			pass
		"-":
			pass
		"*":
			pass
		"/":
			pass
		"==":
			pass
		"!=":
			pass
		">":
			pass
		"<":
			pass
		">=":
			pass
		"<=":
			pass

func _Interpret_Block(ast : ASTNode) -> int:
	for i in range(ast.node_count):
		var node : ASTNode = ast.get_node(i)
		match node.get_type():
			ASTNode.TYPE.ASSIGNMENT:
				pass
			ASTNode.TYPE.BINARY:
				pass
			ASTNode.TYPE.INST:
				pass
			ASTNode.TYPE.DIRECTIVE:
				pass
			ASTNode.TYPE.BLOCK:
				return _Interpret_Block(node)
	return OK

func _Interpret(ast : ASTNode) -> int:
	#print(ast.to_string(true))
	if not ast.is_type(ASTNode.TYPE.BLOCK):
		return ERR_PARSE_ERROR
	return _Interpret_Block(ast)

# ------------------------------------------------------------------------------
# Parser Methods
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

func _Parse_Number(ts : TokenSet) -> ASTNode:
	var ast : ASTNode = null
	var val = ts.get_symbol_as_number()
	if val != INF:
		ast = ASTNode.new(ASTNode.TYPE.NUMBER, ts.get_line(), ts.get_column(), {"value":val})
	else: _Err(ERR_PARSE_ERROR, "Invalid number token.", ts.get_line(), ts.get_column())
	ts.next()
	return ast

func _Parse_String(ts : TokenSet) -> ASTNode:
	var ast : ASTNode = ASTNode.new(ASTNode.TYPE.STRING, ts.get_line(), ts.get_column(), {"value":_StripQuotes(ts.get_symbol())})
	ts.next()
	return ast

func _Parse_Label(ts : TokenSet) -> ASTNode:
	var ast : ASTNode = ASTNode.new(ASTNode.TYPE.LABEL, ts.get_line(), ts.get_column(), {"value":ts.get_symbol()})
	ts.next()
	return ast

func _Parse_Vector(ts : TokenSet) -> ASTNode:
	var l : int = ts.get_line()
	var c : int = ts.get_column()
	var ast : ASTNode = _Parse_Delimited(
		ts,
		ASTNode.new(ASTNode.TYPE.VECTOR, l, c),
		TokenSet.TOKEN.LT,
		TokenSet.TOKEN.GT
	)
	if ast != null:
		var count : int = ast.node_count()
		if count >= 2 and count <= 3:
			var vals : Array = []
			var n : ASTNode = ast.get_node(0)
			if not n.is_type(ASTNode.TYPE.NUMBER):
				_Err(ERR_INVALID_DECLARATION, "Vector expected number value.", n.get_line(), n.get_column())
				return null
			vals.append(n.get_meta("value"))

			n = ast.get_node(1)
			if not n.is_type(ASTNode.TYPE.NUMBER):
				_Err(ERR_INVALID_DECLARATION, "Vector expected number value.", n.get_line(), n.get_column())
				return null
			vals.append(n.get_meta("value"))
			
			var vec = Vector2(vals[0], vals[1])
			if count == 3:
				n = ast.get_node(2)
				if not n.is_type(ASTNode.TYPE.NUMBER):
					_Err(ERR_INVALID_DECLARATION, "Vector expected number value.", n.get_line(), n.get_column())
					return null
				vals.append(n.get_meta("value"))
				vec = Vector3(vals[0], vals[1], vals[2])
			
			ast.clear_child_nodes()
			ast.set_meta("value", vec)
			
		else:
			_Err(ERR_INVALID_DECLARATION, "Invalid number of vector datum.", l, c)
	return ast


func _Parse_Atom(ts : TokenSet) -> ASTNode:
	if ts.next_if_type(TokenSet.TOKEN.PAREN_L):
		var e : ASTNode = _Parse_Expression(ts)
		if not ts.next_if_type(TokenSet.TOKEN.PAREN_R):
			return null
		return e
		# TODO: I feel there was supposed to be more. Verify
	elif ts.is_type(TokenSet.TOKEN.LT):
		return _Parse_Vector(ts)
	elif _Is_Instruction(ts):
		return _Parse_Instruction(ts)
	
	if ts.is_type(TokenSet.TOKEN.NUMBER):
		return _Parse_Number(ts)
	elif ts.is_type(TokenSet.TOKEN.STRING):
		return _Parse_String(ts)
	elif ts.is_type(TokenSet.TOKEN.LABEL):
		return _Parse_Label(ts)
	return null


func _Parse_Delimited(ts : TokenSet, node : ASTNode, start_token_type : int, end_token_type : int, delimiter_token_type : int = -1, parse_func : String = "_Parse_Atom") -> ASTNode:
      if not has_method(parse_func):
          _Err(FAILED, "Parse Delimited given unknown parse function.", ts.get_line(), ts.get_column())
          return null
      var toEOL : bool = (start_token_type < 0 or end_token_type < 0)
      if not toEOL:
          if not ts.next_if_type(start_token_type):
              _Err(ERR_INVALID_DECLARATION, "Unexpected token type: %s"%[ts.get_type_name()], ts.get_line(), ts.get_column())
              return null
          ts.next_if_eol(true)
  
      while (not ts.is_eof() and (not toEOL and not ts.is_type(end_token_type))) or (toEOL and not ts.is_eol()):
          if node.node_count() > 1: # Not the first delimited expression
              if delimiter_token_type >= 0 and not ts.next_if_type(delimiter_token_type):
                  _Err(ERR_INVALID_DECLARATION, "Unexpected token type: %s"%[ts.get_type_name()], ts.get_line(), ts.get_column())
                  return null
              if not toEOL:
                  ts.next_if_eol(true)
          var e : ASTNode = call(parse_func, ts)
          if e != null:
              node.append_node(e)
          else: return null
          if not toEOL: ts.next_if_eol(true)
  
      if not toEOL:
          if not ts.is_type(end_token_type):
              _Err(ERR_INVALID_DECLARATION, "Unexpected token type: %s"%[ts.get_type_name()], ts.get_line(), ts.get_column())
              return null
      return node


func _Parse_Instruction(ts) -> ASTNode:
	var ast : ASTNode = ASTNode.new(ASTNode.TYPE.INST, ts.get_line(), ts.get_column(), {"inst": ts.get_symbol()})
	ts.next()
	return _Parse_Delimited(ts, ast, -1, -1, TokenSet.TOKEN.COMMA)


func _Parse_MaybeBinary(ts : TokenSet, l_ast : ASTNode, presidence : int) -> ASTNode:
      if l_ast != null and ts.is_binop():
          var tok : Dictionary = ts.get_token()
          var cpres : int = ts.binop_presidence()
          var operator : String = tok.symbol
          ts.next()
          if cpres > presidence:
              var r_ast : ASTNode = _Parse_MaybeBinary(ts, _Parse_Atom(ts), cpres)
              if r_ast == null:
                  return null
              var ast : ASTNode = ASTNode.new(
				ASTNode.TYPE.ASSIGNMENT if operator == "=" else ASTNode.TYPE.BINARY, 
				tok.line, tok.column, {"operator":operator})
              ast.set_left(l_ast)
              ast.set_right(r_ast)
              return _Parse_MaybeBinary(ts, ast, presidence)
      return l_ast

func _Parse_Expression(ts : TokenSet) -> ASTNode:
      return _Parse_MaybeBinary(ts, _Parse_Atom(ts), 0)


func _Parse_Block(ts : TokenSet, terminator : int = TokenSet.TOKEN.EOF) -> void:
	var ast : ASTNode = null
	while not (ts.is_type(terminator) or ts.is_eof()):
		if ts.next_if_eol():
			continue
		ast = _Parse_Expression(ts)
		if ast == null:
			emit_signal("parser_failed", _error.id, _error.msg, _error.line, _error.column)
			return
		if _Interpret(ast) != OK:
			break
		ast = null

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
		if SUPPORTED_TYPES.find(arg) < 0:
			return ERR_INVALID_DECLARATION
		def.args.append(arg)
	_instructions[inst_name] = def
	return OK

func define_var(var_name : String, value, overwritable : bool = true) -> int:
	if SUPPORTED_TYPES.find(typeof(value)) < 0:
		return ERR_INVALID_DATA
	if not var_name.is_valid_identifier():
		return ERR_INVALID_DECLARATION
	if identifier_defined(var_name):
		return ERR_ALREADY_EXISTS
	_env[var_name] = {"value": value, "overwrite": overwritable}
	return OK

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
	var tokens = csr.get_tokens()
	_Parse_Block(tokens)


