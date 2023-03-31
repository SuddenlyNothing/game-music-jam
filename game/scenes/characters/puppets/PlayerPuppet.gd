extends AnimatedSprite

signal reached_last_waypoint
signal reached_waypoint(waypoint)

export(NodePath) var waypoints_path
export(String, "1", "2", "3") var act := "1" setget set_act
export(int) var move_speed := 50 setget set_move_speed
export(bool) var muted := false
export(bool) var outside := false
export(bool) var start_left := false

var target: Vector2

onready var waypoints := get_node_or_null(waypoints_path)
onready var outdoor_step_sfx := $OutdoorStepSFX
onready var indoor_step_sfx := $IndoorStepSFX
onready var start_speed_scale := speed_scale
onready var start_move_speed := move_speed


func _ready() -> void:
	if waypoints and waypoints.has_start_point():
		position = waypoints.get_start_point()
	set_physics_process(false)
	play_anim("idle")
	if start_left:
		set_facing(Vector2.LEFT)


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


func set_move_speed(val: int) -> void:
	move_speed = val
	if is_inside_tree():
		speed_scale = move_speed / start_move_speed * start_speed_scale


func set_act(val: String) -> void:
	act = val
	play_anim(animation.substr(0, len(animation) - 1))


func goto_next() -> void:
	if waypoints.has_next_point():
		set_physics_process(true)
		target = waypoints.get_next_point()
		play_anim("walk")
	else:
		emit_signal("reached_last_waypoint")


func set_facing(dir: Vector2) -> void:
	if (dir.x > 0 and scale.x < 0) or\
			(dir.x < 0 and scale.x > 0):
		flip()


func flip() -> void:
	scale.x *= -1


func play_anim(anim: String) -> void:
	play(anim + act)


func _on_PlayerPuppet_frame_changed() -> void:
	if muted:
		return
	if animation.begins_with("walk"):
		match frame:
			1, 4:
				if outside:
					outdoor_step_sfx.play()
				else:
					indoor_step_sfx.play()
