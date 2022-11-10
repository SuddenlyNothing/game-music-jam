class_name StreetRoom
extends Node2D

onready var outside := $Outside

var t: SceneTreeTween


func set_season(season: String, dur: float = 1.0) -> void:
	season = season.capitalize()
	if t:
		t.kill()
	t = create_tween().parallel()
	for child in outside.get_children():
		if child.name == season:
			if child.modulate.a > 0.5:
				child.modulate.a = 0
			t.tween_property(child, "modulate:a", 1.0, dur)
			child.z_index = 60
			child.call_deferred("show")
		elif child.z_index > 25:
			child.z_index = 25
		else:
			child.z_index = 0
