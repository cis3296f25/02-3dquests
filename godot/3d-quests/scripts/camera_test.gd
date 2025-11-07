extends Node3D

@onready var camera: Camera3D = $PlacerCamera
@onready var object: Node3D = $GhostObject
@onready var main_ui = $UILayer/MainUIControl
@onready var object_menu = $UILayer/ObjectMenuControl

var can_place := false
var selected_object: Node3D = null

var min_pos: Vector3 = Vector3(-75, 0, -75)
var max_pos: Vector3 = Vector3(75, 10, 75)

func _ready() -> void:
	camera.set_to_place(object)
	main_ui.place_mode_changed.connect(_on_mode_changed)
	if object:
		object.visible = can_place
	object_menu.object_selected.connect(_on_object_changed)
	
func _on_mode_changed(enabled: bool) -> void:
	can_place = enabled
	print("Placement mode is now: ", enabled)
	if object:
		object.visible = enabled
		
func _on_object_changed(scene: PackedScene):
	object.set_mesh(scene)


#NOT FINAL SOLUTION
func _process(delta: float) -> void:
	for child in get_children():
		if "position" in child and child != $Floor:
			child.position = child.position.clamp(min_pos, max_pos)

#gets info from ghost obj, adds child
func place_object():
	var props = object.get_properties()
	var new_obj: Node3D = props["mesh"].instantiate()
	$Node3D.add_child(new_obj)
	new_obj.global_position = props["position"]
	new_obj.global_rotation = props["rotation"]
