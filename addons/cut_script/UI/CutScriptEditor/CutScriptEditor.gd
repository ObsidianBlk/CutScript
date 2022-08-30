extends Control
tool


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _cutscript_resource : CutScriptResource = null

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
onready var _editor_node : TextEdit = $TextEdit
onready var _op_minimap : CheckButton = $HFlowContainer/OpMiniMap

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_op_minimap.pressed = _editor_node.minimap_draw

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _PrepEditor() -> void:
	if _editor_node == null:
		return
	#_editor_node.syntax_highlighting = true
	if _cutscript_resource != null:
		_editor_node.text = _cutscript_resource.source
	else:
		_editor_node.text = ""

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func set_cutscript_resource(csr : Resource) -> void:
	if not csr is CutScriptResource:
		return
	
	_cutscript_resource = csr
	_PrepEditor()

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_source_changed() -> void:
	if not _cutscript_resource:
		return
	_cutscript_resource.set_source(_editor_node.text)

func _on_OpMiniMap_toggled(button_pressed : bool) -> void:
	if _editor_node:
		_editor_node.minimap_draw = button_pressed

