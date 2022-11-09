extends KinematicBody2D

export(float) var acceleration := 600.0
export(float) var turn_acceleration_multiplier := 3.0
export(float) var friction := 1000.0
export(float) var max_speed := 100.0

export(float) var dash_dist := 100.0
export(float) var dash_hit_dur := 0.3
export(float) var fov := 180.0
export(float) var dash_eat_padding := 10.0

var prev_input := Vector2.RIGHT
var input := Vector2()
var velocity := Vector2()
var line: Line2D

onready var dash_dist_squared := pow(dash_dist, 2)
onready var dash_eat_padding_squared := pow(dash_eat_padding, 2)

onready var pivot := $Pivot
onready var anim_sprite := $Pivot/AnimatedSprite
onready var dash_timer := $DashTimer
onready var topdown_player_states := $TopdownPlayerStates
onready var dash_line := $DashLine

onready var dash_sfx := $DashSFX
onready var eat_sfx := $EatSFX


func _process(delta: float) -> void:
	input = Input.get_vector("left", "right", "up", "down")
	if input:
		prev_input = input.normalized()


func play_anim(anim: String) -> void:
	anim_sprite.play(anim)


func move(delta: float) -> void:
	apply_acceleration(delta)
	apply_friction(delta)
	velocity = move_and_slide(velocity)
	set_facing(input)


func dash() -> void:
	var prev_pos := position
	var line_dur: float = dash_timer.wait_time
	
	var dash_food := get_closest_dashable_food()
	if dash_food:
		yield(get_tree(), "idle_frame")
		var vec := dash_food.position - position
		dash_food.free()
		move_and_collide(vec)
		topdown_player_states.call_deferred("set_state", "idle")
		line_dur = dash_hit_dur
		velocity = vec.normalized() * max_speed
	else:
		velocity = Vector2()
		dash_timer.start()
		move_and_collide(prev_input * dash_dist)
	
	eat_sfx.play()
	dash_sfx.play()
	var rel_vec := prev_pos - position
	if is_instance_valid(line):
		line.queue_free()
	var new_points := PoolVector2Array()
	new_points.append(Vector2())
	for point in dash_line.points:
		new_points.append(point + rel_vec)
	dash_line.points = new_points
	dash_line.dur = line_dur
	dash_line.start()


func apply_acceleration(delta: float) -> void:
	if not input:
		return
	var desired_vel := input * max_speed
	var acceleration_amoount := acceleration * delta
	if desired_vel.dot(velocity) < 0:
		acceleration_amoount *= turn_acceleration_multiplier
	if velocity.distance_to(desired_vel) <= acceleration_amoount:
		velocity = desired_vel
	else:
		velocity += velocity.direction_to(desired_vel) * acceleration_amoount


func set_facing(dir: Vector2) -> void:
	if (pivot.scale.x < 0 and dir.x > 0) or\
			(pivot.scale.x > 0 and dir.x < 0):
		pivot.scale.x *= -1


func apply_friction(delta: float) -> void:
	if input:
		return
	var friction_amount := friction * delta
	if velocity.length() <= friction_amount:
		velocity = Vector2()
	else:
		velocity -= velocity.normalized() * friction_amount


func get_closest_dashable_food() -> Node2D:
	var min_dist := 0.0
	var closest_food: Node2D = null
	for food in get_tree().get_nodes_in_group("food"):
		if is_pos_dashable(food.position):
			var dist := position.distance_squared_to(food.position)
			if not closest_food or dist < min_dist:
				min_dist = dist
				closest_food = food
	return closest_food


func is_pos_dashable(pos: Vector2) -> bool:
	if position.distance_squared_to(pos) > dash_dist_squared + \
			dash_eat_padding_squared:
		return false
	var dot = prev_input.dot((pos - position).normalized())
	var ang = rad2deg(acos(dot))
	if ang < fov / 2:
		return true
	return false


func _on_DashTimer_timeout() -> void:
	topdown_player_states.call_deferred("set_state", "idle")
