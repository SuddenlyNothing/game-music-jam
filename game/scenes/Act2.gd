extends StreetRoom

const PlayerPuppet := preload(
	"res://scenes/characters/puppets/PlayerPuppet.tscn")

export(String, FILE, "*.tscn") var next_scene
export(Array, String, MULTILINE) var start_dialog
export(Array, Array, String, MULTILINE) var food_dialog

var eating := false
var ate_start := false
var food_finish_dialog := false
var montage_started := false
var player_puppet: Node
var was_eating := false

onready var player := $YSort/RoomPlayer
onready var ysort := $YSort
onready var camera := $Camera2D
onready var room_elements := $YSort/RoomElements
onready var dialog_player := $CanvasLayer/DialogPlayer
onready var minigames_manager := $MinigamesManager
onready var fade := $CanvasLayer/Fade
onready var knock1 := $Knock1
onready var knock2 := $Knock2
onready var desk_enterable := $YSort/RoomElements/Enterables/Desk
onready var weights_enterable := $YSort/RoomElements/Enterables/Weights
onready var waypoints := $Waypoints


func _ready() -> void:
	set_season("fall", 0.0)
	play_montage()
#	set_season("fall", 0.0)
#	var d: Node = Dialogic.start("food1_2")
#	d.connect("dialogic_signal", self, "dialogic_signal")
#	d.connect("timeline_end", self, "timeline_end")
#	var t := create_tween().set_trans(Tween.TRANS_QUAD)\
#			.set_ease(Tween.EASE_IN_OUT)
#	t.tween_interval(1.0)
#	t.tween_callback(self, "set_season", ["winter", 2])
#	t.tween_interval(3.0)
#	t.tween_property(cover, "modulate:a", 1.0, 0.5)
#	t.parallel().tween_property(ysort, "modulate:a", 1.0, 0.5)
#	t.parallel().tween_callback(self, "set_outdoor", [false, 0.5])
#	t.tween_property(camera, "position", room_elements.position, 1)
#	t.tween_callback(self, "add_child", [d])


func play_montage() -> void:
	montage_started = true
	yield(get_tree(), "idle_frame")
	exit_enterables()
	player_puppet = PlayerPuppet.instance()
	player_puppet.waypoints_path = waypoints.get_path()
	player_puppet.position = player.position
	player_puppet.start_left = player.player_puppet.scale.x < 0
	player.free()
	ysort.add_child(player_puppet)
	
	# Fade out in
	fade.show()
	var t := create_tween()
	t.tween_interval(1.0)
	t.tween_property(fade, "modulate:a", 1.0, 1.0)
	t.tween_callback(cover, "set_modulate", [Color.transparent])
	t.tween_callback(ysort, "set_modulate", [Color.transparent])
	t.tween_callback(camera, "set_position", [Vector2(192, 128)])
	t.tween_property(fade, "modulate:a", 0.0, 1.0)
	yield(t, "finished")
	
#	# Season change
#	dialog_player.read_line(
#		["Time is flying by so fast. Is it because I'm having fun?"], 1)
#	yield(view_season_change_to("spring"), "completed")
#
#	# Workout
#	dialog_player.read_line(["That can't be it... I feel miserable."])
#	yield(montage_task("weights", 10.0), "completed")
#
#	# Food Inturrupt
#	yield(knock(), "completed")
#	dialog_player.read_line(["The only thing I enjoy is sleep and food."])
#	yield(montage_task("food", 9.0), "completed")
#
#	# Platformer
#	dialog_player.read_line(
#		["I play games all day to bide time, but " + \
#		"I don't enjoy them like I used to"]
#	)
#	yield(montage_task("desk", 8.0), "completed")
#
#	# Food Inturrupt
#	yield(knock(0.4), "completed")
#	dialog_player.read_line(["I feel so sluggish. Everything is exhausting. "])
#	yield(montage_task("food", 7.0), "completed")
#
#	# Change season
#	yield(view_season_change_to("summer", 1.7), "completed")
#
#	# Food
#	yield(knock(0.3), "completed")
#	yield(montage_task("food", 6.0), "completed")
#
#	# Workout
#	yield(montage_task("weights", 5.0), "completed")
#
#	# Change season
#	yield(view_season_change_to("fall", 1.4), "completed")
#
#	# Food
#	yield(knock(0.2), "completed")
#	yield(montage_task("food", 4.0), "completed")
#
#	# Change season
#	yield(view_season_change_to("winter", 1.1), "completed")
#
#	# Desk
#	yield(montage_task("desk", 3.0), "completed")
#
#	# Change season
#	yield(view_season_change_to("spring", 0.8), "completed")
#
#	# Food
#	yield(knock(0.1), "completed")
#	yield(montage_task("food", 2.0), "completed")
#
#	# Change season
#	yield(view_season_change_to("summer", 0.5), "completed")
#
#	# Workout
#	yield(montage_task("weights", 2.0), "completed")
#
#	# Desk
#	yield(montage_task("desk", 2.0), "completed")
#
#	# Food
#	yield(knock(0.1), "completed")
#	yield(montage_task("food", 2.0), "completed")
	
	var dur = 3.0
	var season = "fall"
	player_puppet.set_act("3")
	player_puppet.set_facing(Vector2.LEFT)
	player_puppet.goto_next()
	yield(player_puppet, "reached_waypoint")
	
	t = create_tween()
	t.tween_property(camera, "position", Vector2(192, 128), dur / 2)
	t.tween_property(cover, "modulate:a", 0.0, dur / 4)
