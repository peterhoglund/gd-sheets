tool
extends Cell
class_name CellData


var _regex := RegEx.new()


func _ready() -> void:
	## Init of texg alignment for each cell (depending on if it is numbers or text
	## is set from the SheetDataHandler in the SheetGridHandler. This is because the
	## cell text_field doens't know it's content when this _ready function runs.
	pass


func set_active(v : bool):
	.set_active(v)
	
	if active == true:
		text_field.align = LineEdit.ALIGN_LEFT
	elif active == false:
		text_field.align = get_align(text_field.text)


func get_align(text):
	if _is_text_float(text) : #or _is_text_integer(text):
		return LineEdit.ALIGN_RIGHT
	else:
		return  LineEdit.ALIGN_LEFT


func _is_text_integer(text):
	if not text : return
	
	_regex.compile("^[0-9]*$")
	if _regex.search(text) : return true
	else : return false


func _is_text_float(text):
	if not text : return
	
	_regex.compile("^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$")
	if _regex.search(text) : return true
	else : return false


#func _regex_check(new_text):
#	match cell_type:
#		CellType.NONE:
#			pass
#		CellType.STRING:
#			pass
#		CellType.INTEGER:
#			_regex.compile("^[0-9]*$")
#			if _regex.search(new_text) or text_field.text == "":
#				text_field.text = new_text   
#				_old_text = text_field.text
#			else:
#				text_field.text = _old_text
#			text_field.set_cursor_position(text_field.text.length())
#		CellType.FLOAT:
#			_regex.compile("^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$")
#			if _regex.search(new_text) or text_field.text == "":
#				text_field.text = new_text   
#				_old_text = text_field.text
#			else:
#				text_field.text = _old_text
#			text_field.set_cursor_position(text_field.text.length())
