extends Node2D

const FoodEnemy := preload("res://scenes/characters/enemies/FoodEnemy.tscn")

onready var player := $YSort/TopdownPlayer
onready var ysort := $YSort


func _ready() -> void:
	get_tree().call_group("needs_player", "set_player", player)


func _on_SpawnInterval_timeout() -> void:
	var fe := FoodEnemy.instance()
	Variables.rng.randomize()
	fe.position = Vector2(
		Variables.rng.randf_range(10, 438),
		Variables.rng.randf_range(10, 246)
	)
	ysort.add_child(fe)
	get_tree().call_group("needs_player", "set_player", player)
