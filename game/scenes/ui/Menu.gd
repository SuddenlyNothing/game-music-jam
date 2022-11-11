extends Control

signal started

var showing_credits := false
var t: SceneTreeTween

onready var credits := $Credits
onready var buttons := [$"%Start", $"%Settings", $"%Credits"]
onready var start_sfx := $StartSFX


func _on_Settings_pressed() -> void:
	OptionsMenu.set_active(true)


func _on_Credits_pressed() -> void:
	if t:
		t.kill()
	t = create_tween()
	if showing_credits:
		t.tween_property(credits, "rect_position:y", 276.0, 0.4)\
				.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	else:
		t.tween_property(credits, "rect_position:y", 128.0, 0.5)\
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	showing_credits = not showing_credits


func _on_Start_pressed() -> void:
	emit_signal("started")
	Variables.hints = {}
	for btn in buttons:
		btn.disabled = true
	var tw := create_tween().set_ease(Tween.EASE_IN)\
			.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "rect_position:x", -175.0, 0.5)
	start_sfx.play()


func _on_StartSFX_finished() -> void:
	queue_free()
