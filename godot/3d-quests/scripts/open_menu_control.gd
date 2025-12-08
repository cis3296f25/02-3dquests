extends Control

signal object_selected(scene: PackedScene)

@onready var menu_window = $OpenMenuWindow
@onready var grid_container = $OpenMenuWindow/PanelContainer/ScrollContainer/GridContainer
@onready var asset_categorizer = AssetCategorizer.new()

func _ready():
	menu_window.close_requested.connect(_on_menu_closed)
	menu_window.hide()
	var object_scenes = load_asset_json()
	for category in object_scenes.keys():
		var asset_list = object_scenes[category]
		
		for asset_path in asset_list:
			var scene = load(asset_path)
			if scene:
				var button = Button.new()
				button.text = "%s" % asset_path.get_file().get_basename()
				button.pressed.connect(func(): _on_button_pressed(scene))
				grid_container.add_child(button)


func _on_button_pressed(scene: PackedScene):
	object_selected.emit(scene)
	menu_window.hide()

func _on_menu_closed():
	menu_window.hide()
	
func load_asset_json() -> Dictionary:
	var file_path = "res://assets/asset_list.json"
	if not FileAccess.file_exists(file_path):
		push_error("asset_list.json not found!")
		return {}
	var text = FileAccess.get_file_as_string(file_path)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid asset_list.json format")
		return {}
	return parsed
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
