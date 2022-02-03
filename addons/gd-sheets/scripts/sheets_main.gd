tool
extends Control

const HeaderCell = preload("res://addons/gd-sheets/scenes/HeaderCell.tscn")
const GridArea = preload("res://addons/gd-sheets/scripts/grid_area.gd")

export (int) var columns = 5 setget set_columns
export (int) var rows = 10 setget set_rows

onready var docs_list : ItemList = $Window/HSplitContainer/FileArea/ScrollContainer/SheetsDocsList
onready var warning_message : Label = $Warning/MarginContainer/HBoxContainer/NotUniqueWarningLabel


var cells := []
var current_focus : LineEdit
var selected_sheet_item
var zoom_level : int = 100

var _current_doc : Resource 

var _ready_done = false
var _scrolling = false
var _mouse_position := Vector2.ZERO


### ICONS ###
var new_icon
var delete_icon
var rename_icon
var dropdown_icon

var primary_color : Color
var secondary_color : Color


signal cell_not_unique


func _ready() -> void:
	if docs_list.get_item_count() > 0:
		_current_doc = load("res://addons/gd-sheets/documents/" + docs_list.get_item_text(0) + ".tres")
	else:
		_current_doc = null
	_init_ui()
	_init_cells()
	update_ids_and_headers()
	_setup_neighbours()
	_update_docs_list()
	_ready_done = true
	
	
	$Window/HSplitContainer/WorkArea/WorkAreaContainer/CellContent.connect("focus_entered", self, "_on_cellcontent_focus_entered")
	$Window/HSplitContainer/WorkArea/WorkAreaContainer/CellContent.connect("focus_exited", self, "_on_cellcontent_focus_exited")
	$Window/HSplitContainer/WorkArea/WorkAreaContainer/CellContent.connect("text_changed", self, "_on_cellcontent_text_changed")
	docs_list.connect("item_selected", self, "_on_docs_list_item_selected")
	
	selected_sheet_item = 0
	docs_list.select(selected_sheet_item)
	docs_list.emit_signal("item_selected", selected_sheet_item)
	
	current_focus = get_cell(1,1)
	current_focus.grab_focus()


func _process(delta: float) -> void:
#	($Window/HSplitContainer/WorkArea/WorkAreaContainer/SheetArea.scroll_horizontal = 
#	stepify($Window/HSplitContainer/WorkArea/WorkAreaContainer/SheetArea.scroll_horizontal, 90))
	($Window/HSplitContainer/WorkArea/WorkAreaContainer/SheetArea.scroll_vertical = 
	stepify($Window/HSplitContainer/WorkArea/WorkAreaContainer/SheetArea.scroll_vertical, _get_resolution_size(30)))
	
	$Window/HSplitContainer/WorkArea/WorkAreaContainer/SheetArea/GridArea/Origo.rect_position.y = +$Window/HSplitContainer/WorkArea/WorkAreaContainer/SheetArea.scroll_vertical #+ _get_resolution_size(90)
	$Window/HSplitContainer/WorkArea/WorkAreaContainer/SheetArea/GridArea/Origo.rect_position.x = +$Window/HSplitContainer/WorkArea/WorkAreaContainer/SheetArea.scroll_horizontal # - _get_resolution_size(30)
	$Window/HSplitContainer/WorkArea/WorkAreaContainer/SheetArea/GridArea/Headers.rect_position.y = +$Window/HSplitContainer/WorkArea/WorkAreaContainer/SheetArea.scroll_vertical #+ _get_resolution_size(90)
	$Window/HSplitContainer/WorkArea/WorkAreaContainer/SheetArea/GridArea/IDs.rect_position.x = +$Window/HSplitContainer/WorkArea/WorkAreaContainer/SheetArea.scroll_horizontal # - _get_resolution_size(30)


func _init_cells():
	cells.clear()
	for x in columns:
		cells.append([])
		for y in rows:
			cells[x].append(columns+rows)


