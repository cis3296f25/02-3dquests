extends Control

# Node references
@onready var edit_menu_button = $MenuBar/EditMenu
@onready var gm_menu_button = $MenuBar/GmMenu
@onready var controls_menu_button = $MenuBar/ControlsMenu
@onready var mp_menu_button = $MenuBar/MultiplayerMenu
@onready var meas_menu_button = $MenuBar/MeasureMenu

@onready var edit_popup_panel = edit_menu_button.get_node("PopupPanel")
@onready var gm_popup_panel = gm_menu_button.get_node("PopupPanel")
@onready var controls_popup_panel = controls_menu_button.get_node("PopupPanel")
@onready var mp_popup_panel = mp_menu_button.get_node("PopupPanel")
@onready var meas_popup_panel = meas_menu_button.get_node("PopupPanel")


func _ready() -> void:
	# Open the popup when the MenuButton is pressed
	edit_menu_button.pressed.connect(edit_popup_panel.open)  # PopupPanel script has an `open()` function
	gm_menu_button.pressed.connect(gm_popup_panel.open)
	controls_menu_button.pressed.connect(controls_popup_panel.open)
	mp_menu_button.pressed.connect(mp_popup_panel.open)
	meas_menu_button.pressed.connect(meas_popup_panel.open)

	# Connect signals from the PopupPanel
	edit_popup_panel.save_button_pressed.connect(_on_save_pressed)
	edit_popup_panel.load_button_pressed.connect(_on_load_pressed)
	edit_popup_panel.open_menu_pressed.connect(_on_open_menu_pressed)


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
