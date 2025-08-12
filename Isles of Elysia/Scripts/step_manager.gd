extends Node

signal step_started
signal step_finished

var player: Player
var enemies: Array = []
var is_stepping: bool = false
var pending_moves: int = 0
var _allowed_movers := {}
var _dispatching_batch := false

func _ready():
	call_deferred("_collect_entities")

func _collect_entities():
	player = get_tree().get_first_node_in_group("Player")
	enemies = get_tree().get_nodes_in_group("Enemy")
	
	if player and not player.is_connected("move_completed", Callable(self, "_on_entity_move_completed")):
		player.connect("move_completed", Callable(self, "_on_entity_move_completed"))
	for e in enemies:
		if e.has_signal("move_completed") and not e.is_connected("move_completed", Callable(self, "_on_entity_move_completed")):
			e.connect("move_completed", Callable(self, "_on_entity_move_completed"))

func refresh_entities():
	player = get_tree().get_first_node_in_group("Player")
	enemies = get_tree().get_nodes_in_group("Enemy")

func can_entity_move(entity: Node) -> bool:
	return is_stepping and _dispatching_batch and _allowed_movers.has(entity)

func start_step(player_dir: Vector2):
	if is_stepping or not player or player_dir == Vector2.ZERO:
		return false

	is_stepping = true
	step_started.emit()
	pending_moves = 0
	_allowed_movers.clear()
	
	_allowed_movers[player] = true
	for e in enemies:
		if is_instance_valid(e):
			_allowed_movers[e] = true

	_dispatching_batch = true  # Ab hier dürfen start_move-Aufrufe laufen

	# Hinweis: is_stepping ist bereits true, damit Player.start_move nicht rekursiv wieder start_step aufruft
	if player.move_component.start_move(player_dir):
		pending_moves += 1
	_allowed_movers.erase(player)
	
	# Gegner-Züge (alle gleichzeitig)
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var dir = e.compute_step_direction(player)
		if dir != Vector2.ZERO and e.move_component.start_move(dir):
			pending_moves += 1
		_allowed_movers.erase(e)
		
	_dispatching_batch = false

	# Falls nur der Spieler sich bewegt (oder niemand), warten wir auf seine Completion
	if pending_moves == 0:
		_finish_step()
	return true

func _on_entity_move_completed():
	if not is_stepping:
		return
	pending_moves -= 1
	if pending_moves <= 0:
		_finish_step()

func _finish_step():
	is_stepping = false
	_allowed_movers.clear()
	step_finished.emit()
