extends Reference
class_name SheetDocumentsHandler

const docs_path = "res://addons/gd-sheets/documents/"

var docs_list : ItemList
var folder_item = Label.new()
var docs_item = LineEdit.new()

var active_document_index = 0 setget set_active_document_index

var root_icon : Texture
var sheets_icon : Texture
var folder_icon : Texture

func _init(docs_list_node : ItemList):
	docs_list = docs_list_node
	docs_list.select(active_document_index)


func get_documents_list():
	var files = []
	var dir = Directory.new()
	if dir.open(docs_path) == OK:
		dir.list_dir_begin()

		while true:
			var file = dir.get_next()
			if file == "":
				break
			elif not file.begins_with("."):
				files.append(file)

		dir.list_dir_end()
		
		return files
		
		docs_list.clear()
		for file in files:
			docs_list.add_item(file.get_basename())
	
	else:
		print("An error occurred when trying to access the path: get_documents_list().")
	return null


func update_documents_list():
	var files = []
	var dir = Directory.new()
	if dir.open(docs_path) == OK:
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
		print("An error occurred when trying to access the path: update_documents_list().")
	
	### Sort alphabetically
	for i in docs_list.get_item_count():
		for j in docs_list.get_item_count():
			if docs_list.get_item_text(i) == docs_list.get_item_text(j):
				continue
			
			if docs_list.get_item_text(i).to_lower() < docs_list.get_item_text(j).to_lower():
				docs_list.move_item(i, j)
				break


func get_selected_item(index : int) -> Resource :
	var file_name = docs_list.get_item_text(index)
	var path = "res://addons/gd-sheets/documents/" + file_name + ".tres"
	var sheet = ResourceLoader.load(path, "", true)
	if not sheet:
		print("[Godot Sheet] Can't find sheet ", file_name, " at ", path)
	return sheet


func rename_document(new_name):
	if new_name == docs_list.get_item_text(active_document_index) : return
	var dir = Directory.new()
	if dir.open("res://addons/gd-sheets/documents/") == OK:
		new_name = GDSUtil.get_unique_name(new_name, _get_docs_list_items())
		dir.rename(docs_list.get_item_text(active_document_index) + ".tres", new_name + ".tres")
	else:
		print("An error occurred when trying to access the path: rename_document.")


func delete_document():
	var dir = Directory.new()
	if dir.open("res://addons/gd-sheets/documents/") == OK:
		if dir.remove(docs_list.get_item_text(active_document_index) + ".tres") != OK:
			print("An error occurred when trying remove the file: " + docs_list.get_item_text(active_document_index) + ".tres")
	else:
		print("An error occurred when trying to access the path: delete_document.")


func set_active_document_index(v):
	active_document_index = v


func _get_new_sheet_filename() -> String:
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
		
		for i in range(0, numbers[numbers.size()-1] ) :
			if i + 1 != numbers[i]:
				var number = str(" ", i + 1) if not i + 1 == 1 else ""
				return "New Sheet" + number
		
	return "New Sheet" + str(counter)


func new_sheet():
	var new_sheet := SheetsDataDocument.new()
	var file_name := _get_new_sheet_filename()
	var path := "res://addons/gd-sheets/documents/" + file_name + ".tres"
	ResourceSaver.save(path, new_sheet)
	update_documents_list()
	docs_list.grab_focus()
	for i in docs_list.get_item_count():
		if docs_list.get_item_text(i) == file_name:
			docs_list.select(i)
			active_document_index = i
			break


func _get_docs_list_items() -> Array:
	var docs_list_items : Array
	for i in docs_list.get_item_count():
		docs_list_items.append(docs_list.get_item_text(i))
	
	return docs_list_items
