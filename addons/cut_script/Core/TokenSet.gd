extends Reference
class_name TokenSet


# -----------------------------------------------------------------------------
# Constants and ENUMs
# -----------------------------------------------------------------------------
enum TOKEN {
	ERROR=-1,
	LABEL,
	NUMBER,
	STRING,
	DIRECTIVE,
	HASH,
	PAREN_L,
	PAREN_R,
	BLOCK_L,
	BLOCK_R,
	BRACE_L,
	BRACE_R,
	LT,
	LTE,
	GT,
	GTE,
	COMMA,
	COLON,
	ASSIGN,
	EQ,
	NEQ,
	PLUS,
	MINUS,
	DIV,
	MULT,
	EOL,
	EOF
}

const BINOP_INFO = {
	TOKEN.ASSIGN : {"presidence":1, "symbol":"="},
	TOKEN.LT : {"presidence":7, "symbol":"<"},
	TOKEN.LTE : {"presidence":7, "symbol":"<="},
	TOKEN.GT : {"presidence":7, "symbol":">"},
	TOKEN.GTE : {"presidence":7, "symbol":">="},
	TOKEN.EQ : {"presidence":7, "symbol":"=="},
	TOKEN.NEQ : {"presidence":7, "symbol":"!="},
	TOKEN.PLUS : {"presidence":10, "symbol":"+"},
	TOKEN.MINUS : {"presidence":10, "symbol":"-"},
	TOKEN.MULT : {"presidence":20, "symbol":"*"},
	TOKEN.DIV : {"presidence":20, "symbol":"/"}
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _tokens : Array = []
var _idx : int = 0
var _mem : int = -1


# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func clone():
	var tsc = get_script().new()
	for token in _tokens:
		tsc.add(token.type, token.symbol, token.line, token.column)
	return tsc


func add(type : int, symbol : String, line : int = -1, column : int = -1) -> void:
	_tokens.append({
		"type": type,
		"symbol": symbol,
		"line": line,
		"column": column
	})

func clear() -> void:
	_tokens.clear()
	reset()

func reset() -> void:
	_idx = 0
	_mem = -1

func count() -> int:
	return _tokens.size()

func remember() -> void:
	_mem = _idx

func recall(auto_forget : bool = false) -> void:
	if _mem >= 0 and _mem < _tokens.size():
		_idx = _mem
		if auto_forget:
			_mem = -1

func forget() -> void:
	_mem = -1

func get_index() -> int:
	return _idx

func get_line() -> int:
	if _idx >= 0 and _idx < _tokens.size():
		return _tokens[_idx].line
	return -1

func get_column() -> int:
	if _idx >= 0 and _idx < _tokens.size():
		return _tokens[_idx].line
	return -1

func get_token() -> Dictionary:
	if _idx >= 0 and _idx < _tokens.size():
		return {
			"type": _tokens[_idx].type,
			"symbol": _tokens[_idx].symbol,
			"line": _tokens[_idx].line,
			"column": _tokens[_idx].column
		}
	return {"type":TOKEN.EOF, "symbol":"", "line":-1, "column":-1}

func peek_token() -> Dictionary:
	var idx : int = _idx + 1
	if idx >= 0 and idx < _tokens.size():
		return{
			"type": _tokens[idx].type,
			"symbol": _tokens[idx].symbol,
			"line": _tokens[idx].line,
			"column": _tokens[idx].column
		}
	return {"type":TOKEN.EOF, "symbol":"", "line":-1, "column":-1}

func next() -> void:
	if _idx + 1 < _tokens.size():
		_idx += 1

func next_if_type(type : int) -> bool:
	if is_type(type):
		next()
		return true
	return false

func next_if_eol(continuous : bool = false) -> bool:
	if is_type(TOKEN.EOL):
		next()
		if continuous:
			while is_type(TOKEN.EOL):
				next()
		return true
	return false

func is_type(type : int) -> bool:
	if _idx >= 0 and _idx < _tokens.size():
		return _tokens[_idx].type == type
	return false

func is_type_oneof(types : Array) -> bool:
	if _idx >= 0 and _idx < _tokens.size():
		return types.find(_tokens[_idx].type) >= 0
	return false

func is_label() -> bool:
	return is_type(TOKEN.LABEL)

func is_number() -> bool:
	return is_type(TOKEN.NUMBER)

func is_string() -> bool:
	return is_type(TOKEN.STRING)

func is_directive() -> bool:
	return is_type(TOKEN.DIRECTIVE)


func is_binop() -> bool:
	return is_type_oneof([
		TOKEN.LT,
		TOKEN.LTE,
		TOKEN.GT,
		TOKEN.GTE,
		TOKEN.EQ,
		TOKEN.NEQ,
		TOKEN.ASSIGN,
		TOKEN.DIV,
		TOKEN.PLUS,
		TOKEN.MINUS,
		TOKEN.MULT
	])

func is_eol() -> bool:
	return is_type(TOKEN.EOL)

func is_eof() -> bool:
	return is_type(TOKEN.EOF)

func binop_presidence() -> int:
	if is_binop():
		return BINOP_INFO[_tokens[_idx].type].presidence
	return -1

func get_symbol() -> String:
	if _idx >= 0 and _idx < _tokens.size():
		return _tokens[_idx].symbol
	return ""

func get_symbol_as_number(force_real : bool = false):
	if _idx >= 0 and _idx < _tokens.size():
		if _tokens[_idx].symbol.is_valid_integer():
			return _tokens[_idx].symbol.to_int()
		elif _tokens[_idx].symbol.is_valid_float():
			return _tokens[_idx].symbol.to_float()
	return INF

func get_type() -> int:
	if _idx >= 0 and _idx < _tokens.size():
		return _tokens[_idx].type
	return -1

func get_token_type_name(type : int) -> String:
	for key in TOKEN.keys():
		if TOKEN[key] == type:
			return key
	return ""

func get_type_name() -> String:
	if _idx >= 0 and _idx < _tokens.size():
		return get_token_type_name(_tokens[_idx].type)
	return ""

func to_string() -> String:
	if _idx >= 0 and _idx < _tokens.size():
		return "TOKEN(type: {type}, symbol: \"{symbol}\", line: {line}, column: {column})".format(_tokens[_idx])
	return ""

func to_string_array() -> PoolStringArray:
	var res : Array = []
	if _tokens.size() > 0:
		var idx : int = _idx
		for i in range(_tokens.size()):
			_idx = i
			res.append(to_string())
		_idx = idx
	return PoolStringArray(res)

