extends Node

signal player_turn_started
signal enemy_turn_started
signal battle_ended

var in_battle: bool = false
var turn_queue: Array = []   # enthält Player + Enemies in Zugreihenfolge
var current_turn_index: int = 0

var player: Player = null
var enemies: Array = []

func _ready():
	call_deferred("setup_entities")
	
func setup_entities():
	player = get_tree().get_first_node_in_group("Player")
	enemies = get_tree().get_nodes_in_group("Enemies")

	turn_queue.clear()
	if player:
		turn_queue.append(player)
		player.move_completed.connect(_on_entity_move_completed)

	for enemy in enemies:
		if is_instance_valid(enemy):
			turn_queue.append(enemy)
			if enemy.has_signal("move_completed"):
				enemy.move_completed.connect(_on_entity_move_completed)

func start_battle():
	if turn_queue.is_empty():
		return
	in_battle = true
	current_turn_index = 0
	_start_current_turn()

func end_battle():
	in_battle = false
	turn_queue.clear()
	emit_signal("battle_ended")

func remove_entity(entity):
	turn_queue.erase(entity)
	enemies.erase(entity)
	if turn_queue.is_empty():
		end_battle()
	elif current_turn_index >= turn_queue.size():
		current_turn_index = 0
		_start_current_turn()

func _start_current_turn():
	if not in_battle:
		return

	var entity = turn_queue[current_turn_index]
	if entity == player:
		player_turn_started.emit()
	else:
		enemy_turn_started.emit()

	# Entität führt ihren Zug aus
	if is_instance_valid(entity):
		if entity.has_method("take_turn"):
			entity.take_turn()
	else:
		_on_entity_move_completed()

func _on_entity_move_completed():
	if not in_battle:
		return

	# Nächste Entität
	current_turn_index = (current_turn_index + 1) % turn_queue.size()
	_start_current_turn()
