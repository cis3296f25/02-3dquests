extends PopupPanel

signal new_map_created(map_name: String)

@onready var create_button = $VBoxContainer/Create
@onready var cancel_button = $VBoxContainer/Cancel
@onready var input = $VBoxContainer/LineEdit


func _ready():
	create_button.pressed.connect(_on_confirm)
	cancel_button.pressed.connect(hide)

func _on_confirm():
	var map_name = input.text
	if map_name != "":
		new_map_created.emit(map_name)
		hide()
