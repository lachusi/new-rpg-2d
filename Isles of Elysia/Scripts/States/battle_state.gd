extends State

@export var explore_state: State

func init(_entity, _world_state_machine, _input_component = null, _move_component = null, _animplayer = null, _state_machine = null):
	entity = _entity
	world_state_machine = _world_state_machine

func _process(_delta):
	if Input.is_action_just_pressed("end_battle"):
		TurnManager.end_battle()


func enter():
	print("⚔ Kampfrunde gestartet!")
	if not TurnManager.is_connected("player_turn_started", Callable(self, "_on_player_turn_started")):
		TurnManager.connect("player_turn_started", Callable(self, "_on_player_turn_started"))
	if not TurnManager.is_connected("battle_ended", Callable(self, "_on_battle_ended")):
		TurnManager.connect("battle_ended", Callable(self, "_on_battle_ended"))

func exit():
	if TurnManager.is_connected("player_turn_started", Callable(self, "_on_player_turn_started")):
		TurnManager.disconnect("player_turn_started", Callable(self, "_on_player_turn_started"))
	if TurnManager.is_connected("battle_ended", Callable(self, "_on_battle_ended")):
		TurnManager.disconnect("battle_ended", Callable(self, "_on_battle_ended"))

func _on_turn_started(current_entity):
	if current_entity == entity.player:
		print("🎮 Spieler ist dran.")
	else:
		print("🤖 Gegner ist dran.")

func _on_battle_ended():
	print("✅ Kampf beendet. Zurück zu ExploreState.")
		# Optional: Zustand aller Gegner zurücksetzen (Zum Testen)
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		var enemy_sm = enemy.get_node_or_null("StateMachine")
		var idle_state = enemy_sm.get_node_or_null("IdleState")
		if enemy_sm and idle_state:
			enemy_sm.transition_to(idle_state)	
	world_state_machine.transition_to(explore_state)
