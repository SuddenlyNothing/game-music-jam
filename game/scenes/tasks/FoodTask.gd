extends Task

const FoodEnemy := preload("res://scenes/characters/enemies/FoodEnemy.tscn")
const Player := preload("res://scenes/characters/players/TopdownPlayer.tscn")
const BarParticles := preload("res://scenes/tasks/BarParticles.tscn")

export(bool) var testing := false

export(int) var min_food := 6
export(int) var max_food := 20
export(int) var min_dist_to_player := 100.0

export(float) var max_shake_time := 1.5
export(float) var eat_shake_intensity := 0.2
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

onready var min_dist_to_player_squared := pow(min_dist_to_player, 2)

onready var player: Node2D
onready var ysort: YSort = $"%YSort"
onready var score_label: Label = $"%ScoreLabel"
onready var pc: PanelContainer = $"%PC"
onready var shake_timer := $ShakeTimer
onready var score_label_position: Vector2 = score_label.rect_position
onready var play_timer := $PlayTimer
onready var bar_particles: CPUParticles2D
onready var time_progress := $M/M2/TimeProgress
onready var hint := $Hint
onready var times_up_sfx := $TimesUpSFX


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_focus_next") and testing:
		Variables.rng.randomize()
		start(1)


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
	time_progress.value = 0
	diff = difficulty
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


# Stop abruptly
# Hide and free everything
func stop() -> void:
	hide()
	get_tree().call_group("food", "queue_free")
	bar_particles.queue_free()
	player.queue_free()


func spawn_enemy(add_score: bool = true) -> void:
	var fe := FoodEnemy.instance()
	Variables.rng.randomize()
	var new_pos := Vector2(
		Variables.rng.randf_range(20, 380),
			Variables.rng.randf_range(20, 250)
	)
	while new_pos.distance_squared_to(player.position) < \
			min_dist_to_player_squared:
		new_pos = Vector2(
			Variables.rng.randf_range(20, 380),
			Variables.rng.randf_range(20, 250)
		)
	if add_score:
		add_score()
	fe.position = new_pos
	fe.connect("died", self, "spawn_enemy")
	ysort.add_child(fe)
	get_tree().call_group("needs_player", "set_player", player)


func add_score() -> void:
	score += 1
	score_label.text = str(score)
	var shake_time := min(shake_timer.time_left + eat_shake_intensity,
			max_shake_time)
	shake_timer.start(shake_time)
	if score_t:
		score_t.kill()
	score_t = create_tween()
	score_t.tween_property(score_label, "modulate", Color.white,
			shake_time).from(Color('c85a12'))


func _on_ShakeTimer_timeout() -> void:
	score_label.rect_position = score_label_position


func _on_PlayTimer_timeout() -> void:
	times_up_sfx.play()
	player.set_locked(true)
	get_tree().call_group("food", "set_locked", true)
	if t:
		t.kill()
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
	bar_particles = BarParticles.instance()
	bar_particles.position.y = 6.5
	time_progress.add_child(bar_particles)
	play_timer.start()
	player = Player.instance()
	player.position = Vector2(192, 133)
	ysort.call_deferred("add_child", player)
	for _i in round(lerp(min_food, max_food, diff)):
		spawn_enemy(false)