onready var data_col_node = $Window/HSplitContainer/WorkArea/WorkAreaContainer/SheetArea/GridArea/Data
onready var headers_node = $Window/HSplitContainer/WorkArea/WorkAreaContainer/SheetArea/GridArea/Headers
onready var ids_node = $Window/HSplitContainer/WorkArea/WorkAreaContainer/SheetArea/GridArea/IDs
onready var origo_node = $Window/HSplitContainer/WorkArea/WorkAreaContainer/SheetArea/GridArea/Origo
func update_ids_and_headers():
	if not _current_doc:
		return
	
	for child in headers_node.get_children():
		child.queue_free()
	for child in ids_node.get_children():
		child.queue_free()
	for child in data_col_node.get_children():
		child.queue_free()
	for child in origo_node.get_children():
		child.queue_free()
	
	## "ORIGO" CELL
	origo_node.rect_size = Vector2.ZERO
	origo_node.rect_min_size = Vector2.ZERO
	var origo = HeaderCell.instance()
	origo.set_script(load("res://addons/gd-sheets/scripts/header_cell.gd"))
	origo.connect("dragging", self, "_on_header_cell_dragging")
	origo.connect("dragging_start", self, "_on_header_cell_dragging_start")
	origo.connect("dragging_stop", self, "_on_header_cell_dragging_stop")
	origo.index = Vector2(0, 0)
	origo.editable = false
	origo.selecting_enabled = false
#	var origo_bg_color := StyleBoxFlat.new()
#	origo_bg_color.set_bg_color(primary_color)
#	origo.set("custom_styles/normal", origo_bg_color)
	origo.modulate = Color(0.9,0.9,0.9,1)
	origo.text = "ID"
	_init_cell(origo)
	origo_node.add_child(origo)
	
	## HEADERS
	headers_node.rect_size = Vector2.ZERO
	headers_node.rect_min_size = Vector2.ZERO
	for i in range(1, columns):
		var cell = HeaderCell.instance()
		cell.set_script(load("res://addons/gd-sheets/scripts/header_cell.gd"))
		cell.connect("dragging", self, "_on_header_cell_dragging")
		cell.connect("dragging_start", self, "_on_header_cell_dragging_start")
		cell.connect("dragging_stop", self, "_on_header_cell_dragging_stop")
		cell.dropdown_icon = dropdown_icon
#		cell.set_dropdown_icon_size(Vector2(_get_resolution_size(30), _get_resolution_size(30)))
#		cell.set_drag_handle_size(Vector2(_get_resolution_size(6), _get_resolution_size(30)))
		cell.index = Vector2(i, 0)
#		var bg_color := StyleBoxFlat.new()
#		bg_color.set_bg_color(primary_color)
#		cell.set("custom_styles/normal", bg_color)
		cell.modulate = Color(0.9,0.9,0.9,1)
		cell.placeholder_text = SheetsUtility.get_column_letter(cell.index.x-1)
		
		if _current_doc and range(_current_doc.data.size()).has(0):
			if range(_current_doc.data[0].size()).has(i):
				cell.text = "%s" % [_current_doc.data[0][i]]
		
		_init_cell(cell)
		headers_node.add_child(cell)
	
	## IDs
	ids_node.rect_size = Vector2.ZERO
	ids_node.rect_min_size = Vector2.ZERO
	for i in range(1, rows):
		var cell := LineEdit.new()
		cell.set_script(load("res://addons/gd-sheets/scripts/cell.gd"))
		cell.index = Vector2(0, i)
#		var bg_color := StyleBoxFlat.new()
#		bg_color.set_bg_color(primary_color)
#		cell.set("custom_styles/normal", bg_color)
		cell.modulate = Color(0.9,0.9,0.9,1)
		if _current_doc and range(_current_doc.data.size()).has(i):
			if range(_current_doc.data[i].size()).has(0):
				cell.text = "%s" % [_current_doc.data[i][0]]
		else:
			cell.placeholder_text = "%s" % [i]
		
		_init_cell(cell)
		cell.parent_column = ids_node
		ids_node.add_child(cell)
	
	## DATA
	data_col_node.rect_size = Vector2.ZERO
	data_col_node.rect_min_size = Vector2.ZERO
	for x in range(1, columns):
		var col := VBoxContainer.new()
		col.set("custom_constants/separation", 0)
		col.rect_min_size = Vector2(0,0)
		for y in range(1, rows):
			var cell = LineEdit.new()
			cell.set_script(load("res://addons/gd-sheets/scripts/cell.gd"))
			cell.index = Vector2(x, y)
			cell.text = ""
			if _current_doc and range(_current_doc.data.size()).has(y):
				if range(_current_doc.data[y].size()).has(x):
					cell.text = "%s" % [_current_doc.data[y][x]]
			
			_init_cell(cell)
			cell.parent_column = col
			col.add_child(cell)
		
		data_col_node.add_child(col)
	
	_setup_neighbours()


