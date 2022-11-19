extends KinematicBody2D

signal killed
signal consumed

const TextFloater := preload("res://utils/TextFloater.tscn")

export(bool) var dashable := true

export(float) var acceleration := 600.0
export(float) var turn_acceleration_multiplier := 3.0
export(float) var friction := 1000.0
export(float) var max_speed := 100.0

export(float) var dash_dist := 100.0
export(float) var dash_hit_dur := 0.5
export(float) var fov := 180.0
export(float) var dash_eat_padding := 10.0
export(float) var hit_speed := 40.0
export(float) var hit_speed_drecrement := 10.0
export(float) var min_hit_speed := 10.0

export(float) var lunge_speed := 400.0
export(float) var lunge_friction := 800.0

export(int) var powerup_threshold := 3

var prev_input := Vector2.RIGHT
var input := Vector2()
var velocity := Vector2()
var combo: int = 0
var locked := false setget set_locked
var powerup_count := 0
var knockback_enemies := false

onready var dash_dist_squared := pow(dash_dist, 2)
onready var dash_eat_padding_squared := pow(dash_eat_padding, 2)

onready var pivot := $Pivot
onready var anim_sprite := $Pivot/AnimatedSprite
onready var dash_timer := $DashTimer
onready var topdown_player_states := $TopdownPlayerStates
onready var dash_line := $DashLine
onready var powerup_particles := $PowerupParticles
onready var hit_timer := $HitTimer
onready var start_max_speed := max_speed
onready var no_dash_timer := $NoDashTimer

onready var dash_sfx := $DashSFX
onready var eat_sfx := $EatSFX
onready var powerup_sfx := $PowerupSFX
onready var hurt_sfx := $HurtSFX
onready var ignite_sfx := $IgniteSFX
onready var on_fire_sfx := $OnFireSFX
onready var death_sfx := $DeathSFX


func _process(delta: float) -> void:
	input = Input.get_vector("left", "right", "up", "down")
	if input:
		prev_input = input.normalized()


func set_locked(val: bool) -> void:
	locked = val
	set_process(not val)
	if val:
		input = Vector2()
		topdown_player_states.call_deferred("set_state", "idle")


func play_anim(anim: String) -> void:
	if anim_sprite.animation == "dash" and anim_sprite.animation != "dash":
		return
	anim_sprite.play(anim)


func move(delta: float) -> void:
	apply_acceleration(delta)
	apply_friction(delta)
	velocity = move_and_slide(velocity)
	set_facing(input)


func kill(from: Vector2) -> void:
	hurt_sfx.play()
	death_sfx.play()
	topdown_player_states.call_deferred("set_state", "death")
	emit_signal("killed")


func hit() -> bool:
	match topdown_player_states.state:
		"idle", "walk":
			if hit_timer.is_stopped():
				max_speed = hit_speed
			else:
				max_speed = max(max_speed - hit_speed_drecrement,
						min_hit_speed)
			hit_timer.start()
			hurt_sfx.play()
			no_dash_timer.start()
			var t := create_tween()
			t.tween_property(anim_sprite.get_material(),
					"shader_param/hit_strength", 0.0, hit_timer.wait_time)\
					.from(1.0)
			return true
	return false


func can_dash() -> bool:
	return not locked and powerup_count >= powerup_threshold and dashable\
			and no_dash_timer.is_stopped()


func can_lunge() -> bool:
	return Input.is_action_just_pressed("interact", true) and not locked\
			and (powerup_count < powerup_threshold or not dashable)\
			and no_dash_timer.is_stopped()


func start_lunge() -> void:
	var dashable_food := get_closest_dashable_food(90)
	var lunge_dir: Vector2
	if dashable_food:
		lunge_dir = position.direction_to(dashable_food.position)
	else:
		lunge_dir = prev_input
	velocity = lunge_dir * lunge_speed
	set_facing(lunge_dir)
	dash_sfx.play()


func move_lunge(delta: float) -> void:
	var collision := move_and_collide(velocity * delta)
	if collision and collision.collider.is_in_group("food"):
		topdown_player_states.call_deferred("set_state", "idle")
		powerup_count += 1
		eat_sfx.play()
		anim_sprite.play("idle")
		if knockback_enemies:
			if powerup_count > powerup_threshold:
				collision.collider.knockback(velocity.normalized() * 2)
			else:
				collision.collider.knockback(velocity.normalized())
		else:
			collision.collider.kill()
		velocity = Vector2()
		emit_signal("consumed")
		powerup_sfx.pitch_scale = 1 + (powerup_count - 1) * 0.1
		powerup_sfx.play()
		if powerup_count >= powerup_threshold - 1 and \
				not powerup_particles.emitting:
			powerup_particles.emitting = true
			ignite_sfx.play()
			on_fire_sfx.play()
	else:
		var friction_amount := lunge_friction * delta
		if velocity.length() <= friction_amount:
			velocity = Vector2()
			topdown_player_states.call_deferred("set_state", "idle")
		else:
			velocity -= velocity.normalized() * friction_amount


func dash() -> void:
	var prev_pos := position
	var line_dur: float = dash_timer.wait_time
	
	if dash_line.points.size() <= 1:
		combo = 0
	
	var dash_food := get_closest_dashable_food()
	if dash_food:
		var vec := dash_food.position - position
		if knockback_enemies:
			dash_food.knockback(vec.normalized() * 2)
		else:
			dash_food.kill()
		emit_signal("consumed")
		move_and_collide(vec)
		topdown_player_states.call_deferred("set_state", "idle")
		line_dur = dash_hit_dur
		velocity = vec.normalized() * max_speed
		eat_sfx.play()
		combo += 1
	else:
		combo = 0
		velocity = Vector2()
		dash_timer.start()
		move_and_collide(prev_input * dash_dist)
		dash_sfx.play()
		powerup_count = 0
		powerup_particles.emitting = false
		on_fire_sfx.stop()
	
	if combo > 0:
		var text_floater := TextFloater.instance()
		text_floater.position = position
		text_floater.text = str(combo)
		text_floater.pitch_scale = 1 + min(combo, 20) * 0.1
		get_parent().add_child(text_floater)
	
	var rel_vec := prev_pos - position
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


func get_closest_dashable_food(f: float = fov) -> Node2D:
	var min_dist := 0.0
	var closest_food: Node2D = null
	for food in get_tree().get_nodes_in_group("food"):
		if not food is PhysicsBody2D:
			continue
		if is_pos_dashable(food.position, f):
			var dist := position.distance_squared_to(food.position)
			if not closest_food or dist < min_dist:
				min_dist = dist
				closest_food = food
	return closest_food


func is_pos_dashable(pos: Vector2, f: float = fov) -> bool:
	if position.distance_squared_to(pos) > dash_dist_squared + \
			dash_eat_padding_squared:
		return false
	var dot = prev_input.dot((pos - position).normalized())
	var ang = rad2deg(acos(dot))
	if ang < f / 2:
		return true
	return false


func _on_DashTimer_timeout() -> void:
	topdown_player_states.call_deferred("set_state", "idle")


func _on_AnimatedSprite_animation_finished() -> void:
	if anim_sprite.animation == "dash":
		match topdown_player_states.state:
			"idle":
				anim_sprite.play("idle")
			"walk":
				anim_sprite.play("walk")


func _on_HitTimer_timeout() -> void:
	max_speed = start_max_speed
