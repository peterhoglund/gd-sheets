class_name SheetsUtility

static func get_column_letter(index : int, character_list = "ABCDEFGHIJKLMNOPQRSTUVWXYZ" ) -> String:
	
	var letters := ""
	var i = 0
	var rem = index % character_list.length()
#	for _i in (index / character_list.size()):
#		if _i == index / alphabet.size():
#			letters += alphabet[rem]
#		else:
#			letters += alphabet[_i]
#		i += 1
	return character_list[index % character_list.length()]
