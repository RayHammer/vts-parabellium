extends Control

enum PluginState {
	_SIZE
}

@export var status_bar: LineEdit
@export var log_window: TextEdit
@export var rps: RPS
@export var reconnect_button: Button
@export var update_time_cap: SpinBox
@export var update_timer: Timer

@export var websocket_url = "ws://localhost:8001"
@export var config_path = "user://config.cfg"
@export var verbose = false

var plugin_name = "Parabellium"
var plugin_developer = "RayHammer"

var _request_base = {
	"apiName": "VTubeStudioPublicAPI",
	"apiVersion": "1.0",
	"requestID": "Parabellium",
	"data": {}
}

var _socket = WebSocketPeer.new()
var _token = ""
var _connect_requested = true
var _root: SceneTree
var _queued_data: Dictionary = {}

func _ready():
	set_update_cap(update_time_cap.value)
	if !update_time_cap.value_changed.is_connected(set_update_cap):
		update_time_cap.value_changed.connect(set_update_cap)
	log_window.text = ""
	status_bar.text = ""
	_root = get_tree()
	var config = ConfigFile.new()
	if config.load(config_path) == OK:
		_token = config.get_value("Global", "token", "")
		for node in _root.get_nodes_in_group("TrackedFields"):
			node.read_config(config)
			pass
	_socket.connect_to_url(websocket_url)
	pass

func _physics_process(_delta):
	_socket.poll()
	var state = _socket.get_ready_state()
	match state:
		WebSocketPeer.STATE_OPEN:
			if _connect_requested:
				var request = _request_base.duplicate()
				request["messageType"] = "APIStateRequest"
				_socket.send_text(JSON.stringify(request))
				_connect_requested = false
			while _socket.get_available_packet_count():
				var packet = _socket.get_packet()
				parse_response(packet.get_string_from_utf8())
		WebSocketPeer.STATE_CLOSING:
			pass
		WebSocketPeer.STATE_CLOSED:
			var code = _socket.get_close_code()
			var reason = _socket.get_close_reason()
			if verbose:
				print("WebSocket closed with code: %d, reason: %s. Clean: %s" % [code, reason, code != -1])
	pass

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_config()
		#get_tree().quit()
	pass

func save_config():
	var config = ConfigFile.new()
	config.set_value("Global", "token", _token)
	for node in _root.get_nodes_in_group("TrackedFields"):
		node.write_config(config)
	config.save(config_path)
	pass

func parse_response(response):
	if verbose:
		print("Received: ", response)
	var json = JSON.parse_string(response)
	if json != null:
		match json["messageType"]:
			"APIStateResponse":
				if json["data"]["currentSessionAuthenticated"] == false:
					if _token == "":
						get_token()
					else:
						authenticate()
			"AuthenticationTokenResponse":
				_token = json["data"]["authenticationToken"]
				authenticate()
			"AuthenticationResponse":
				if json["data"]["authenticated"] == true:
					add_custom_params()
				else:
					_token = ""
					get_token()
			"ParameterCreationResponse":
				add_log(json["data"]["parameterName"] + " is live!")
			"InjectParameterDataResponse":
				pass
			"ParameterValueResponse":
				pass
			"APIError":
				add_log(json["data"]["message"])
				print(json)
	pass

func new_request(type: String, data: Dictionary) -> Dictionary:
	var request = _request_base.duplicate()
	request["messageType"] = type
	request.data.merge(data, true)
	return request

func send_request(request: Variant):
	if verbose:
		print("Sent: ", request)
	rps.increment()
	_socket.send_text(JSON.stringify(request))

func add_log(text):
	#log_window.set_line(log_window.get_line_count(), text)
	log_window.text += text + "\n"
	pass

func get_token():
	status_bar.text = "Retrieving auth token"
	var request = new_request("AuthenticationTokenRequest", {
		"pluginName": plugin_name,
		"pluginDeveloper": plugin_developer
	})
	send_request(request)
	pass

func authenticate():
	status_bar.text = "Authorizing"
	var request = new_request("AuthenticationRequest", {
		"pluginName": plugin_name,
		"pluginDeveloper": plugin_developer,
		"authenticationToken": _token
	})
	send_request(request)
	pass

func add_custom_params():
	status_bar.text = "Adding custom parameters"
	for node in _root.get_nodes_in_group("TrackedFields"):
		for param in node.get_parameter_data():
			var request = new_request("ParameterCreationRequest", param)
			send_request(request)
			if !node.set_parameters.is_connected(queue_parameters):
				node.set_parameters.connect(queue_parameters)
			pass
	status_bar.text = "Ready"
	pass

func set_update_cap(value: float):
	update_timer.wait_time = 1.0 / value

func queue_parameters(data: Dictionary):
	_queued_data.merge(data, true)

func set_parameters():
	if _queued_data.is_empty():
		return
	var parsed_data = []
	for id in _queued_data:
		parsed_data.push_back({
			"id": id,
			"value": _queued_data[id]
		})
	_queued_data.clear()
	var request = new_request("InjectParameterDataRequest", {
		"mode": "set",
		"parameterValues": parsed_data
	})
	send_request(request)

