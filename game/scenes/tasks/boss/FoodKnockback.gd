extends Node2D

const DeathParticles := preload(
		"res://scenes/characters/enemies/DeathParticles.tscn")

const FOODS := [
	"pizza",
	"burger",
	"fries",
	"donut",
]

export(Vector2) var dir := Vector2.RIGHT
export(float) var speed := 300.0

var food: String
var facing := 1

onready var anim_sprite := $AnimatedSprite


func _ready() -> void:
	print(dir * speed)
	anim_sprite.scale.x = facing
	anim_sprite.play("idle_" + food)
	var t := create_tween()
	t.tween_property(get_material(), "shader_param/hit_strength", 0.0,
			$DeathTimer.wait_time)


func _physics_process(delta: float) -> void:
	position += dir * speed * delta


func _on_DeathTimer_timeout() -> void:
	var dp := DeathParticles.instance()
	dp.position = anim_sprite.global_position
	get_parent().add_child(dp)
	queue_free()
