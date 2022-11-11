extends StreetRoom

const RoomPlayer := preload("res://scenes/characters/players/RoomPlayer.tscn")

export(float) var season_dur := 1.0
export(float) var betwee_dur := 1.5

export(Array, Array, String, MULTILINE) var dialogs

onready var player_puppet := $YSort/PlayerPuppet
onready var door := $YSort/RoomElements/Door
onready var camera := $YSort/PlayerPuppet/Camera2D
onready var room_elements := $YSort/RoomElements
onready var dialog := $CanvasLayer/DialogPlayer
onready var ysort := $YSort
onready var minigames_manager := $MinigamesManager
onready var hint := $Hint

var seasons_t: SceneTreeTween


func _ready() -> void:
	get_tree().call_group("sprite_select", "set_disabled", true)
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
	var t := create_tween().set_ease(Tween.EASE_IN_OUT)\
			.set_trans(Tween.TRANS_QUAD)
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


func view_street(season: String) -> void:
	var t := create_tween().set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)
	t.tween_property(camera, "position", Vector2(192, 128), 0.5)\
			.set_ease(Tween.EASE_OUT)
	t.tween_callback(self, "set_outdoor", [true, 0.5])
	t.tween_property(cover, "modulate:a", 0.0, 0.5)
	t.parallel().tween_property(room_elements, "modulate",
			Color("#0000"), 0.5)
	t.tween_callback(cover, "hide")
	if season:
		t.tween_callback(self, "set_season", [season, 1.5])
		t.tween_interval(2.0)
	t.tween_interval(1.0)
	t.tween_callback(cover, "show")
	t.tween_callback(self, "set_outdoor", [false, 0.5])
	t.tween_property(cover, "modulate:a", 1.0, 0.5)
	t.parallel().tween_property(room_elements, "modulate",
			Color.white, 0.5)
	t.tween_property(camera, "position", camera.position, 0.5)
	t.tween_callback(minigames_manager, "finished_viewing_street")


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
			door_sfx.play()
			player_puppet.outside = false
			var t := create_tween()
			t.tween_property(room_elements, "modulate", Color.white, 0.5)
		5:
			var t := create_tween()
			t.tween_callback(cover, "show")
			t.tween_callback(self, "set_outdoor", [false, 0.5])
			t.tween_property(cover, "modulate:a", 1.0, 0.5)
			play_indoor_sfx()
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
	hint.start()


func _on_Menu_started() -> void:
	start()


func _on_MinigamesManager_view_street(season: String) -> void:
	view_street(season)


func _on_Hint_completed() -> void:
	get_tree().call_group("sprite_select", "set_disabled", false)
	var room_player := RoomPlayer.instance()
	room_player.position = player_puppet.position
	room_player.z_index = player_puppet.z_index
	player_puppet.queue_free()
	ysort.add_child(room_player)
