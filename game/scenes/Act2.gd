extends StreetRoom

export(String, FILE, "*.tscn") var next_scene

onready var player := $YSort/RoomPlayer
onready var d2 := $CanvasLayer/D2
onready var ysort := $YSort


func _ready() -> void:
	pass


func _on_DialogPlayer_dialog_finished() -> void:
	player.set_locked(false)


func _on_MinigamesManager_do_event() -> void:
	d2.read()
	yield(d2, "dialog_finished")
	SceneHandler.goto_scene(next_scene)
