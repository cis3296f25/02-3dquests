extends Node

# Our TCP Server instance.
var _tcp_server = TCPServer.new()

# Our connected peers list.
var _peers: Dictionary[String, WebSocketPeer] = {}

var last_peer_id := 0

# Authoritative object storage
var objects: Dictionary = {}  # object_id -> {mesh, position, rotation}
var last_object_id := 0

var maps = []
var current_map_name: String = ""

var port = ""
var campaign_id = ""
var session_token = ""

var last_activity = Time.get_unix_time_from_system()

func _ready():
	var args = OS.get_cmdline_args()
	for a in args:
		if a.begins_with("--session-token="):
			session_token = a.split("=")[1]
		elif a.begins_with("--port="):
			port = int(a.split("=")[1])
		elif a.begins_with("--campaign-id="):
			campaign_id = a.split("=")[1]

	print("Starting server for campaign: %s on port %d" % [campaign_id, port])
	# Start listening on the given port.
	var err = _tcp_server.listen(port)
	if err == OK:
		print("Server started.")
		load_maps()
	else:
		push_error("Unable to start server.")
		set_process(false)

func _process(_delta):
	if Time.get_unix_time_from_system() - last_activity > 3600:
		print("Idle 1h – quitting.")
		stop_session()
		get_tree().quit()

	while _tcp_server.is_connection_available():
		last_peer_id += 1
		var ws = WebSocketPeer.new()
		ws.accept_stream(_tcp_server.take_connection())
		print("+Peer %d connected." % last_peer_id)
		_peers[str(last_peer_id)] = ws

	# Iterate over all connected peers using "keys()" so we can erase in the loop
	for peer_id in _peers.keys():
		var peer = _peers[peer_id]
		peer.poll()
		
		if peer.has_meta("sent_world"):
			var err = peer.send_text("ping")
			if err != OK:
				print("- Peer %s disconnected (send failed)" % peer_id)
				_peers.erase(peer_id)
				player_leave(peer_id)
		
			
		var peer_state = peer.get_ready_state()
		if peer_state == WebSocketPeer.STATE_OPEN:
			if not peer.has_meta("sent_world"):
				send_world_state(peer_id)
				peer.set_meta("sent_world", true)
			while peer.get_available_packet_count():
				var packet = peer.get_packet()
				if peer.was_string_packet():
					var packet_text = packet.get_string_from_utf8()
					# JSON messages for objects
					var json = JSON.new()
					var error = json.parse(packet_text)
					if error == OK:
						var data_recieved = json.data
						if typeof(data_recieved) == TYPE_DICTIONARY:
							handle_packet(peer_id, data_recieved)
							print(data_recieved)
						else:
							print("Unexpected Data")
					else:
						print("JSON Parse Error: ", json.get_error_message(), " in ", packet_text, " at line ", json.get_error_line())
					# Echo the packet back.
					# peer.send_text(packet_text)
				else:
					print("< Got binary data from peer %s: %d ... echoing" % [peer_id, packet.size()])
					# Echo the packet back.
					# peer.send(packet)
		elif peer_state == WebSocketPeer.STATE_CLOSED:
			pass

func player_join(user_id: String):
	var http_request = HTTPRequest.new()
	add_child(http_request)

	http_request.request_completed.connect(self._http_join_request_completed)

	var data = {
		"session_token": session_token
	}

	var json = JSON.stringify(data)
	var headers = ["Content-Type: application/json", "Authorization: Bearer %s" % user_id]

	var error = http_request.request("https://game.3dquests.com/join", headers, HTTPClient.METHOD_POST, json)
	if error != OK:
		print("An error occurred in the HTTP request.")
	#http_request.queue_free()

func _http_join_request_completed(result, response_code, headers, body):
	if response_code != 200:
		print("Failed to join active session: %s" % response_code)
		return
	
	var json = JSON.new()
	var error = json.parse(body.get_string_from_utf8())
	if error != OK:
		print("Failed to parse JSON from session API")
		return

func player_leave(peer_id: String):
	var http_request = HTTPRequest.new()
	add_child(http_request)

	http_request.request_completed.connect(self._http_join_request_completed)
	var data = {
		"campaignId": campaign_id,
		"session_token": session_token,
	}

	var json = JSON.stringify(data)
	var headers = ["Content-Type: application/json", "Authorization: Bearer %s" % peer_id]

	var error = http_request.request("https://game.3dquests.com/leave", headers, HTTPClient.METHOD_POST, json)
	if error != OK:
		print("An error occurred in the HTTP request.")
	#http_request.queue_free()

