extends Node3D
@export var ghost_mesh: PackedScene

func _ready() -> void:
	if ghost_mesh:
		set_mesh(ghost_mesh)

func _process(delta: float) -> void:
	var rotation_speed = 90 # degrees per second
	if Input.is_action_pressed("rotate_left"):
		rotate_y(deg_to_rad(rotation_speed * delta))
	if Input.is_action_pressed("rotate_right"):
		rotate_y(deg_to_rad(-rotation_speed * delta))
	if Input.is_action_pressed("rotate_up"):
		rotate_object_local(Vector3(1,0,0), deg_to_rad(rotation_speed * delta))
	if Input.is_action_pressed("rotate_down"):
		rotate_object_local(Vector3(1,0,0), deg_to_rad(-rotation_speed * delta))

#set the mesh that will be replicated by the ghost
func set_mesh(mesh: PackedScene):
	#remove any previous mesh
	for child in get_children():
		child.queue_free()
	#Add new mesh (disable collision, will enable again upon placement)
	var new_child = mesh.instantiate()
	var col = new_child.get_node("CollisionShape3D")
	if col: col.disabled = true
	add_child(new_child)
	ghost_mesh = mesh

# return a dictionary of properties, called when placing, will tell where to place what object
func get_properties() -> Dictionary:
	var properties = {
		"mesh": ghost_mesh,
		"position": self.global_position,
		"rotation": self.global_rotation,
		"path": ghost_mesh.resource_path
	}
	
	return properties
