extends Control

signal finished(points)

export(bool) var testing := false

var slept := false
var t: SceneTreeTween


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_focus_next") and testing:
		Variables.rng.randomize()
		start(Variables.rng.randf())


func start(diff: float) -> void:
	if t:
		t.kill()
	modulate.a = 0
	show()
	t = create_tween()
	t.tween_property(self, "modulate:a", 1.0, 1.0)
	t.tween_interval(1.0)
	t.tween_property(self, "modulate:a", 0.0, 1.0)
	t.tween_callback(self, "hide")
	if slept:
		t.tween_callback(self, "emit_signal", ["finished", 1])
	else:
		slept = true
		t.tween_callback(self, "emit_signal", ["finished", 20])


func stop() -> void:
	if t:
		t.kill()
	modulate.a = 0.0
	hide()