#	t.parallel().tween_property(ysort, "modulate:a", 0.0, 0.5)
	t.parallel().tween_callback(self, "set_outdoor", [true, 0.5])
	t.tween_callback(self, "set_season", [season, dur])
	t.tween_interval(dur * 1.5)
	t.tween_property(cover, "modulate:a", 1.0, dur / 4)
	t.parallel().tween_property(ysort, "modulate:a", 1.0, dur / 4)
	t.parallel().tween_callback(self, "set_outdoor", [false, dur / 4])
	t.tween_property(camera, "position", room_elements.position, dur / 2)
	t.tween_interval(dur / 2)
	yield(t, "finished")
	dialog_player.read_line([
		"Hello World"
	])
	
#	SceneHandler.goto_scene(next_scene)


func dialogic_signal(val: String) -> void:
	match val:
		"food":
			eating = true
			minigames_manager.start_task("food")


func timeline_end(timeline: String) -> void:
	if eating:
		return
	player.set_disabled(false)


func _on_MinigamesManager_completed_task(points: int) -> void:
	if montage_started:
		return
	if not ate_start:
		player.set_disabled(true)
		ate_start = true
		dialog_player.read(start_dialog)
		yield(dialog_player, "dialog_finished")
		minigames_manager.start_task("food")
	elif not food_finish_dialog:
		player.set_disabled(true)
		food_finish_dialog = true
		dialog_player.read([
			"That's much better"
		])
		yield(dialog_player, "dialog_finished")
		player.set_disabled(false)
	elif not was_eating:
		was_eating = true
		player.set_disabled(true)
		dialog_player.read(food_dialog[Variables.rng.randi_range(0,
				len(food_dialog) - 1)])
		yield(dialog_player, "dialog_finished")
		eating = true
		minigames_manager.start_task("food")
	else:
		was_eating = false
	eating = false


func view_season_change_to(season: String, dur: float = 2.0) -> void:
	print("Change to season: ", season)
	var t := create_tween()
	t.tween_property(camera, "position", Vector2(192, 128), dur / 2)
	t.tween_property(cover, "modulate:a", 0.0, dur / 4)
	t.parallel().tween_property(ysort, "modulate:a", 0.0, 0.5)
	t.parallel().tween_callback(self, "set_outdoor", [true, 0.5])
	t.tween_callback(self, "set_season", [season, dur])
	t.tween_interval(dur * 1.5)
	t.tween_property(cover, "modulate:a", 1.0, dur / 4)
	t.parallel().tween_property(ysort, "modulate:a", 1.0, dur / 4)
	t.parallel().tween_callback(self, "set_outdoor", [false, dur / 4])
	t.tween_property(camera, "position", room_elements.position, dur / 2)
	t.tween_interval(dur / 2)
	yield(t, "finished")


func montage_task(task: String, dur: float) -> void:
	print("Montage task: ", task)
	player_puppet.hide()
	match task:
		"desk":
			desk_enterable.show_inside("2")
		"weights":
			weights_enterable.show_inside("2")
	minigames_manager.start_task(task, true, false, 0.0, true)
	yield(get_tree().create_timer(dur, false), "timeout")
	player_puppet.show()
	minigames_manager.stop_task(task)
	match task:
		"desk":
			desk_enterable.exit()
		"weights":
			weights_enterable.exit()


func knock(dur: float = 0.5) -> void:
	knock1.play()
	yield(get_tree().create_timer(dur, false), "timeout")
	knock2.play()
	yield(get_tree().create_timer(dur, false), "timeout")


func _on_MinigamesManager_view_street(season) -> void:
	view_street(season)


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


func _on_MinigamesManager_do_event() -> void:
	play_montage()
