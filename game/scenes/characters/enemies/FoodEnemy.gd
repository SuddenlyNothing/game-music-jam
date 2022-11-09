extends KinematicBody2D

export(Color) var good_color := Color.green
export(Color) var bad_color := Color.red
export(int) var num_rays := 16
export(int) var ray_dist := 50.0
export(int) var num_calc_rays := 32
export(bool) var avoid := false
export(int) var min_shape_target_dist := 40
export(int) var far_shape_target_dist := 60

export(float) var max_speed := 100.0
export(float) var acceleration := 100.0

var rays := []
var calc_rays := []
var target: Node2D
var velocity := Vector2()

onready var min_shape_target_dist_squared := pow(min_shape_target_dist, 2)
onready var far_shape_target_dist_squared := pow(far_shape_target_dist, 2)

onready var anim_sprite := $AnimatedSprite


func _ready() -> void:
	for i in num_rays:
		var r := RayCast2D.new()
		r.cast_to = Vector2.RIGHT.rotated(i / float(num_rays) * 2 * PI) *\
				ray_dist
		add_child(r)
		rays.append(r)
	for i in num_calc_rays:
		calc_rays.append(1.0)


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


func set_player(p: Node2D) -> void:
	target = p


func move(delta: float) -> void:
	apply_acceleration(delta)
	velocity = move_and_slide(velocity)


func apply_acceleration(delta: float) -> void:
	var acceleration_amount := acceleration * delta
	var desired_vel := max_speed * get_desired_dir()
	if velocity.distance_to(desired_vel) <= acceleration_amount:
		velocity = desired_vel
	else:
		velocity += velocity.direction_to(desired_vel) * acceleration_amount
	


func get_desired_dir() -> Vector2:
	if not is_instance_valid(target):
		return Vector2()
	
	var target_dir := position.direction_to(target.position)
	var target_dist_weight := clamp(
			(position.distance_squared_to(target.position) - \
			min_shape_target_dist_squared) / (far_shape_target_dist_squared - \
			min_shape_target_dist), 0, 1)
	
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
		calc_rays[i] += max(dot, 0) * 0.2
	update()
	
	# Calculate desired rotation
	var desired_rot := 0.0
	var max_desire := -INF
	for i in len(calc_rays):
		if calc_rays[i] > max_desire:
			desired_rot = i / float(num_calc_rays) * 2 * PI
			max_desire = calc_rays[i]
	return Vector2.RIGHT.rotated(desired_rot)
