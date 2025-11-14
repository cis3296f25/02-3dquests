extends Node

var save_path = "user://map_data.save"
var obj_pos_array = []
var obj_rot_array = []
var obj_path_array = []
signal load_obj(pos: Vector3, rot: Vector3, path: String)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func store_properties(pos: Vector3, rot: Vector3, path: String):
	obj_pos_array.append(pos)
	obj_rot_array.append(rot)
	obj_path_array.append(path)

# Saves all placed objects
func save():
	var save_file = FileAccess.open(save_path, FileAccess.WRITE)
	
	save_file.store_var(obj_pos_array)
	save_file.store_var(obj_rot_array)
	save_file.store_var(obj_path_array)
	save_file.close()

# Loads objects from previous save 
func load():
	if FileAccess.file_exists(save_path):
		var save_file = FileAccess.open(save_path, FileAccess.READ)
		obj_pos_array = save_file.get_var()
		obj_rot_array = save_file.get_var()
		obj_path_array = save_file.get_var()
		for i in range(obj_pos_array.size()):
			load_obj.emit(obj_pos_array[i], obj_rot_array[i], obj_path_array[i])
	else:
		print("FILE LOAD ERROR: No data found.")
