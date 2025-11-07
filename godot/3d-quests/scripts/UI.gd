extends Control

signal place_mode_changed(enabled: bool)
signal save_button_pressed
signal load_button_pressed


@onready var save_button = $PanelContainer/VBoxContainer/SaveButton
@onready var load_button = $PanelContainer/VBoxContainer/LoadButton
@onready var place_mode_label = $PanelContainer/VBoxContainer/PlaceModeLabel
@onready var save_system = $SaveSystem

var placement_mode_enabled := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	update_mode_label()

func _on_save_pressed():
	save_button_pressed.emit()
	

func _on_load_pressed():
	load_button_pressed.emit()
	
func update_mode_label():
	var mode_text = "Placement" if placement_mode_enabled else "View"
	place_mode_label.text = "Mode: %s (Press P to toggle)" % mode_text

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("toggle_place"):
		placement_mode_enabled = !placement_mode_enabled
		update_mode_label()
		place_mode_changed.emit(placement_mode_enabled)
