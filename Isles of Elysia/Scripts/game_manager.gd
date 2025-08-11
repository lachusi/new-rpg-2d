extends Node2D

@onready var state_machine = $StateMachine
@onready var world_state_machine: WorldStateMachine = $WorldStateMachine
@onready var input_component = $Components/InputComponent
@onready var move_component = $Components/MoveComponent
@onready var animplayer = $AnimationPlayer
@onready var player = $Player

func _ready():
	if world_state_machine:
		world_state_machine.init(
			self,
			state_machine,
			input_component,
			move_component,
			animplayer
		)

func _process(delta: float) -> void: pass
