extends CharacterBody2D
class_name Player

@onready var state_machine: Node = $StateMachine
@onready var world_state_machine: WorldStateMachine = $"../WorldStateMachine"
@onready var input_component: Node = $Components/InputComponent
@onready var move_component: Node = $Components/MoveComponent
@onready var animplayer: AnimationPlayer = $AnimationPlayer
@onready var weapon_component: Node = $Components/WeaponComponent
@onready var sprite: Sprite2D = $Sprite2D

var facing_direction: Vector2 = Vector2.RIGHT
var can_move: bool = true
var turn_manager: TurnManager = null
var step_manager: StepManager
var next_step_dir: Vector2 = Vector2.ZERO

signal move_completed

func _ready():
	add_to_group("Player")
	step_manager = get_node_or_null("/root/StepManager")
	move_component.init(self, animplayer, state_machine)
	state_machine.init(self, world_state_machine, input_component, move_component, animplayer)

	# Turn Manager Verbindung nach einem Frame
	call_deferred("_connect_turn_manager")

func _connect_turn_manager():
	turn_manager = get_node_or_null("/root/TurnManager")
	if turn_manager:
		turn_manager.player_turn_started.connect(_on_player_turn_started)
		turn_manager.enemy_turn_started.connect(_on_enemy_turn_started)

func _on_player_turn_started():
	can_move = true

func _on_enemy_turn_started():
	can_move = false

func _unhandled_input(event):
	if not step_manager or step_manager.is_stepping:
		return
	if can_move:
		state_machine._unhandled_input(event)
func _physics_process(delta): state_machine._physics_process(delta)
func _process(delta): state_machine._process(delta)

func start_attack():
	# Prüfen, ob vor dem Spieler ein lebender Gegner steht
	var tile = move_component.tile_size
	var target_pos = global_position + facing_direction * tile
	var has_live_target := false
	for e in get_tree().get_nodes_in_group("Enemy"):
		if not is_instance_valid(e):
			continue
		if e.global_position == target_pos:
			var hc: HealthComponent = e.get_node_or_null("Components/HealthComponent")
			if hc and hc.is_alive:
				has_live_target = true
				break
	if not has_live_target:
		return  # kein lebendes Ziel → kein Angriff
	if weapon_component:
		weapon_component.trigger_hitbox(self, facing_direction)
