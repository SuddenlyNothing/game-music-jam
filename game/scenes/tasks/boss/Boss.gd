extends Area2D

const FoodProjectile := preload("res://scenes/tasks/boss/FoodProjectile.tscn")

var player: Node2D
var t: SceneTreeTween

onready var anim_sprite := $AnimatedSprite
onready var boss_states := $BossStates
onready var collision := $CollisionShape2D
onready var change_state_timer := $ChangeStateTimer
onready var mark := $Mark
onready var shadow := $Shadow
onready var throw_pos := $AnimatedSprite/ThrowPos
onready var land_sfx := $LandSFX


func _ready() -> void:
	anim_sprite.offset.y = -600
	anim_sprite.show()
	if t:
		t.kill()
	t = create_tween()
	t.tween_property(anim_sprite, "offset:y", 0.0, 1.0)
	t.tween_callback(land_sfx, "play")
	t.tween_callback(shadow, "show")
	t.tween_callback(get_tree(), "call_group",
			["effects_camera", "shake", 1])
	t.tween_callback(player, "set_locked", [false]).set_delay(1.0)
	change_state_timer.start(3)


func _process(delta: float) -> void:
	set_facing(player.position - position)


func set_facing(dir: Vector2) -> void:
	if (anim_sprite.scale.x < 0 and dir.x > 0) or \
			(anim_sprite.scale.x > 0 and dir.x < 0):
		anim_sprite.scale.x *= -1


func set_player(p: Node2D) -> void:
	player = p


func enter_state(state) -> void:
	match state:
		"jump":
			anim_sprite.play("jump")
		"throw":
			anim_sprite.play("throw")


func _on_AnimatedSprite_animation_finished() -> void:
	match anim_sprite.animation:
		"jump":
			anim_sprite.play("airborne")
			collision.call_deferred("set_disabled", true)
			shadow.hide()
			if t:
				t.kill()
			t = create_tween()
			t.tween_property(anim_sprite, "offset:y", -600.0, 1)
			t.tween_callback(self, "goto_player")
			t.tween_callback(mark, "show")
			t.tween_property(anim_sprite, "offset:y", 0.0, 0.5)
			t.tween_callback(shadow, "show")
			t.tween_callback(mark, "hide")
			t.tween_callback(anim_sprite, "play", ["land"])
			t.tween_callback(land_sfx, "play")
			t.tween_callback(collision, "call_deferred",
					["set_disabled", false])
			t.tween_callback(get_tree(), "call_group",
					["effects_camera", "shake", 0.4])
		"throw":
			pick_rand_state()
#			Variables.rng.randomize()
#			change_state_timer.start(Variables.rng.randf_range(0.1, 0.3))
			anim_sprite.play("idle")
		"land":
			pick_rand_state()
#			Variables.rng.randomize()
#			change_state_timer.start(Variables.rng.randf_range(0.1, 0.3))
			anim_sprite.play("idle")


func goto_player() -> void:
	Variables.rng.randomize()
	var new_pos: Vector2 = player.position + player.velocity * \
			Variables.rng.randf_range(0, 0.5)
	position = Vector2(
		clamp(new_pos.x, 0, 384),
		clamp(new_pos.y, 0, 256)
	)


func _on_ChangeStateTimer_timeout() -> void:
	pick_rand_state()


func pick_rand_state() -> void:
	Variables.rng.randomize()
	if Variables.rng.randf() > 0.6:
		boss_states.call_deferred("set_state", "jump")
	else:
		boss_states.call_deferred("set_state", "throw")


func _on_AnimatedSprite_frame_changed() -> void:
	if anim_sprite.animation == "throw" and anim_sprite.frame == 4:
		var f := FoodProjectile.instance()
		f.position = position
		f.dir = throw_pos.global_position.direction_to(player.position)
		f.player = player
		get_parent().add_child(f)


func _on_Boss_body_entered(body: Node) -> void:
	if not body == player:
		return
	player.kill(position)
