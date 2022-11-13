class_name StreetRoom
extends Node2D

var t: SceneTreeTween
var audio_t: SceneTreeTween

onready var outside := $Outside
onready var outdoor_audio := $Audio/Outdoor
onready var cover := $Outside/Cover/Cover
onready var outdoor_bus_idx := AudioServer.get_bus_index("SFX Outdoor")
onready var indoor_bus_idx := AudioServer.get_bus_index("SFX Indoor")
onready var door_sfx := $Audio/DoorSFX
onready var indoor_sfx := $Audio/Indoor


func set_season(season: String, dur: float = 1.0) -> void:
	season = season.capitalize()
	if t:
		t.kill()
	t = create_tween().set_parallel()
	for child in outside.get_children():
		if child.name == "Cover":
			continue
		child.modulate.a = 1
		if child.name == season:
			if child.modulate.a >= 0.5:
				child.modulate.a = 0
			t.tween_property(child, "modulate:a", 1.0, dur)
			child.z_index = 60
			child.show()
		else:
			if child.z_index > 25:
				child.z_index = 25
			else:
				child.z_index = 0
				child.modulate.a = 0
			t.tween_callback(child, "hide").set_delay(dur)
	
	for child in outdoor_audio.get_children():
		if child.name == season:
			child.volume_db = -30.0
			if child.stream_paused:
				child.stream_paused = false
			else:
				child.play()
			t.tween_property(child, "volume_db", 0.0, dur)
		else:
			if child.playing:
				t.tween_property(child, "volume_db", -30.0, dur)
				t.tween_callback(child, "set_stream_paused", [true])\
						.set_delay(dur)


func set_bus_volume_db(volume: float, bus: int) -> void:
	AudioServer.set_bus_volume_db(bus, volume)


func play_indoor_sfx() -> void:
	for child in indoor_sfx.get_children():
		child.play()


func stop_indoor_sfx() -> void:
	for child in indoor_sfx.get_children():
		child.stop()


func set_outdoor(val: bool, dur: float = 1.0) -> void:
	var lpf := AudioServer.get_bus_effect(outdoor_bus_idx, 0)\
			as AudioEffectLowPassFilter
	
	if audio_t:
		audio_t.kill()
	audio_t = create_tween().set_parallel()
	if val:
		audio_t.tween_method(self, "set_bus_volume_db", 0.0, -20.0, dur,
				[indoor_bus_idx])
		audio_t.tween_callback(AudioServer, "set_bus_mute",
				[indoor_bus_idx, true])
		audio_t.tween_property(lpf, "cutoff_hz", 20500.0, dur)
	else:
		AudioServer.set_bus_mute(indoor_bus_idx, false)
		audio_t.tween_method(self, "set_bus_volume_db", -20.0, 0.0, dur,
				[indoor_bus_idx])
		audio_t.tween_property(lpf, "cutoff_hz", 2000.0, dur)


func _on_Door_interacted() -> void:
	pass # Replace with function body.
