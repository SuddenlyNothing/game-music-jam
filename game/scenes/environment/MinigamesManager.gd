class_name MinigamesManager
extends CanvasLayer

signal view_street(season)

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

export(int) var max_points := 100

export(Characters) var character
export(Array, String, MULTILINE) var hint_dialog
export(Array, String, MULTILINE) var reluctant_dialog

export(float) var max_mult := 1.5
export(float, 1) var difficulty_increment := 0.2
export(float, 1) var boredom_increment := 0.333333
export(float, 1) var boredom_decrement := 0.5

var interacting := false
var task_boredom := 0.0
var event_idx: int = -1

# task station | difficulty | boredom | showed hint
onready var tasks := {
	"food": [$FoodTask, 0, 0, false],
	"bed": [$FoodTask, 0, 0, false],
	"desk": [$PlatformerTask, 0, 0, false],
	"weights": [$WorkoutTask, 0, 0, false],
	"window": [self, 0, 0, false],
}
onready var score_renderer := $ScoreRenderer
onready var dialog := $DialogPlayer


func _ready() -> void:
	dialog.character = character
	score_renderer.set_new_bar(max_points)


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


func start_task(task: String) -> void:
	if interacting:
		return
	lock_room()
	if tasks[task][2] >= MAX_BOREDOM and not tasks[task][3]:
		# Tell player that they're bored of this task
		dialog.read(hint_dialog)
		tasks[task][3] = true
		yield(dialog, "dialog_finished")
		unlock_room()
	else:
		if tasks[task][3]:
			dialog.read(reluctant_dialog)
			tasks[task][3] = false
			yield(dialog, "dialog_finished")
		score_renderer.hide()
		tasks[task][0].start(tasks[task][1])
		task_boredom = tasks[task][2]
		tasks[task][1] = min(tasks[task][1] + difficulty_increment,
				MAX_DIFFICULTY)
		tasks[task][2] = min(tasks[task][2] + boredom_increment, MAX_BOREDOM)
		for t in tasks:
			if tasks[task][3]:
				tasks[task][3] = false
			if t == task:
				continue
			tasks[t][2] = max(tasks[t][2] - boredom_decrement, 0)


func finished_viewing_street() -> void:
	score_renderer.add_points(1, max_mult - task_boredom * max_mult)


func _on_Weights_interacted() -> void:
	start_task("weights")


func _on_Bed_interacted() -> void:
	start_task("bed")


func _on_Desk_interacted() -> void:
	start_task("desk")


func _on_Window_interacted() -> void:
	start_task("window")


func _on_Task_finished(points) -> void:
	score_renderer.add_points(points, max_mult - task_boredom * max_mult)


func _on_ScoreRenderer_added_points() -> void:
	unlock_room()


func _on_ScoreRenderer_max_points_reached() -> void:
	event_idx += 1
	do_event()
