extends StaticBody2D

signal interacted

export(String) var input_hint_text := "interact"

export(bool) var disabled := false
export(Array, String, MULTILINE) var disabled_dialog

var is_inside := false

onready var default := $Default
onready var entered := $Entered
onready var input_hint := $InputHint
onready var hint_label := $"%Label"
onready var dialog := $CanvasLayer/DialogPlayer
onready var enter_sfx := $EnterSFX


func _ready() -> void:
	hint_label.text = input_hint_text


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact", false, true) and is_inside and \
			not disabled:
		emit_signal("interacted")


func enter(act: String, player: Node) -> void:
	is_inside = true
	get_material().set_shader_param("line_scale", 1.0)
	default.hide()
	entered.play(act)
	entered.show()
	enter_sfx.play()
	if disabled:
		player.set_locked(true)
		var a := 0
		match act:
			"1":
				a = 0
			"2":
				a = 1
			"3":
				a = 2
		dialog.read(disabled_dialog, a)
		yield(dialog, "dialog_finished")
		player.set_locked(false)
	else:
		input_hint.show()


func show_inside(act: String) -> void:
	get_material().set_shader_param("line_scale", 1.0)
	default.hide()
	entered.play(act)
	entered.show()


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
