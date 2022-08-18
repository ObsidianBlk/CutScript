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

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _instructions : Dictionary = {}
var _error : Dictionary = {"id":OK, "msg":"", "line":-1, "column":-1}


# ------------------------------------------------------------------------------
# Interpreter Methods
# ------------------------------------------------------------------------------
func _Interpret(ast : ASTNode) -> int:
	# TODO: Interpret this shit!
	return OK

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
              var ast : ASTNode = ASTNode.new(ASTNode.TYPE.ASSIGNMENT, tok.line, tok.column, {"operator":operator})
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
			emit_signal("parser_failed", _error.err, _error.msg, _error.line, _error.column)
		if _Interpret(ast) != OK:
			break
		ast = null

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func define_inst(inst_name : String, owner : Object, method : String, args : Array = []) -> int:
	if not inst_name.is_valid_identifier():
		return ERR_INVALID_DECLARATION
	if inst_name in _instructions:
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

func execute(csr : CutScriptResource) -> void:
	if csr == null:
		return
	var tokens = csr.get_tokens()
	_Parse_Block(tokens)


