extends "res://TrackedField.gd"

# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	var color = get_node("ColorPicker").color
	parameters[name + "R"] = color.r8
	parameters[name + "G"] = color.g8
	parameters[name + "B"] = color.b8
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
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
