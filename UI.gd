extends Control

enum PluginState {
	_SIZE
}

@export var websocket_url = "ws://localhost:8001"
@export var config_path = "user://config.cfg"
@export var verbose = true

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
var _once = true

func _ready():
	var config = ConfigFile.new()
	if config.load(config_path) == OK:
		for node in get_children():
			if node.is_in_group("TrackedFields"):
				node.read_config(config)
				pass
	_socket.connect_to_url(websocket_url)
	pass

func _process(_delta):
	_socket.poll()
	var state = _socket.get_ready_state()
	match state:
		WebSocketPeer.STATE_OPEN:
			if _once:
				var request = _request_base.duplicate()
				request["messageType"] = "APIStateRequest"
				_socket.send_text(JSON.stringify(request))
				_once = false
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

func _exit_tree():
	var config = ConfigFile.new()
	for node in get_children():
		if node.is_in_group("TrackedFields"):
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
			"ParameterCreationResponse":
				print(json["data"]["parameterName"], " is live!")
			"InjectParameterDataResponse":
				#send_request(new_request("ParameterValueRequest", {"name": "CustomShirtR"}))
				pass
			"ParameterValueResponse":
				pass
			"APIError":
				print(json)
	pass

func new_request(type: String, data: Dictionary) -> Dictionary:
	var request = _request_base.duplicate()
	request["messageType"] = type
	request.data.merge(data, true)
	return request

func send_request(request: Variant):
	_socket.send_text(JSON.stringify(request))

func get_token():
	var request = new_request("AuthenticationTokenRequest", {
		"pluginName": plugin_name,
		"pluginDeveloper": plugin_developer
	})
	send_request(request)
	pass

func authenticate():
	print("Begin authentication")
	var request = new_request("AuthenticationRequest", {
		"pluginName": plugin_name,
		"pluginDeveloper": plugin_developer,
		"authenticationToken": _token
	})
	send_request(request)
	pass

func add_custom_params():
	print("Adding custom parameters")
	for node in get_children():
		if node.is_in_group("TrackedFields"):
			for param in node.get_parameter_data():
				var request = new_request("ParameterCreationRequest", param)
				#print("Sent: ", JSON.stringify(request))
				send_request(request)
				node.set_parameters.connect(set_parameters)
				pass
	pass

func set_parameters(data: Array):
	var request = new_request("InjectParameterDataRequest", {
		"mode": "set",
		"parameterValues": data
	})
	send_request(request)

