extends Control

signal max_points_reached
signal added_points

const LineParticles := preload("res://scenes/ui/LineParticle.tscn")

export(int) var max_points := 100
export(float) var dur := 1.0
export(float) var particle_dur := 0.5
export(float) var points_dur := 2.0
export(float) var enter_dur := 0.5

var points: int = 0
var adding_points: int = 0
var t: SceneTreeTween
var bar_t: SceneTreeTween

onready var bar := $M/Bar
onready var bar_end := $M/Bar/BarEnd
onready var points_label := $M2/H/PointsLabel
onready var mult_label := $M2/H/MultLabel
onready var total_label := $M2/TotalLabel
onready var cover := $Cover
onready var h := $M2/H


func _process(delta: float) -> void:
	bar_end.position.x = lerp(2, bar.rect_size.x - 2, bar.value)


func set_new_bar(new_max: int) -> void:
	max_points = new_max
	points = 0
	bar.value = 0


func add_points(p: int, mult: float) -> void:
	show()
	var start_points = points
	var total_points = ceil(p * mult)
	points = min(points + total_points, max_points)
	adding_points = total_points
	points_label.text = str(p)
	mult_label.text = str(mult)
	total_label.text = str(total_points)
	total_label.rect_pivot_offset = total_label.rect_size / 2
	total_label.rect_scale = Vector2()
	h.set("custom_constants/separation", 5)
	cover.show()
	cover.modulate.a = 0
	total_label.hide()
	if t:
		t.kill()
	h.show()
	t = create_tween().set_trans(Tween.TRANS_QUAD)
	t.tween_property(cover, "modulate:a", 1.0, enter_dur)
	t.tween_interval(points_dur / 5)
	t.tween_property(h, "custom_constants/separation", 50, points_dur / 5)\
			.set_ease(Tween.EASE_OUT)
	t.tween_property(h, "custom_constants/separation", -20, points_dur / 5)\
			.set_ease(Tween.EASE_IN)
	t.tween_callback(h, "hide")
	t.tween_callback(total_label, "show")
	t.tween_property(total_label, "rect_scale", Vector2.ONE * 3,
			points_dur / 5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	t.tween_property(total_label, "rect_scale", Vector2.ONE,
			points_dur / 5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	if bar_t:
		bar_t.kill()
	bar_t = create_tween().set_trans(Tween.TRANS_QUAD)
	bar_t.tween_interval(particle_dur + points_dur + enter_dur)
	for i in total_points:
		t.tween_callback(self, "spawn_particle")
		t.tween_interval(dur / total_points)
		bar_t.tween_property(bar, "value",
				lerp(float(start_points) / max_points,
				float(points) / max_points,
				(i + 1) / total_points),
				dur / total_points)
	bar_t.tween_interval(0.5)
	bar_t.tween_callback(total_label, "hide")
	bar_t.tween_property(cover, "modulate:a", 0.0, 0.5)
	bar_t.tween_callback(cover, "hide")
	if points >= max_points:
		bar_t.tween_callback(self, "emit_signal", ["max_points_reached"])
	else:
		bar_t.tween_callback(self, "emit_signal", ["added_points"])


func spawn_particle(dur: float = particle_dur) -> void:
	adding_points -= 1
	total_label.text = str(adding_points)
	var lp := LineParticles.instance()
	lp.position = Vector2(192, 128)
	lp.target = bar_end
	lp.duration = dur
	add_child(lp)
