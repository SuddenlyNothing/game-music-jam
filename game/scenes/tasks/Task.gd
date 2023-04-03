class_name Task
extends Control

signal finished(points)

export(float) var start_dur := 0.5
export(float) var end_dur := 0.5


# Start minigame with difficulty 0-1
func start(difficulty: float, music: bool) -> void:
	pass


# Stop abruptly
# Hide and free everything
func stop() -> void:
	pass


# Points accumulated
func finished(points: int) -> void:
	emit_signal("finished", points)
