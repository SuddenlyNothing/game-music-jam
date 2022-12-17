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


func _input(event: InputEvent) -> void:
	if has_dialog:
		if event.is_action_pressed("interact", false, true):
			if reading:
				print("dialog interact stop")
				t.kill()
				label.percent_visible = 1.0
				stop_reading()
			else:
				print("dialog interact next")
				interact_sfx.play()
				read_next()
			accept_event()


func read_line(dialogs: Array, wait: float = 0.0) -> void:
	next_indicator_container.hide()
	reading = true
	modulate.a = 1.0
	show()
	if t:
		t.kill()
	t = create_tween()
	for dialog in dialogs:
		print(dialog)
		text_sfx.audio_streams = character_audios[character]
		t.tween_callback(text_sfx, "play")
		t.tween_callback(text_sfx_interval, "start")
		label.text = dialog
		t.tween_callback(label, "set_percent_visible", [0.0])
		t.tween_callback(label, "set_text", [dialog])
		var new_dialog_spaceless: String = dialog.replace(" ", "")
		var dialog_len := len(new_dialog_spaceless)
		var curr_percent_visible: float = 0.0
		var max_delay := 0.0
		var has_pause := false
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
		t.tween_interval(wait)
		t.tween_callback(text_sfx, "stop")
		t.tween_callback(text_sfx_interval, "stop")
	yield(t, "finished")
	reading = false


func read(d: Array = autoplay_dialog, c: int = character) -> void:
	label.modulate = character_colors[c]
	text_sfx.audio_streams = character_audios[c]
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
	yield(enter_exit_t, "finished")
	has_dialog = true


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
	
	print("reading = true")
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
