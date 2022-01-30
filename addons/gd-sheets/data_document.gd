tool
extends Resource
class_name SheetsDataDocument

# Data = [[Origo, Header1, Header2...][ID1, Data1, Data2...]...]
export var data := []
export var hash_map : Dictionary

func build_hash_map():
	hash_map.clear()
	for y in range(1, data.size()):
		if data[y][0].empty(): continue
		var inner : Dictionary
		for x in range(1, data[y].size()):
			if data[y][x].empty() : continue
			inner[data[0][x]] = data[y][x]
		
		hash_map[data[y][0]] = inner