func _init_cell(cell : Cell):
	cells[cell.index.x][cell.index.y] = cell
	#cell.size_flags_horizontal = 3
	cell.rect_min_size = Vector2(_get_resolution_size(90), _get_resolution_size(30)) #cell.custom_size
	cell.rect_size = Vector2(_get_resolution_size(90), _get_resolution_size(30)) #cell.custom_size
	cell.connect("text_changed_id", self, "_on_cell_text_changed")
	cell.connect("focus_entered_id", self, "_on_cell_focus_entered")
	cell.connect("focus_exited_id", self, "_on_cell_focus_exited")
	cell.set("custom_constants/minimum_spaces", 10)
	cell.rect_clip_content = true


func _update_sheet(doc):
	_current_doc = doc
	#_init_sheet()
	update_ids_and_headers()


func _setup_neighbours():
	for x in range(0, columns-1):
		for y in range(0, rows-1):
			if x == 0 and y == 0:
				continue
			get_cell(x, y).focus_next = get_cell(x + 1, y).get_path()
			get_cell(x, y).focus_previous = get_cell(x - 1, y).get_path()
			get_cell(x, y).focus_next_enter = get_cell(x, y + 1).get_path()
			get_cell(x, y).focus_previous_enter = get_cell(x, y - 1).get_path()


func write_data():
	var empty_counter = 0
	_current_doc.data.resize(rows)

	_current_doc.data.clear()
	for y in range(0, rows):
		_current_doc.data.append([])
		for x in range(0, columns):
#			if get_cell(x, y).text.empty():
#				_current_doc.data[y].append(get_cell(x, y).placeholder_text)
#			else:
			_current_doc.data[y].append(get_cell(x, y).text)
	
	_current_doc.build_hash_map()
	
	var empty_row_counter = 0
	var empty_col_counter = 0
	var empty_rows := []
	var empty_cols := []
	for y in range(0, rows):
		for x in range(0, columns):
			if x == 0 and y == 0:
				continue
			
			if get_cell(x, y).text == "":
				empty_row_counter += 1
			else:
				break
		if empty_row_counter == columns:
			empty_rows.append(y)
		empty_row_counter = 0

	for x in range(0, columns):
		for y in range(0, rows):
			if get_cell(x, y).text == "":
				empty_col_counter += 1
			else:
				break
		if empty_col_counter == rows:
			empty_cols.append(x)
		empty_col_counter = 0

	empty_rows.invert()
	for i in empty_rows:
		#print(i)
		_current_doc.data.remove(i)
	empty_rows.clear()
#
#	empty_cols.invert()
#	for y in range(0, rows):
#		for i in empty_cols:
#			_current_doc.data[y].remove(i)
#		empty_rows.clear()
	
	#print(_current_doc.data)
	
	ResourceSaver.save(_current_doc.resource_path, _current_doc)


func _update_docs_list():
	var files = []
	var dir = Directory.new()
	if dir.open("res://addons/gd-sheets/documents/") == OK:
		dir.list_dir_begin()

		while true:
			var file = dir.get_next()
			if file == "":
				break
			elif not file.begins_with("."):
				files.append(file)

		dir.list_dir_end()
		
		docs_list.clear()
		for file in files:
			docs_list.add_item(file.get_basename())
	
	else:
		print("An error occurred when trying to access the path: _update_docs_list().")
	
	### Sort alphabetically
	for i in docs_list.get_item_count():
		for j in docs_list.get_item_count():
			if docs_list.get_item_text(i) == docs_list.get_item_text(j):
				continue
			
			if docs_list.get_item_text(i).to_lower() < docs_list.get_item_text(j).to_lower():
				docs_list.move_item(i, j)
				break


func _on_docs_list_item_selected(index):
	#print("Selected item: ", index)
	selected_sheet_item = index
	var file_name = docs_list.get_item_text(index)
	var path = "res://addons/gd-sheets/documents/" + file_name + ".tres"
	_current_doc = load(path)
	
	_update_sheet(_current_doc)
	$Window/HSplitContainer/WorkArea/WorkAreaContainer/CellContent.text = ""

var _old_text = ""
func _on_cell_text_changed(text, cell : LineEdit):
	#var id_header_cell_text = "[" + get_cell(0, cell.index.y).text + "][" + get_cell(cell.index.x, 0).text + "]: "
	$Window/HSplitContainer/WorkArea/WorkAreaContainer/CellContent.text =  text
	
