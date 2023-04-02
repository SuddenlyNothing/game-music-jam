extends AnimatedSprite

signal ate

var target_offset := Vector2(0, -42)
var rot_speed: float
var speed: float
var rng := RandomNumberGenerator.new()
var target: Node2D

onready var eat_sfx := $EatSFX
onready var hit_sfx := $HitSFX


func _ready() -> void:
	rng.randomize()
	speed = rng.randf_range(400, 500)
	rot_speed = rng.randf_range(-5, 5)
	play(str(rng.randi_range(0, 3)))


func _physics_process(delta: float) -> void:
	var move_amount := speed * delta
	if global_position.distance_squared_to(
			target.global_position + target_offset) <= pow(move_amount, 2):
		eat_sfx.play()
		hit_sfx.play()
		hide()
		emit_signal("ate")
		set_physics_process(false)
		return
	rotation += PI * 2 * rot_speed * delta
	position += global_position.direction_to(target.global_position +\
			target_offset) * move_amount


func _on_EatSFX_finished() -> void:
	queue_free()
