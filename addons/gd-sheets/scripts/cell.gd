tool
extends LineEdit
class_name Cell


var index : Vector2
var active = false
var parent_column : Control
var custom_size : Vector2

var focus_next_enter : NodePath
var focus_previous_enter : NodePath

enum CellType { NONE, STRING, INTEGER, FLOAT }
var cell_type

var _regex := RegEx.new()
var _old_modulate : Color

signal focus_entered_id
signal focus_exited_id
signal text_changed_id

func _ready() -> void:
	#parent_column.connect("minimum_size_changed", self, "_on_parent_column_resize")
	connect("focus_exited", self, "_on_focus_exited")
	connect("focus_entered", self, "_on_focus_entered")
	connect("text_changed", self, "_on_text_changed")
	
	if not text.empty():
		active = true
	else:
		active = false
	
	cell_type = CellType.NONE


func _on_parent_column_resize():
	caret_position = 0

func _on_focus_exited():
	emit_signal("focus_exited_id", self)
	caret_position = 0
	select(0,0)
	modulate = _old_modulate

func _on_focus_entered():
	emit_signal("focus_entered_id", self)
	_old_modulate = modulate
	modulate = Color(0.9, 1, 1, 1)
	yield(get_tree(), "idle_frame")
	select_all()

var _old_text = ""
func _on_text_changed(new_text):
	match cell_type:
		CellType.NONE:
			pass
		CellType.STRING:
			pass
		CellType.INTEGER:
			_regex.compile("^[0-9]*$")
			if _regex.search(new_text) or text == "":
				text = new_text   
				_old_text = text
			else:
				text = _old_text
			set_cursor_position(text.length())
		CellType.FLOAT:
			_regex.compile("^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$")
			if _regex.search(new_text) or text == "":
				text = new_text   
				_old_text = text
			else:
				text = _old_text
			set_cursor_position(text.length())
	
	emit_signal("text_changed_id", text, self)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if get_focus_owner() == self and event.pressed:
			if event.scancode == KEY_ENTER:
				if event.scancode == KEY_SHIFT: #TODO - Not working at all
					if focus_previous_enter:
						get_node(focus_previous_enter).grab_focus()
				else: 
					if focus_next_enter:
						get_node(focus_next_enter).grab_focus()



