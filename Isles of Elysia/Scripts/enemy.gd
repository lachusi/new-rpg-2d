extends CharacterBody2D
class_name Enemy

@export var sight_range_tiles: int = 8

@onready var state_machine: Node = $StateMachine
@onready var world_state_machine: WorldStateMachine = $"../WorldStateMachine"
@onready var animplayer: AnimationPlayer = $AnimationPlayer
@onready var move_component: MoveComponent = $Components/MoveComponent
@onready var weapon_component: Node = $Components/WeaponComponent
@onready var sprite: Sprite2D = $Sprite2D

signal move_completed

var player: Player
var facing_direction: Vector2 = Vector2.RIGHT

func _ready():
	player = get_tree().get_root().find_child("Player", true, false)
	move_component.init(self, animplayer, state_machine)
	state_machine.init(self, world_state_machine, null, move_component, animplayer)

func compute_step_direction(p: Player) -> Vector2:
	if not p:
		return _random_dir()
	var delta := p.position - position
	var tile_size := move_component.tile_size
	var dist_tiles = abs(delta.x)/tile_size + abs(delta.y)/tile_size
	if dist_tiles <= sight_range_tiles and _has_los(p):
		if abs(delta.x) > abs(delta.y):
			return Vector2(sign(delta.x), 0)
		else:
			return Vector2(0, sign(delta.y))
	return _random_dir()
	
func _random_dir() -> Vector2:
	var dirs = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	dirs.shuffle()
	for d in dirs:
		var target = position + d * move_component.tile_size
		if not Tilemanager.is_tile_occupied(target):
			return d
	return Vector2.ZERO

func _has_los(p: Player) -> bool:
	var rc: RayCast2D = get_node_or_null("RayCast2D")
	if not rc:
		return true
	rc.target_position = p.position - position
	rc.force_raycast_update()
	return not rc.is_colliding()

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