func _on_cell_focus_entered(cell):
	_old_text = cell.text
	#var id_header_cell_text = "[" + get_cell(0, cell.index.y).text + "][" + get_cell(cell.index.x, 0).text + "]: "
	$Window/HSplitContainer/WorkArea/WorkAreaContainer/CellContent.text = get_focus_owner().text
	current_focus = get_focus_owner()
	pass
	
func _on_cell_focus_exited(cell):
	# DATA CELLS
	if cell.index.x > 0 and cell.index.y > 0: 
		var id_cell = get_cell(0, cell.index.y)
		if id_cell.text.empty() and not cell.text.empty():
			var IDs = _get_ids(true)
			id_cell.text = get_unique_name("ID", IDs)
		var header_cell = get_cell(cell.index.x, 0)
		if header_cell.text.empty() and not cell.text.empty():
			var headers = _get_headers(true)
			header_cell.text = get_unique_name("Header", headers)
	
	# ID CELL
	if cell.index.x == 0:
		if cell.text.empty():
			if not row_empty(cell.index.y):
				var IDs = _get_ids(true)
				cell.text = get_unique_name("ID", IDs)
				return
			else:
				cell.placeholder_text = str(cell.index.y)
				return
		else:
			if _is_id_taken(cell):
				warning_message.text = "ID has to be unique."
				$Warning.pop()
				yield(get_tree(), "idle_frame")
				cell.text = _old_text
				cell.grab_focus()
				
				return

	# HEADER CELL
	if cell.index.y == 0:
		if cell.text.empty():
			if not column_empty(cell.index.x):
				var headers = _get_headers(true)
				cell.text = get_unique_name("Header", headers)
				return
			else:
				cell.placeholder_text = SheetsUtility.get_column_letter(cell.index.x - 1)
				return
		else:
			if _is_header_taken(cell):
				warning_message.text = "Header has to be unique."
				$Warning.pop()
				yield(get_tree(), "idle_frame")
				cell.text = _old_text
				cell.grab_focus()
				
				return
	
	write_data()



### Cell Content Field behavior
var old_color : Color = Color.white
func _on_cellcontent_focus_exited():
	current_focus.modulate = old_color
	write_data()
func _on_cellcontent_focus_entered():
	current_focus.modulate = Color(0.8, 1.0, 1.0, 1.0)
func _on_cellcontent_text_changed(text):
	current_focus.text = text


func set_columns(v):
	columns = v
	if _ready_done:
		$Window/HSplitContainer/WorkArea/WorkAreaContainer/SheetArea/GridArea.set_grid_size()
		_init_cells()
		update_ids_and_headers()
func set_rows(v):
	rows = v
	if _ready_done:
		$Window/HSplitContainer/WorkArea/WorkAreaContainer/SheetArea/GridArea.set_grid_size()
		_init_cells()
		update_ids_and_headers()

func get_cell(x : int, y : int) -> LineEdit:
	return cells[x][y]
func get_cellv(index : Vector2) -> LineEdit:
	return cells[index.x][index.y]


func _init_ui():
	$Window/HSplitContainer/FileArea.rect_min_size.x = _get_resolution_size(130)
	$Window/MarginContainer/HBoxContainer/Actions/NewSheetButton.icon = new_icon
	$Window/MarginContainer/HBoxContainer/Actions/DeleteSheetButton.icon = delete_icon
	$Window/MarginContainer/HBoxContainer/Actions/RenameSheetButton.icon = rename_icon
	
	$DeleteSheetPopup.get_ok().text = "Delete"
	$RenamePopup.get_ok().text = "Rename"
	
	$Window/MarginContainer/HBoxContainer/RowCol/Rows.value = rows - 1
	$Window/MarginContainer/HBoxContainer/RowCol/Columns.value = columns - 1
	
	$Window/MarginContainer/HBoxContainer/Zoom/ZoomMinus.rect_min_size.x = _get_resolution_size(24)
	$Window/MarginContainer/HBoxContainer/Zoom/ZoomPlus.rect_min_size.x = _get_resolution_size(24)
	
	$Window/HSplitContainer/WorkArea/WorkAreaContainer/SheetArea/GridArea/ColumnResizeMarker.rect_size.x = _get_resolution_size(1)


