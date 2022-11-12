extends StateMachine

var tracking := false


func _ready() -> void:
	add_state("idle")
	add_state("walk")
	add_state("track")
	call_deferred("set_state", "idle")


# Contains state logic.
func _state_logic(delta: float) -> void:
	match state:
		states.idle:
			parent.move_idle(delta)
		states.walk:
			parent.move(delta)
		states.track:
			parent.move_track(delta)


# Return value will be used to change state.
func _get_transition(delta: float):
	match state:
		states.idle:
			pass
		states.walk:
			pass
	return null


# Called on entering state.
# new_state is the state being entered.
# old_state is the state being exited.
func _enter_state(new_state: String, old_state) -> void:
	match new_state:
		states.idle:
			parent.play_anim("idle")
			parent.start_idle_timer()
		states.walk:
			parent.start_walk_timer()
			parent.play_anim("walk")
		states.track:
			parent.stop_timers()
			parent.play_anim("walk")


# Called on exiting state.
# old_state is the state being exited.
# new_state is the state being entered.
func _exit_state(old_state, new_state: String) -> void:
	match old_state:
		states.idle:
			pass
		states.walk:
			pass


func set_state(new_state: String) -> void:
	if tracking:
		return
	if new_state == "track":
		tracking = true
	.set_state(new_state)
