extends Resource
class_name CSLexer

# Lexer for an Assembly-like language called CutScript.

# A reference for custom resource loading.
# https://godotengine.org/qa/105703/how-to-import-a-custom-resource


# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------
const SINGLE_SYMBOLS = {
	"#":TokenSet.TOKEN.HASH,
	"(":TokenSet.TOKEN.PAREN_L,
	")":TokenSet.TOKEN.PAREN_R,
	"{":TokenSet.TOKEN.BLOCK_L,
	"}":TokenSet.TOKEN.BLOCK_R,
	"[":TokenSet.TOKEN.BRACE_L,
	"]":TokenSet.TOKEN.BRACE_R,
	",":TokenSet.TOKEN.COMMA,
	":":TokenSet.TOKEN.COLON,
	"+":TokenSet.TOKEN.PLUS,
	"-":TokenSet.TOKEN.MINUS,
	"/":TokenSet.TOKEN.DIV,
	"*":TokenSet.TOKEN.MULT,
}

const OPERATOR_SYMBOLS = {
	"=":TokenSet.TOKEN.ASSIGN,
	"==":TokenSet.TOKEN.EQ,
	"<":TokenSet.TOKEN.LT,
	"<=":TokenSet.TOKEN.LTE,
	">":TokenSet.TOKEN.GT,
	">=":TokenSet.TOKEN.GTE,
	"!=":TokenSet.TOKEN.NEQ,
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _lines : Array = []
var _error : Dictionary = {"err":OK, "msg":OK, "line":0, "col":0}


# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _Clear_Error() -> void:
	_Set_Error(OK, "", 0, 0)

func _Set_Error(err : int, msg : String, line : int, col : int) -> int:
	_error.err = err
	_error.msg = msg
	_error.line = line
	_error.col = col
	return err

func _Is_Symbol_String(sym : String) -> bool:
	if sym.left(1) == "\"" and sym.length() >= 2:
		var r = sym.substr(sym.length() -1)
		var r2 = sym.substr(sym.length() -2)
		return r == "\"" and r2 != "\\\"" 
	return false


func _Attempt_Store(ts : TokenSet, state : Dictionary) -> Dictionary:
	# TODO: Need to finish this method!!
	var clear_state : bool = false
	if state.s != "":
		if state.sm == true:
			clear_state = _Is_Symbol_String(state.s)
			if clear_state:
				ts.add(TokenSet.TOKEN.STRING, state.s, state.l, state.c)
		else:
			clear_state = true
			var l = state.s.substr(0,1)
			if SINGLE_SYMBOLS.keys().find(state.s) >= 0:
				ts.add(SINGLE_SYMBOLS[state.s], state.s, state.l, state.c)
			elif OPERATOR_SYMBOLS.keys().find(state.s) >= 0:
				ts.add(OPERATOR_SYMBOLS[state.s], state.s, state.l, state.c)
			elif l == ".":
				ts.add(TokenSet.TOKEN.DIRECTIVE, state.s, state.l, state.c)
			elif l == "$":
				if state.s.substr(1).is_valid_hex_number():
					ts.add(TokenSet.TOKEN.NUMBER, state.s, state.l, state.c)
				else: state.err = _Set_Error(ERR_COMPILATION_FAILED, "Malformed hexidecimal number", state.l, state.c)
			elif "0123456789".find(l) >= 0:
				if state.s.is_valid_integer():
					ts.add(TokenSet.TOKEN.NUMBER, state.s, state.l, state.c)
				elif state.s.is_valid_float():
					ts.add(TokenSet.TOKEN.NUMBER, state.s, state.l, state.c)
				else: state.err = _Set_Error(ERR_COMPILATION_FAILED, "Malformed number", state.l, state.c)
			else:
				ts.add(TokenSet.TOKEN.LABEL, state.s, state.l, state.c)
				
	
	if state.err == OK and clear_state:
		state.s = ""
		state.sm = false
	
	return state


func _Attempt_Store_Dual(ts : TokenSet, state1 : Dictionary, state2 : Dictionary) -> Dictionary:
	state1 = _Attempt_Store(ts, state1)
	if state1.err == OK:
		state2 = _Attempt_Store(ts, state2)
		if state2.err != OK:
			return state2
	return state1


func _Char_To_CharOp(c1 : String, c2 : String) -> String:
	if SINGLE_SYMBOLS.keys().find(c1) >= 0:
		return c1
	elif OPERATOR_SYMBOLS.keys().find(c1) >= 0:
		if OPERATOR_SYMBOLS.keys().find(c1 + c2) >= 0:
			return c1 + c2
		return c1
	return ""

func _Parse_Line(ts : TokenSet, idx : int, line : String) -> int:
	# s = symbol | l = line | c = column | sm = "String Mode" | err = Error code, if any (OK by default)
	var state : Dictionary = {"s":"", "l":idx, "c":0, "sm":false, "err":OK}
	var line_len : int = line.length()
	for col in range(line_len):
		var chr : String = line.substr(col,1)
		var chr2 : String = "" if col+1 < line_len else line.substr(col+1,1)
		
		if chr == "\"" or state.sm == true: # Are we about to or in the middle of handling a string...
			var closing = state.sm # Determines if we START with "string mode" on or off
			if not state.sm: # If "string mode" is off...
				if state.s != "":
					# If we have a quote but the symbol has data and "string mode" (sm) is NOT true,
					#  then this is a strait up error!
					return ERR_COMPILATION_FAILED
				state.c = col # Store the column and turn "string mode" on!
				state.sm = true
			state.s += chr # Store the character in the symbol
			if chr == "\"" and closing: # If the character is a quote and we ENTERED with "string mode" on...
				state = _Attempt_Store(ts, state) # Then the string should be done, attempt to store
				if state.err != OK:
					return state.err
		else: # Handle characters as normal...
			# Check to see if the current (or current and following) is a single character symbol or operation
			var sym : String = _Char_To_CharOp(chr, chr2)
			if sym != "": # If it is/they are then...
				# ... attempt to store both the current symbol (in state) and this new symbol
				state = _Attempt_Store_Dual(ts, state, {"s":sym, "l":idx, "c":col, "sm":false, "err":OK})
				if state.err != OK:
					return state.err
			elif chr != " ": # Otherwise, if the character isn't a space
				if state.s == "": # Store the column index if this looks to be a new symbol
					state.c = col
				state.s += chr # and store the character in the symbol
			else: # Otherwise, the character IS a space, so, attempt to store any current symbol
				state = _Attempt_Store(ts, state)
				if state.err != OK:
					return state.err
	
	# If "string mode" is still active at this point, then something went wrong.
	if state.sm == true:
		return _Set_Error(ERR_COMPILATION_FAILED, "String missing closure", idx, state.c)
	
	# At this point, attempt to store any symbol data we still have...
	state = _Attempt_Store(ts, state)
	return state.err # and return the ultimate error result (which, hopefully, should be OK)

# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func parse(text : String) -> TokenSet:
	_Clear_Error()
	_lines = text.replace("\r", "").replace("\t", " ").split("\n")
	var ts : TokenSet = TokenSet.new()
	for idx in range(_lines.size()):
		var line : String = _lines[idx].split(";", true, 1)[0]
		var res : int = _Parse_Line(ts, idx, line)
		if res != OK:
			return null
		ts.add(TokenSet.TOKEN.EOL, "", ts.get_line(), ts.get_column())
	ts.add(TokenSet.TOKEN.EOF, "", ts.get_line(), ts.get_column())
	return ts

func get_error() -> Dictionary:
	return {
		"err":_error.err,
		"msg":_error.msg,
		"line":_error.line,
		"col":_error.col
	}

