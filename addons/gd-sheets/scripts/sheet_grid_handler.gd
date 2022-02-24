extends Reference 
class_name SheetGridHandler

const data_cell = preload("res://addons/gd-sheets/scenes/Cell.tscn")
const header_cell = preload("res://addons/gd-sheets/scenes/HeaderCell.tscn")
const id_cell = preload("res://addons/gd-sheets/scenes/IDCell.tscn")
const origo_cell = preload("res://addons/gd-sheets/scenes/OrigoCell.tscn")
#const grid_area = preload("res://addons/gd-sheets/scenes/GridArea.tscn")

var cells : Array
var data_handler : SheetDataHandler
var sheet_doc : SheetsDataDocument setget set_sheet_doc
var undo_redo : UndoRedo
var sheet
var edit_line_vertical : ColorRect
var edit_line_horizontal : ColorRect
var select_block : ColorRect
var cell_content_ref : LineEdit

### Default number of cols/rows are set from data_document.gd
var columns setget set_columns
var rows setget set_rows

var interface_scale : float

var selected_cell : Cell
var _old_cell_text := ""
var _drag_distance := 0.0
var _closest_cell : Cell


signal warning_sent
signal cell_focus_enabled
signal cell_text_changed
#signal column_moved
#signal row_moved
signal sheet_edited


func _init(sheet_doc : SheetsDataDocument) :
	data_handler = SheetDataHandler.new()
	data_handler.sheet_doc = sheet_doc

	if sheet_doc:
		self.sheet_doc = sheet_doc
		self.columns = sheet_doc.columns
		self.rows = sheet_doc.rows



################################################
##              CREATE SHEET CELLS            ##
################################################

func get_sheet(sheet_doc) -> Control:
	cells.clear()
	
	if sheet_doc:
		self.sheet_doc = sheet_doc
		self.columns = sheet_doc.columns
		self.rows = sheet_doc.rows
	
	var sheet : SheetGridContainer = _create_sheet_container()
	
	#grid_area.children[0] = Data
	#grid_area.children[1] = IDs
	#grid_area.children[2] = Headers
	#grid_area.children[3] = Origo
	#grid_area.children[4] = Columns Resize Marker
	#grid_area.children[5] = Row Resize Marker
	for x in columns:
		cells.append([])
		var data_column : VBoxContainer = _get_data_column()
		for y in rows:
			var cell : Cell
			
			## ORIGO
			if x == 0 and y == 0:
				cell = origo_cell.instance()
				cell.index = Vector2(x, y)
				cell.name = "Origo %s, %s" % [x, y]
				cell.modulate = Color(0.9,0.9,0.9,1)
				_init_cell(cell)
				sheet.children[3].add_child(cell)
			
			## HEADERS
			if x > 0 and y == 0:
				cell = header_cell.instance()
				cell.index = Vector2(x, y)
				cell.name = "Header Cell %s, %s" % [x, y]
				cell.modulate = Color(0.9,0.9,0.9,1)
				cell.placeholder_text = GDSUtil.get_column_letter(cell.index.x-1)
				_init_cell(cell)
				sheet.children[2].add_child(cell)
			
			## IDS
			if x == 0 and y > 0:
				cell = id_cell.instance()
				cell.index = Vector2(x, y)
				cell.name = "ID Cell %s, %s" % [x, y]
				cell.modulate = Color(0.9,0.9,0.9,1)
				cell.placeholder_text = "%s" % [y]
				_init_cell(cell)
				sheet.children[1].add_child(cell)
			
			## DATA
			if x > 0 and y > 0:
				cell = data_cell.instance()
				cell.index = Vector2(x, y)
				cell.name = "Data Cell %s, %s" % [x, y]
				_init_cell(cell)
				data_column.add_child(cell)
			
			cells[x].append(cell)
		
		if x > 0:
			sheet.children[0].add_child(data_column)
	
	sheet.set_grid_size()
	
	return sheet


func _init_cell(cell : Cell):
	cell.undo_redo = undo_redo
	cell.interface_scale = interface_scale
	cell.rect_min_size = Vector2(90, 30) * interface_scale
	cell.rect_size = Vector2(90, 30) * interface_scale
	cell.rect_clip_content = true
	#cell.size_flags_horizontal = 3
	cell.connect("text_changed_id", self, "_on_cell_text_changed")
	cell.connect("focus_entered_id", self, "_on_cell_focus_entered")
	cell.connect("focus_exited_id", self, "_on_cell_focus_exited")
	cell.connect("editing_completed", self, "_on_editing_completed")
	
	if cell is CellHeader or cell is CellID or cell is CellOrigo:
		cell.connect("resizing_started", self, "_on_cell_resizing_started")
		cell.connect("resizing_stopped", self, "_on_cell_resizing_stopped")
		cell.connect("resizing", self, "_on_cell_resizing")
	if cell is CellHeader or cell is CellID:
		cell.connect("moving_started", self, "_on_cell_moving_started")
		cell.connect("moving_stopped", self, "_on_cell_moving_stopped")
		cell.connect("moving", self, "_on_cell_moving")
		cell.connect("edit_menu_index_pressed_id", self, "_on_cell_edit_menu_index_pressed")

