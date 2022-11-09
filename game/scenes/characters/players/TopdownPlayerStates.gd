extends StateMachine


func _ready() -> void:
	add_state("idle")
	add_state("walk")
	add_state("dash")
	add_state("death")
	call_deferred("set_state", "idle")


# Contains state logic.
func _state_logic(delta: float) -> void:
	match state:
		states.idle:
			parent.move(delta)
		states.walk:
			
			parent.move(delta)
		states.dash:
			pass
		states.death:
			pass


# Return value will be used to change state.
func _get_transition(delta: float):
	match state:
		states.idle:
			if Input.is_action_just_pressed("dash"):
				return states.dash
			if parent.input:
				return states.walk
		states.walk:
			if Input.is_action_just_pressed("dash"):
				return states.dash
			if not parent.input:
				return states.idle
		states.dash:
			pass
		states.death:
			pass
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
		states.dash:
			parent.play_anim("dash")
			parent.dash()
		states.death:
			parent.play_anim("death")


# Called on exiting state.
# old_state is the state being exited.
# new_state is the state being entered.
func _exit_state(old_state, new_state: String) -> void:
	match old_state:
		states.idle:
			pass
		states.walk:
			pass
		states.dash:
			pass
		states.death:
			pass
