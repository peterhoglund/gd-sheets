tool
extends MarginContainer

var text setget set_text
var tween := Tween.new()

func _ready() -> void:
	add_child(tween)
	tween.connect("tween_completed", self, "_on_tween_completed")
	visible = false


func pop():
	visible = true
	if tween.is_active():
		tween.stop_all()
		modulate.a = 1
	
	yield(get_tree().create_timer(3), "timeout")
	tween.interpolate_property(self, "modulate:a", 1, 0, 0.5, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.start()


func _on_tween_completed(obj, key):
	modulate.a = 1
	visible = false


func set_text(v):
	text = v
	$MarginContainer/HBoxContainer/NotUniqueWarningLabel.text = text
