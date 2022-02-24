extends Reference
class_name SheetDataHandler


var sheet_doc : SheetsDataDocument

func _init():
	pass


func set_cells_data(cells : Array):
	for x in sheet_doc.columns:
		for y in sheet_doc.rows:
			if range(sheet_doc.data.size()).has(x):
				if range(sheet_doc.data[x].size()).has(y):
					if sheet_doc.data[x][y] == null:
						cells[x][y].text = ""
					else:
						cells[x][y].text = sheet_doc.data[x][y]
					
					if cells[x][y].has_method("get_align"):
						cells[x][y].text_field.align = cells[x][y].get_align(sheet_doc.data[x][y])


func write_cell_data(cell : Cell):
	
	if cell.index.x > sheet_doc.data.size() - 1:
		for x in range(sheet_doc.data.size(), cell.index.x + 1):
			var rows_array : Array
			for y in cell.index.y + 1:
				rows_array.append("")
			
			sheet_doc.data.append(rows_array)
#		for y in cell.index.y + 1:
#			sheet_doc.data[cell.index.x].append("")
	
	elif cell.index.y > sheet_doc.data[cell.index.x].size() - 1:
		for y in range(sheet_doc.data[cell.index.x].size(), cell.index.y + 1):
			sheet_doc.data[cell.index.x].append("")

	sheet_doc.data[cell.index.x][cell.index.y] = cell.text
	
	sheet_doc.is_dirty = true
	ResourceSaver.save(sheet_doc.resource_path, sheet_doc)


func build_hash_map(cast_values = false):
	if sheet_doc.is_dirty == false : return
	
	sheet_doc.hash_map.clear()
	
	for y in range(1, sheet_doc.data[0].size()):
		if sheet_doc.data[0][y].empty() : continue
		var inner : Dictionary
		for x in range(1, sheet_doc.data.size()):
			if range(sheet_doc.data.size()).has(x) and range(sheet_doc.data[x].size()).has(y):
				if sheet_doc.data[x][y].empty():
					inner[sheet_doc.data[x][0]] = ""
				if cast_values:
					inner[sheet_doc.data[x][0]] = _cast_value(sheet_doc.data[x][y])
				else:
					inner[sheet_doc.data[x][0]] = sheet_doc.data[x][y]
		
		sheet_doc.hash_map[sheet_doc.data[0][y]] = inner
	
	sheet_doc.is_dirty = false
	
	print("[Godot Sheets] Database built: " , str(sheet_doc.resource_path.get_file()).trim_suffix(".tres") )


func set_columns(columns):
	sheet_doc.columns = columns
	sheet_doc.header_sizes.resize(columns)
	ResourceSaver.save(sheet_doc.resource_path, sheet_doc)


func set_rows(rows):
	sheet_doc.rows = rows
	sheet_doc.id_sizes.resize(rows)
	ResourceSaver.save(sheet_doc.resource_path, sheet_doc)


func store_header_size(cell : Cell, size : float):
	sheet_doc.header_sizes[cell.index.x] = size
	ResourceSaver.save(sheet_doc.resource_path, sheet_doc)


func store_id_size(cell : Cell, size : float):
	sheet_doc.id_sizes[cell.index.y] = size
	ResourceSaver.save(sheet_doc.resource_path, sheet_doc)


func move_column(cell : Cell, to_index):
	var from_index = cell.index.x
	
	# moving to outside data range, fill gap with empty cells/data
	if to_index > sheet_doc.data.size() - 1 :
		for x in range(sheet_doc.data.size(), to_index + 1):
			sheet_doc.data.append([])
			sheet_doc.data[cell.index.x].append("")
	
	# moving within data range
	if from_index < sheet_doc.data.size() :
		var data_to_move = sheet_doc.data.pop_at(from_index)
		sheet_doc.data.insert(to_index, data_to_move)
	
	# moving from outside to outside data range
	else:
		remove_column(from_index)
		insert_column(to_index)
	
	var header_size_to_move = sheet_doc.header_sizes.pop_at(from_index)
	sheet_doc.header_sizes.insert(to_index, header_size_to_move)
	
	ResourceSaver.save(sheet_doc.resource_path, sheet_doc)


func move_row(cell : Cell, to_index):
	var from_index = cell.index.y
	
	for x in sheet_doc.data.size() :
		# moving to outside data range, fill gap with empty cells/data
		if to_index > sheet_doc.data[x].size() - 1:
			for y in range(sheet_doc.data[x].size(), to_index + 1):
				sheet_doc.data[x].append("")
		
		# moving withing data range
		if sheet_doc.data[x].size() > from_index:
			var data_to_move = sheet_doc.data[x].pop_at(from_index)
			sheet_doc.data[x].insert(to_index, data_to_move)
		
		# moving from outside to outside data range
		else:
			#remove cell
			if sheet_doc.data[x].size() > from_index:
				sheet_doc.data[x].remove(from_index)
			#insert cell
			if sheet_doc.data[x].size() > to_index:
				sheet_doc.data[x].insert(to_index, "")
	
	var id_size_to_move = sheet_doc.id_sizes.pop_at(from_index)
	sheet_doc.id_sizes.insert(to_index, id_size_to_move)
	
	ResourceSaver.save(sheet_doc.resource_path, sheet_doc)


func remove_column(position):
	if sheet_doc.data.size() > position:
		sheet_doc.data.remove(position)
	
	sheet_doc.columns -= 1
	sheet_doc.header_sizes.remove(position)
	
	ResourceSaver.save(sheet_doc.resource_path, sheet_doc)


func remove_row(position):
	for x in sheet_doc.data.size():
		if sheet_doc.data[x].size() > position:
			sheet_doc.data[x].remove(position)
	
	sheet_doc.rows -= 1
	sheet_doc.id_sizes.remove(position)
	
	ResourceSaver.save(sheet_doc.resource_path, sheet_doc)


func insert_column(position):
	sheet_doc.data.insert(position, [])
	sheet_doc.columns += 1
	
	sheet_doc.header_sizes.insert(position, null)
	
	ResourceSaver.save(sheet_doc.resource_path, sheet_doc)


func insert_row(position):
	for x in sheet_doc.data.size():
		if sheet_doc.data[x].size() > position:
			sheet_doc.data[x].insert(position, "")
	sheet_doc.rows += 1
	
	sheet_doc.id_sizes.insert(position, null)
	
	ResourceSaver.save(sheet_doc.resource_path, sheet_doc)


func _cast_value(value):
	var regex = RegEx.new()
#	regex.compile("^[0-9]*$")
#	if regex.search(value) : 
#		return int(value)
	
	regex.compile("^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$")
	if regex.search(value) : 
		return float(value)
	
	return str(value)

