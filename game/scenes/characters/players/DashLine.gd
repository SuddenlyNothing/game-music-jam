extends Line2D

export(float) var dur := 1.5

var point_start_pos: Vector2
var t: SceneTreeTween

onready var camera := $Camera2D


func start() -> void:
	var total_dist := 0.0
	for i in range(1, points.size()):
		total_dist += points[i].distance_to(points[i - 1])
	
	if points:
		if t:
			t.kill()
		t = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		for i in points.size() - 1:
			var cur_pos := points[points.size() - i - 1]
			var next_pos := points[points.size() - i - 2]
			var point_dur = cur_pos.distance_to(next_pos)\
					/ total_dist * dur
			t.tween_callback(self, "set", ["point_start_pos", cur_pos])
			t.tween_method(self, "contract_last_point", 0.0, 1.0, point_dur)
			t.parallel().tween_property(camera, "position", next_pos, point_dur)\
					.from(cur_pos)
			t.tween_callback(self, "remove_point", [points.size() - i - 1])


func contract_last_point(weight: float) -> void:
	set_point_position(points.size() - 1,
			lerp(point_start_pos, points[points.size() - 2], weight))
