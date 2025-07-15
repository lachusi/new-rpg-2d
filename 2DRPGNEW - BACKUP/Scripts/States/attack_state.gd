extends State

@export var idle_state: State

var attack_timer := 0.0
const ATTACK_DURATION := 1
var has_attacked := false

func enter():
	attack_timer = 0.0
	has_attacked = false

	# Prüfe, ob diese Entität am Zug ist
	if TurnManager.in_battle and TurnManager.turn_queue.size() > 0 and TurnManager.turn_queue[TurnManager.current_turn_index] == entity:
		# Angriff sofort ausführen
		_perform_attack()
	else:
		# Nicht am Zug: Sofort zurück in Idle
		state_machine.transition_to(idle_state)

func _physics_process(delta: float) -> State:
	if not has_attacked:
		return null

	attack_timer += delta
	if attack_timer >= ATTACK_DURATION:
		# Nach Angriff: Nächster Zug
		TurnManager.next_turn()
		return idle_state

	return null

func _perform_attack():
	var dir = entity.facing_direction
	var anim = "attack"

	if entity.is_in_group("BOSS"):
		entity.start_attack()
		anim = "attack"
	elif entity:
		entity.start_attack()
		if dir == Vector2.UP:
			anim = "attack_up"
		elif dir == Vector2.DOWN:
			anim = "attack_down"
		elif dir == Vector2.LEFT:
			anim = "attack_left"
		elif dir == Vector2.RIGHT:
			anim = "attack_right"

	if entity.animplayer and entity.animplayer.current_animation != anim and entity.animplayer.current_animation != "hurt":
		entity.animplayer.play(anim)

	has_attacked = true
