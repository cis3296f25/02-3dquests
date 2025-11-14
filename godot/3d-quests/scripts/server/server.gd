extends Node

# The port we will listen to.
const PORT = 9080

# Our TCP Server instance.
var _tcp_server = TCPServer.new()

# Our connected peers list.
var _peers: Dictionary[int, WebSocketPeer] = {}

var last_peer_id := 0

# Authoritative object storage
var objects: Dictionary[int, Dictionary] = {}  # object_id -> {mesh, position, rotation}
var last_object_id := 0


func _ready():
	# Start listening on the given port.
	var err = _tcp_server.listen(PORT)
	if err == OK:
		print("Server started.")
	else:
		push_error("Unable to start server.")
		set_process(false)


func _process(_delta):
	while _tcp_server.is_connection_available():
		last_peer_id += 1
		print("+ Peer %d connected." % last_peer_id)
		var ws = WebSocketPeer.new()
		ws.accept_stream(_tcp_server.take_connection())
		_peers[last_peer_id] = ws

	# Iterate over all connected peers using "keys()" so we can erase in the loop
	for peer_id in _peers.keys():
		var peer = _peers[peer_id]

		peer.poll()

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
					print("< Got binary data from peer %d: %d ... echoing" % [peer_id, packet.size()])
					# Echo the packet back.
					# peer.send(packet)
		elif peer_state == WebSocketPeer.STATE_CLOSED:
			# Remove the disconnected peer.
			_peers.erase(peer_id)
			var code = peer.get_close_code()
			var reason = peer.get_close_reason()
			print("- Peer %s closed with code: %d, reason %s. Clean: %s" % [peer_id, code, reason, code != -1])

# To make sure no more than one person can move an object at a time
var object_owners: Dictionary[int, int] = {}

func handle_packet(peer_id: int, data: Dictionary):
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
		_:
			print("Unknown packet type: ", data.type)

func handle_place(peer_id: int, data: Dictionary):
	last_object_id += 1
	var obj_id = last_object_id
	objects[obj_id] = {
		"mesh": data.mesh,
		"position": data.position,
		"rotation": data.rotation
	}
	print("Placed object %d by peer %d" % [obj_id, peer_id])

	# Broadcast authoritative object info
	broadcast({
		"type": "object_created",
		"obj_id": obj_id,
		"mesh": data.mesh,
		"position": data.position,
		"rotation": data.rotation
	})
	

func handle_update(peer_id: int, data: Dictionary):
	var obj_id = int(data.obj_id)
	if not objects.has(data.obj_id):
		print("Peer %d tried to update missing object %d" % [peer_id, data.obj_id])
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

func handle_delete(peer_id: int, data: Dictionary):
	var obj_id = int(data.obj_id)
	if not objects.has(obj_id):
		print("Peer %d tried to delete missing object %d" % [peer_id, data.obj_id])
		return
	
	objects.erase(obj_id)
	
	broadcast({
		"type": "object_deleted",
		"obj_id": obj_id
	})
	
	print("Deleted object %d" % data.obj_id)

func handle_pickup(peer_id: int, data: Dictionary):
	var obj_id = int(data.obj_id)
	if not objects.has(obj_id):
		print("Peer %d tried to pick up missing object %d" % [peer_id, obj_id])
	
	if object_owners.has(obj_id):
		print("Peer %d tried to pick up object %d but its already held by %d" % [peer_id, obj_id, object_owners[obj_id]])
		_peers[peer_id].send_text(JSON.stringify({
			"type": "pickup_denied",
			"obj_id": obj_id
		}))
		return
	
	object_owners[obj_id] = peer_id
	print("Peer %d picked up object %d" % [peer_id, obj_id])

	broadcast({
		"type": "object_picked_up",
		"obj_id": obj_id,
		"owner_id": peer_id
	})
	
func handle_drop(peer_id: int, data: Dictionary):
	var obj_id = int(data.obj_id)
	if not object_owners.has(obj_id):
		print("Peer %d tried to drop object %d, but it’s not held" % [peer_id, obj_id])
		return

	if object_owners[obj_id] != peer_id:
		print("Peer %d tried to drop object %d they don’t own" % [peer_id, obj_id])
		return
		
	object_owners.erase(obj_id)
	print("Peer %d dropped object %d" % [peer_id, obj_id])
	
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
	
func send_world_state(peer_id):
	var peer = _peers[peer_id]
	var obj_list: Array = []
	for obj_id in objects.keys():
		var obj_data = objects[obj_id]
		obj_data["obj_id"] = obj_id
		obj_list.append(obj_data)
	peer.send_text(JSON.stringify({
		"type": "world_state_update",
		"objects": obj_list
	}))

	
	
func broadcast(data: Dictionary):
	var text = JSON.stringify(data)
	for p in _peers.values():
		if p.get_ready_state() == WebSocketPeer.STATE_OPEN:
			p.send_text(text)
