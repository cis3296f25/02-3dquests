extends PopupPanel

signal button_pressed

@onready var button = $VBoxContainer/HowTo

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	button.pressed.connect(_on_button_pressed)

func open():
	popup()

func _on_button_pressed():
	button_pressed.emit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
