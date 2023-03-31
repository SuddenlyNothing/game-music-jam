tool
extends Node2D

export(bool) var has_start_point := true

export(Color) var start_color
export(Color) var end_color

var waypoint_ind := -1


func _process(delta: float) -> void:
	if not Engine.editor_hint:
		return
	if get_child_count() <= 1:
		return
	update()


func _draw() -> void:
	if not Engine.editor_hint:
		return
	var points := PoolVector2Array()
	var colors := PoolColorArray()
	var num_children := get_child_count()
	for i in num_children:
		points.append(get_child(i).position)
		colors.append(lerp(start_color, end_color, i / float(num_children - 1)))
	draw_polyline_colors(points, colors, 5.0)


func get_start_point() -> Vector2:
	waypoint_ind = 0
	return get_child(0).global_position


func get_next_point() -> Vector2:
	waypoint_ind += 1
	return get_child(waypoint_ind).global_position


func has_next_point() -> bool:
	return waypoint_ind < get_child_count() - 1


func has_start_point() -> bool:
	return has_start_point && get_child_count() > 0
