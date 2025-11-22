extends Node3D

@onready var parent = get_parent()
@onready var camera: Camera3D = get_parent().get_node("PlacerCamera")
@onready var object: Node3D = $GhostObject
@onready var main_ui = get_parent().get_node("UILayer/NewUIControl/MenuBar/EditMenu/PopupPanel")
@onready var object_menu = get_parent().get_node("UILayer/OpenMenuControl")
@onready var object_menu_window = get_parent().get_node("UILayer/OpenMenuControl/OpenMenuWindow")
@onready var save_system = get_parent().get_node("SaveSystem")
@onready var props_container = get_parent().get_node("PropsContainer")

var can_place := false

var min_pos: Vector3 = Vector3(-75, 0, -75)
var max_pos: Vector3 = Vector3(75, 10, 75)

func _ready() -> void:
	camera.set_to_place(object)
	main_ui.place_mode_changed.connect(_on_mode_changed)
	main_ui.save_button_pressed.connect(_save_button)
	main_ui.load_button_pressed.connect(_load_button)
	main_ui.open_menu_pressed.connect(_open_menu)
	main_ui.close_button_pressed.connect(_close_button)
	object_menu.object_selected.connect(_select_object)
	save_system.load_obj.connect(_load_object)
	
#NOT FINAL SOLUTION
func _process(delta: float) -> void:
	for child in get_children():
		if "position" in child and child != get_parent().get_node("Floor"):
			child.position = child.position.clamp(min_pos, max_pos)
	if can_place:
		object.visible = true
	else:
		object.visible = false

func _on_mode_changed(enabled: bool) -> void:
	can_place = enabled
	print("Placement mode is now: ", enabled)

#gets info from ghost obj, adds child
func place_object():
	var props = object.get_properties()
	parent.place_object(
		props["mesh"].resource_path,
		props["position"],
		props["rotation"]
	)
	save_system.store_properties(props["position"],props["rotation"], props["path"])
	
func _add_collision_recursive(node: Node3D) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			if not child.get_node_or_null("CollisionShape3D"):
				var body = StaticBody3D.new()
				body.name = "StaticBody3D"

				var shape = CollisionShape3D.new()
				shape.name = "CollisionShape3D"
				shape.shape = child.mesh.create_trimesh_shape() # accurate collision

				# Reparent child under StaticBody3D
				var original_parent = child.get_parent()
				original_parent.remove_child(child)
				body.add_child(child)
				body.add_child(shape)

				# Add StaticBody3D to the original parent
				original_parent.add_child(body)
				
				# Add to pickable group
				body.add_to_group("Pickable")
		else:
			_add_collision_recursive(child)

# Gets infro from file, adds child
func _load_object(pos: Vector3, rot: Vector3, path: String):
	if load(path) != null:
		parent.place_object(path, pos, rot)
		save_system.store_properties(pos, rot, path)

func _save_button() -> void:
	save_system.save()

func _load_button() -> void:
	save_system.load()
	
func _open_menu():
	object_menu_window.popup_centered()
	
func _select_object(scene: PackedScene):
	object.set_mesh(scene)

func _close_button() -> void:
	$"../UILayer/NewUIControl/MenuBar/EditMenu/PopupPanel".hide()
