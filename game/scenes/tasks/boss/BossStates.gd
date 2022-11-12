extends StateMachine


func _ready() -> void:
	add_state("jump")
	add_state("throw")


# Called on entering state.
# new_state is the state being entered.
# old_state is the state being exited.
func _enter_state(new_state: String, old_state) -> void:
	parent.enter_state(new_state)
