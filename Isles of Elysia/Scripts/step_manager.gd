extends Node

signal step_started
signal step_finished

var player: Player
var enemies: Array = []
var is_stepping: bool = false
var pending_moves: int = 0

func _ready():
	call_deferred("_collect_entities")

func _collect_entities():
	player = get_tree().get_first_node_in_group("player")
	enemies = get_tree().get_nodes_in_group("Enemy")
	if player and not player.is_connected("move_completed", Callable(self, "_on_entity_move_completed")):
		player.connect("move_completed", Callable(self, "_on_entity_move_completed"))
	for e in enemies:
		if e.has_signal("move_completed") and not e.is_connected("move_completed", Callable(self, "_on_entity_move_completed")):
			e.connect("move_completed", Callable(self, "_on_entity_move_completed"))

func start_step(player_dir: Vector2):
	if is_stepping:
		return
	if not player:
		return
	# Spielerbewegung zuerst validieren
	var ok = player.move_component.start_move(player_dir)
	if not ok:
		return

	is_stepping = true
	step_started.emit()
	pending_moves = 1  # Spieler zählt

	# Gegner-Züge (alle gleichzeitig)
	for e in enemies:
		if not is_instance_valid(e): continue
		if e.health_component and not e.health_component.is_alive: continue
		var dir = e.compute_step_direction(player)
		if dir != Vector2.ZERO:
			if e.move_component.start_move(dir):
				pending_moves += 1

	# Falls nur der Spieler sich bewegt (oder niemand), warten wir auf seine Completion
	if pending_moves == 0:
		_finish_step()

func _on_entity_move_completed():
	if not is_stepping:
		return
	pending_moves -= 1
	if pending_moves <= 0:
		_finish_step()

func _finish_step():
	is_stepping = false
	step_finished.emit()
