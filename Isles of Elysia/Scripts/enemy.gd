extends CharacterBody2D
class_name Enemy

@onready var state_machine: Node = $StateMachine
@onready var world_state_machine: WorldStateMachine = $"../WorldStateMachine"
@onready var animplayer: AnimationPlayer = $AnimationPlayer
@onready var move_component: MoveComponent = $Components/MoveComponent
@onready var weapon_component: Node = $Components/WeaponComponent
@onready var sprite: Sprite2D = $Sprite2D

var player: Node2D = null
var facing_direction: Vector2 = Vector2.RIGHT

func _ready():
	player = get_tree().get_root().find_child("Player", true, false)
	move_component.init(self, animplayer, state_machine)
	state_machine.init(self, world_state_machine, null, move_component, animplayer)

func get_component(name: String) -> Node:
	var components_node = get_node_or_null("Components")
	if components_node and components_node.has_node(name):
		return components_node.get_node(name)
	return null

func on_player_detected(p: Node2D):
	player = p
	var chase_state = state_machine.get_node_or_null("ChaseState")
	if chase_state and state_machine.current_state != chase_state:
		state_machine.transition_to(chase_state)

func start_attack():
	if weapon_component:
		weapon_component.trigger_hitbox(self, facing_direction)
