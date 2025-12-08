extends Control

# Node references
@onready var edit_menu_button = $MenuBar/EditMenu
@onready var popup_panel = edit_menu_button.get_node("PopupPanel")
@onready var root = get_tree().root.get_child(0)
@onready var new_map_popup = $NewMapPopup
@onready var edit_menu_popup = $MenuBar/EditMenu/PopupPanel
@onready var load_map_popup = $LoadMapPopup


func _ready() -> void:
	# Open the popup when the MenuButton is pressed
	edit_menu_button.pressed.connect(popup_panel.open)  # PopupPanel script has an `open()` function

	# Connect signals from the PopupPanel
	popup_panel.save_button_pressed.connect(_on_save_pressed)
	popup_panel.load_button_pressed.connect(_on_load_pressed)
	popup_panel.new_button_pressed.connect(_on_new_pressed)
	popup_panel.open_menu_pressed.connect(_on_open_menu_pressed)
	
	# Connecting signals from NewMapPopup
	new_map_popup.new_map_created.connect(_on_map_created)
	
	# Connecting signals from LoadMapPopup
	load_map_popup.map_selected.connect(_on_map_load)


# ------------------------
# CALLBACKS FOR POPUP SIGNALS
# ------------------------

func _on_map_created(map_name: String):
	root.new_map(map_name)

func _on_new_pressed():
	edit_menu_popup.hide()
	new_map_popup.popup_centered()
	
func _on_save_pressed():
	print("Control detected Save pressed")
	# Your save logic here
	root.save_map()

func _on_load_pressed():
	print("Control detected Load pressed")
	edit_menu_popup.hide()
	load_map_popup.load_map_list(root.maps)
	load_map_popup.popup_centered()
	# Your load logic here
	
func _on_map_load(map_name: String):
	root.load_map(map_name)
	load_map_popup.hide()

func _on_open_menu_pressed():
	print("Control detected OpenMenu pressed")
	# Your open menu logic here

func _on_place_mode_changed(enabled: bool):
	print("Placement mode changed:", enabled)
	# Respond to mode toggle
