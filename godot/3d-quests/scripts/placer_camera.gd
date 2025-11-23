class_name FreeLookCamera extends Camera3D

@onready var root = get_parent()

@export_range(0.0, 1.0) var sensitivity: float = 0.25
@export var snap: bool = true

# Mouse state
var _mouse_position = Vector2(0.0, 0.0)
var _total_pitch = 0.0

# Movement state
var _direction = Vector3(0.0, 0.0, 0.0)
var _velocity = Vector3(0.0, 0.0, 0.0)
var _acceleration = 30
var _deceleration = -10
var _vel_multiplier = 4

# Place Distance
@onready var place_area = $PlaceArea
@export_range(-10, -2) var far_place_distance: int = -8
@export var place_distance: int = -3
var near_place_distance: int = -2

# Raycast
@onready var raycast: RayCast3D = $RayCast3D

#object to place
var placer_obj: Node3D

#parent node
@onready var camera_manager = get_parent().get_node("CameraTestManager")
@onready var ui = get_parent().get_node("UILayer/NewUIControl/MenuBar/EditMenu/PopupPanel")  # adjust path

func _unhandled_input(event):
	raycast.force_raycast_update()
	
	# Receives mouse motion
	if event is InputEventMouseMotion:
		_mouse_position = event.relative
	
	# Receives mouse button input
	if event is InputEventMouseButton and event.pressed:
		var delete_mode = ui.delete_mode_enabled
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if delete_mode:
					var obj_to_delete = get_object_under_cursor()
					if obj_to_delete:
						root.delete_object(obj_to_delete.get_meta("obj_id"))
				else:
					if picked_object:
						drop_object()
					else:
						raycast.force_raycast_update()
						var obj = get_object_under_cursor()
						if obj:
							pick_up_object(obj)
						elif camera_manager.can_place:
							camera_manager.place_object()
			MOUSE_BUTTON_WHEEL_UP: # Increases place distance
				place_distance -= 1
				_update_place_distance()
			MOUSE_BUTTON_WHEEL_DOWN: # Decreases place distance
				place_distance += 1
				_update_place_distance()
	
	if Input.is_action_just_pressed("tab"):
		snap = not snap
		get_parent().get_node("UILayer/MainUIControl").update_snap_label(snap)

# Updates mouselook and movement every frame
func _process(delta):
	_update_mouselook()
	_update_movement(delta)
	if picked_object:
		var new_pos = get_place_object_pos()
		picked_object.global_position = new_pos
	
		var rotation_speed = 90 # degrees per second
		if Input.is_action_pressed("rotate_left"):
			picked_object.rotate_y(deg_to_rad(rotation_speed * delta))
		if Input.is_action_pressed("rotate_right"):
			picked_object.rotate_y(deg_to_rad(-rotation_speed * delta))
		if Input.is_action_pressed("rotate_up"):
			picked_object.rotate_object_local(Vector3(1,0,0), deg_to_rad(rotation_speed * delta))
		if Input.is_action_pressed("rotate_down"):
			picked_object.rotate_object_local(Vector3(1,0,0), deg_to_rad(-rotation_speed * delta))
	else:
		get_place_object_pos()
	

# Updates camera movement
func _update_movement(delta):
	# Computes desired direction from key states
	var lx := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var lz := Input.get_action_strength("move_backwards") - Input.get_action_strength("move_forward")
	var ly := Input.get_action_strength("move_up") - Input.get_action_strength("move_down")
	_direction = Vector3(lx, ly, lz)
	
	
	# Computes the change in velocity due to desired direction and "drag"
	# The "drag" is a constant acceleration on the camera to bring it's velocity to 0
	var offset = _direction.normalized() * _acceleration * _vel_multiplier * delta \
		+ _velocity.normalized() * _deceleration * _vel_multiplier * delta
	
	# Checks if we should bother translating the camera
	if _direction == Vector3.ZERO and offset.length_squared() > _velocity.length_squared():
		# Sets the velocity to 0 to prevent jittering due to imperfect deceleration
		_velocity = Vector3.ZERO
	else:
		# Clamps speed to stay within maximum value (_vel_multiplier)
		_velocity.x = clamp(_velocity.x + offset.x, -_vel_multiplier, _vel_multiplier)
		_velocity.y = clamp(_velocity.y + offset.y, -_vel_multiplier, _vel_multiplier)
		_velocity.z = clamp(_velocity.z + offset.z, -_vel_multiplier, _vel_multiplier)
	
		translate(_velocity * delta)

