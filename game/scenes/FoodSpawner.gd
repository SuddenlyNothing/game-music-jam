extends Node2D

signal food_ate
signal finished_eating

const RandomFood := preload("res://scenes/environment/RandomFood.tscn")

var remaining := 0
var yet_to_eat := 0

onready var timer := $Timer
onready var target_node: Node2D


func start(amt: int) -> void:
	remaining = amt
	yet_to_eat = amt
	start_timer()


func start_timer() -> void:
	timer.start(randf() * 0.2)


func ate_food() -> void:
	emit_signal("food_ate")
	yet_to_eat -= 1
	if yet_to_eat <= 0:
		emit_signal("finished_eating")


func _on_Timer_timeout() -> void:
	if remaining > 0:
		remaining -= 1
		start_timer()
	var rf := RandomFood.instance()
	rf.position = Vector2.UP * (randf() - 0.5) * 60
	rf.target = target_node
	rf.connect("ate", self, "ate_food")
	add_child(rf)
