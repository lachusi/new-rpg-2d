extends Node
class_name StateMachine

@export var initial_state: State

signal state_changed(new_state)

var current_state: State

var entity
var input_component
var move_component
var animplayer
var world_state_machine

func init(_entity, _world_state_machine, _input_component = null, _move_component = null, _animplayer = null):
	entity = _entity
	world_state_machine = _world_state_machine
	input_component = _input_component
	move_component = _move_component
	animplayer = _animplayer

	for child in get_children():
		if child is State:
			child.init(entity, world_state_machine, input_component, move_component, animplayer, self)

	if initial_state:
		current_state = initial_state
		current_state.enter()
		if entity.has_node("Control/MarginContainer/ColorRect/StateLabel"):
			entity.get_node("Control/MarginContainer/ColorRect/StateLabel").text = str(current_state.name)
		emit_signal("state_changed", current_state)

func transition_to(new_state: State):
	if new_state == null:
		push_error("StateMachine: transition_to(null) ignoriert")
		return
	if new_state == current_state:
		return
	# Aus dem aktuellen State raus
	if current_state:
		current_state.exit()
	# Der neue State ist jetzt der aktuelle State
	current_state = new_state
	current_state.enter()
	if entity.has_node("Control/MarginContainer/ColorRect/StateLabel"):
		entity.get_node("Control/MarginContainer/ColorRect/StateLabel").text = str(new_state.name)
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
