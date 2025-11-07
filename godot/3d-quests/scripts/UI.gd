extends Control

signal place_mode_changed(enabled: bool)

@onready var save_button = $PanelContainer/VBoxContainer/SaveButton
@onready var load_button = $PanelContainer/VBoxContainer/LoadButton
@onready var open_object_menu_button = $PanelContainer/VBoxContainer/OpenObjectMenuButton
@onready var place_mode_label = $PanelContainer/VBoxContainer/PlaceModeLabel
@onready var object_menu_control = get_parent().get_node("ObjectMenuControl")

var placement_mode_enabled := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	open_object_menu_button.pressed.connect(_on_open_menu_pressed)
	update_mode_label()
	object_menu_control.object_selected.connect(Callable(self, "_on_asset_selected"))


func _on_save_pressed():
	print("save")

func _on_load_pressed():
	print("load")
	
func _on_open_menu_pressed():
	object_menu_control.open_inventory()
	
func update_mode_label():
	var mode_text = "Placement" if placement_mode_enabled else "View"
	place_mode_label.text = "Mode: %s (Press P to toggle)" % mode_text

func _on_asset_selected(asset_scene: PackedScene):
	print("Selected asset: ", asset_scene)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("toggle_place"):
		placement_mode_enabled = !placement_mode_enabled
		update_mode_label()
		place_mode_changed.emit(placement_mode_enabled)
