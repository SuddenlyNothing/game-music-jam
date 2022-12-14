extends KinematicBody2D

export(String, "1", "2", "3") var act := "1"
export(int) var move_speed := 40
export(float) var leave_distance := 2.5
export(int) var num_slides := 4
export(bool) var locked := false setget set_locked
export(bool) var start_left := false

var input := Vector2()
var enter_point := Vector2()
var entered_collision: PhysicsBody2D
var disabled := false setget set_disabled

onready var leave_distance_squared := pow(leave_distance, 2)

onready var player_puppet := $PlayerPuppet


func _ready() -> void:
	player_puppet.act = act
	if locked:
		set_process(false)
	if start_left:
		player_puppet.set_facing(Vector2.LEFT)


func _process(delta: float) -> void:
	input = Input.get_vector("left", "right", "up", "down")


func move(delta: float) -> void:
	player_puppet.set_facing(input)
	var velocity := input * move_speed
	for i in 4:
		var collision = move_and_collide(velocity * delta)
		if collision:
			if collision.collider.is_in_group("enterable"):
				if collision.collider == entered_collision:
					break
				enter_point = position
				if entered_collision:
					entered_collision.exit()
				entered_collision = collision.collider
				entered_collision.enter(act, self)
				player_puppet.hide()
				player_puppet.muted = true
				break
			else:
				velocity = velocity.slide(collision.normal)
		else:
			if entered_collision and position.distance_squared_to(enter_point)\
					> leave_distance_squared:
				player_puppet.show()
				entered_collision.exit()
				entered_collision = null
				player_puppet.muted = false
			break


func play_anim(anim: String) -> void:
	player_puppet.play_anim(anim)


func set_locked(val: bool) -> void:
	locked = val
	if val:
		set_process(false)
		input = Vector2()
	else:
		set_process(true)


func set_disabled(val: bool) -> void:
	disabled = val
	if val:
		set_process(false)
		input = Vector2()
		player_puppet.show()
		player_puppet.muted = false
		if entered_collision:
			entered_collision.exit()
			entered_collision = null
	else:
		set_process(true)
