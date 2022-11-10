extends Node2D

onready var dialog := $CanvasLayer/DialogPlayer
onready var player := $FoodTask/YSort/TopdownPlayer


#func _input(event: InputEvent) -> void:
#	if event.is_action_pressed("down"):
#		dialog.read(dialog.autoplay_dialog)
#		player.set_locked(true)


func _on_DialogPlayer_dialog_finished() -> void:
	player.set_locked(false)
