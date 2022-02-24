tool
extends Control


var current_doc : SheetsDataDocument
var sheet_handler : SheetGridHandler
var sheet_docs_handler : SheetDocumentsHandler
var undo_redo : UndoRedo #not implemented

var interface_scale = 1.0
var new_icon : Texture
var delete_icon : Texture
var 	rename_icon : Texture
var 	dropdown_icon : Texture
var sheets_icon : Texture
var left_icon : Texture
var right_icon : Texture
var up_icon : Texture
var down_icon : Texture

var base_color : Color
var dark_color_1 : Color
var dark_color_2 : Color
var dark_color_3 : Color

var _ready_done := false
var _headers : Control
var _ids : Control
var _origo : Control

onready var sheet_area = $Window/HSplitContainer/WorkArea/WorkAreaContainer/SheetArea
onready var docs_list = $Window/HSplitContainer/FileArea/SheetsDocsList
onready var cell_content = $Window/HSplitContainer/WorkArea/WorkAreaContainer/CellContent


func _ready() -> void:
	current_doc = SheetsDataDocument.new()
	sheet_handler = SheetGridHandler.new(current_doc)
	sheet_handler.cell_content_ref = cell_content
	sheet_handler.interface_scale = interface_scale
	sheet_handler.undo_redo = undo_redo
	
	sheet_docs_handler = SheetDocumentsHandler.new(docs_list)
	sheet_docs_handler.root_icon = sheets_icon
	sheet_docs_handler.folder_item = null
	sheet_docs_handler.sheets_icon = null
	
	_setup_gui()
	_connect_signals()
	_generate_documents_list()
	_generate_sheet_cells()
	_update_data()
	
	# Need to set this flag for the _process to not start too early. Specific for Editor.
	_ready_done = true


func _process(delta: float) -> void:
	if not _ready_done : return
	
	sheet_area.scroll_vertical = stepify(sheet_area.scroll_vertical, 30 * interface_scale)
	
	if _origo and _headers and _ids:
		_origo.rect_position.y = sheet_area.scroll_vertical 
		_origo.rect_position.x = sheet_area.scroll_horizontal
		_headers.rect_position.y = sheet_area.scroll_vertical
		_ids.rect_position.x = sheet_area.scroll_horizontal


func _generate_documents_list():
	sheet_docs_handler.update_documents_list()
	if docs_list.get_item_count() > 0:
		current_doc = sheet_docs_handler.get_selected_item(0)
		docs_list.select(0)
	

func _generate_sheet_cells():
	
	for child in sheet_area.get_children():
		if child is SheetGridContainer:
#			sheet_area.get_child(0).queue_free()
			_unload_sheet(child)
	
	var sheet : Control
	if not current_doc: 
		sheet = sheet_handler.clear_sheet()
		sheet_area.add_child(sheet)
		$Window/HSplitContainer/WorkArea/NoSheetContainer.visible = true
	else:
		$Window/HSplitContainer/WorkArea/NoSheetContainer.visible = false
		sheet = sheet_handler.get_sheet(current_doc)
	
		sheet_area.add_child(sheet)
		sheet_area.move_child(sheet, 0)
		
		## The cells have to be in the tree (sheet_area.add_child()) before doing these
		## Or need access to all cells before doing these
		sheet_handler.setup_neighbours()
		sheet_handler.resize_headers_and_ids()
		sheet_handler.cells[0][0].background.color = dark_color_1
		
		## Need to get these node references for the scrolling to work
		_get_header_and_id_nodes()


func _unload_sheet(sheet):
	sheet.queue_free()
	_clear_headers_and_id_nodes()


func run_game():
	if sheet_handler.data_handler.has_method("build_hash_map"):
		sheet_handler.data_handler.build_hash_map(true)


func _update_data():
	if current_doc:
		sheet_handler.update_data()


func update_cell_content(text):
	cell_content.text = text


func update_docs_list():
	pass