#	cell.set("custom_constants/minimum_spaces", 6)


func _create_sheet_container() -> SheetGridContainer:
	sheet = Control.new()
	sheet.name = "GridArea"
	var data_container = HBoxContainer.new()
	data_container.name = "Data"
	data_container.set("custom_constants/separation", 0)
	sheet.add_child(data_container)
	var ids_container = VBoxContainer.new()
	ids_container.name = "IDs"
	ids_container.set("custom_constants/separation", 0)
	sheet.add_child(ids_container)
	var headers_container = HBoxContainer.new()
	headers_container.name = "Headers"
	headers_container.set("custom_constants/separation", 0)
	sheet.add_child(headers_container)
	var origo_container = Control.new()
	origo_container.name = "Origo"
	sheet.add_child(origo_container)
	
	### Resize indicator lines
	edit_line_vertical = ColorRect.new()
	edit_line_vertical.color = Color("#689ce8")
	edit_line_vertical.rect_min_size = Vector2(1 * interface_scale, 0)
	edit_line_vertical.rect_size.x = edit_line_vertical.rect_min_size.x
	edit_line_vertical.rect_size.y = sheet.rect_size.y
	edit_line_vertical.visible = false
	sheet.add_child(edit_line_vertical)
	edit_line_horizontal = ColorRect.new()
	edit_line_horizontal.color = Color("#689ce8")
	edit_line_horizontal.rect_min_size = Vector2(0, 1 * interface_scale)
	edit_line_horizontal.rect_size.y = edit_line_horizontal.rect_min_size.y
	edit_line_horizontal.rect_size.x = sheet.rect_size.x
	edit_line_horizontal.visible = false
	sheet.add_child(edit_line_horizontal)
	
	### Row and Columns selector blocks
	select_block = ColorRect.new()
	select_block.color = Color("#689ce8")
	select_block.color.a = 0.06
	select_block.visible = false
	select_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.add_child(select_block)
	
	sheet.set_script(load("res://addons/gd-sheets/scripts/grid_area.gd"))
	
	return sheet


func _get_data_column() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.set("custom_constants/separation", 0)
	col.rect_min_size = Vector2(0,0)
	return col


func setup_neighbours():
	for x in range(0, columns):
		for y in range(0, rows):
			if x == 0 and y == 0:
				continue
			get_cell(x, y).focus_neighbour_top = get_cell(x, (y - 1) % rows).get_path()
			get_cell(x, y).focus_neighbour_right = get_cell((x + 1) % columns, y).get_path()
			get_cell(x, y).focus_neighbour_bottom = get_cell(x, (y + 1) % rows).get_path()
			get_cell(x, y).focus_neighbour_left = get_cell((x + -1) % columns, y).get_path()
			
			get_cell(x, y).focus_next = get_cell((x + 1) % columns, y).get_path()
			get_cell(x, y).focus_previous = get_cell((x - 1) % columns, y).get_path()


func update_data():
	data_handler.set_cells_data(cells)


func clear_sheet():
	cells.clear()
	return Control.new()


func get_cell(x : int, y : int) -> Cell:
	return cells[x][y]



################################################
##               EDIT CELL TEXT               ##
################################################

func _on_cell_focus_entered(cell : Cell):
	selected_cell = cell
	_old_cell_text = cell.text
	
	_set_select_block(cell)
	
	emit_signal("cell_focus_enabled", cell.text)


func _on_cell_text_changed(text, cell : Cell):
	emit_signal("cell_text_changed", text)


func _on_editing_completed(cell : Cell):
	# write_cell_data and autofill_ids_and_headers need to come in this order
	# or the data array will not be populated correctly (cell data has to be set before header/id)
	data_handler.write_cell_data(cell)
	_autofill_ids_and_headers(cell)
	selected_cell = null


func _on_cell_focus_exited(cell : Cell):
	if not cell.popup_active == true:
		select_block.visible = false


## Cell content ref signals are connected from sheets_main
## It's a bit weird but it works and was the quickest solution :/
func _on_cell_content_ref_focus_entered():
	if selected_cell:
		selected_cell.make_semi_selected()


func _on_cell_content_ref_text_changed(text):
	if selected_cell:
		selected_cell.text = text


