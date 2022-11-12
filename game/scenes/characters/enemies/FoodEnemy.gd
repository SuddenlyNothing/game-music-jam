extends KinematicBody2D

signal died

const DeathParticles := preload(
		"res://scenes/characters/enemies/DeathParticles.tscn")

const FOODS := [
	"pizza",
	"burger",
	"fries",
	"donut",
]

export(Color) var good_color := Color.green
export(Color) var bad_color := Color.red
export(int) var num_rays := 16
export(int) var ray_dist := 20.0
export(int) var num_calc_rays := 32
export(bool) var avoid := false
export(int) var min_shape_target_dist := 20
export(float) var min_shape_target_dist_offset := 20.0
export(int) var far_shape_target_dist := 300
export(float) var far_shape_target_dist_offset := 200.0

export(int) var min_speed_dist := 20
export(float) var min_speed_dist_offset := 20.0
export(int) var far_speed_dist := 80
export(float) var far_speed_dist_offset := 30.0
export(float) var max_speed := 100.0
export(float) var min_speed := 50.0
export(float) var min_acceleration := 100.0
export(float) var max_acceleration := 500.0

export(float) var friction := 100.0

export(float) var min_idle_time := 0.1
export(float) var max_idle_time := 2.0

export(float) var min_walk_time := 2.0
export(float) var max_walk_time := 5.0

export(float) var track_speed := 90.0

export(float, 1.0) var continue_straight_weight := 1

var randomize_food := true
var track := false
var rays := []
var calc_rays := []
var target: Node2D
var velocity := Vector2()
var food: String
var locked := false setget set_locked

onready var min_shape_target_dist_squared := pow(min_shape_target_dist + \
		Variables.rng.randf_range(-min_shape_target_dist_offset,
		min_shape_target_dist_offset), 2)
onready var far_shape_target_dist_squared := pow(far_shape_target_dist + \
		Variables.rng.randf_range(-far_shape_target_dist_offset,
		far_shape_target_dist_offset), 2)
onready var min_speed_dist_squared := pow(min_speed_dist + \
		Variables.rng.randf_range(-min_speed_dist_offset,
		min_speed_dist_offset), 2)
onready var far_speed_dist_squared := pow(far_speed_dist + \
		Variables.rng.randf_range(-far_speed_dist_offset,
		far_speed_dist_offset), 2)

onready var anim_sprite := $Pivot/AnimatedSprite
onready var pivot := $Pivot
onready var food_enemy_states := $FoodEnemyStates
onready var idle_timer := $IdleTimer
onready var walk_timer := $WalkTimer


func _ready() -> void:
	Variables.rng.randomize()
	if randomize_food:
		food = FOODS[Variables.rng.randi_range(0, len(FOODS) - 1)]
	for i in num_rays:
		var r := RayCast2D.new()
		r.cast_to = Vector2.RIGHT.rotated(i / float(num_rays) * 2 * PI) *\
				ray_dist
		r.collision_mask = 3
		add_child(r)
		rays.append(r)
	for i in num_calc_rays:
		calc_rays.append(1.0)
	if track:
		food_enemy_states.call_deferred("set_state", "track")
		set_collision_layer_bit(0, true)


func _draw() -> void:
	if get_tree().is_debugging_collisions_hint():
		for i in len(calc_rays):
			var color: Color = lerp(Color.white, good_color,
					calc_rays[i] / 1.0)
			if calc_rays[i] < 0:
				color = lerp(Color.white, bad_color, calc_rays[i] / -1.0)
			draw_line(Vector2(), (Vector2.RIGHT * abs(calc_rays[i]) * 30)\
					.rotated(i / float(num_calc_rays) * 2 * PI),
					color, 1.01)
		draw_line(Vector2(), velocity, Color.blue, 1.2)


func set_locked(val: bool) -> void:
	locked = val
	if val:
		idle_timer.stop()
		walk_timer.stop()
		food_enemy_states.call_deferred("set_state", "idle")
	else:
		food_enemy_states.call_deferred("set_state", "idle")


func stop_timers() -> void:
	idle_timer.stop()
	walk_timer.stop()


