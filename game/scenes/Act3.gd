extends StreetRoom

export(String, FILE, "*.tscn") var next_scene
export(Array, String, MULTILINE) var friend_dialog

onready var ysort := $YSort
onready var window := $Outside/Cover/Window
onready var knock1 := $Knock1
onready var knock2 := $Knock2
onready var player_puppet := $PlayerPuppet
onready var particles_wall_cover := $YSort/ParticlesWallCover
onready var door := $YSort/RoomElements/Enterables/Door
onready var door_open_sfx := $DoorOpen
onready var dialog_player := $CanvasLayer/DialogPlayer


func _ready() -> void:
	yield(knock(), "completed")
	var t := create_tween().set_parallel()
	t.tween_property(ysort, "modulate:a", 1.0, 1.0)
	t.tween_property(window, "modulate:a", 1.0, 1.0)
	yield(t, "finished")
	
	dialog_player.read(friend_dialog)
	yield(dialog_player, "dialog_finished")
	
	particles_wall_cover.show()
	player_puppet.goto_next()
	yield(player_puppet, "reached_waypoint")
	
	yield(get_tree().create_timer(2.0, false), "timeout")
	door.hide()
	door_open_sfx.play()
	yield(get_tree().create_timer(1.4, false), "timeout")
	player_puppet.goto_next()
	yield(player_puppet, "reached_waypoint")
	
	player_puppet.lower_volume(10.0)
	player_puppet.z_index = 80
	player_puppet.outside = true
	player_puppet.goto_next()
	yield(player_puppet, "reached_last_waypoint")
	Variables.restarted = true
	SceneHandler.goto_scene(next_scene)


func knock(dur: float = 0.5) -> void:
	knock1.play()
	yield(get_tree().create_timer(dur, false), "timeout")
	knock2.play()
	yield(get_tree().create_timer(dur, false), "timeout")
