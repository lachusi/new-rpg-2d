extends State

@export var patrol_state: State
@export var attack_state: State
@export var step_interval := 0.3

var step_timer := 0.0

func enter():
	step_timer = 0.0

func _physics_process(delta: float) -> State:
	if not entity.player:
		return patrol_state

	# Verliert Sicht?
	if entity.distance_tiles_to_player() > entity.sight_range_tiles or not entity.has_line_of_sight_to_player():
		return patrol_state

	# In Angriffsreichweite?
	if entity.move_component.can_attack(entity.player):
		return attack_state

	step_timer -= delta
	if step_timer <= 0.0:
		var delta_pos = entity.player.global_position - entity.global_position
		var dir = Vector2.ZERO
		if abs(delta_pos.x) > abs(delta_pos.y):
			dir.x = sign(delta_pos.x)
		else:
			dir.y = sign(delta_pos.y)
		entity.step_intent = dir
		step_timer = step_interval
	return null