func _on_cell_content_ref_text_entered(text):
	if selected_cell:
		selected_cell.enter_text()
		_on_editing_completed(selected_cell)


################################################
##                 RESIZE CELLS               ##
################################################


func _on_cell_resizing_started(cell : Cell, mouse_position : Vector2):
	if cell is CellHeader or cell is CellOrigo:
		_drag_distance = mouse_position.x
		edit_line_vertical.visible = true
		edit_line_vertical.rect_global_position.x = mouse_position.x
	
	elif cell is CellID:
		_drag_distance = mouse_position.y
		edit_line_horizontal.visible = true
		edit_line_horizontal.rect_global_position.y = mouse_position.y


func _on_cell_resizing(cell : Cell, mouse_position : Vector2):
	if cell is CellHeader or cell is CellOrigo:
		edit_line_vertical.rect_global_position.x = mouse_position.x
	
	elif cell is CellID:
		edit_line_horizontal.rect_global_position.y = mouse_position.y


func _on_cell_resizing_stopped(cell : Cell, mouse_position : Vector2):
	var size_delta = Vector2.ZERO
	if cell is CellHeader or cell is CellOrigo:
		_drag_distance = mouse_position.x - _drag_distance
		size_delta.x = _drag_distance
		edit_line_vertical.visible = false
	
	elif cell is CellID:
		_drag_distance = mouse_position.y - _drag_distance
		size_delta.y = _drag_distance
		edit_line_horizontal.visible = false
	
	if cell is CellHeader or cell is CellOrigo:
		var size : float = cell.rect_size.x + size_delta.x
		_resize_column(cell, size)
		data_handler.store_header_size(cell, size)
	
	if cell is CellID:
		var size : float = cell.rect_size.y + size_delta.y
		_resize_row(cell, size)
		data_handler.store_id_size(cell, size)
	
	_set_select_block(cell)


func _resize_column(cell : Cell, size : float):
	for i in cells[cell.index.x].size():
		cells[cell.index.x][i].rect_min_size.x = 0
		cells[cell.index.x][i].rect_size.x = size
		cells[cell.index.x][i].rect_min_size.x = size


func _resize_row(cell : Cell, size : float):
	for i in cells.size():
		cells[i][cell.index.y].rect_min_size.y = 0
		cells[i][cell.index.y].rect_size.y = size
		cells[i][cell.index.y].rect_min_size.y = size


func resize_headers_and_ids():
	for x in columns:
		if sheet_doc.header_sizes[x]:
			_resize_column(get_cell(x, 0), sheet_doc.header_sizes[x])
	for y in rows:
		if sheet_doc.id_sizes[y]:
			_resize_row(get_cell(0, y), sheet_doc.id_sizes[y])



################################################
##                 MOVE CELLS                 ##
################################################

func _on_cell_moving_started(cell : Cell, position : Vector2):
	if cell is CellHeader:
		_drag_distance = position.x
		edit_line_vertical.visible = true
		edit_line_vertical.rect_global_position.x = cell.rect_global_position.x
	
	if cell is CellID:
		_drag_distance = position.y
		edit_line_horizontal.visible = true
		edit_line_horizontal.rect_global_position.y = cell.rect_global_position.y + cell.rect_size.y


func _on_cell_moving(cell : Cell, position : Vector2):
	var line_pos := 0
	if cell is CellHeader:
		for i in range(0, cells.size()):
			if (position.x < cells[i][0].rect_global_position.x + cells[i][0].rect_size.x and
				position.x > cells[i-1][0].rect_global_position.x + cells[i-1][0].rect_size.x):
				_closest_cell = cells[i][0]
				if cells[i][0].index.x <= cell.index.x:
					line_pos = cells[i][0].rect_global_position.x
				elif cells[i][0].index.x > cell.index.x:
					line_pos = cells[i][0].rect_global_position.x + cells[i][0].rect_size.x
		edit_line_vertical.rect_global_position.x = line_pos
		
		select_block.rect_global_position.x = position.x - cell.rect_size.x * 0.5
	
	if cell is CellID:
		for i in range(0, cells[0].size()):
			if (position.y < cells[0][i].rect_global_position.y + cells[0][i].rect_size.y and
				position.y > cells[0][i-1].rect_global_position.y + cells[0][i-1].rect_size.y):
				_closest_cell = cells[0][i]
				if cells[0][i].index.y < cell.index.y:
					line_pos = cells[0][i].rect_global_position.y
				elif cells[0][i].index.y >= cell.index.y:
					line_pos = cells[0][i].rect_global_position.y + cells[0][i].rect_size.y
		
		edit_line_horizontal.rect_global_position.y = line_pos
		
		select_block.rect_global_position.y = position.y - cell.rect_size.y * 0.5


