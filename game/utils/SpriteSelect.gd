extends Area2D

signal clicked

var t: SceneTreeTween
var is_mouse_inside := false
var disabled := false setget set_disabled


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("continue") and is_mouse_inside and not disabled:
		emit_signal("clicked")


func set_disabled(val: bool) -> void:
	disabled = val
	if val:
		if is_mouse_inside:
			if t:
				t.kill()
			t.tween_property(get_material(), "shader_param/line_scale", 0.0, 0.1)
	else:
		if is_mouse_inside:
			if t:
				t.kill()
			t = create_tween()
			t.tween_property(get_material(), "shader_param/line_scale", 1.0, 0.1)


func _on_SpriteSelect_mouse_entered() -> void:
	is_mouse_inside = true
	if not disabled:
		if t:
			t.kill()
		t = create_tween()
		t.tween_property(get_material(), "shader_param/line_scale", 1.0, 0.1)


func _on_SpriteSelect_mouse_exited() -> void:
	is_mouse_inside = false
	if not disabled:
		if t:
			t.kill()
		t = create_tween()
		t.tween_property(get_material(), "shader_param/line_scale", 0.0, 0.1)
