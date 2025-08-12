extends Node2D

@onready var world_state_machine: WorldStateMachine = $WorldStateMachine
@onready var player = $Player

func _ready():
	if world_state_machine:
		world_state_machine.init(
			self,
			null,
			null,
			null,
			null
		)

func _process(delta: float) -> void: pass
