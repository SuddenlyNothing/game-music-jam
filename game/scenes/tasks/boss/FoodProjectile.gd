extends KinematicBody2D

const FoodEnemy := preload("res://scenes/characters/enemies/FoodEnemy.tscn")
const DeathParticles := preload(
		"res://scenes/characters/enemies/DeathParticles.tscn")
const FoodKnockback := preload("res://scenes/tasks/boss/FoodKnockback.tscn")

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
var velocity := Vector2()

onready var anim_sprite := $AnimatedSprite


func _ready() -> void:
	Variables.rng.randomize()
	if dir == Vector2():
		dir = Vector2.RIGHT.rotated(Variables.rng.randf() * 2 * PI)
	food = FOODS[Variables.rng.randi_range(0, len(FOODS) - 1)]
	anim_sprite.play("idle_" + food)
	anim_sprite.rotation = Variables.rng.randf() * 2 * PI
	rot_speed = Variables.rng.randf_range(-8 * PI, 8 * PI)
	velocity = dir * move_speed


func _process(delta: float) -> void:
	anim_sprite.rotation += rot_speed * delta


func _physics_process(delta: float) -> void:
	var collision := move_and_collide(velocity * delta)
	if collision:
		if collision.collider == player and player.hit():
			kill()
		else:
			velocity = velocity.bounce(collision.normal)


func knockback(dir: Vector2) -> void:
	var fk := FoodKnockback.instance()
	fk.position = position
	fk.food = food
	fk.dir = dir
	get_parent().add_child(fk)
	queue_free()


func kill() -> void:
	var dp := DeathParticles.instance()
	dp.position = anim_sprite.global_position
	get_parent().add_child(dp)
	queue_free()


func _on_SpawnTimer_timeout() -> void:
	var fe := FoodEnemy.instance()
	fe.position = position
	fe.randomize_food = false
	fe.food = food
	fe.target = player
	Variables.rng.randomize()
	if Variables.rng.randf() > 0.4:
		fe.track = true
	get_parent().add_child(fe)
	queue_free()


func _on_Hitbox_body_entered(body: Node) -> void:
	if not body == player:
		return
	if player.hit():
		var death_particles := DeathParticles.instance()
		death_particles.position = anim_sprite.global_position
		get_parent().add_child(death_particles)
		queue_free()
