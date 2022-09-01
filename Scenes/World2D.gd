extends Node2D

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
export var cut_script : Resource = null


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _interpreter : CSInterpreter = null

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_cut_script(cs : Resource) -> void:
	if cs is CutScriptResource:
		cut_script = cs

# ------------------------------------------------------------------------------
# Override Method
# ------------------------------------------------------------------------------
func _ready() -> void:
	if cut_script != null:
		_interpreter = CSInterpreter.new()
		_interpreter.define_instruction("PRINT", self, "_INST_Print", [CSInterpreter.ARG_TYPE_VARIANT])
		_interpreter.define_instruction("TYPEOF", self, "_INST_TypeOf", [CSInterpreter.ARG_TYPE_VARIANT])
		_interpreter.connect("parser_failed", self, "_on_parse_failed")
		_interpreter.connect("interpreter_failed", self, "_on_interpreter_failed")
		_interpreter.execute(cut_script)


# ------------------------------------------------------------------------------
# Interpreter Method
# ------------------------------------------------------------------------------
func _INST_Print(msg) -> void:
	print(msg)

func _INST_TypeOf(variable) -> int:
	return typeof(variable)

# ------------------------------------------------------------------------------
# Handler Method
# ------------------------------------------------------------------------------
func _on_parse_failed(err : int, msg : String, line : int, col : int) -> void:
	print("Parse Error [", err, "]: ", msg, " | line=", line, ", column=", col)

func _on_interpreter_failed(err : int, msg : String, line : int, col : int) -> void:
	print("Interpreter Error [", err, "]: ", msg, " | line=", line, ", column=", col)


