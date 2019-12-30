extends Node
class_name StackFSM

var stack : Array

func _physics_process(delta):
	var current_state_function = get_current_state()
	if current_state_function != null:
		if get_parent().has_method(current_state_function):
			get_parent().call(current_state_function)

func pop_state():
	return stack.pop_back()

func push_state(state):
	if get_current_state() != state:
		stack.push_back(state)

func get_current_state():
	if stack.size() > 0:
		return stack[stack.size() - 1]
	else:
		return null