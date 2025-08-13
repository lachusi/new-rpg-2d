extends State

@export var move_state: State
@export var attack_state: State
@export var patrol_state: State

@export var min_wait_time := 1.0
@export var max_wait_time := 2.0

var pause_timer: SceneTreeTimer = null

func enter():
	if entity.is_in_group("Enemy"):
		move_component.move_speed = 2.0
		animplayer.speed_scale = 1.0

		# Pause zufällig festlegen
		var pause_duration = randf_range(min_wait_time, max_wait_time)
		pause_timer = get_tree().create_timer(pause_duration)
		pause_timer.timeout.connect(_on_pause_timeout)

		play_enemy_idle_animation()

	if entity.is_in_group("Player"):
		play_player_idle_animation()

func _on_pause_timeout():
	state_machine.transition_to(patrol_state)

func exit():
	if pause_timer:
		pause_timer.timeout.disconnect(_on_pause_timeout)
		pause_timer = null

func _unhandled_input(event):
	if not input_component:
		return

	var dir = input_component.get_move_input()
	if dir != Vector2.ZERO:
		state_machine.transition_to(move_state)

		if dir != move_component.last_direction:
			entity.facing_direction = dir
			move_component.last_direction = dir
			play_player_idle_animation()

func play_player_idle_animation():
	var dir = move_component.last_direction
	var anim = ""
	if dir.y < 0:
		anim = "idle_up"
	elif dir.y > 0:
		anim = "idle_down"
	else:
		anim = "idle"
		if entity.has_node("Sprite2D"):
			entity.get_node("Sprite2D").flip_h = dir.x < 0
	if animplayer and animplayer.current_animation != anim and animplayer.current_animation != "hurt":
		animplayer.play(anim)

func play_enemy_idle_animation():
	var dir = move_component.last_direction
	var anim = "idle"
	if entity.has_node("Sprite2D"):
		entity.get_node("Sprite2D").flip_h = dir.x < 0
	if animplayer and animplayer.current_animation != anim and animplayer.current_animation != "hurt":
		animplayer.play(anim)
