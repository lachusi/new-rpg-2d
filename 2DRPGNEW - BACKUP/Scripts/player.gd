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

func _ready():
	move_component.init(self, animplayer, state_machine)
	state_machine.init(self, world_state_machine, input_component, move_component, animplayer)

func _unhandled_input(event): state_machine._unhandled_input(event)
func _physics_process(delta): state_machine._physics_process(delta)
func _process(delta): state_machine._process(delta)

func start_attack():
	if weapon_component:
		weapon_component.trigger_hitbox(self, facing_direction)
