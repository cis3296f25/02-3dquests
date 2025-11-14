extends Control

signal object_selected(scene: PackedScene)

@onready var menu_window = $OpenMenuWindow
@onready var grid_container = $OpenMenuWindow/PanelContainer/ScrollContainer/GridContainer
@onready var asset_categorizer = AssetCategorizer.new()

func _ready():
	menu_window.close_requested.connect(_on_menu_closed)
	menu_window.hide()
	asset_categorizer.scan_and_categorize("res://assets")
	var object_scenes = asset_categorizer.get_all_categorized_assets()
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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
