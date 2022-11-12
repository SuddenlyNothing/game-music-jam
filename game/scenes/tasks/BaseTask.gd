class_name BaseTask
extends Task

const BarParticles := preload("res://scenes/tasks/BarParticles.tscn")

export(bool) var testing := false

export(float) var max_shake_time := 1.5
export(float) var increment_shake_intensity := 0.2
export(float) var max_shake_offset := 10.0

var score := 0
var t: SceneTreeTween
var score_t: SceneTreeTween
var bar_particle_settings := {
	"lifetime": [0.1, 2],
	"initial_velocity": [0, 100],
	"scale_amount": [1, 2],
}
var diff: float

onready var score_label: Label = $"%ScoreLabel"
onready var pc: PanelContainer = $"%PC"
onready var shake_timer := $ShakeTimer
onready var score_label_position: Vector2 = score_label.rect_position
onready var play_timer := $PlayTimer
onready var bar_particles: CPUParticles2D
onready var time_progress := $M/M2/TimeProgress
onready var hint := $Hint
onready var times_up_sfx := $TimesUpSFX
onready var riser_sfx := $RiserSFX
onready var riser_timer := $RiserTimer


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_focus_next") and testing:
		Variables.rng.randomize()
		start(Variables.rng.randf())


func _process(delta: float) -> void:
	if not shake_timer.is_stopped():
		score_label.rect_position = Vector2(
			Variables.rng.randf_range(-max_shake_offset, max_shake_offset),
			Variables.rng.randf_range(-max_shake_offset, max_shake_offset)
		) * shake_timer.time_left / max_shake_time + score_label_position
	if not play_timer.is_stopped():
		var weight: float = 1.0 - play_timer.time_left / play_timer.wait_time
		for setting in bar_particle_settings:
			var vals = bar_particle_settings[setting]
			bar_particles[setting] = lerp(vals[0], vals[1], weight)
		time_progress.value = weight
		bar_particles.position.x = lerp(
				2, time_progress.rect_size.x - 2, weight)


# Start minigame with difficulty 0-1
func start(difficulty: float) -> void:
	diff = difficulty
	play_timer.stop()
	time_progress.value = 0
	if bar_particles and is_instance_valid(bar_particles):
		bar_particles.queue_free()
	score = 0
	score_label.text = "0"
	show()
	if t:
		t.kill()
	modulate.a = 0
	pc.rect_scale = Vector2()
	pc.rect_pivot_offset = pc.rect_size / 2
	t = create_tween().set_parallel().set_ease(Tween.EASE_OUT)
	t.tween_property(pc, "rect_scale", Vector2.ONE, start_dur).from(Vector2())\
			.set_trans(Tween.TRANS_BACK)
	t.tween_property(self, "modulate:a", 1.0, start_dur)\
			.set_trans(Tween.TRANS_QUAD)
	t.chain().tween_callback(hint, "start")


func add_score() -> void:
	score += 1
	score_label.text = str(score)
	var shake_time := min(shake_timer.time_left + increment_shake_intensity,
			max_shake_time)
	shake_timer.start(shake_time)
	if score_t:
		score_t.kill()
	score_t = create_tween()
	score_t.tween_property(score_label, "modulate", Color.white,
			shake_time).from(Color('c85a12'))


func remove_score() -> void:
	score = max(score - 1, 0)
	score_label.text = str(score)


# Override
func init(difficulty: float) -> void:
	pass


# Override
func wait_stop() -> void:
	pass


# Stop abruptly
# Hide and free everything
func stop() -> void:
	hide()
	bar_particles.queue_free()


func _on_ShakeTimer_timeout() -> void:
	score_label.rect_position = score_label_position


func _on_PlayTimer_timeout() -> void:
	times_up_sfx.play()
	if t:
		t.kill()
	wait_stop()
	t = create_tween()
	t.tween_interval(1)
	t.tween_property(self, "modulate:a", 0.0, end_dur)
	t.set_parallel()
	t.tween_property(pc, "rect_scale", Vector2(), end_dur)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.set_parallel(false)
	t.tween_callback(self, "stop")
	t.tween_callback(self, "finished", [score])


func _on_Hint_completed() -> void:
	play_timer.start()
	riser_timer.start(play_timer.wait_time - riser_sfx.stream.get_length())
	bar_particles = BarParticles.instance()
	bar_particles.position.y = 6.5
	time_progress.add_child(bar_particles)
	init(diff)


func _on_RiserTimer_timeout() -> void:
	riser_sfx.play()
