tool
extends Control
class_name Cell


enum CellType { NONE, STRING, INTEGER, FLOAT }
var cell_type

export (bool) var menu_enabled = false

onready var text_field := $LineEdit
onready var edit_menu := $EditMenu if menu_enabled and $EditMenu else null


var index : Vector2
var text : String = "" setget set_text
var placeholder_text : String = "" setget set_placeholder_text
var dirty = false
var active := false setget set_active
var interface_scale := 1.0
var undo_redo : UndoRedo # not yet implemented

var _old_text := ""
var _old_modulate : Color
var popup_active := false


signal focus_entered_id
signal focus_exited_id
signal text_changed_id
signal editing_completed


func _ready() -> void:
	connect("focus_exited", self, "_on_focus_exited")
	connect("focus_entered", self, "_on_focus_entered")
	text_field.connect("focus_exited", self, "_on_text_field_focus_exited")
	text_field.connect("text_changed", self, "_on_text_field_text_changed")
	if menu_enabled:
		edit_menu.connect("focus_exited", self, "_on_edit_menu_focus_exited")
		edit_menu.size_flags_horizontal = 0
		edit_menu.size_flags_vertical = 0
#	text_field.connect("gui_input", self, "_on_text_field_gui_input")
	cell_type = CellType.NONE
	
	$Border.modulate.a = 0.0


func _on_focus_entered():
	$Border.modulate.a = 1
	emit_signal("focus_entered_id", self)
	_old_modulate = modulate
	popup_active = false


func _on_focus_exited():
	if not popup_active:
		$Border.modulate.a = 0
		popup_active = false
		emit_signal("focus_exited_id", self)
	modulate = _old_modulate


## For when the text_field is inactive
func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if get_focus_owner() == self and event.pressed:
			if event.scancode == KEY_ENTER and not active:
				self.active = true
			elif event.scancode == KEY_ENTER and active:
				self.active = false
				get_node(focus_neighbour_bottom).grab_focus()
			elif event.scancode == KEY_BACKSPACE and not active:
				_erase_text()
			elif event.unicode:
				_set_text_directly(event.unicode)
	
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.doubleclick:
				self.active = true
		elif event.button_index == BUTTON_RIGHT:
			if event.pressed:
				if menu_enabled:
					grab_focus()
					popup_active = true
					edit_menu.rect_global_position = event.global_position
					edit_menu.popup()


## For when the text_field is active
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if get_focus_owner() == text_field and active and event.pressed :
			if event.scancode == KEY_ENTER:
#				self.active = false # this is handled by _on_text_field_focus_exited()
				get_node(focus_neighbour_bottom).call_deferred( "grab_focus" )
			elif event.scancode == KEY_TAB:
#				self.active = false # this is handled by _on_text_field_focus_exited()
				get_node(focus_neighbour_right).call_deferred( "grab_focus" )
			elif event.scancode == KEY_ESCAPE:
				dirty = false
				active = false
				_restore_cell()
				text_field.text = _old_text
				call_deferred("grab_focus")
			elif event.scancode == KEY_DOWN:
				text_field.caret_position = text_field.text.length()
			elif event.scancode == KEY_UP:
				text_field.caret_position = 0


func enter_text():
	dirty = true
	_on_focus_exited()
	get_node(focus_neighbour_bottom).call_deferred( "grab_focus" )


func set_active(v : bool):
	active = v
	if active == true:
		_prepare_cell()
	elif active == false:
		## Similar to text_field focus exited
		_restore_cell()
		emit_signal("editing_completed", self)


func _prepare_cell():
	dirty = true
	self.focus_mode = Control.FOCUS_NONE
	self.mouse_filter = Control.MOUSE_FILTER_IGNORE
	#self.mouse_default_cursor_shape = CURSOR_IBEAM
	text_field.focus_mode = Control.FOCUS_ALL
	text_field.grab_focus()
	
	## Similar to text_field focus entered
	_old_text = text
	text_field.mouse_filter = Control.MOUSE_FILTER_PASS
	text_field.caret_position = text_field.text.length()
	text_field.select(0, 0) #text_field.text.length())


func _restore_cell():
	self.focus_mode = Control.FOCUS_ALL
	self.mouse_filter = Control.MOUSE_FILTER_STOP
	#self.mouse_default_cursor_shape = CURSOR_ARROW
	text = text_field.text
	
	text_field.focus_mode = Control.FOCUS_NONE
	text_field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_field.select(0, 0)


func set_text(v):
	text = v
	text_field.text = text


func _set_text_directly(character):
	text_field.text = char(character)
	self.active = true
	emit_signal("text_changed_id", text_field.text, self)


func _erase_text():
	self.text = ""
	emit_signal("text_changed_id", text, self)
	emit_signal("editing_completed", self)


func set_placeholder_text(v):
	placeholder_text = v
	$LineEdit.placeholder_text = placeholder_text


# Unfortunately this signal is needed to reset the cell if focus is lost when in active mode
# e.g writing in the text_field
func _on_text_field_focus_exited():
	if dirty:
		self.active = false


func _on_text_field_text_changed(text):
	emit_signal("text_changed_id", text, self)


func _on_edit_menu_focus_exited():
	$Border.modulate.a = 0
	popup_active = false


func make_semi_selected():
	$Border.modulate.a = 0.5
