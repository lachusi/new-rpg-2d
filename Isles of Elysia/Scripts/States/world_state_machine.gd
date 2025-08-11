extends Node
class_name WorldStateMachine

@export var initial_state: State

signal state_changed(new_state)

var current_state: State

var entity
var input_component
var move_component
var animplayer
var state_machine

func init(_entity, _input_component, _move_component, _animplayer, _state_machine):
	print("HERRO")
	entity = _entity
	input_component = _input_component
	move_component = _move_component
	animplayer = _animplayer
	state_machine = _state_machine

	# Initialisierung aller States
	for child in get_children():
		if child is State:
			print("Initialisiere World-State: ", child.name)
			print("Initialisiere World-State: ", self.name)
			child.init(entity, self, input_component, move_component, animplayer, state_machine)

	# Initialer Zustand
	if initial_state:
		print("Ich explore")
		current_state = initial_state
		current_state.enter()
		emit_signal("state_changed", current_state)

func transition_to(new_state: State):
	if not new_state:
		push_error("WorldStateMachine: transition_to() wurde mit null aufgerufen!")
		return

	if current_state:
		current_state.exit()

	current_state = new_state
	current_state.enter()
	emit_signal("state_changed", new_state)

func _unhandled_input(event):
	if current_state:
		current_state._unhandled_input(event)

func _process(delta):
	if current_state:
		current_state._process(delta)

func _physics_process(delta):
	if current_state:
		current_state._physics_process(delta)
