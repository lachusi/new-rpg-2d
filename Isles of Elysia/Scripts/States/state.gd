class_name State
extends Node

var state_machine: Node = null
var world_state_machine: Node = null
var entity: Node = null  # z. B. Player, Enemy, NPC
var input_component
var move_component: Node = null
var animplayer
var weapon_component

func init(_entity, _world_state_machine, _input, _move, _anim, _state_machine):
	entity = _entity
	world_state_machine = _world_state_machine
	input_component = _input
	move_component = _move
	animplayer = _anim
	state_machine = _state_machine
	
	# Optionale Komponenten automatisch abrufen, falls vorhanden
	if entity.has_node("InputComponent"):
		input_component = entity.get_node("InputComponent")
	if entity.has_node("MoveComponent"):
		move_component = entity.get_node("MoveComponent")
	if entity.has_node("AnimationPlayer"):
		animplayer = entity.get_node("AnimationPlayer")
	if entity.has_node("WeaponComponent"):
		weapon_component = entity.get_node("WeaponComponent")

# Wird in den richtigen States erst ausgerufen
func enter(): pass
func exit(): pass
func _unhandled_input(event): pass
func _process(delta): pass
func _physics_process(delta): pass
