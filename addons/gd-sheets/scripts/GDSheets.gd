class_name GDSheets


#GDSheets.sheet("New Sheet")["Long Sword"]["Name"]
static func sheet(sheet_name : String):
	var sheet = load("res://addons/gd-sheets/documents/" + sheet_name + ".tres")
	assert(sheet, "[Godot Sheets] Can't find sheet '" + sheet_name + "'.")
	return sheet.hash_map
