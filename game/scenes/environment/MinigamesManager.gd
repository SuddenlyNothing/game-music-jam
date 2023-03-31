class_name MinigamesManager
extends CanvasLayer

signal do_event
signal view_street(season)
signal completed_task(points)

enum Characters {
	MC1 = 0,
	MC2 = 1,
	MC3 = 2,
	BOSS = 3,
	FRIEND = 4,
	MISC = 5,
}

const MAX_DIFFICULTY := 1
const MAX_BOREDOM := 1

export(bool) var has_boredom := true
export(bool) var has_difficulty := true
export(bool) var looked_outside := false

export(int) var max_points := 100

export(Characters) var character
export(Array, String, MULTILINE) var hint_dialog
export(Array, String, MULTILINE) var reluctant_dialog

export(float) var max_mult := 1.0
export(float, 1) var difficulty_increment := 0.3
export(float, 1) var boredom_increment := 1.0
export(float, 1) var boredom_decrement := 1.0
export(float, 1) var start_difficulty := 0.0

export(bool) var add_points := true

var interacting := false
var task_boredom := 0.0
var event_idx: int = -1

# task station
# difficulty | boredom | showed hint | diff inc | bore inc | bore dec
onready var tasks := {
	"food": [$FoodTask, start_difficulty, 0, false, 0.4, 0, 0],
	"bed": [$SleepTask, start_difficulty, 0, false, difficulty_increment,
			boredom_increment, boredom_decrement],
	"desk": [$PlatformerTask, start_difficulty, 0, false, difficulty_increment,
			boredom_increment, boredom_decrement],
	"weights": [$WorkoutTask, start_difficulty, 0, false, difficulty_increment,
			boredom_increment, boredom_decrement],
	"window": [self, start_difficulty, 0, false, difficulty_increment,
			boredom_increment, boredom_decrement],
}
onready var score_renderer := $ScoreRenderer
onready var dialog := $DialogPlayer
onready var start_sfx := $StartSFX

onready var indoor_sfx_idx := AudioServer.get_bus_index("SFX Indoor")
onready var outdoor_sfx_idx := AudioServer.get_bus_index("SFX Outdoor")


func _ready() -> void:
	dialog.character = character
	score_renderer.set_new_bar(max_points)
	score_renderer.do_multiply = has_boredom


func do_event() -> void:
	pass


func start(_difficulty: float) -> void:
	emit_signal("view_street", "")


func lock_room() -> void:
	interacting = true
	get_tree().call_group_flags(2, "room_player", "set_locked", true)
	get_tree().call_group_flags(2, "enterable", "set_hint_visible", false)


func unlock_room() -> void:
	interacting = false
	get_tree().call_group_flags(2, "room_player", "set_locked", false)
	get_tree().call_group_flags(2, "enterable", "set_hint_visible", true)


func start_task(task: String, mute: bool = true,
		force_difficulty: bool = false, diff: float = 0.0,
		force_start: bool = false) -> void:
	if interacting:
		return
	if mute:
		AudioServer.set_bus_mute(outdoor_sfx_idx, true)
		AudioServer.set_bus_mute(indoor_sfx_idx, true)
	lock_room()
	if tasks[task][2] >= MAX_BOREDOM and not tasks[task][3] and has_boredom \
			and not force_start:
		# Tell player that they're bored of this task
		dialog.read(hint_dialog)
		tasks[task][3] = true
		yield(dialog, "dialog_finished")
		unlock_room()
	else:
		if tasks[task][3] and not force_start:
			dialog.read(reluctant_dialog)
			tasks[task][3] = false
			yield(dialog, "dialog_finished")
		start_sfx.play()
		score_renderer.hide()
		if force_difficulty:
			tasks[task][0].start(diff)
		else:
			tasks[task][0].start(tasks[task][1])
		task_boredom = tasks[task][2]
		if has_difficulty or task == "food":
			tasks[task][1] = min(tasks[task][1] + tasks[task][4],
					MAX_DIFFICULTY)
		if has_boredom:
			tasks[task][2] = min(tasks[task][2] + tasks[task][5],
					MAX_BOREDOM)
			for t in tasks:
				if tasks[task][3]:
					tasks[task][3] = false
				if t == task:
					continue
				tasks[t][2] = max(tasks[t][2] - tasks[task][6], 0)


func stop_task(task: String) -> void:
	AudioServer.set_bus_mute(outdoor_sfx_idx, false)
	AudioServer.set_bus_mute(indoor_sfx_idx, false)
	tasks[task][0].stop()
	unlock_room()


func hide_score_renderer(duration: float) -> void:
	var t := get_tree().create_tween()
	t.tween_property(score_renderer, "rect_scale", Vector2.ONE * 1.25,
			duration / 2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	t.tween_property(score_renderer, "rect_scale", Vector2.ONE, duration / 2)\
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	t.parallel().tween_property(score_renderer, "modulate:a", 0.0, duration / 2)
	yield(t, "finished")


func finished_viewing_street() -> void:
	if looked_outside:
		_on_Task_finished(1)
	else:
		looked_outside = true
		_on_Task_finished(20)


func _on_Weights_interacted() -> void:
	start_task("weights")


func _on_Bed_interacted() -> void:
	start_task("bed", false)


func _on_Desk_interacted() -> void:
	start_task("desk")


func _on_Window_interacted() -> void:
	start_task("window", false)


func _on_Task_finished(points: int) -> void:
	AudioServer.set_bus_mute(indoor_sfx_idx, false)
	AudioServer.set_bus_mute(outdoor_sfx_idx, false)
	if add_points:
		if has_boredom:
			score_renderer.add_points(points,
					stepify(max_mult - task_boredom * max_mult, 0.1))
		else:
			score_renderer.add_points(points, max_mult)
	else:
		emit_signal("completed_task", score_renderer.points)


func _on_ScoreRenderer_added_points() -> void:
	unlock_room()
	emit_signal("completed_task", score_renderer.points)


func _on_ScoreRenderer_max_points_reached() -> void:
	event_idx += 1
	unlock_room()
	do_event()
	emit_signal("do_event")
