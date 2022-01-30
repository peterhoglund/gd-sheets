class_name GDSheets


#GDSheets.sheet("Default")["Long Sword"]["Name"]
static func sheet(sheet_name : String) -> Dictionary:
	assert(load("res://addons/gd-sheets/documents/" + sheet_name + ".tres"), "[GodotSheets] No sheet called '" + sheet_name + "'.")
	var sheet = load("res://addons/gd-sheets/documents/" + sheet_name + ".tres")
	return sheet.hash_map

