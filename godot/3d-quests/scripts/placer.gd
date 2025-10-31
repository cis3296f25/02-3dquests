extends Node3D
### PLACER TEST ###
#  USED TO TEST PLACING OBJECTS IN 3D SPACE


# Tracks the current mouse position in 3D space
var mouse_pos

# Adjustable distance from the camera for the CameraArea node
# Determins how far the object is from the camera
@export_range(1, 20) var area_distance: int #TODO: Use scroll wheel to change this number

#References to child nodes for convenience
@onready var box = $Box #TODO: Have a list of objects to cycle through placing
@onready var raycast = $Camera3D/RayCast3D
@onready var area = $Camera3D/CameraArea

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#guarantees that the CameraArea is always in front of the camera
	area.position.z = area_distance * -1
	
	#gets 3D position and points raycast to that position
	var world_pos = get_mouse_world_pos()
	raycast.target_position = raycast.to_local(world_pos)
	
	#raycast hits CameraArea before it hits its final position
	#box is placed in the position of the collision
	#this solves the issue of the box always being a certain radius from the camera, making it easier to reliably place objects where expected
	var point = raycast.get_collision_point()
	point = point.round()
	box.global_position = point

#Converts the current mouse position to a point in 3D space
func get_mouse_world_pos() -> Vector3:
	var cam = get_viewport().get_camera_3d()
	var mp  = get_viewport().get_mouse_position()
	return (cam.project_ray_origin(mp) + cam.project_ray_normal(mp)) * 50.0
