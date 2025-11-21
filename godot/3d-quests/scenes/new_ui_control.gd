extends Control

# Node references
@onready var edit_menu_button = $MenuBar/EditMenu
@onready var popup_panel = edit_menu_button.get_node("PopupPanel")


func _ready() -> void:
	# Open the popup when the MenuButton is pressed
	edit_menu_button.pressed.connect(popup_panel.open)  # PopupPanel script has an `open()` function

	# Connect signals from the PopupPanel
	popup_panel.save_button_pressed.connect(_on_save_pressed)
	popup_panel.load_button_pressed.connect(_on_load_pressed)
	popup_panel.open_menu_pressed.connect(_on_open_menu_pressed)


# ------------------------
# CALLBACKS FOR POPUP SIGNALS
# ------------------------

func _on_save_pressed():
	print("Control detected Save pressed")
	# Your save logic here

func _on_load_pressed():
	print("Control detected Load pressed")
	# Your load logic here

func _on_open_menu_pressed():
	print("Control detected OpenMenu pressed")
	# Your open menu logic here

func _on_place_mode_changed(enabled: bool):
	print("Placement mode changed:", enabled)
	# Respond to mode toggle
