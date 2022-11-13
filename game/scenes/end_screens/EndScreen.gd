extends Control

onready var focus := $M/PanelContainer/V/V


func _ready() -> void:
	focus.get_child(0).grab_focus()
