extends StaticBody2D

signal interacted

var is_inside := false

onready var default := $Default
onready var entered := $Entered
onready var input_hint := $InputHint


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("continue", false, true) and is_inside:
		emit_signal("interacted")


func enter() -> void:
	is_inside = true
	get_material().set_shader_param("line_scale", 1.0)
	default.hide()
	entered.show()
	input_hint.show()


func exit() -> void:
	is_inside = false
	get_material().set_shader_param("line_scale", 0.0)
	default.show()
	entered.hide()
	input_hint.hide()


func set_hint_visible(vis: bool) -> void:
	if not is_inside:
		return
	input_hint.visible = vis
