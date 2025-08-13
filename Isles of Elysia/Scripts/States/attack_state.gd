extends State

@export var idle_state: State
@export var attack_duration_fallback := 0.35  # Falls Animation keine Länge liefert

var has_attacked := false
var ending := false

func enter():
	has_attacked = false
	ending = false

	# Prüfen ob noch Ziel direkt vor dem Spieler (nur für Player-Angriffe relevant)
	if entity.is_in_group("Player"):
		if not _has_live_enemy_ahead():
			state_machine.transition_to(idle_state)
			return

	_perform_attack()

func _perform_attack():
	if has_attacked:
		return

	var dir: Vector2 = entity.facing_direction if "facing_direction" in entity else Vector2.RIGHT
	var anim_name := _anim_for_dir(dir)

	# Animation spielen
	if entity.animplayer:
		entity.animplayer.play(anim_name)
		# Länge bestimmen
		var length = entity.animplayer.current_animation_length
		if length <= 0.0:
			length = attack_duration_fallback
		# Asynchrones Ende einplanen
		_call_deferred_end(length)
	else:
		_call_deferred_end(attack_duration_fallback)

	# Schaden / Hitbox nur einmal
	if entity.has_method("start_attack"):
		# Falls start_attack selbst animiert: dort KEINE Anim mehr abspielen lassen
		entity.start_attack()
	elif entity.has_method("weapon_component") and entity.weapon_component:
		entity.weapon_component.trigger_hitbox(entity, dir)

	has_attacked = true

func _physics_process(_delta: float) -> State:
	# StateMachine nutzt Rückgabewert? Wir verlassen den State erst bei _finish_attack
	return null

func _call_deferred_end(duration: float):
	# Timer für Attack-Ende
	var t = get_tree().create_timer(duration)
	t.timeout.connect(_finish_attack)

func _finish_attack():
	if ending:
		return
	ending = true
	state_machine.transition_to(idle_state)

func _anim_for_dir(d: Vector2) -> String:
	if d.y < 0 and _has_anim("attack_up"): return "attack_up"
	if d.y > 0 and _has_anim("attack_down"): return "attack_down"
	if d.x < 0 and _has_anim("attack_left"): return "attack_left"
	if d.x > 0 and _has_anim("attack_right"): return "attack_right"
	return _first_available_attack_anim()

func _first_available_attack_anim() -> String:
	var prefs = ["attack", "attack_right", "attack_left", "attack_up", "attack_down"]
	for a in prefs:
		if _has_anim(a):
			return a
	return ""  # keins gefunden

func _has_anim(name: String) -> bool:
	return entity.animplayer and entity.animplayer.has_animation(name)

func _has_live_enemy_ahead() -> bool:
	var tile_size = entity.move_component.tile_size if entity.move_component else 16
	var ahead_pos = entity.global_position + entity.facing_direction * tile_size
	for e in get_tree().get_nodes_in_group("Enemy"):
		if not is_instance_valid(e):
			continue
		if e.global_position == ahead_pos:
			var hc = e.get_node_or_null("Components/HealthComponent")
			if hc and hc.is_alive:
				return true
	return false
