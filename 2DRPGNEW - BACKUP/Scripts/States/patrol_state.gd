extends State

@export var idle_state: State

@export_range(1.0, 3.0) var patrol_duration_min := 1.0
@export_range(2.0, 5.0) var patrol_duration_max := 3.0
@export var step_interval := 0.5  # Wie oft ein Schritt versucht wird
const tile_size := 16

var patrol_timer: SceneTreeTimer = null

signal start_battle(enemy)

func enter():
	move_component.move_speed = 2.0
	animplayer.speed_scale = 2.0

	# Prüfe DetectionArea des Players
	if entity.player:
		var player_detection_area = entity.player.get_node_or_null("DetectionArea")
		if player_detection_area:
			for body in player_detection_area.get_overlapping_bodies():
				if body == entity:
					print("👁 Gegner hat Spieler entdeckt – Kampfsignal senden")
					emit_signal("start_battle", entity)
					return

	# Starte zufällige Patrouillierzeit
	var patrol_duration = randf_range(patrol_duration_min, patrol_duration_max)
	patrol_timer = get_tree().create_timer(patrol_duration)
	patrol_timer.timeout.connect(_on_patrol_timeout)

	# Bewegung starten (in zufälliger Richtung)
	var dirs = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	dirs.shuffle()
	for dir in dirs:
		if can_move_in_direction(dir):
			entity.facing_direction = dir
			move_component.start_move(dir)
			break

func _on_patrol_timeout():
	state_machine.transition_to(idle_state)

func exit():
	if patrol_timer:
		patrol_timer.timeout.disconnect(_on_patrol_timeout)
		patrol_timer = null

func can_move_in_direction(dir: Vector2) -> bool:
	var ray = entity.get_node_or_null("RayCast2D")
	if not ray:
		return false
	ray.target_position = dir * tile_size
	ray.force_raycast_update()
	return not ray.is_colliding()
