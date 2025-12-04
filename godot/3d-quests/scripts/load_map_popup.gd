extends PopupPanel

signal map_selected(name: String)

@onready var map_name_list = $VBoxContainer/MapNameList
@onready var cancel = $VBoxContainer/Cancel
@onready var confirm = $VBoxContainer/Confirm

func load_map_list(maps: Array[String]):
	map_name_list.clear()
	for m in maps:
		map_name_list.add_item(m, null, true)

func _ready():
	confirm.pressed.connect(_on_load_pressed)
	cancel.pressed.connect(hide)

func _on_load_pressed():
	var idx = map_name_list.get_selected_items()
	if idx.size() > 0:
		map_selected.emit(map_name_list.get_item_text(idx[0]))
		hide()
