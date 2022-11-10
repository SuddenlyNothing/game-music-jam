extends CanvasLayer

signal view_street(season)

var interacting := false


func task_started() -> void:
	if interacting:
		return
	interacting = true
	get_tree().call_group_flags(2, "room_player", "set_locked", true)
	get_tree().call_group_flags(2, "enterable", "set_hint_visible", false)


func task_ended() -> void:
	interacting = false
	get_tree().call_group_flags(2, "room_player", "set_locked", false)
	get_tree().call_group_flags(2, "enterable", "set_hint_visible", true)


func finished_viewing_street() -> void:
	task_ended()


func _on_Weights_interacted() -> void:
	task_started()


func _on_Bed_interacted() -> void:
	task_started()


func _on_Desk_interacted() -> void:
	task_started()


func _on_Window_interacted() -> void:
	if interacting:
		return
	task_started()
	emit_signal("view_street", "")
