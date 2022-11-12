extends Area2D

const FoodEnemy := preload("res://scenes/characters/enemies/FoodEnemy.tscn")
const DeathParticles := preload(
		"res://scenes/characters/enemies/DeathParticles.tscn")

const FOODS := [
	"pizza",
	"burger",
	"fries",
	"donut",
]

export(float) var move_speed := 100
export(Vector2) var dir := Vector2.ONE

var food := "pizza"
var player: Node2D
var rot_speed := 2 * PI

onready var anim_sprite := $AnimatedSprite


func _ready() -> void:
	Variables.rng.randomize()
	if dir == Vector2():
		dir = Vector2.RIGHT.rotated(Variables.rng.randf() * 2 * PI)
	food = FOODS[Variables.rng.randi_range(0, len(FOODS) - 1)]
	anim_sprite.play("idle_" + food)
	anim_sprite.rotation = Variables.rng.randf() * 2 * PI
	rot_speed = Variables.rng.randf_range(-8 * PI, 8 * PI)


func _process(delta: float) -> void:
	anim_sprite.rotation += rot_speed * delta


func _physics_process(delta: float) -> void:
	position += move_speed * dir * delta


func _on_SpawnTimer_timeout() -> void:
	if Rect2(0, 0, 384, 256).has_point(position):
		var fe := FoodEnemy.instance()
		fe.position = position
		fe.randomize_food = false
		fe.food = food
		fe.target = player
		fe.track = true
		get_parent().add_child(fe)
	queue_free()


func _on_FoodProjectile_body_entered(body: Node) -> void:
	if not body == player:
		return
	if player.hit():
		var death_particles := DeathParticles.instance()
		death_particles.position = anim_sprite.global_position
		get_parent().add_child(death_particles)
		queue_free()
