extends Line2D

export(float) var dur := 1.5

var point_start_pos: Vector2


func _ready() -> void:
	var total_dist := 0.0
	for i in range(1, points.size()):
		total_dist += points[i].distance_to(points[i - 1])
	
	var t := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	for i in points.size():
		var cur_pos := points[points.size() - i - 1]
		var point_dur = cur_pos.distance_to(points[points.size() - i - 2])\
				/ total_dist * dur
		t.tween_callback(self, "set", ["point_start_pos", cur_pos])
		t.tween_method(self, "contract_last_point", 0.0, 1.0, point_dur)
		t.tween_callback(self, "remove_point", [points.size() - i - 1])
	t.tween_callback(self, "queue_free")


func contract_last_point(weight: float) -> void:
	set_point_position(points.size() - 1,
			lerp(point_start_pos, points[points.size() - 2], weight))