func _on_cell_moving_stopped(cell : Cell, position : Vector2):
	if is_instance_valid(_closest_cell):
		if cell is CellHeader:
			data_handler.move_column(cell, _closest_cell.index.x)
#			emit_signal("column_moved")
			emit_signal("sheet_edited")

		if cell is CellID:
			data_handler.move_row(cell, _closest_cell.index.y)
#			emit_signal("row_moved")
			emit_signal("sheet_edited")

	edit_line_vertical.visible = false
	edit_line_horizontal.visible = false



################################################
##             INSERT / DELETE CELL           ##
################################################

func _on_cell_edit_menu_index_pressed(cell : Cell, index : int):
	if cell is CellHeader:
		match index:
			0:
				insert_column(cell.index.x)
			1:
				insert_column(cell.index.x + 1)
			3:
				_remove_column(cell.index.x)
				
	if cell is CellID:
		match index:
			0:
				insert_row(cell.index.y)
			1:
				insert_row(cell.index.y + 1)
			3:
				_remove_row(cell.index.y)


func insert_column(position):
	data_handler.insert_column(position)
	emit_signal("sheet_edited")


func insert_row(position):
	data_handler.insert_row(position)
	emit_signal("sheet_edited")


func _remove_column(position):
	data_handler.remove_column(position)
	emit_signal("sheet_edited")


func _remove_row(position):
	data_handler.remove_row(position)
	emit_signal("sheet_edited")



###################################################

func _autofill_ids_and_headers(cell):
	# DATA CELLS
	if cell.index.x > 0 and cell.index.y > 0: 
		var id_cell = get_cell(0, cell.index.y)
		if id_cell.text.empty() and not cell.text.empty():
			var IDs = _get_ids(true)
			id_cell.text = GDSUtil.get_unique_name("ID", IDs)
			data_handler.write_cell_data(id_cell)
		var header_cell = get_cell(cell.index.x, 0)
		if header_cell.text.empty() and not cell.text.empty():
			var headers = _get_headers(true)
			header_cell.text = GDSUtil.get_unique_name("Header", headers)
			data_handler.write_cell_data(header_cell)
	
	# ID CELL
	if cell.index.x == 0:
		if cell.text.empty():
			if not _row_empty(cell.index.y):
				var IDs = _get_ids(true)
				cell.text = GDSUtil.get_unique_name("ID", IDs)
				emit_signal("cell_text_changed", cell.text)
				return
			else:
				cell.placeholder_text = str(cell.index.y)
				return
		else:
			if _is_id_taken(cell):
				emit_signal("warning_sent", "ID has to be unique.")
#				warning_message.text = "ID has to be unique."
#				$Warning.pop()
#				yield(get_tree(), "idle_frame")
				cell.text = _old_cell_text
				cell.call_deferred("grab_focus")
				
				return

	# HEADER CELL
	if cell.index.y == 0:
		if cell.text.empty():
			if not _column_empty(cell.index.x):
				var headers = _get_headers(true)
				cell.text = GDSUtil.get_unique_name("Header", headers)
				emit_signal("cell_text_changed", cell.text)
				return
			else:
				cell.placeholder_text = GDSUtil.get_column_letter(cell.index.x - 1)
				return
		else:
			if _is_header_taken(cell):
				emit_signal("warning_sent", "Header has to be unique.")
#				$Warning.pop()
#				yield(get_tree(), "idle_frame")
				cell.text = _old_cell_text
				cell.call_deferred("grab_focus")
				
				return


func _set_select_block(cell):
	if cell is CellHeader:
		select_block.rect_global_position = cell.rect_global_position
		select_block.rect_min_size = Vector2.ZERO
		select_block.rect_size.x = cell.rect_min_size.x
		select_block.rect_size.y = sheet.rect_size.y
		select_block.visible = true
	if cell is CellID:
		select_block.rect_global_position = cell.rect_global_position
		select_block.rect_min_size = Vector2.ZERO
		select_block.rect_size.y = cell.rect_min_size.y
		select_block.rect_size.x = sheet.rect_size.x
		select_block.visible = true



################################################
##               SETTERS/GETTERS              ##
################################################

func set_sheet_doc(v):
	sheet_doc = v
	data_handler.sheet_doc = sheet_doc


func set_columns(v):
	columns = v


func set_rows(v):
	rows = v



################################################
##              HELPER FUNCTIONS              ##
################################################

### Helper functions for autofilling IDs and Headers.
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

func _row_empty(row) -> bool:
	for x in range(1, columns):
		if not get_cell(x, row).text.empty():
			return false
	return true

func _column_empty(column) -> bool:
	for y in range(1, rows):
		if not get_cell(column, y).text.empty():
			return false
	return true