func _setup_gui():
	$Window/HSplitContainer/FileArea.rect_min_size.x = 150 * interface_scale
	$Window/MarginContainer/HBoxContainer/Actions/NewSheetButton.icon = new_icon
	$Window/MarginContainer/HBoxContainer/Actions/DeleteSheetButton.icon = delete_icon
	$Window/MarginContainer/HBoxContainer/Actions/RenameSheetButton.icon = rename_icon
	$Window/MarginContainer/HBoxContainer/GridActions/AddColumnLeftButton.icon = left_icon
	$Window/MarginContainer/HBoxContainer/GridActions/AddColumnRightButton.icon = right_icon
	$Window/MarginContainer/HBoxContainer/GridActions/AddRowAboveButton.icon = up_icon
	$Window/MarginContainer/HBoxContainer/GridActions/AddRowBelowButton.icon = down_icon
	$Window/HSplitContainer/WorkArea/NoSheetContainer/NoSheetContainer/ButtonCenterContainer/NewSheetButton.icon = new_icon
	
	$DeleteSheetPopup.get_ok().text = "Delete"
	$RenamePopup.get_ok().text = "Rename"
	
	$Window/MarginContainer/HBoxContainer/Zoom/ZoomMinus.rect_min_size.x = 24 * interface_scale
	$Window/MarginContainer/HBoxContainer/Zoom/ZoomPlus.rect_min_size.x = 24 * interface_scale
	
	#$Window/HSplitContainer/WorkArea/WorkAreaContainer/SheetArea/GridArea/ColumnResizeMarker.rect_size.x = 1 * interface_scale


func _get_header_and_id_nodes():
	_headers = sheet_area.get_child(0).get_node("Headers")
	_ids = sheet_area.get_child(0).get_node("IDs")
	_origo = sheet_area.get_child(0).get_node("Origo")


func _clear_headers_and_id_nodes():
	_headers = null
	_ids = null
	_origo = null



####################################################
##                    SIGNALS                     ##
####################################################
func _connect_signals():
	sheet_handler.connect("warning_sent", self, "_on_warning_sent")
	sheet_handler.connect("cell_focus_enabled", self, "update_cell_content")
	sheet_handler.connect("cell_text_changed", self, "update_cell_content")
#	sheet_handler.connect("column_moved", self, "_on_column_moved")
#	sheet_handler.connect("row_moved", self, "_on_row_moved")
	sheet_handler.connect("sheet_edited", self, "_on_sheet_edited")
	docs_list.connect("item_selected", self, "_on_docs_list_item_selected")
	docs_list.connect("item_activated", self, "_on_docs_list_item_activated")
	cell_content.connect("text_changed", sheet_handler, "_on_cell_content_ref_text_changed")
	cell_content.connect("text_entered", sheet_handler, "_on_cell_content_ref_text_entered")
	cell_content.connect("focus_entered", sheet_handler, "_on_cell_content_ref_focus_entered")


func _on_docs_list_item_selected(index):
	sheet_docs_handler.active_document_index = index
	current_doc = sheet_docs_handler.get_selected_item(index)
	sheet_handler.sheet_doc = current_doc
	_generate_sheet_cells()
	_update_data()


func _on_docs_list_item_activated(index):
	_on_RenameSheetButton_pressed()


func _on_sheet_edited():
	_generate_sheet_cells()
	_update_data()


func _on_column_moved():
	_generate_sheet_cells()
	_update_data()


func _on_row_moved():
	_generate_sheet_cells()
	_update_data()


func _on_warning_sent(text):
	$Warning.text = text
	$Warning.pop()


func _on_NewSheetButton_pressed() -> void:
	sheet_docs_handler.new_sheet()
	docs_list.emit_signal("item_selected", sheet_docs_handler.active_document_index)