func _http_leave_request_completed(result, response_code, headers, body):
	if response_code != 200:
		print("Failed to leave active session: %s" % response_code)
		return
	
	var json = JSON.new()
	var error = json.parse(body.get_string_from_utf8())
	if error != OK:
		print("Failed to parse JSON from session API")
		return

func stop_session():
	var http_request = HTTPRequest.new()
	add_child(http_request)

	http_request.request_completed.connect(self._http_stop_session_request_completed)
	var data = {
		"campaignId": campaign_id,
		"session_token": session_token,
		"last_map_name": current_map_name
	}
	var json = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	var error = http_request.request("https://game.3dquests.com/stop_session", headers, HTTPClient.METHOD_POST, json)
	if error != OK:
		print("An error occurred in the HTTP request.")

func _http_stop_session_request_completed(result, response_code, headers, body):
	if response_code != 200:
		print("Failed to stop server: %s" % response_code)
		return
	
	print("Server stopped successfully.")

# To make sure no more than one person can move an object at a time
var object_owners: Dictionary[int, String] = {}

func handle_packet(peer_id: String, data: Dictionary):
	match data.type:
		"place_object":
			handle_place(peer_id, data)
		"update_object":
			handle_update(peer_id, data)
		"delete_object":
			handle_delete(peer_id, data)
		"pickup_object":
			handle_pickup(peer_id, data)
		"drop_object":
			handle_drop(peer_id, data)
		"new_map":
			new_map(data)
			broadcast_world_state()
		"save_map":
			save_map()
		"load_map":
			load_objects_from_specific_map(data)
			broadcast_world_state()
		"hello":
			handle_first_contact(peer_id, data)
		_:
			print("Unknown packet type: ", data.type)
			
func handle_first_contact(peer_id: String, data: Dictionary):
	var user_id = str(data.userId)
	var old_peer = _peers.get(user_id, null)
	if old_peer != null:
		print("User %s reconnected, closing old connection." % user_id)
		old_peer.close(1000, "Reconnected")

	_peers[user_id] = _peers[peer_id]
	_peers.erase(peer_id)
	print("Peer %s identified as user %s" % [peer_id, user_id])
	player_join(user_id)

func handle_place(peer_id: String, data: Dictionary):
	last_object_id += 1
	var obj_id = last_object_id
	objects[obj_id] = {
		"mesh": data.mesh,
		"position": data.position,
		"rotation": data.rotation
	}
	print("Placed object %s by peer %s" % [obj_id, peer_id])

	# Broadcast authoritative object info
	broadcast({
		"type": "object_created",
		"obj_id": obj_id,
		"mesh": data.mesh,
		"position": data.position,
		"rotation": data.rotation
	})
	last_activity = Time.get_unix_time_from_system()
	

func handle_update(peer_id: String, data: Dictionary):
	var obj_id = int(data.obj_id)
	if not objects.has(data.obj_id):
		print("Peer %s tried to update missing object %s" % [peer_id, data.obj_id])
		return
	
	var obj = objects[obj_id]
	obj.position = data.position
	obj.rotation = data.rotation
	objects[obj_id] = obj
	
	broadcast({
		"type": "object_updated",
		"obj_id": obj_id,
		"position": data.position,
		"rotation": data.rotation
	})
	last_activity = Time.get_unix_time_from_system()

func handle_delete(peer_id: String, data: Dictionary):
	var obj_id = int(data.obj_id)
	if not objects.has(obj_id):
		print("Peer %s tried to delete missing object %s" % [peer_id, data.obj_id])
		return
	
	objects.erase(obj_id)
	
	broadcast({
		"type": "object_deleted",
		"obj_id": obj_id
	})
	
	print("Deleted object %s" % data.obj_id)
	last_activity = Time.get_unix_time_from_system()

func handle_pickup(peer_id: String, data: Dictionary):
	var obj_id = int(data.obj_id)
	if not objects.has(obj_id):
		print("Peer %s tried to pick up missing object %s" % [peer_id, obj_id])
	
	if object_owners.has(obj_id):
		print("Peer %s tried to pick up object %s but its already held by %s" % [peer_id, obj_id, object_owners[obj_id]])
		_peers[peer_id].send_text(JSON.stringify({
			"type": "pickup_denied",
			"obj_id": obj_id
		}))
		return
	
	object_owners[obj_id] = peer_id
	print("Peer %s picked up object %s" % [peer_id, obj_id])

	broadcast({
		"type": "object_picked_up",
		"obj_id": obj_id,
		"owner_id": peer_id
	})
	last_activity = Time.get_unix_time_from_system()
	
