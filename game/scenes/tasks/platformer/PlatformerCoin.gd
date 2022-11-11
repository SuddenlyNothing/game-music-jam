extends Area2D

signal collected


func _on_PlatformerCoin_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	emit_signal("collected")
	queue_free()
