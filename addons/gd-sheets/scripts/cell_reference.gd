tool
extends Cell
class_name CellReference

export (NodePath) var resize_handle_node
onready var resize_handle = get_node(resize_handle_node)
onready var move_timer = $MoveTimer

var _resizing := false
var _moving := false


signal resizing
signal resizing_started
signal resizing_stopped

signal moving
signal moving_started
signal moving_stopped

signal edit_menu_index_pressed_id


func _ready() -> void:
	#resize_handle.rect_min_size.x = 6 * interface_scale
	resize_handle.connect("mouse_entered", self, "_on_resize_handle_mouse_entered")
	resize_handle.connect("mouse_exited", self, "_on_resize_handle_mouse_exited")
	resize_handle.connect("gui_input", self, "_on_resize_handle_gui_input")
	move_timer.connect("timeout", self, "_on_move_timer_timeout")
	if edit_menu:
		edit_menu.connect("index_pressed", self, "_on_edit_menu_index_pressed")


func set_dropdown_icon_size(size):
	$MenuButton.rect_min_size = size


func _on_edit_menu_index_pressed(index : int):
	emit_signal("edit_menu_index_pressed_id", self, index)


func _on_resize_handle_mouse_entered() -> void:
	resize_handle.color.a = 1
	mouse_default_cursor_shape = Control.CURSOR_HSIZE


func _on_resize_handle_mouse_exited() -> void:
	resize_handle.color.a = 0
	mouse_default_cursor_shape = Control.CURSOR_ARROW


func _on_move_timer_timeout():
	_moving = true
	emit_signal("moving_started", self, rect_global_position)
	mouse_default_cursor_shape = Control.CURSOR_DRAG


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.doubleclick:
				move_timer.stop()
			elif event.pressed:
				move_timer.start()
			else:
				move_timer.stop()
				if _moving:
					_moving = false
					mouse_default_cursor_shape = Control.CURSOR_ARROW
					emit_signal("moving_stopped", self, event.global_position)
		
		elif event.button_index == BUTTON_RIGHT:
			if event.pressed:
				edit_menu.rect_global_position = event.global_position
				edit_menu.popup()
				
	if _moving:
		if event is InputEventMouseMotion:
			emit_signal("moving", self, event.global_position)


func _on_resize_handle_gui_input(event : InputEvent):
	var mouse_pos := Vector2.ZERO
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				_resizing = true
				emit_signal("resizing_started", self, event.global_position)
			else:
				_resizing = false
				emit_signal("resizing_stopped", self, event.global_position)
	
	if _resizing:
		if event is InputEventMouseMotion:
			emit_signal("resizing", self, event.global_position)
