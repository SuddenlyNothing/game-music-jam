extends KinematicBody2D

const DashLine := preload("res://scenes/characters/players/DashLine.tscn")

export(float) var acceleration := 600.0
export(float) var turn_acceleration_multiplier := 3.0
export(float) var friction := 1000.0
export(float) var max_speed := 200.0

export(float) var dash_dist := 100.0
export(float) var dash_hit_dur := 0.3
export(float) var fov := 180.0
export(float) var dash_eat_padding := 10.0

var prev_input := Vector2()
var input := Vector2()
var velocity := Vector2()
var arrow_t: SceneTreeTween
var camera_t: SceneTreeTween
var line: Line2D

onready var dash_dist_squared := pow(dash_dist, 2)
onready var dash_eat_padding_squared := pow(dash_eat_padding, 2)

onready var pivot := $Pivot
onready var anim_sprite := $Pivot/AnimatedSprite
onready var dash_timer := $DashTimer
onready var topdown_player_states := $TopdownPlayerStates
onready var arrow := $Arrow
onready var dash_arrow := $Arrow/DashArrow
onready var camera := $Camera2D


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
	set_arrow_dir()


func dash() -> void:
	if arrow_t:
		arrow_t.kill()
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
		arrow.modulate.a = 1
	else:
		arrow.modulate.a = 0
		velocity = Vector2()
		dash_timer.start()
		move_and_collide(prev_input * dash_dist)
	
	var rel_vect := prev_pos - position
	if is_instance_valid(line):
		line.queue_free()
	line = DashLine.instance()
	line.points = PoolVector2Array([Vector2(), rel_vect])
	line.dur = line_dur
	add_child(line)
	if camera_t:
		camera_t.kill()
	camera_t = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	camera_t.tween_property(camera, "offset", Vector2(),
			line_dur).from(rel_vect)


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


func set_arrow_dir() -> void:
	if velocity:
		dash_arrow.rotation = velocity.angle()


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
	if arrow_t:
		arrow_t.kill()
	arrow_t = create_tween()
	arrow_t.tween_interval(0.1)
	arrow_t.tween_property(arrow, "modulate:a", 1.0, 0.2)
	topdown_player_states.call_deferred("set_state", "idle")
