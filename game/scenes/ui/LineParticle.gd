extends Node2D

var target: Node2D
var duration := 0.5
var max_points := 10
var random_offset := (Vector2.RIGHT * 200).rotated(2 * PI * (randf() - 0.5))
var finished := false

onready var line := $Line2D
onready var start_pos := position
onready var t := $Tween


func _ready() -> void:
	$StartSFX.play()
	set_as_toplevel(true)
	line.set_as_toplevel(true)
	t.interpolate_method(self, "move_to_end", 0, 1, duration)
	t.start()


func _process(delta: float) -> void:
	line.add_point(position)
	if finished:
		position = target.global_position
		line.remove_point(0)
	if len(line.points) >= max_points:
		line.remove_point(0)
	if len(line.points) <= 0:
		queue_free()


func move_to_end(weight: float) -> void:
	position = lerp(start_pos,
			lerp(target.global_position + random_offset,
			target.global_position, weight),
			weight)


func _on_Tween_tween_all_completed() -> void:
	max_points = 0
	finished = true
	$EndSFX.play()
