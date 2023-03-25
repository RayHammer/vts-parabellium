class_name RPS
extends HBoxContainer

var rps_value: LineEdit
var rps_counter = 0

func _ready():
	rps_value = get_node("Value")
	rps_value.text = str(0)
	pass

func increment():
	rps_counter += 1

func _on_timer_timeout():
	rps_value.text = str(rps_counter)
	rps_counter = 0
	pass
