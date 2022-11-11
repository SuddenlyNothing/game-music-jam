extends BaseTask

onready var platformer := $M/M/PC/M/VC/Viewport/Platformer


# Override
func init(difficulty: float) -> void:
	platformer.start(difficulty)


# Override
func wait_stop() -> void:
	platformer.wait_stop()


func stop() -> void:
	platformer.stop()
	.stop()


func _on_Platformer_collected() -> void:
	add_score()
