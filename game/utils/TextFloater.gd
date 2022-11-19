extends Node2D

export(String) var text := ""
export(float) var duration := 1.0
export(float) var pitch_scale := 1.0
export(bool) var do_sfx := true

onready var label := $Label
onready var sfx := $SFX


func _ready() -> void:
	label.text = text
	if do_sfx:
		sfx.play()
		sfx.pitch_scale = pitch_scale
	var t := create_tween().set_trans(Tween.TRANS_QUINT)
	t.tween_property(self, "scale", Vector2.ONE * 2, duration / 3 * 2)\
			.from(Vector2()).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "scale", Vector2(), duration / 3)\
			.set_ease(Tween.EASE_IN)
	t.tween_callback(self, "queue_free")
