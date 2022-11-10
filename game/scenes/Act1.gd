extends StreetRoom

export(float) var season_dur := 2.0
export(float) var betwee_dur := 0.5

export(Array, Array, String, MULTILINE) var dialogs

onready var player_puppet := $PlayerPuppet
onready var door := $RoomElements/Door
onready var camera := $PlayerPuppet/Camera2D
onready var room_elements := $RoomElements
onready var dialog := $CanvasLayer/DialogPlayer

var seasons_t: SceneTreeTween


func _ready() -> void:
	seasons_t = create_tween().set_loops()
	seasons_t.tween_callback(self, "set_season", ["fall", season_dur])
	seasons_t.tween_interval(season_dur + betwee_dur)
	seasons_t.tween_callback(self, "set_season", ["winter", season_dur])
	seasons_t.tween_interval(season_dur + betwee_dur)
	seasons_t.tween_callback(self, "set_season", ["spring", season_dur])
	seasons_t.tween_interval(season_dur + betwee_dur)
	seasons_t.tween_callback(self, "set_season", ["summer", season_dur])
	seasons_t.tween_interval(season_dur + betwee_dur)


func start() -> void:
	if seasons_t:
		seasons_t.kill()
	set_season("summer", 2.0)
	var t := create_tween()
	t.tween_interval(2.5)
	t.tween_callback(player_puppet, "goto_next")
	t.tween_callback(dialog, "read", [dialogs[0]])
	t.tween_property(camera, "zoom", Vector2.ONE * 0.5, 0.3)
	t.tween_property(camera, "zoom", Vector2.ONE, 5.0)


func unlock_camera() -> void:
	camera.limit_bottom = 10000
	camera.limit_left = -10000
	camera.limit_right = 10000
	camera.limit_top = -10000


func _on_PlayerPuppet_reached_waypoint(waypoint_ind: int) -> void:
	match waypoint_ind:
		1:
			player_puppet.set_facing(Vector2.RIGHT)
			player_puppet.move_speed *= 2
			if dialog.has_dialog:
				yield(dialog, "dialog_finished")
		2:
			dialog.read(dialogs[1])
			yield(dialog, "dialog_finished")
		3:
			player_puppet.move_speed /= 2
			dialog.read(dialogs[2])
			yield(dialog, "dialog_finished")
		4:
			dialog.read(dialogs[3])
			yield(dialog, "dialog_finished")
			door.hide()
			var t := create_tween()
			t.tween_property(room_elements, "modulate", Color.white, 0.5)
		5:
			var t := create_tween()
			t.tween_property(outside, "modulate:a", 0.0, 0.5)
			player_puppet.z_index = 0
		6:
			door.show()
	player_puppet.goto_next()


func _on_PlayerPuppet_reached_last_waypoint() -> void:
	
	unlock_camera()
	player_puppet.remove_child(camera)
	add_child(camera)
	camera.position = Vector2(192, 128)
	var t := create_tween()
	t.tween_property(camera, "position", room_elements.position, 1.0)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	t.tween_callback(dialog, "read", [dialogs[4]])
	yield(dialog, "dialog_finished")


func _on_Menu_started() -> void:
	start()
