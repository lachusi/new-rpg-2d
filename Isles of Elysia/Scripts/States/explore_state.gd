extends State

@export var battle_state : State

func init(_entity, _world_state_machine, _input_component = null, _move_component = null, _animplayer = null, _state_machine = null):
	entity = _entity
	world_state_machine = _world_state_machine

func enter():
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		var patrol_state = enemy.get_node_or_null("StateMachine/PatrolState")
		if patrol_state and not patrol_state.is_connected("start_battle", Callable(self, "_on_start_battle")):
			patrol_state.connect("start_battle", Callable(self, "_on_start_battle"))

func _on_start_battle(enemy):
	print("📣 Kampfsignal empfangen im ExploreState!")
	world_state_machine.transition_to(battle_state)
