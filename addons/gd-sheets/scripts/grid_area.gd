tool
extends Container

# _______________
# |      |      |
# |  3   |  2   |
# |      |      |
# ---------------
# |      |      |
# |  1   |  0   |
# |______|______|

var children
func _ready() -> void:
	yield(get_tree(), "idle_frame")
	
	set_grid_size()
	_connect_signals()


func set_grid_size():
	children = get_children()
	_reset_sizes()
	
	children[3].rect_position = Vector2.ZERO
	
	var pos = max(children[3].rect_size.x, children[1].rect_size.x)
	children[2].rect_position = Vector2(pos, 0)
	
	pos = max(children[3].rect_size.y, children[2].rect_size.y)
	children[1].rect_position = Vector2(0, pos)
	
	var pos_x = max(children[3].rect_size.x, children[1].rect_size.x)
	var pos_y = max(children[3].rect_size.y, children[2].rect_size.y)
	children[0].rect_position = Vector2(pos_x, pos_y)
	
	rect_min_size.x = max(children[3].rect_size.x, children[1].rect_size.x) + max(children[2].rect_size.x, children[0].rect_size.x) + 180
	rect_min_size.y = max(children[3].rect_size.y, children[2].rect_size.y) + max(children[1].rect_size.y, children[0].rect_size.y) + 60
	rect_size.x = max(children[3].rect_size.x, children[1].rect_size.x) + max(children[2].rect_size.x, children[0].rect_size.x) + 180
	rect_size.y = max(children[3].rect_size.y, children[2].rect_size.y) + max(children[1].rect_size.y, children[0].rect_size.y) + 60
	

func _connect_signals():
	for child_node in children:
		for child in child_node.get_children():
			child.connect("item_rect_changed", self, "_on_children_item_rect_changed")


func _on_children_item_rect_changed():
	set_grid_size()


func _reset_sizes():
	for i in range(0, 4):
		children[i].rect_min_size = Vector2.ZERO
		children[i].rect_size = Vector2.ZERO
