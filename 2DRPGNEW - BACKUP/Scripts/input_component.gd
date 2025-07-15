extends Node2D
class_name InputComponent

func get_move_input() -> Vector2:
	var input = Vector2.ZERO
	if Input.is_action_pressed("move_right"):
		input.x += 1
	if Input.is_action_pressed("move_left"):
		input.x -= 1
	if Input.is_action_pressed("move_down"):
		input.y += 1
	if Input.is_action_pressed("move_up"):
		input.y -= 1

	# Nur eine Richtung zulassen für tilebasiert
	if abs(input.x) > 0:
		input.y = 0

	return input.normalized()

func is_attack_pressed() -> bool:
	return Input.is_action_just_pressed("attack")
