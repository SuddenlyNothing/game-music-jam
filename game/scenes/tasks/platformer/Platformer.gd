extends Node2D

signal collected

const Coin := preload("res://scenes/tasks/platformer/PlatformerCoin.tscn")
const Platformer := preload(
		"res://scenes/characters/players/BasicPlatformer.tscn")

export(int) var num_coins := 30

var picked_coins := {}
var used_coins := 0
var player: Node

onready var easy_coins := $EasyCoins
onready var medium_coins := $MediumCoins
onready var hard_coins := $HardCoins
onready var picked_sfx := $PickedSFX
onready var camera := $Camera2D


func start(difficulty: float) -> void:
	picked_coins = {}
	used_coins = 0
	if player and is_instance_valid(player):
		player.queue_free()
	player = Platformer.instance()
	add_child(player)
	if difficulty > 0.7:
		spawn_coins_from_array(hard_coins.get_children())
	elif difficulty > 0.4:
		spawn_coins_from_array(medium_coins.get_children())
	else:
		spawn_coins_from_array(easy_coins.get_children())


func wait_stop() -> void:
	player.set_locked(true)


func stop() -> void:
	player.queue_free()
	camera.current = true
	get_tree().call_group("coins", "queue_free")


func spawn_coins_from_array(coins: Array) -> void:
	Variables.rng.randomize()
	while used_coins < num_coins:
		var coin_pos: Node2D = coins[Variables.rng.randi_range(0,
				len(coins) - 1)]
		if not coin_pos in picked_coins:
			picked_coins[coin_pos] = 1
			var c := Coin.instance()
			c.position = coin_pos.global_position
			c.connect("collected", self, "coin_picked")
			add_child(c)
			used_coins += 1


func coin_picked() -> void:
	emit_signal("collected")
	picked_sfx.play()
