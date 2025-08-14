extends Area2D
class_name HitboxComponent

@export var health_component : HealthComponent
@export var knockback_resistance: float = 0.0
@export var is_stunnable: bool = true

func damage(attack: AttackComponent):
	if health_component:
		health_component.damage(attack)
		var direction = (global_position - attack.attack_position).normalized()
		
		# Nur kardinale Richtung (keine Diagonale)
		if abs(direction.x) > abs(direction.y):
			direction.y = 0
			direction.x = sign(direction.x)
		else:
			direction.x = 0
			direction.y = sign(direction.y)

		# Knockback-Stärke anhand Widerstand berechnen
		var knockback_distance = 3 * 16 * (1.0 - knockback_resistance)  # Max. 3 Tiles
		var knockback_vector = direction * knockback_distance
		
		var parent = get_parent()
		if parent.has_method("apply_knockback"):
			parent.apply_knockback(knockback_vector)
