extends Node3D
@export var ghost_mesh: PackedScene

func _ready() -> void:
	if ghost_mesh:
		set_mesh(ghost_mesh)

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
		"rotation": self.global_rotation
	}
	
	return properties
