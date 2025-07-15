extends State

@export var tile_size: int = 16
@export var chase_interval: float = 1.0
@export var attack_cooldown := 1.5

@export var attack_state: State
@export var patrol_state: State

var move_timer: float = 0.0
var attack_cooldown_timer: float = 0.0

func enter():
	move_component.move_speed = 3.5
	animplayer.speed_scale = 4.0
	move_timer = 0.0
	attack_cooldown_timer = 0.0
	
func _physics_process(delta: float) -> void:
	if entity == null or move_component == null or entity.player == null:
		return

	move_timer -= delta
	attack_cooldown_timer -= delta  # Cooldown runterzählen
	if move_timer > 0.0 or move_component.is_moving:
		return

	var to_player = entity.player.global_position - entity.global_position

	# DetectionArea prüfen
	var player_detection_area = entity.player.get_node_or_null("DetectionArea")
	var player_detected = false
	if player_detection_area:
		for body in player_detection_area.get_overlapping_bodies():
			if body == entity:
				player_detected = true
				break

	# Kein Sichtkontakt → zurück zur Patrouille
	if not player_detected:
		print("Wechsle zu:", patrol_state)
		state_machine.transition_to(patrol_state)
		return

	# Spieler nahe genug → Attacke starten
	if to_player.length() <= tile_size:
		attack_cooldown_timer = attack_cooldown  # Zurücksetzen
		state_machine.transition_to(attack_state)
		return

	# Richtung berechnen
	var dir = Vector2.ZERO
	if abs(to_player.x) > abs(to_player.y):
		dir.x = sign(to_player.x)
	else:
		dir.y = sign(to_player.y)

	entity.facing_direction = dir

	if move_component.start_move(dir):
		move_timer = chase_interval
		entity.facing_direction = dir
	else:
		move_timer = 0.1  # blockiert, kurz warten