func _on_NewSheetButton_pressed() -> void:
	var new_sheet := SheetsDataDocument.new()
	var file_name := get_new_sheet_filename()
	var path := "res://addons/gd-sheets/documents/" + file_name + ".tres"
	ResourceSaver.save(path, new_sheet)
	_update_docs_list()
	docs_list.grab_focus()
	for i in docs_list.get_item_count():
		if docs_list.get_item_text(i) == file_name:
			docs_list.select(i)
			_on_docs_list_item_selected(i)
			break

func _on_RenameSheetButton_pressed() -> void:
	$RenamePopup.popup()
	$RenamePopup/MarginContainer/FileName.text = docs_list.get_item_text(selected_sheet_item)
func _on_RenamePopup_confirmed() -> void:
	rename_sheet($RenamePopup/MarginContainer/FileName.text)
	_update_docs_list()

func _on_DeleteSheetButton_pressed() -> void:
	$DeleteSheetPopup.dialog_text = "Do you want to delete " + docs_list.get_item_text(selected_sheet_item) + "?"
	$DeleteSheetPopup.popup()
func _on_DeleteSheetPopup_confirmed() -> void:
	delete_sheet()
	_update_docs_list()
	if selected_sheet_item == docs_list.get_item_count():
		docs_list.select(selected_sheet_item - 1)
		docs_list.emit_signal("item_selected", selected_sheet_item - 1)
	else:
		docs_list.select(selected_sheet_item)
		docs_list.emit_signal("item_selected", selected_sheet_item)


func get_new_sheet_filename() -> String:
	var numbers := []
	for i in docs_list.get_item_count():
		var item_name : String = docs_list.get_item_text(i)
		if item_name.begins_with("New Sheet ") or item_name == "New Sheet":
			var number = item_name.substr(10)
			if int(number):
				numbers.append(int(number))
			else:
				numbers.append(1)
	numbers.sort()
	
	var counter = ""
	if numbers.size() > 0:
		counter = " " + str(numbers[numbers.size() - 1] + 1)
		
		for i in range(1, numbers[numbers.size()-1] ) :
			if i + 1 != numbers[i]:
				return "New Sheet " + str(i + 1)
		
	return "New Sheet" + str(counter)


func _get_unique_id(id_cell):
	var counter = 1
	var is_unique = false
	while is_unique == false:
		counter += 1
		var new_id := ""
		for y in range(1, rows):
			var comp_cell := get_cell(0, y)
			if id_cell == comp_cell: continue
			if id_cell.text == comp_cell.text:
				new_id = get_unique_name(id_cell.text, _get_ids(true))
			else:
				id_cell.text = new_id
				is_unique = true


func get_unique_name(prefix : String, list : Array) -> String:
	var numbers := []
	for i in list:
		var item_name : String = i
		if item_name.begins_with(prefix + " ") or item_name == prefix:
			var number = item_name.substr(prefix.length() + 1)
			if int(number):
				numbers.append(int(number))
			else:
				numbers.append(1)
	numbers.sort()
	
	var counter = ""
	if numbers.size() > 0:
		if not numbers.has(1):
			return prefix
		
		counter = " " + str(numbers[numbers.size() - 1] + 1)
		
		for i in range(1, numbers[numbers.size()-1] ) :
			if i + 1 != numbers[i]:
				return prefix + " " + str(i + 1)
		
	return prefix + str(counter)


func _is_header_taken(cell):
	return _is_taken(cell, columns, "header")
func _is_id_taken(cell):
	return _is_taken(cell, rows, "id")
func _is_taken(cell, rows_cols, id_or_header):
	for i in range(1, rows_cols):
		var comp_cell
		if id_or_header == "id":
			comp_cell = get_cell(0, i)
		elif id_or_header == "header":
			comp_cell = get_cell(i, 0)
		if cell == comp_cell: continue
		if cell.text == comp_cell.text:
			return true
	return false


func rename_sheet(new_name):
	var dir = Directory.new()
	if dir.open("res://addons/gd-sheets/documents/") == OK:
		dir.rename(docs_list.get_item_text(selected_sheet_item) + ".tres", new_name + ".tres")
	else:
		print("An error occurred when trying to access the path: _rename_sheet.")

func delete_sheet():
	var dir = Directory.new()
	if dir.open("res://addons/gd-sheets/documents/") == OK:
		dir.remove(docs_list.get_item_text(selected_sheet_item) + ".tres")
	else:
		print("An error occurred when trying to access the path: _rename_sheet.")



func _on_Rows_value_changed(value: float) -> void:
	self.rows = int(value + 1)


