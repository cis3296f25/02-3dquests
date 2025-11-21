extends Control

signal place_mode_changed(enabled: bool)
signal save_button_pressed
signal load_button_pressed
signal open_menu_pressed

var placement_mode_enabled := false
var delete_mode_enabled := false
var delete_mode_in_scope := false

@onready var popup: PopupMenu = $MenuBar/YourMenuButton/PopupMenu
@onready var save_system = get_parent().get_parent().get_node("SaveSystem")

func _ready() -> void:
	# Clear and rebuild menu items
	popup.clear()

	popup.add_item("Save", 0)
	popup.add_item("Load", 1)
	popup.add_item("Open Menu", 2)
	popup.add_separator()
	popup.add_check_item("Delete Mode", 3)
	popup.add_separator()
	popup.add_item("Toggle Placement Mode (P)", 4)

	# Connect signals
	popup.id_pressed.connect(_on_menu_item_selected)

	update_menu_state()


func _on_menu_item_selected(id: int) -> void:
	match id:
		0:
			save_button_pressed.emit()
		1:
			load_button_pressed.emit()
		2:
			open_menu_pressed.emit()
		3:
			delete_mode_enabled = popup.is_item_checked(3)
		4:
			_toggle_placement_mode()


func _toggle_placement_mode():
	placement_mode_enabled = !placement_mode_enabled
	
	if placement_mode_enabled:
		delete_mode_in_scope = delete_mode_enabled
		delete_mode_enabled = false
		popup.set_item_checked(3, false)
	else:
		delete_mode_enabled = delete_mode_in_scope
		popup.set_item_checked(3, delete_mode_enabled)

	place_mode_changed.emit(placement_mode_enabled)
	update_menu_state()


func update_menu_state():
	# Disable items during placement mode
	var disabled_state = placement_mode_enabled

	popup.set_item_disabled(0, disabled_state) # Save
	popup.set_item_disabled(1, disabled_state) # Load
	popup.set_item_disabled(2, disabled_state) # Open Menu
	popup.set_item_disabled(3, disabled_state) # Delete Mode checkbox

	# Update mode label (optional: rename item)
	var mode_text = "Placement" if placement_mode_enabled else "Edit"
	popup.set_item_text(4, "Switch Mode (Current: %s)" % mode_text)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle_place"):
		_toggle_placement_mode()
