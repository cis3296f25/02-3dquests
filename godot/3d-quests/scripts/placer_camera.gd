class_name FreeLookCamera extends Camera3D

@export_range(0.0, 1.0) var sensitivity: float = 0.25

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
@onready var parent = get_parent()

func _input(event):
	# Receives mouse motion
	if event is InputEventMouseMotion:
		_mouse_position = event.relative
	
	# Receives mouse button input
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_RIGHT: # Only allows camera rotation if right click down
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE)
			MOUSE_BUTTON_LEFT:
				parent.place_object()
			MOUSE_BUTTON_WHEEL_UP: # Increases place distance
				place_distance -= 1
				_update_place_distance()
			MOUSE_BUTTON_WHEEL_DOWN: # Decreases place distance
				place_distance += 1
				_update_place_distance()

# Updates mouselook and movement every frame
func _process(delta):
	_update_mouselook()
	_update_movement(delta)
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
	# Only rotates mouse if the mouse is captured
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_mouse_position *= sensitivity
		var yaw = _mouse_position.x
		var pitch = _mouse_position.y
		_mouse_position = Vector2(0, 0)
		
		# Prevents looking up/down too far
		pitch = clamp(pitch, -90 - _total_pitch, 90 - _total_pitch)
		_total_pitch += pitch
	
		rotate_y(deg_to_rad(-yaw))
		rotate_object_local(Vector3(1,0,0), deg_to_rad(-pitch))

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
		point = point.round()
		placer_obj.position = point

# Converts the current mouse position to a point in 3D space
func get_mouse_world_pos():
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		var mp  = get_viewport().get_mouse_position()
		return self.project_ray_origin(mp) + self.project_ray_normal(mp) * 50.0

#sets the ghost object to be placed
func set_to_place(obj: Node3D):
	placer_obj = obj
