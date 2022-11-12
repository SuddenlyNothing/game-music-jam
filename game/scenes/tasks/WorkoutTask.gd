extends BaseTask

export(int) var min_x := 44
export(int) var max_x := 340
export(float) var min_normal_speed := 1
export(float) var max_normal_speed := 1.2
export(float) var min_size := 20
export(float) var max_size := 40
export(Color) var easy_color
export(Color) var hard_color

var normal_speed := 1.0
var playing := false
var tw: SceneTreeTween

onready var hit := $Hit
onready var aim := $Aim
onready var anim_player := $Aim/AnimationPlayer
onready var anim_sprite := $M/M/PC/M/VC/Viewport/Player
onready var hit_sfx := $HitSFX
onready var hurt_sfx := $HurtSFX


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("continue", false, true) and playing:
		if is_position_in_hit():
			add_score()
			hit_sfx.play()
			set_hit_pos()
			anim_sprite.frame = 0
			anim_sprite.play("curl")
		else:
			if tw:
				tw.kill()
			tw = create_tween()
			tw.tween_property(anim_player, "playback_speed",
					normal_speed, 0.5).from(0.0)
			hurt_sfx.play()


# Override
func init(difficulty: float) -> void:
	aim.rect_position.x = 187
	normal_speed = lerp(min_normal_speed, max_normal_speed, difficulty)
	hit.rect_size.x = lerp(max_size, min_size, difficulty)
	hit.color = lerp(easy_color, hard_color, difficulty)
	anim_player.playback_speed = normal_speed
	anim_player.play("slide")
	hit.show()
	playing = true
	set_hit_pos()


# Override
func wait_stop() -> void:
	anim_player.stop()
	playing = false


func is_position_in_hit() -> bool:
	var aim_pos: int = aim.rect_position.x + aim.rect_size.x / 2
	return aim_pos > hit.rect_position.x and \
			aim_pos < hit.rect_position.x + hit.rect_size.x


func set_hit_pos() -> void:
	Variables.rng.randomize()
	var new_pos := Variables.rng.randi_range(min_x,
			max_x - hit.rect_size.x)
	while abs(new_pos + hit.rect_size.x / 2 - aim.rect_position.x) < 40:
		new_pos = Variables.rng.randi_range(min_x,
			max_x - hit.rect_size.x)
	hit.rect_position.x = new_pos