func _on_Columns_value_changed(value: float) -> void:
	self.columns = int(value + 1)


func _get_resolution_size(size):
	if get_viewport_rect().size.x > 1920:
		return size * 2
	else	:
		return size


func _on_ZoomMinus_pressed() -> void:
	if zoom_level > 50:
		zoom_level -= 25
		$Window/MarginContainer/HBoxContainer/Zoom/MarginContainer/HBoxContainer/ZoomValue.text = str(zoom_level)
		$Window/HSplitContainer/WorkArea/WorkAreaContainer/SheetArea/Columns.rect_scale -= Vector2(0.25, 0.25)
		$Window/HSplitContainer/WorkArea/WorkAreaContainer/SheetArea/Columns.rect_size *= Vector2(0.75, 0.75)


func _on_ZoomPlus_pressed() -> void:
	if zoom_level < 150:
			zoom_level += 25
			$Window/MarginContainer/HBoxContainer/Zoom/MarginContainer/HBoxContainer/ZoomValue.text = str(zoom_level)
			$Window/HSplitContainer/WorkArea/WorkAreaContainer/SheetArea/Columns.rect_scale += Vector2(0.25, 0.25)
			$Window/HSplitContainer/WorkArea/WorkAreaContainer/SheetArea/Columns.rect_size *= Vector2(1.25, 1.25)
		

var _start_pos = 0
func _on_header_cell_dragging_start(cell : LineEdit):
	#print("Start Draggin")
	cell.selecting_enabled = false
	cell.editable = false
	$Window/HSplitContainer/WorkArea/WorkAreaContainer/SheetArea/GridArea/ColumnResizeMarker.rect_size.x = _get_resolution_size(1)
	$Window/HSplitContainer/WorkArea/WorkAreaContainer/SheetArea/GridArea/ColumnResizeMarker.visible = true
	_start_pos = _mouse_position.x
func _on_header_cell_dragging(cell : LineEdit):
	if _mouse_position.x - _start_pos > -cell.rect_size.x:
		$Window/HSplitContainer/WorkArea/WorkAreaContainer/SheetArea/GridArea/ColumnResizeMarker.rect_global_position.x = _mouse_position.x
func _on_header_cell_dragging_stop(cell : LineEdit):
	#print("Stop Sragging")
	$Window/HSplitContainer/WorkArea/WorkAreaContainer/SheetArea/GridArea/ColumnResizeMarker.visible = false
	var resize_size = _mouse_position.x - _start_pos
	
	# Have to reset the min size for it not to interfer with the rect_size change.
	cell.rect_min_size.x = 0
	cell.rect_size.x += resize_size
	cell.rect_min_size.x = cell.rect_size.x
	cell.custom_size.x += resize_size
	
	for i in range(1, rows):
		cells[cell.index.x][i].rect_min_size.x = 0
		cells[cell.index.x][i].rect_size.x = cell.rect_size.x
		cells[cell.index.x][i].rect_min_size.x = cell.rect_size.x
		cells[cell.index.x][i].custom_size.x = cell.custom_size.x
		if cells[cell.index.x][i].get("parent_column"):
			cells[cell.index.x][i].parent_column.rect_min_size.x = 0
			cells[cell.index.x][i].parent_column.rect_size.x = cell.rect_size.x
			cells[cell.index.x][i].parent_column.rect_min_size.x = cell.rect_size.x

	cell.selecting_enabled = true
	cell.editable = true


func _gui_input(event: InputEvent) -> void:
	pass


func _input(event):
	if event is InputEventMouseMotion:
		_mouse_position = event.position

# Get all objects in the ID list. If text=true only return the text label as a String
# othwewise return the whole cell objects (LineEdit)
func _get_ids(only_text = false):
	var IDs = []
	for y in range(1, rows):
		if only_text:
			IDs.append(get_cell(0, y).text)
		else:
			IDs.append(get_cell(0, y))
	return IDs
func _get_headers(only_text = false):
	var headers = []
	for x in range(1, columns):
		if only_text:
			headers.append(get_cell(x, 0).text)
		else:
			headers.append(get_cell(x, 0))
	return headers


func row_empty(row) -> bool:
	for x in range(1, columns):
		if not get_cell(x, row).text.empty():
			return false
	return true

func column_empty(column) -> bool:
	for y in range(1, rows):
		if not get_cell(column, y).text.empty():
			return false
	return true
