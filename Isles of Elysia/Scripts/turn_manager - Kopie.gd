extends Node

var turn_queue: Array = []
var current_turn_index: int = 0
var in_battle: bool = false

signal turn_started(entity)
signal battle_ended

func start_battle(entities: Array):
	turn_queue = entities.duplicate()
	current_turn_index = 0
	in_battle = true
	emit_signal("turn_started", turn_queue[current_turn_index])

func end_battle():
	in_battle = false
	turn_queue.clear()
	emit_signal("battle_ended")

func next_turn():
	if not in_battle or turn_queue.is_empty():
		return
	current_turn_index = (current_turn_index + 1) % turn_queue.size()
	emit_signal("turn_started", turn_queue[current_turn_index])

func remove_entity(entity):
	turn_queue.erase(entity)
	if turn_queue.is_empty():
		end_battle()
	elif current_turn_index >= turn_queue.size():
		current_turn_index = 0
		emit_signal("turn_started", turn_queue[current_turn_index])
