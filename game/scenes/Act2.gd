extends StreetRoom

export(String, FILE, "*.tscn") var next_scene
export(Array, String, MULTILINE) var start_dialog

var eating := false
var ate_start := false
var food_finish_dialog := false

onready var player := $YSort/RoomPlayer
onready var d2 := $CanvasLayer/D2
onready var ysort := $YSort
onready var camera := $Camera2D
onready var room_elements := $YSort/RoomElements
onready var dialog_player := $CanvasLayer/DialogPlayer
onready var minigames_manager := $MinigamesManager


func _ready() -> void:
	set_season("fall", 0.0)
	var d: Node = Dialogic.start("food1_2")
	d.connect("dialogic_signal", self, "dialogic_signal")
	d.connect("timeline_end", self, "timeline_end")
	var t := create_tween().set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_IN_OUT)
	t.tween_interval(1.0)
	t.tween_callback(self, "set_season", ["winter", 2])
	t.tween_interval(3.0)
	t.tween_property(cover, "modulate:a", 1.0, 0.5)
	t.parallel().tween_property(ysort, "modulate:a", 1.0, 0.5)
	t.parallel().tween_callback(self, "set_outdoor", [false, 0.5])
	t.tween_property(camera, "position", room_elements.position, 1)
	t.tween_callback(self, "add_child", [d])


func _on_MinigamesManager_do_event() -> void:
	d2.read()
	yield(d2, "dialog_finished")
	SceneHandler.goto_scene(next_scene)


func dialogic_signal(val: String) -> void:
	match val:
		"food":
			eating = true
			minigames_manager.start_task("food")


func timeline_end(timeline: String) -> void:
	if eating:
		return
	player.set_disabled(false)


func _on_MinigamesManager_completed_task(points) -> void:
	eating = false
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
	elif eating:
		pass
	eating = false


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
