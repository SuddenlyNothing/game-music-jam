extends Control

onready var buttons := $"%V"


func _ready() -> void:
	buttons.get_child(0).grab_focus()