func move_track(delta: float) -> void:
	var dir := position.direction_to(target.position)
	var collision := move_and_collide(dir * track_speed * delta)
	if collision and collision.collider == target:
		if target.hit():
			kill()
	set_facing(dir)


func kill() -> void:
	emit_signal("died")
	var dp := DeathParticles.instance()
	dp.position = anim_sprite.global_position
	get_parent().add_child(dp)
	queue_free()


func play_anim(anim: String) -> void:
	anim_sprite.play(anim + "_" + food)


func set_player(p: Node2D) -> void:
	target = p


func move(delta: float) -> void:
	apply_acceleration(delta)
	velocity = move_and_slide(velocity)
	set_facing(target.position - position)


func move_idle(delta: float) -> void:
	velocity = move_and_slide(velocity)
	var friction_amount := friction * delta
	if friction_amount >= velocity.length():
		velocity = Vector2()
	else:
		velocity -= velocity.normalized() * friction_amount


func apply_acceleration(delta: float) -> void:
	var speed_weight := clamp(
			(position.distance_squared_to(target.position) - \
			min_speed_dist_squared) / (far_speed_dist_squared - \
			min_speed_dist_squared), 0, 1)
	var acceleration_amount: float = lerp(max_acceleration, min_acceleration,
			speed_weight) * delta
	var desired_vel: Vector2 = lerp(max_speed, min_speed, speed_weight) *\
			get_desired_dir()
	if velocity.distance_to(desired_vel) <= acceleration_amount:
		velocity = desired_vel
	else:
		velocity += velocity.direction_to(desired_vel) * acceleration_amount


func set_facing(dir: Vector2) -> void:
	if (pivot.scale.x < 0 and dir.x > 0) or\
			(pivot.scale.x > 0 and dir.x < 0):
		pivot.scale.x *= -1


func get_desired_dir() -> Vector2:
	if not is_instance_valid(target):
		return Vector2()
	
	var target_dir := position.direction_to(target.position)
	var target_dist_weight := clamp(
			(position.distance_squared_to(target.position) - \
			min_shape_target_dist_squared) / (far_shape_target_dist_squared - \
			min_shape_target_dist_squared), 0, 1)
	
	for i in len(calc_rays):
		var rot: float = i / float(num_calc_rays) * 2.0 * PI
		var ray_dir := Vector2.RIGHT.rotated(rot)
		var dot := target_dir.dot(ray_dir)
		calc_rays[i] = lerp(1 - abs(dot), max(dot, 0), target_dist_weight) * 2
	
	for ray in rays:
		ray = ray as RayCast2D
		ray.force_raycast_update()
		if ray.is_colliding():
			for i in len(calc_rays):
				var rot: float = i / float(num_calc_rays) * 2.0 * PI
				var dot = ray.cast_to.normalized()\
						.dot(Vector2.RIGHT.rotated(rot))
				calc_rays[i] -= max(dot, 0)
	
	for i in len(calc_rays):
		var rot: float = i / float(num_calc_rays) * 2.0 * PI
		var dot := velocity.normalized()\
				.dot(Vector2.RIGHT.rotated(rot))
		calc_rays[i] += max(dot, 0) * continue_straight_weight
	update()
	
	# Calculate desired rotation
	var desired_rot := 0.0
	var max_desire := -INF
	for i in len(calc_rays):
		if calc_rays[i] > max_desire:
			desired_rot = i / float(num_calc_rays) * 2 * PI
			max_desire = calc_rays[i]
	return Vector2.RIGHT.rotated(desired_rot)


func start_idle_timer() -> void:
	if locked:
		return
	Variables.rng.randomize()
	idle_timer.start(Variables.rng.randf_range(min_idle_time, max_idle_time))


func start_walk_timer() -> void:
	if locked:
		return
	Variables.rng.randomize()
	walk_timer.start(Variables.rng.randf_range(min_walk_time, max_walk_time))


func _on_IdleTimer_timeout() -> void:
	if locked:
		return
	food_enemy_states.call_deferred("set_state", "walk")


func _on_WalkTimer_timeout() -> void:
	if locked:
		return
	food_enemy_states.call_deferred("set_state", "idle")
