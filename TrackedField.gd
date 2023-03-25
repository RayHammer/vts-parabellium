extends Control

signal set_parameters(array)

var parameters = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	# print("Tracked Field ", name, " is ready")
	add_to_group("TrackedFields")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func get_parameter_data() -> Array:
	return []

func read_config(_config: ConfigFile):
	pass

func write_config(_config: ConfigFile):
	pass
