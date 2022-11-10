extends AnimatedSprite

signal reached_last_waypoint
signal reached_waypoint(waypoint)

export(NodePath) var waypoints_path
export(String, "1", "2", "3") var act := "1"
export(int) var move_speed := 50

var target: Vector2

onready var waypoints := get_node(waypoints_path)


func _ready() -> void:
	if waypoints.has_start_point():
		position = waypoints.get_start_point()
	set_physics_process(false)
	play("idle" + act)


func _physics_process(delta: float) -> void:
	var move_amount := delta * move_speed
	if position.distance_to(target) < move_amount:
		position = target
		play("idle" + act)
		set_physics_process(false)
		if waypoints.has_next_point():
			emit_signal("reached_waypoint", waypoints.waypoint_ind)
		else:
			emit_signal("reached_last_waypoint")
	else:
		var dir := position.direction_to(target)
		position += dir * move_amount
		set_facing(dir)


func goto_next() -> void:
	if waypoints.has_next_point():
		set_physics_process(true)
		target = waypoints.get_next_point()
		play("walk" + act)
	else:
		emit_signal("reached_last_waypoint")


func set_facing(dir: Vector2) -> void:
	if (dir.x > 0 and scale.x < 0) or\
			(dir.x < 0 and scale.x > 0):
		scale.x *= -1