# Updates mouse look 
func _update_mouselook():
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		_mouse_position *= sensitivity
		var yaw = _mouse_position.x
		var pitch = _mouse_position.y
		_mouse_position = Vector2(0, 0)
		
		pitch = clamp(pitch, -90 - _total_pitch, 90 - _total_pitch)
		_total_pitch += pitch
	
		rotate_y(deg_to_rad(-yaw))
		rotate_object_local(Vector3(1,0,0), deg_to_rad(-pitch))
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Updates how far the place distance is from the camera
func _update_place_distance():
	place_distance = clamp(place_distance, far_place_distance, near_place_distance)
	place_area.position.z = place_distance

# Updates the objects position
func get_place_object_pos():
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		#gets 3D position and points raycast to that position
		var world_pos = get_mouse_world_pos()
		raycast.target_position = raycast.to_local(world_pos)
		
		#raycast hits CameraArea before it hits its final position
		#box is placed in the position of the collision
		#this solves the issue of the box always being a certain radius from the camera, making it easier to reliably place objects where expected
		var point = raycast.get_collision_point()
		if snap:
			point = point.round()
		
		var placer_mesh = placer_obj.get_child(0).get_child(0)
		var lowest_local = 0
		if placer_mesh is MeshInstance3D:
			lowest_local = get_mesh_lowest_local(placer_mesh)
		point.y = clamp(point.y, lowest_local * -1, 1000)
		placer_obj.position = point
	return placer_obj.global_transform.origin

func get_mesh_lowest_local(mi: MeshInstance3D) -> float:
	var mesh = mi.mesh
	if mesh == null:
		return 0.0
	
	var lowest = INF

	for surface_idx in range(mesh.get_surface_count()):
		var arrays := mesh.surface_get_arrays(surface_idx)
		var verts = arrays[Mesh.ARRAY_VERTEX]

		for v in verts:
			if v.y < lowest:
				lowest = v.y

	# If mesh had no vertices:
	return lowest if lowest != INF else 0.0


# Converts the current mouse position to a point in 3D space
func get_mouse_world_pos():
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		var mp  = get_viewport().get_mouse_position()
		return self.project_ray_origin(mp) + self.project_ray_normal(mp) * 50.0

func add_collision_to_mesh(mesh_instance: MeshInstance3D) -> void:
	# Only add if it doesn’t already have a collision
	if mesh_instance.get_node_or_null("CollisionShape3D"):
		return
	var static_body = StaticBody3D.new()
	static_body.name = "StaticBody3D"

	var collision_shape = CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"

	# Use a simple BoxShape for now
	var aabb = mesh_instance.get_aabb()
	collision_shape.shape = BoxShape3D.new()
	collision_shape.shape.size = aabb.size

	# Re-parent mesh under static body
	mesh_instance.parent.remove_child(mesh_instance)
	static_body.add_child(mesh_instance)
	static_body.add_child(collision_shape)

	# Add to Pickable group so your raycast detects it
	static_body.add_to_group("Pickable")

	# Add static body to scene
	camera_manager.add_child(static_body)

#sets the ghost object to be placed
func set_to_place(obj: Node3D):
	placer_obj = obj

var picked_object: Node3D = null

func pick_up_object(obj: Node3D):
	picked_object = obj
	root.pickup_object(obj.get_meta("obj_id"))

func drop_object():
	if picked_object:
		root.drop_object(picked_object.get_meta("obj_id"), picked_object.global_position, picked_object.global_rotation)
		picked_object = null

		
func get_object_under_cursor() -> Node3D:
	raycast.force_raycast_update()
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		# walk up until we find the ancestor that is in the Pickable group
		while collider != null and not collider.is_in_group("Pickable"):
			# stop if we reach the top-level map parent to avoid climbing too far
			if collider == get_parent() or collider == placer_obj:
				collider = null
				break
			collider = collider.get_parent()
		# ignore floor and null
		if collider != null and collider != get_parent().get_node("Floor"):
			return collider
	return null
	
func show_ghost():
	for child in placer_obj.get_children():
		if child is MeshInstance3D:
			child.visible = true