func _on_RenameSheetButton_pressed() -> void:
	if not docs_list.is_anything_selected() : return
	$RenamePopup.file_name = docs_list.get_item_text(sheet_docs_handler.active_document_index)
	$RenamePopup.popup()
	$RenamePopup/MarginContainer/FileName.grab_focus()
	
func _on_RenamePopup_confirmed() -> void:
	if $RenamePopup.file_name.empty() : return
	
	sheet_docs_handler.rename_document($RenamePopup.file_name)
	sheet_docs_handler.update_documents_list()
	for i in range(0, docs_list.get_item_count()):
		if docs_list.get_item_text(i) == $RenamePopup.file_name:
			docs_list.select(i)
			docs_list.emit_signal("item_selected", i)
	docs_list.grab_focus()


func _on_DeleteSheetButton_pressed() -> void:
	if not docs_list.is_anything_selected() : return
	$DeleteSheetPopup.dialog_text = "Do you want to delete " + docs_list.get_item_text(sheet_docs_handler.active_document_index) + "?"
	$DeleteSheetPopup.popup()
	
func _on_DeleteSheetPopup_confirmed() -> void:
	sheet_docs_handler.delete_document()
	sheet_docs_handler.update_documents_list()
	
	if docs_list.get_item_count() > 0 :
		if sheet_docs_handler.active_document_index == docs_list.get_item_count():
			docs_list.select(sheet_docs_handler.active_document_index - 1)
			docs_list.emit_signal("item_selected", sheet_docs_handler.active_document_index - 1)
		else:
			docs_list.select(sheet_docs_handler.active_document_index)
			docs_list.emit_signal("item_selected", sheet_docs_handler.active_document_index)
	else:
		current_doc = null
		_generate_sheet_cells()
	
	docs_list.grab_focus()


## For some reason the scroll goes to the bottom when adding a new col/row from the buttons.
## That is why the scroll_pos is added here
func _on_AddColumnLeftButton_pressed() -> void:
	if not sheet_handler.selected_cell : return
	$Window/MarginContainer/HBoxContainer/GridActions/AddColumnLeftButton.release_focus()
	var scroll_pos = sheet_area.scroll_vertical
	var pos = sheet_handler.selected_cell.index.x
	sheet_handler.insert_column(pos)
	## grabbing focus won't work from the sheet_handler's insert_x function, has to do it here
	sheet_handler.cells[pos][sheet_handler.selected_cell.index.y].grab_focus()
	sheet_area.scroll_vertical = scroll_pos


func _on_AddColumnRightButton_pressed() -> void:
	if not sheet_handler.selected_cell : return
	$Window/MarginContainer/HBoxContainer/GridActions/AddColumnRightButton.release_focus()
	var scroll_pos = sheet_area.scroll_vertical
	var pos = sheet_handler.selected_cell.index.x + 1
	sheet_handler.insert_column(pos)
	sheet_handler.cells[pos][sheet_handler.selected_cell.index.y].grab_focus()
	sheet_area.scroll_vertical = scroll_pos


func _on_AddRowAboveButton_pressed() -> void:
	if not sheet_handler.selected_cell : return
	$Window/MarginContainer/HBoxContainer/GridActions/AddRowAboveButton.release_focus()
	var scroll_pos = sheet_area.scroll_vertical
	var pos = sheet_handler.selected_cell.index.y
	sheet_handler.insert_row(pos)
	sheet_handler.cells[sheet_handler.selected_cell.index.x][pos].grab_focus()
	sheet_area.scroll_vertical = scroll_pos


func _on_AddRowBelowButton_pressed() -> void:
	if not sheet_handler.selected_cell : return
	$Window/MarginContainer/HBoxContainer/GridActions/AddRowBelowButton.release_focus()
	var scroll_pos = sheet_area.scroll_vertical
	var pos = sheet_handler.selected_cell.index.y + 1
	sheet_handler.insert_row(pos)
	sheet_handler.cells[sheet_handler.selected_cell.index.x][pos].grab_focus()
	sheet_area.scroll_vertical = scroll_pos

