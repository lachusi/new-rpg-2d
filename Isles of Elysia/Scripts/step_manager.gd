extends Node

signal step_started
signal step_finished

var player: Player
var enemies: Array = []

var is_stepping: bool = false
var pending_moves: int = 0

var _allowed_movers := {}
var _active_movers := {}
var _dispatching_batch: bool = false
var _tracked_emitters := {}

func _ready():
	call_deferred("_collect_entities")

func _collect_entities():
	player = get_tree().get_first_node_in_group("Player")
	enemies = get_tree().get_nodes_in_group("Enemy")
	
	if player:
		_connect_move_completed(player)
		
	for e in enemies:
		_connect_move_completed(e)

func refresh_entities():
	_collect_entities()

func _connect_move_completed(node: Node):
	if not is_instance_valid(node):
		return
	if not node.has_signal("move_completed"):
		return
	if _tracked_emitters.has(node):
		return
	# MoveComponent emittiert ohne Argument → Emitter binden
	node.connect("move_completed", Callable(self, "_on_entity_move_completed").bind(node))
	_tracked_emitters[node] = true

func can_entity_move(entity: Node) -> bool:
	return is_stepping and _dispatching_batch and _allowed_movers.has(entity)

func start_step(player_dir: Vector2):
	if is_stepping or not player or player_dir == Vector2.ZERO:
		return false

	is_stepping = true
	step_started.emit()
	pending_moves = 0
	_allowed_movers.clear()
	_active_movers.clear()
	
	_allowed_movers[player] = true
	for e in enemies:
		if is_instance_valid(e):
			_allowed_movers[e] = true
	
	_dispatching_batch = true
	
	if player.move_component and player.move_component.start_move(player_dir):
		pending_moves += 1
	_active_movers[player] = true
	_allowed_movers.erase(player)

	for e in enemies:
		if not is_instance_valid(e):
			continue
		if not e.move_component:
			continue
		var dir = Vector2.ZERO
		if e.has_method("compute_step_direction"):
			dir = e.compute_step_direction(player)
		if dir != Vector2.ZERO and e.move_component.start_move(dir):
			pending_moves += 1
			_active_movers[e] = true
		_allowed_movers.erase(e)

	_dispatching_batch = false

	if pending_moves == 0:
		_finish_step()
	return true

func _on_entity_move_completed(emitter: Node):
	if not is_stepping:
		return
	if _active_movers.has(emitter):
		_active_movers.erase(emitter)
		pending_moves -= 1
		if pending_moves < 0:
			pending_moves = 0
	if pending_moves == 0 or _active_movers.is_empty():
		_finish_step()

func notify_entity_removed(entity: Node):
	if not is_stepping:
		return
	if _active_movers.has(entity):
		_active_movers.erase(entity)
		pending_moves -= 1
		if pending_moves < 0:
			pending_moves = 0
	if pending_moves == 0 or _active_movers.is_empty():
		_finish_step()

func _finish_step():
	if not is_stepping:
		return
	is_stepping = false
	_allowed_movers.clear()
	_active_movers.clear()
	pending_moves = 0
	step_finished.emit()

# Debug / Notfall
func force_finish():
	_finish_step()
