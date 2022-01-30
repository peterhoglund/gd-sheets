tool
extends Cell

var _drag_ready := false
var _dragging := false
var _drag_start := 0
var _drag_delta := 0
var dropdown_icon setget set_dropwdown_icon


signal dragging
signal dragging_start
signal dragging_stop


func _ready() -> void:
	$ColorRect.rect_min_size = _get_resolution_size(Vector2(6, 30))
	$ColorRect.rect_position.x = _get_resolution_size($ColorRect.rect_position.x, $ColorRect.rect_position.x - 6)
	$MenuButton.rect_min_size = _get_resolution_size(Vector2(30, 30))

func _process(delta: float) -> void:
	if _dragging:
	#	parent_column.rect_min_size.x += _drag_delta
		#print(_drag_delta)
		emit_signal("dragging", self)
	pass


func set_drag_handle_size(size):
	$ColorRect.rect_min_size = size
func set_dropdown_icon_size(size):
	$MenuButton.rect_min_size = size


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		#print((event.position.x / rect_size.x) * rect_size.x)
		if not _dragging:
			if (event.position.x / rect_size.x) * rect_size.x > rect_size.x - _get_resolution_size(10):
				mouse_default_cursor_shape = Control.CURSOR_HSPLIT
				_drag_ready = true
			else:
				mouse_default_cursor_shape = Control.CURSOR_IBEAM
				_drag_ready = false
	
		else:
			_drag_delta = event.position.x - _drag_start
			_drag_start = event.position.x
	
	
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				if _drag_ready:
					_dragging = true
					_drag_start = event.position.x
					emit_signal("dragging_start", self)
			else:
				if _dragging:
					_dragging = false
					emit_signal("dragging_stop", self)


func _on_ColorRect_mouse_entered() -> void:
	$ColorRect.color.a = 1
	mouse_default_cursor_shape = Control.CURSOR_HSIZE
	_drag_ready = true

func _on_ColorRect_mouse_exited() -> void:
	$ColorRect.color.a = 0
	mouse_default_cursor_shape = Control.CURSOR_IBEAM
	_drag_ready = false


func set_dropwdown_icon(value):
	$MenuButton.icon = value


func _get_resolution_size(size, hd_size = null):
	if get_viewport_rect().size.x > 1080:
		if not hd_size:
			return size * 2
		else:
			return hd_size
	else	:
		return size
