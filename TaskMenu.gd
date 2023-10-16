extends MenuBar

@export var debug_menu: PopupMenu
@export var debug_info: Control

var min_debug_size_x

# Called when the node enters the scene tree for the first time.
func _ready():
	debug_id_pressed(0, false)
	min_debug_size_x = debug_info.custom_minimum_size.x
	# WTF fym this shit returns (0, 0)
	# print(debug_info.custom_minimum_size)

func debug_id_pressed(index: int, change_state: bool = true):
	if index == 0:
		if change_state:
			debug_menu.toggle_item_checked(0)
		var expand = debug_menu.is_item_checked(0)
		debug_info.visible = expand;
		debug_info.custom_minimum_size.x = 150 if expand else 0
