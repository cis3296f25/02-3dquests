extends Node3D

@onready var camera: Camera3D = $PlacerCamera
@onready var object: StaticBody3D = $Object

func _ready() -> void:
	camera.set_to_place(object)
