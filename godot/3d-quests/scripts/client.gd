extends Node

# The URL we will connect to.
# Use "ws://localhost:9080" if testing with the minimal server example below.
# `wss://` is used for secure connections,
# while `ws://` is used for plain text (insecure) connections.
var campaign_id: String = ""
var session_token: String = ""
var token: String = ""


# Our WebSocketClient instance.
var socket = WebSocketPeer.new()

var local_objects: Dictionary[int, Node3D] = {}

func _ready():
	var http_request = HTTPRequest.new()
	add_child(http_request)
	# Read the campaignId from the window object
	if Engine.has_singleton("JavaScript"):
		var js = Engine.get_singleton("JavaScript")
		campaign_id = js.eval("window.GAME_CONFIG.campaignId")
		print("Campaign ID:", campaign_id)
	
	http_request.request_completed.connect(self._http_request_completed)

	var error = http_request.request("https://3dquests.com/api/get-active-session/" + campaign_id)
	if error != OK:
		push_error("An error occurred in the HTTP request.")

func _http_request_completed(result, response_code, headers, body):
	if response_code != 200:
		push_error("Failed to get active session: %s" % response_code)
		return
	
	var json = JSON.new()
	var text = json.parse(body.get_string_from_utf8())
	if text.error != OK:
		push_error("Failed to parse JSON from session API")
		return
	
	session_token = text.result.session_token
	
	var websocket_url = "wss://game.3dquests.com/campaign?token=%s" % [session_token]

	# Initiate connection to the given URL.
	var err = socket.connect_to_url(websocket_url)
	if err == OK:
		print("Connecting to %s..." % websocket_url)
		# Wait for the socket to connect.
		await get_tree().create_timer(2).timeout
	else:
		push_error("Unable to connect.")
		set_process(false)

func _process(_delta):
	# Call this in `_process()` or `_physics_process()`.
	# Data transfer and state updates will only happen when calling this function.
	socket.poll()

	# get_ready_state() tells you what state the socket is in.
	var state = socket.get_ready_state()

	# `WebSocketPeer.STATE_OPEN` means the socket is connected and ready
	# to send and receive data.
	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			var packet = socket.get_packet()
			if socket.was_string_packet():
				# JSON messages for objects
					var json = JSON.new()
					var packet_text = packet.get_string_from_utf8()
					var error = json.parse(packet_text)
					if error == OK:
						var data_recieved = json.data
						print(data_recieved)
						if typeof(data_recieved) == TYPE_DICTIONARY:
							handle_data_recieved(data_recieved)
					print("< Got text data from server: %s" % packet_text)
			else:
				print("< Got binary data from server: %d bytes" % packet.size())

	# `WebSocketPeer.STATE_CLOSING` means the socket is closing.
	# It is important to keep polling for a clean close.
	elif state == WebSocketPeer.STATE_CLOSING:
		pass

	# `WebSocketPeer.STATE_CLOSED` means the connection has fully closed.
	# It is now safe to stop polling.
	elif state == WebSocketPeer.STATE_CLOSED:
		# The code will be `-1` if the disconnection was not properly notified by the remote peer.
		var code = socket.get_close_code()
		print("WebSocket closed with code: %d. Clean: %s" % [code, code != -1])
		set_process(false) # Stop processing.
		
func handle_data_recieved(data_recieved: Dictionary):
	match data_recieved.type:
		"object_created":
			add_object_to_props_container(data_recieved)
		"object_updated":
			var obj_id = int(data_recieved["obj_id"])
			if local_objects.has(obj_id):
				var obj = local_objects[obj_id]
				obj.global_position = _parse_vector3_string(data_recieved.position)
				obj.global_rotation = _parse_vector3_string(data_recieved.rotation)
		"object_deleted":
			var obj_id = int(data_recieved["obj_id"])
			if local_objects.has(obj_id):
				local_objects[obj_id].queue_free()
				local_objects.erase(obj_id)
		"object_picked_up":
			var obj_id = int(data_recieved["obj_id"])
			if local_objects.has(obj_id):
				print("Object %d picked up by peer %d" % [obj_id, data_recieved.owner_id])
		"object_dropped":
			var obj_id = int(data_recieved["obj_id"])
			if local_objects.has(obj_id):
				var obj = local_objects[obj_id]
				obj.position = _parse_vector3_string(data_recieved.position)
				obj.rotation = _parse_vector3_string(data_recieved.rotation)
		"world_state_update":
			for obj_data in data_recieved["objects"]:
				add_object_to_props_container(obj_data)
				
func add_object_to_props_container(data_recieved):
	var obj_id = int(data_recieved["obj_id"])
	var scene = load(data_recieved.mesh)
	var obj = scene.instantiate()
	obj.owner = null
	obj.set_meta("obj_id", obj_id)
	_add_collision_recursive(obj, obj_id)
	obj.add_to_group("Pickable")
	$PropsContainer.add_child(obj)
	obj.global_position = _parse_vector3_string(data_recieved.position)
	obj.global_rotation = _parse_vector3_string(data_recieved.rotation)
	local_objects[obj_id] = obj
				
func _parse_vector3_string(vector_str: String) -> Vector3:
	# Remove parentheses and split by commas
	vector_str = vector_str.replace("(", "").replace(")", "")
	var parts = vector_str.split(",")
	
	if parts.size() >= 3:
		var x = parts[0].strip_edges().to_float()
		var y = parts[1].strip_edges().to_float()
		var z = parts[2].strip_edges().to_float()
		return Vector3(x, y, z)
	
	return Vector3.ZERO

func _add_collision_recursive(node: Node3D, obj_id: int) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			if not child.get_node_or_null("CollisionShape3D"):
				var body = StaticBody3D.new()
				body.name = "StaticBody3D"
				body.set_meta("obj_id", obj_id)

				var shape = CollisionShape3D.new()
				shape.name = "CollisionShape3D"
				shape.shape = child.mesh.create_trimesh_shape() # accurate collision

				# Reparent child under StaticBody3D
				var original_parent = child.get_parent()
				original_parent.remove_child(child)
				body.add_child(child)
				body.add_child(shape)

				# Add StaticBody3D to the original parent
				original_parent.add_child(body)
				
				# Add to pickable group
				body.add_to_group("Pickable")
		else:
			_add_collision_recursive(child, obj_id)

func place_object(mesh_path: String, pos: Vector3, rot: Vector3):
	var data = {
		"type": "place_object",
		"mesh": mesh_path,
		"position": pos,
		"rotation": rot
	}
	socket.send_text(JSON.stringify(data))

func update_object(obj_id, pos, rot):
	var data = {
		"type": "update_object",
		"obj_id": obj_id,
		"position": pos,
		"rotation": rot
	}
	socket.send_text(JSON.stringify(data))
	
func delete_object(obj_id):
	var data = {
		"type": "delete_object",
		"obj_id": obj_id
	}
	socket.send_text(JSON.stringify(data))
	
func pickup_object(obj_id):
	var data = {
		"type": "pickup_object",
		"obj_id": obj_id
	}
	socket.send_text(JSON.stringify(data))

func drop_object(obj_id, pos, rot):
	var data = {
		"type": "drop_object",
		"obj_id": obj_id,
		"position": pos,
		"rotation": rot
	}
	socket.send_text(JSON.stringify(data))
