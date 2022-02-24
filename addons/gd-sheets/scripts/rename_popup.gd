tool
extends AcceptDialog


onready var name_edit = $MarginContainer/FileName
var file_name : String setget set_file_name, get_file_name

func _ready() -> void:
	name_edit.select_all()
	name_edit.caret_position = name_edit.text.length()
	name_edit.grab_focus()
	
	register_text_enter(name_edit)


func set_file_name(v):
	name_edit.text = v

func get_file_name():
	return name_edit.text


func _on_RenamePopup_about_to_show() -> void:
	name_edit.select_all()
	name_edit.caret_position = name_edit.text.length()
