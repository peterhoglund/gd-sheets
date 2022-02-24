tool
extends EditorPlugin

const MainSheetsPanel = preload("res://addons/gd-sheets/scenes/SheetsMain.tscn")

var sheets_main_instance


func _enter_tree() -> void:
	sheets_main_instance = MainSheetsPanel.instance()
	sheets_main_instance.undo_redo = get_undo_redo() #not implemented
	set_gui()
	
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


func apply_changes():
	if sheets_main_instance.has_method("run_game"):
		sheets_main_instance.run_game()


func set_gui():
	var gui = get_editor_interface().get_base_control()
	var theme = get_editor_interface().get_editor_settings()
	sheets_main_instance.new_icon = gui.get_icon("New", "EditorIcons")
	sheets_main_instance.delete_icon = gui.get_icon("Remove", "EditorIcons")
	sheets_main_instance.rename_icon = gui.get_icon("Rename", "EditorIcons")
	sheets_main_instance.dropdown_icon = gui.get_icon("GuiOptionArrow", "EditorIcons")
	sheets_main_instance.sheets_icon = gui.get_icon("SpriteSheet", "EditorIcons")
	sheets_main_instance.left_icon = gui.get_icon("ArrowLeft", "EditorIcons")
	sheets_main_instance.right_icon = gui.get_icon("ArrowRight", "EditorIcons")
	sheets_main_instance.up_icon = gui.get_icon("ArrowUp", "EditorIcons")
	sheets_main_instance.down_icon = gui.get_icon("ArrowDown", "EditorIcons")
	
	sheets_main_instance.base_color = gui.get_color("base_color", "Editor")
	sheets_main_instance.dark_color_1 = gui.get_color("dark_color_1", "Editor")
	sheets_main_instance.dark_color_2 = gui.get_color("dark_color_2", "Editor")
	sheets_main_instance.dark_color_3 = gui.get_color("dark_color_3", "Editor")
	
	sheets_main_instance.interface_scale = get_editor_interface().get_editor_scale()
