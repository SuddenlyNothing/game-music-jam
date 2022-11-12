extends Camera2D

export(int) var max_shake := 10
export(float) var max_tile := 5.0

onready var timer := $ShakeTimer
onready var time: float = $ShakeTimer.wait_time


func _process(delta: float) -> void:
	if not timer.is_stopped():
		offset = Vector2(
			Variables.rng.randf_range(-max_shake, max_shake),
			Variables.rng.randf_range(-max_shake, max_shake)
		) * timer.time_left / time
		rotation = Variables.rng.randf_range(-max_tile, max_tile)\
				* timer.time_left / time


func shake(percent: float) -> void:
	percent = clamp(percent, 0, 1)
	timer.start(timer.time_left + percent * time)


func _on_ShakeTimer_timeout() -> void:
	offset = Vector2()
