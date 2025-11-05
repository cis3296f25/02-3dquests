extends Node3D

@onready var camera: Camera3D = $PlacerCamera
@onready var object: Node3D = $GhostObject

var min_pos: Vector3 = Vector3(-75, 0, -75)
var max_pos: Vector3 = Vector3(75, 10, 75)
func _ready() -> void:
	camera.set_to_place(object)

#NOT FINAL SOLUTION
func _process(delta: float) -> void:
	for child in get_children():
		if "position" in child and child != $Floor:
			child.position = child.position.clamp(min_pos, max_pos)

#gets info from ghost obj, adds child
func place_object():
	var props = object.get_properties()
	var new_obj: StaticBody3D = props["mesh"].instantiate()
	$Node3D.add_child(new_obj)
	new_obj.global_position = props["position"]
	new_obj.global_rotation = props["rotation"]
