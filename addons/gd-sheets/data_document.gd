tool
extends Resource
class_name SheetsDataDocument

# Data [[Origo, ID1, ID2...], [Header1, Data, Data...], [Header2, Data, Data...], ...]
export var data : Array
export var hash_map : Dictionary

export var header_sizes : Array
export var id_sizes : Array

export var columns : int = 11
export var rows : int = 21

export var is_dirty = false


func _init() -> void:
	header_sizes.resize(columns)
	id_sizes.resize(rows)


func clear_all_data():
	data.clear()
	header_sizes.clear()
	id_sizes.clear()


#var keys
#var current
#var end
#func should_continue():
#	return (current < end)
#
#func _iter_init(arg):
#	keys = hash_map.keys()
#	end = hash_map.size()
#	current = 0
#	return should_continue()
#
#func _iter_next(arg):
#	current += 1
#	return should_continue()
#
#func _iter_get(arg):
#	return hash_map[keys[current]].values()
