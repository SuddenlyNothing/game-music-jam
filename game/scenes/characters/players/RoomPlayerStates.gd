extends StateMachine


func _ready() -> void:
	add_state("idle")
	add_state("walk")
	call_deferred("set_state", "idle")


# Contains state logic.
func _state_logic(delta: float) -> void:
	match state:
		states.idle:
			pass
		states.walk:
			parent.move(delta)


# Return value will be used to change state.
func _get_transition(delta: float):
	match state:
		states.idle:
			if parent.input:
				return states.walk
		states.walk:
			if not parent.input:
				return states.idle
	return null


# Called on entering state.
# new_state is the state being entered.
# old_state is the state being exited.
func _enter_state(new_state: String, old_state) -> void:
	match new_state:
		states.idle:
			parent.play_anim("idle")
		states.walk:
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
