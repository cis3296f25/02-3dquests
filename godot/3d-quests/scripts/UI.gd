extends Control

signal place_mode_changed(enabled: bool)
signal save_button_pressed
signal load_button_pressed
signal open_menu_pressed


@onready var save_button = $PanelContainer/VBoxContainer/SaveButton
@onready var load_button = $PanelContainer/VBoxContainer/LoadButton
@onready var open_menu = $PanelContainer/VBoxContainer/OpenMenu
@onready var place_mode_label = $PanelContainer/VBoxContainer/PlaceModeLabel
@onready var snap_mode_label = $PanelContainer/VBoxContainer/SnapModeLabel
@onready var delete_obj_check = $PanelContainer/VBoxContainer/DeleteObjMode
@onready var save_system = get_parent().get_parent().get_node("SaveSystem")
@onready var camera = get_parent().get_parent().get_node("PlacerCamera")

var placement_mode_enabled := false
var delete_mode_enabled := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	save_button.disabled = placement_mode_enabled
	load_button.disabled = placement_mode_enabled
	open_menu.disabled = placement_mode_enabled
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	open_menu.pressed.connect(_on_open_menu_pressed)
	delete_obj_check.toggled.connect(_on_delete_mode_toggled)
	update_mode_label()
	update_snap_label(camera.snap)

func _on_save_pressed():
	save_button_pressed.emit()
	
func _on_load_pressed():
	load_button_pressed.emit()
	
func _on_open_menu_pressed():
	open_menu_pressed.emit()
	
func update_mode_label():
	var mode_text = "Placement" if placement_mode_enabled else "Edit"
	place_mode_label.text = "Mode: %s (Press P to toggle)" % mode_text

func update_snap_label(snap_enabled: bool):
	var snap_text = "ENABLED" if snap_enabled else "DISABLED"
	snap_mode_label.text = "Snap: %s (Press T to toggle)" % snap_text

func _on_delete_mode_toggled(button_pressed: bool):
	delete_mode_enabled = button_pressed
	if delete_obj_check.pressed:
		pass
		
var delete_mode_in_scope = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("toggle_place"):
		placement_mode_enabled = !placement_mode_enabled
		if placement_mode_enabled:
			delete_mode_in_scope = delete_mode_enabled
			delete_mode_enabled = false
		else:
			delete_mode_enabled = delete_mode_in_scope
		update_mode_label()
		save_button.disabled = placement_mode_enabled
		load_button.disabled = placement_mode_enabled
		open_menu.disabled = placement_mode_enabled
		delete_obj_check.disabled = placement_mode_enabled
		place_mode_changed.emit(placement_mode_enabled)
