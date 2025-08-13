extends State

@export var idle_state: State
@export var chase_state: State

@export_range(1.0, 3.0) var patrol_duration_min := 1.0
@export_range(2.0, 5.0) var patrol_duration_max := 3.0
@export var step_interval := 0.8  # Wie oft ein Schritt versucht wird
const tile_size := 16

var step_timer := 0.0
var patrol_timer: SceneTreeTimer = null

signal start_battle

func enter():
	step_timer = 0.0

func _set_random_step_intent():
	var dirs = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	dirs.shuffle()
	for d in dirs:
		if _can_move_dir(d):
			if "step_intent" in entity:
				entity.step_intent = d
			if "facing_direction" in entity:
				entity.facing_direction = d
			if entity.move_component:
				entity.move_component.last_direction = d

func _physics_process(delta: float) -> State:
	# Sichtprüfung: Distanz + LOS
	if entity.player and entity.distance_tiles_to_player() <= entity.sight_range_tiles and entity.has_line_of_sight_to_player():
		return chase_state

	# Nur wenn kein Sichtkontakt: zufällige Schritt-Intention setzen
	step_timer -= delta
	if step_timer <= 0.0:
		var dirs = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
		dirs.shuffle()
		for d in dirs:
			if _can_move_dir(d):
				entity.step_intent = d
				break
		step_timer = step_interval

	return null

func _can_move_dir(d: Vector2) -> bool:
	var rc: RayCast2D = entity.get_node_or_null("RayCast2D")
	if not rc:
		return true
	rc.target_position = d * entity.move_component.tile_size
	rc.force_raycast_update()
	return not rc.is_colliding()
