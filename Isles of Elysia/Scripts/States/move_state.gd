extends State

@export var idle_state: State
@export var attack_state: State

func enter():
	# Keine Aktionen in enter ausführen (Vermeidet Konflikte)
	pass

func _physics_process(delta):
	if not input_component:
		return
	var dir = input_component.get_move_input()

	if dir == Vector2.ZERO:
		state_machine.transition_to(idle_state)
		return
		
	# Blickrichtung immer setzen, auch wenn Bewegung blockiert ist
	entity.facing_direction = dir
	move_component.last_direction = dir

	# Bewegung starten
	if not move_component.is_moving:
		if move_component.start_move(dir):
			return
			
		# Blockiert: Prüfen ob lebender Gegner vor uns -> AttackState
		var tile := float(move_component.tile_size)
		var target_pos = entity.global_position + dir * tile
		if _live_enemy_at(target_pos):
			state_machine.transition_to(attack_state)
			return
		# sonst Idle
		state_machine.transition_to(idle_state)
		
func _live_enemy_at(pos: Vector2) -> bool:
	for e in get_tree().get_nodes_in_group("Enemy"):
		if not is_instance_valid(e):
			continue
		if e.global_position == pos:
			var hc = e.get_node_or_null("Components/HealthComponent")
			if hc and hc.is_alive:
				return true
	return false

func _enemy_at_position(pos: Vector2) -> bool:
	for e in get_tree().get_nodes_in_group("Enemy"):
		if not is_instance_valid(e): 
			continue
		if e.global_position == pos:
			var hc: HealthComponent = e.get_node_or_null("Components/HealthComponent")
			if hc and hc.is_alive:
				return true
	return false
	
func _perform_player_attack(dir: Vector2) -> void:
	var tile := float(move_component.tile_size)
	var ahead = entity.global_position + dir * tile
	if not _enemy_at_position(ahead):
		state_machine.transition_to(idle_state)
		return
	# Hitbox auslösen
	if entity.has_method("start_attack"):
		entity.start_attack()
	# Animation wählen (nur wenn keine Hurt-Anim läuft)
	if animplayer and animplayer.current_animation != "hurt":
		var anim := "attack"
		if dir == Vector2.UP:
			anim = "attack_up"
		elif dir == Vector2.DOWN:
			anim = "attack_down"
		elif dir == Vector2.LEFT:
			anim = "attack_left"
		elif dir == Vector2.RIGHT:
			anim = "attack_right"
		animplayer.play(anim)
	# Nach dem Angriff wieder Idle
	state_machine.transition_to(idle_state)
