extends Control

@onready var modal_window = $ObjectMenuWindow
@onready var grid = $ObjectMenuWindow/PanelContainer/ScrollContainer/GridContainer

signal object_selected(scene: PackedScene)

func open_inventory():
	modal_window.popup_centered()

func add_asset_buttons(asset_pack: Array[PackedScene]):
	
	for child in grid.get_children():
		child.queue_free()
	
	for asset in asset_pack:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(80, 80)
		btn.text = asset.resource_path.get_file().get_basename()
		btn.pressed.connect(Callable(self, "_on_asset_pressed").bind(asset))
		grid.add_child(btn)
	

func _on_asset_pressed(asset):
	emit_signal("object_selected", asset)
	modal_window.hide()

var asset_categorizer: AssetCategorizer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	modal_window.close_requested.connect(_on_modal_closed)
	asset_categorizer = AssetCategorizer.new()
	asset_categorizer.scan_and_categorize("res://")
	
	
	var wall_assets = asset_categorizer.get_assets_by_category("Wall")
	var scenes: Array[PackedScene] = []
	for path in wall_assets:
		var scene = load(path)
		if scene:
			scenes.append(scene)

	add_asset_buttons(scenes)
	
func _on_modal_closed():
	modal_window.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
