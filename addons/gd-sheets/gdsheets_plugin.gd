tool
extends EditorPlugin

const MainSheetsPanel = preload("res://addons/gd-sheets/scenes/SheetsMain.tscn")

var sheets_main_instance


func _enter_tree() -> void:
	sheets_main_instance = MainSheetsPanel.instance()
	set_icons()
	
	get_editor_interface().get_editor_viewport().add_child(sheets_main_instance)
	make_visible(false)


func _exit_tree() -> void:
	if sheets_main_instance:
		sheets_main_instance.queue_free()


func has_main_screen() -> bool:
	return true


func make_visible(visible: bool) -> void:
	if sheets_main_instance:
		sheets_main_instance.visible = visible


func get_plugin_name() -> String:
	return "Sheets"


func get_plugin_icon() -> Texture:
	return get_editor_interface().get_base_control().get_icon("SpriteSheet", "EditorIcons")
	

func set_icons():
	var gui = get_editor_interface().get_base_control()
	var theme = get_editor_interface().get_editor_settings()
	sheets_main_instance.new_icon = gui.get_icon("New", "EditorIcons")
	sheets_main_instance.delete_icon = gui.get_icon("Remove", "EditorIcons")
	sheets_main_instance.rename_icon = gui.get_icon("Rename", "EditorIcons")
	sheets_main_instance.dropdown_icon = gui.get_icon("GuiOptionArrow", "EditorIcons")
	
	sheets_main_instance.primary_color = theme.get_setting("interface/theme/base_color")
	#sheets_main_instance.secondary_color = theme.get_setting("interface/theme/secondary_color")
