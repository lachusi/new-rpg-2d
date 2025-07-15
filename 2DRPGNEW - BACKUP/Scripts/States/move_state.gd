extends State

@export var idle_state: State

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
		move_component.start_move(dir)
