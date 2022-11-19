extends Control

signal dialog_finished

enum Characters {
	MC1 = 0,
	MC2 = 1,
	MC3 = 2,
	BOSS = 3,
	FRIEND = 4,
	MISC = 5,
}

const PAUSE_SYMBOLS := {
	".": 13,
	",": 5,
	":": 10,
	"!": 13,
	"?": 13,
	";": 10,
}

export(Characters) var character
export(bool) var autoplay := false
export(float) var read_speed: float = 40.0
export(Color) var default_color = Color.white
export(String) var empty_dialog := "..."
export(Array, String, MULTILINE) var autoplay_dialog := []
export(Array, Array, AudioStream) var character_audios
export(Array, Color) var character_colors

var dialogs: Array
var d_ind: int
var reading: bool = false
var has_dialog: bool = false
var curr_text: String = ""
var t: SceneTreeTween
var enter_exit_t: SceneTreeTween

onready var label := $"%RichTextLabel"
onready var text_sfx := $TextSFX
onready var next_indicator_container := $M/ColorRect/NextIndicatorContainer
onready var interact_sfx := $InteractSFX
onready var text_sfx_interval := $TextSFXInterval


func _ready() -> void:
	if autoplay:
		read(autoplay_dialog)
#	for i in 3:
#		print("food" + str(i + 1))
#		var d: Node = Dialogic.start("food" + str(i + 1))
#		d.connect("dialogic_signal", self, "test")
#		add_child(d)
#		yield(d, "timeline_end")
#		print(Dialogic.get_variable("delivery"))
#		print("timeline ended")


func _input(event: InputEvent) -> void:
	if has_dialog:
		if event.is_action_pressed("interact", false, true):
			if reading:
				t.kill()
				label.percent_visible = 1.0
				stop_reading()
			else:
				interact_sfx.play()
				read_next()
			accept_event()


func read(d: Array = autoplay_dialog, c: int = character) -> void:
	label.modulate = character_colors[c]
	text_sfx.audio_streams = character_audios[c]
	has_dialog = true
	if t:
		t.kill()
	label.percent_visible = 0.0
	d_ind = -1
	dialogs = d
	next_indicator_container.hide()
	call_deferred("show")
	if enter_exit_t:
		enter_exit_t.kill()
	enter_exit_t = create_tween()
	enter_exit_t.tween_property(self, "modulate:a", 1.0, 0.43).from(0.0)
	enter_exit_t.tween_callback(self, "read_next")


func read_next() -> void:
	d_ind += 1
	if d_ind >= dialogs.size():
		stop()
		return
	text_sfx.play()
	curr_text = dialogs[d_ind]
	var new_dialog: String = dialogs[d_ind].format(Variables.input_format)
	if len(new_dialog) <= 0:
		new_dialog = empty_dialog
	label.bbcode_text = new_dialog
	next_indicator_container.hide()
	text_sfx_interval.start()
	
	set_read_tween(new_dialog)
	
	reading = true


func set_read_tween(new_dialog: String,
		starting_percent_visible: float = 0.0) -> void:
	label.percent_visible = starting_percent_visible
	var new_dialog_spaceless: String = label.text.replace(" ", "")
	var dialog_len := len(new_dialog_spaceless)
	var curr_percent_visible: float = starting_percent_visible
	var max_delay := 0.0
	var has_pause := false
	t = create_tween()
	t.tween_callback(text_sfx, "set_stream_paused", [false])
	for i in range(int(curr_percent_visible * dialog_len), dialog_len):
		var curr_char := new_dialog_spaceless[i]
		if curr_char in PAUSE_SYMBOLS:
			has_pause = true
			max_delay = max(max_delay, PAUSE_SYMBOLS[curr_char])
		elif has_pause:
			has_pause = false
			var new_percent_visible := float(i) / dialog_len
			t.tween_property(label, "percent_visible",
					new_percent_visible, floor((new_percent_visible - \
					curr_percent_visible) * dialog_len) / read_speed)\
					.from(curr_percent_visible)
			t.tween_callback(text_sfx, "set_stream_paused", [true])
			t.tween_interval(max_delay / read_speed)
			t.tween_callback(text_sfx, "set_stream_paused", [false])
			curr_percent_visible = new_percent_visible
			max_delay = 0.0
	t.tween_property(label, "percent_visible", 1.0,
			(1 - curr_percent_visible) * dialog_len / read_speed)
	t.tween_callback(self, "stop_reading")


func stop() -> void:
	emit_signal("dialog_finished")
	reading = false
	has_dialog = false
	if t:
		t.kill()
	text_sfx_interval.stop()
	text_sfx.stop()
	next_indicator_container.hide()
	if enter_exit_t:
		enter_exit_t.kill()
	enter_exit_t = create_tween()
	enter_exit_t.tween_property(self, "modulate:a", 0.0, 0.1)
	enter_exit_t.tween_callback(self, "hide")


func update_keys():
	var new_dialog: String = curr_text.format(Variables.input_format)
	label.text = new_dialog
	if new_dialog == curr_text or not t or not t.is_running():
		return
	t.kill()
	set_read_tween(new_dialog)


func stop_reading() -> void:
	reading = false
	text_sfx_interval.stop()
	text_sfx.stop()
	next_indicator_container.show()
	interact_sfx.play()


func _on_TextSFX_finished() -> void:
	if reading:
		text_sfx.play()


func _on_TextSFXInterval_timeout() -> void:
	if reading:
		text_sfx.play()
