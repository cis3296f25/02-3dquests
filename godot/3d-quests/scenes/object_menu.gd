extends Control

@onready var modal_window = $ObjectMenuWindow

signal object_selected(scene: PackedScene)

func open_inventory():
	modal_window.popup_centered()

func add_asset_buttons(asset_pack: Array[PackedScene]):
	var grid = modal_window/ScrollContainer/GridContainer
	
	for child in grid.get_children():
		child.queue_free()
	
	for asset in asset_pack:
		var btn = Button.new()
		btn.text = asset.resource_path.get_file().get_basename()
		btn.pressed.connect(Callable(self, "_on_asset_pressed").bind(asset))
		grid.add_child(btn)

func _on_asset_pressed(asset):
	emit_signal("object_selected", asset)
	modal_window.hide()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#modal_window.close_requested(modal_window.hide)
	pass

func _on_modal_closed():
	modal_window.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
