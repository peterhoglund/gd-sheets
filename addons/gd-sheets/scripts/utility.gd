class_name GDSUtil


static func get_unique_name(prefix : String, list : Array) -> String:
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


static func resolution_size(size):
	if OS.window_size.x > 1080:
		return size * 2
	else	:
		return size
