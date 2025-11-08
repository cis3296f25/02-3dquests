extends Node3D

@onready var camera: Camera3D = $PlacerCamera
@onready var object: Node3D = $GhostObject
@onready var main_ui = $UILayer/MainUIControl
@onready var object_menu = $UILayer/OpenMenuControl
@onready var object_menu_window = $UILayer/OpenMenuControl/OpenMenuWindow
@onready var save_system = $SaveSystem

var can_place := false

var min_pos: Vector3 = Vector3(-75, 0, -75)
var max_pos: Vector3 = Vector3(75, 10, 75)

func _ready() -> void:
	camera.set_to_place(object)
	main_ui.place_mode_changed.connect(_on_mode_changed)
	main_ui.save_button_pressed.connect(_save_button)
	main_ui.load_button_pressed.connect(_load_button)
	main_ui.open_menu_pressed.connect(_open_menu)
	object_menu.object_selected.connect(_select_object)
	save_system.load_obj.connect(_load_object)
	
#NOT FINAL SOLUTION
func _process(delta: float) -> void:
	for child in get_children():
		if "position" in child and child != $Floor:
			child.position = child.position.clamp(min_pos, max_pos)

func _on_mode_changed(enabled: bool) -> void:
	can_place = enabled
	print("Placement mode is now: ", enabled)

#gets info from ghost obj, adds child
func place_object():
	var props = object.get_properties()
	var new_obj: Node3D = props["mesh"].instantiate()
	add_child(new_obj)
	new_obj.global_position = props["position"]
	new_obj.global_rotation = props["rotation"]
	save_system.store_properties(props["position"],props["rotation"])

# Gets infro from file, adds child
func _load_object(pos: Vector3, rot: Vector3):
	var new_obj: StaticBody3D = object.get_properties()["mesh"].instantiate()
	add_child(new_obj)
	new_obj.global_position = pos
	new_obj.global_rotation = rot
	save_system.store_properties(pos, rot)

func _save_button() -> void:
	save_system.save()

func _load_button() -> void:
	save_system.load()
	
func _open_menu():
	object_menu_window.popup_centered()
	
func _select_object(scene: PackedScene):
	object.set_mesh(scene)
