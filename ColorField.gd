extends "res://TrackedField.gd"

@export var update_time = 1.0 / 10
var update_time_left = update_time
var is_rainbow = false
var color_picker

func _ready():
	super()
	color_picker = get_node("ColorPicker")
	var color = color_picker.color
	parameters[name + "R"] = color.r8
	parameters[name + "G"] = color.g8
	parameters[name + "B"] = color.b8
	pass

func _process(delta):
	if is_rainbow:
		color_picker.color.h = wrapf(color_picker.color.h + delta, 0, 1)
	update_time_left = min(0, update_time_left - delta)
	if update_time_left <= 0:
		_on_color_changed(color_picker.color)
	pass

func get_parameter_data() -> Array:
	var output = []
	for i in ["R", "G", "B"]:
		output.append({
			"parameterName": name + i,
			"explanation": name + i,
			"min": 0,
			"max": 255,
			"defaultValue": parameters[name + i]
		})
	return output

func read_config(config):
	var data = JSON.parse_string(config.get_value(name, "presets"))
	for i in data:
		color_picker.add_preset(Color(i))
	pass

func write_config(config):
	var presets = color_picker.get_presets()
	var data = []
	for i in presets:
		data.append(i.to_html(false))
	config.set_value(name, "presets", JSON.stringify(data))
	pass

func _on_rainbow_toggled(state: bool):
	is_rainbow = state

func _on_color_changed(color):
	set_parameters.emit([
		{
			"id": name + "R",
			"value": color.r8
		},
		{
			"id": name + "G",
			"value": color.g8
		},
		{
			"id": name + "B",
			"value": color.b8
		},
	])
	pass
