@tool
extends "res://TrackedField.gd"

@export var label_name: String :
	set(value):
		label_name = value
		get_node("Label").text = label_name

@export var default_color: Color :
	set(value):
		default_color = value
		get_node("ColorPicker").color = default_color

@export var update_time_idle = 1.0 / 5
@export var update_time_rainbow = 1.0 / 30

var update_time = update_time_idle
var rainbow_speed_spinbox
var update_time_left = update_time
var is_rainbow = false
var color_picker

func _ready():
	update_time = update_time_idle
	if Engine.is_editor_hint():
		return
	super()
	color_picker = get_node("ColorPicker")
	rainbow_speed_spinbox = get_node("RainbowSpeed/Value")
	var color = color_picker.color
	parameters[name + "R"] = color.r8
	parameters[name + "G"] = color.g8
	parameters[name + "B"] = color.b8
	pass

func _physics_process(delta):
	if Engine.is_editor_hint():
		return
	if is_rainbow:
		var speed = rainbow_speed_spinbox.value
		color_picker.color.h = wrapf(color_picker.color.h + delta * speed, 0, 1)
		update_time = update_time_rainbow
	else:
		update_time = update_time_idle
	update_time_left = max(0, update_time_left - delta)
	if update_time_left <= 0:
		_on_color_changed(color_picker.color)
		update_time_left = update_time
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
	var json = JSON.new()
	if json.parse(config.get_value(name, "presets", "")) == OK:
		for i in json.data:
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