func handle_drop(peer_id: String, data: Dictionary):
	var obj_id = int(data.obj_id)
	if not object_owners.has(obj_id):
		print("Peer %s tried to drop object %s, but it’s not held" % [peer_id, obj_id])
		return

	if object_owners[obj_id] != peer_id:
		print("Peer %s tried to drop object %s they don’t own" % [peer_id, obj_id])
		return
		
	object_owners.erase(obj_id)
	print("Peer %s dropped object %s" % [peer_id, obj_id])
	
	if objects.has(obj_id):
			objects[obj_id].position = data.position
			objects[obj_id].rotation = data.rotation
	
	broadcast({
		"type": "object_dropped",
		"obj_id": obj_id,
		"owner_id": peer_id,
		"position": data.position,
		"rotation": data.rotation
	})
	last_activity = Time.get_unix_time_from_system()
	
func send_world_state(peer_id):
	var peer = _peers[peer_id]
	var obj_list: Array = []
	for obj_id in objects.keys():
		var obj_data = objects[obj_id]
		obj_data["obj_id"] = obj_id
		obj_list.append(obj_data)
	peer.send_text(JSON.stringify({
		"type": "world_state_update",
		"map_name": current_map_name,
		"objects": obj_list
	}))
	last_activity = Time.get_unix_time_from_system()
	
func broadcast(data: Dictionary):
	var text = JSON.stringify(data)
	for p in _peers.values():
		if p.get_ready_state() == WebSocketPeer.STATE_OPEN:
			p.send_text(text)

func new_map(data):
	current_map_name = data.map_name
	objects = {}
	save_map()
	
			
func save_map():
	var http_request = HTTPRequest.new()
	add_child(http_request)

	http_request.request_completed.connect(self._http_save_request_completed)
	var data = {
		"campaignId": campaign_id,
		"name": current_map_name,
		"data": objects
	}

	var json = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]

	var error = http_request.request("https://game.3dquests.com/save_map", headers, HTTPClient.METHOD_POST, json)
	if error != OK:
		print("An error occurred in the HTTP request.")
	#http_request.queue_free()

func _http_save_request_completed(result, response_code, headers, body):
	if response_code != 200:
		print("Failed to save map: %s" % response_code)
		return
	
	var json = JSON.new()
	var error = json.parse(body.get_string_from_utf8())
	if error != OK:
		print("Failed to parse JSON from session API")
		return
	print("Map saved successfully")
		
func load_maps():
	var http_request = HTTPRequest.new()
	add_child(http_request)

	http_request.request_completed.connect(self._http_load_request_completed)

	var error = http_request.request("https://game.3dquests.com/load_maps?campaign_id=" + campaign_id, [], HTTPClient.METHOD_GET)
	if error != OK:
		print("An error occurred in the HTTP request.")
	#http_request.queue_free()

func _http_load_request_completed(result, response_code, headers, body):
	if response_code != 200:
		print("Failed to load maps: %s" % response_code)
		return
	
	var json = JSON.new()
	var error = json.parse(body.get_string_from_utf8())
	if error != OK:
		print("Failed to parse JSON from session API")
		return
	var data = json.get_data()
	maps = data["maps"] # API returns { "maps": ["map_name1"], "current_map_name": "name", "objects": "{}" }
	current_map_name = data["current_map_name"]
	objects = data["current_objs"]
	print("Maps loaded")
	
	broadcast({
		"type": "load_maps",
		"maps": maps,
		"current_map_name": current_map_name,
		"current_objs": objects
	})
	
	print("Maps sent")
	
func load_objects_from_specific_map(data: Dictionary):
	var http_request = HTTPRequest.new()
	add_child(http_request)
	current_map_name = data.map_name
	http_request.request_completed.connect(self._http_load_objects_request_completed)
	var error = http_request.request("https://game.3dquests.com/load_map_objects?map_name=" + current_map_name, [], HTTPClient.METHOD_GET)
	if error != OK:
		print("An error occurred in the HTTP request.")
		
func _http_load_objects_request_completed(result, response_code, headers, body):
	if response_code != 200:
		print("Failed to load objects from current map: %s" % response_code)
		return
	
	var json = JSON.new()
	var error = json.parse(body.get_string_from_utf8())
	if error != OK:
		print("Failed to parse JSON from session API")
		return
	objects = json.get_data()["objects"] # API Returns { "objects": { "obj_id1": ... } }
	print("Got Objects")

func broadcast_world_state():
	for peer_id in _peers.keys():
		send_world_state(peer_id)
