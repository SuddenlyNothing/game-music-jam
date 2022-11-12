extends BaseTask

const Player := preload("res://scenes/characters/players/TopdownPlayer.tscn")
const Boss := preload("res://scenes/tasks/boss/Boss.tscn")

export(String, FILE, "*.tscn") var next_scene

var p

onready var ysort := $M/M/PC/M/VC/Viewport/YSort
onready var bg := $M/M/PC/M/VC/Viewport/FoodGameBackground
onready var cbg := $ColorRect
onready var lpc := $M/PanelContainer


# Override
func init(difficulty: float = 0.0) -> void:
	p = Player.instance()
	p.position = Vector2(192, 133)
	p.connect("killed", self, "_on_Player_killed")
	var b := Boss.instance()
	b.position = Vector2(192, 100)
	b.player = p
	ysort.add_child(p)
	ysort.add_child(b)
	p.set_locked(true)


# Override
func wait_stop() -> void:
	pass


func _on_Player_killed() -> void:
	play_timer.stop()
	if bar_particles and is_instance_valid(bar_particles):
		bar_particles.queue_free()
	get_tree().call_group("food", "queue_free")
	var t := create_tween().set_parallel()
	t.tween_property(bg, "modulate:a", 0.0, 1.0)
	t.tween_property(time_progress, "modulate:a", 0.0, 1.0)
	t.tween_property(cbg, "color", Color.black, 1.0)
	t.tween_property(lpc, "modulate:a", 0.0, 1.0)
	t.tween_interval(1.0)
	t.tween_callback(SceneHandler, "goto_scene", [next_scene])


func _on_DialogPlayer_dialog_finished() -> void:
	start(0)


func _on_BossTask_finished(points) -> void:
	if bar_particles and is_instance_valid(bar_particles):
		bar_particles.queue_free()
	p.set_locked(true)
	get_tree().call_group("food", "queue_free")
	var t := create_tween().set_parallel()
	t.tween_property(bg, "modulate:a", 0.0, 1.0)
	t.tween_property(time_progress, "modulate:a", 0.0, 1.0)
	t.tween_property(cbg, "color", Color.black, 1.0)
	t.tween_property(lpc, "modulate:a", 0.0, 1.0)
	t.tween_interval(1.0)
	t.tween_callback(SceneHandler, "goto_scene", [next_scene])
