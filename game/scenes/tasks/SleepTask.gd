extends Control

signal finished(points)

var t: SceneTreeTween


func start(diff: float) -> void:
	if t:
		t.kill()
	modulate.a = 0
	show()
	t = create_tween()
	t.tween_property(self, "modulate:a", 1.0, 1.0)
	t.tween_interval(1.0)
	t.tween_property(self, "modulate:a", 0.0, 1.0)
	if diff > 0:
		t.tween_callback(self, "emit_signal", ["finished", 1])
	else:
		t.tween_callback(self, "emit_signal", ["finished", 20])
