extends CanvasLayer

signal completed

export(String) var hint_name := ""
export(String, MULTILINE) var label_hint := ""

onready var input_format_label := $C/ColorRect/M/InputFormatLabel
onready var next_hint := $C/ColorRect/M/NextHint
onready var c := $C

var t: SceneTreeTween


func _ready() -> void:
	input_format_label.unformatted_text = label_hint
	input_format_label.update_keys()
	set_process_input(false)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact", false, true):
		set_process_input(false)
		if hint_name:
			Variables.hints[hint_name] = 1
		if t:
			t.kill()
		t = create_tween()
		t.tween_property(c, "modulate:a", 0.0, 0.5)
		t.tween_callback(self, "hide")
		t.tween_callback(self, "emit_signal", ["completed"])


func start() -> void:
	if (hint_name and hint_name in Variables.hints) or not hint_name:
		emit_signal("completed")
		return
	if t:
		t.kill()
	next_hint.self_modulate.a = 0
	show()
	t = create_tween()
	set_process_input(true)
	c.modulate.a = 0
	t.tween_property(c, "modulate:a", 1.0, 0.5)
	t.tween_interval(0.2)
	t.tween_callback(self, "set_process_input", [true])
	t.tween_interval(0.8)
	t.tween_property(next_hint, "self_modulate:a", 1.0, 0.5)


func stop() -> void:
	set_process_input(false)
	if t:
		t.kill()
	hide()
