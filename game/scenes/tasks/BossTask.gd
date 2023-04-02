extends BaseTask

const Player := preload("res://scenes/characters/players/TopdownPlayer.tscn")
const Boss := preload("res://scenes/tasks/boss/Boss.tscn")

export(String, FILE, "*.tscn") var next_scene
export(int) var max_consumed := 5
export(String) var consumed_message := "Your gluttony caught up to you"

var consumed := 0
var p
var display_consumed_message := false

onready var ysort := $M/M/PC/M/VC/Viewport/YSort
onready var bg := $M/M/PC/M/VC/Viewport/FoodGameBackground
onready var cbg := $ColorRect
onready var consumed_label := $M/ConsumedLabel


# Override
func init(difficulty: float = 0.0) -> void:
	p = Player.instance()
	p.do_eat_sfx = false
	p.position = Vector2(192, 133)
	p.knockback_enemies = true
	p.connect("killed", self, "_on_Player_killed")
	p.connect("hit", self, "_on_Player_hit")
	var b := Boss.instance()
	b.position = Vector2(192, 100)
	b.player = p
	ysort.add_child(p)
	ysort.add_child(b)
	p.set_locked(true)


# Override
func _on_PlayTimer_timeout() -> void:
	p.set_locked(true)
	get_tree().call_group("food", "queue_free")
	var t := create_tween().set_parallel()
	t.tween_property(bg, "modulate:a", 0.0, 1.0)
	t.tween_property(time_progress, "modulate:a", 0.0, 1.0)
	t.tween_property(cbg, "color", Color.black, 1.0)
	t.set_parallel(false)
	t.tween_interval(1.0)
	t.tween_callback(SceneHandler, "goto_scene", [next_scene])


func _on_Player_hit() -> void:
	consumed += 1
	if consumed >= max_consumed:
		display_consumed_message = true
		p.kill(p.position)


func _on_Player_killed() -> void:
	play_timer.stop()
	riser_timer.stop()
	riser_sfx.stop()
	if bar_particles and is_instance_valid(bar_particles):
		bar_particles.queue_free()
	get_tree().call_group("food", "queue_free")
	var t := create_tween().set_parallel()
	if display_consumed_message:
		consumed_label.modulate.a = 0
		consumed_label.show()
		t.tween_property(consumed_label, "modulate:a", 1.0, 0.5)
	t.tween_property(bg, "modulate:a", 0.0, 0.1)
	t.tween_property(time_progress, "modulate:a", 0.0, 0.1)
	t.tween_property(cbg, "color", Color.black, 1.0)
	t.set_parallel(false)
	t.tween_interval(1.0)
	t.tween_callback(SceneHandler, "goto_scene", [next_scene])


func _on_DialogPlayer_dialog_finished() -> void:
	start(0)


func _on_BossTask_finished(points) -> void:
	SceneHandler.goto_scene(next_scene)
