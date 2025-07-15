extends Node2D
class_name WeaponComponent

@export var attack_damage := 10.0
@export var knockback_force := 100.0
@export var stun_time := 1.5
@export var min_attack_cooldown: float = 1.0
@export var max_attack_cooldown: float = 2.0

var attack_timer := 0.0
var attacker: Node2D
var facing_direction := Vector2.ZERO

@onready var attack_hitbox := $AttackHitbox

func _ready() -> void:
	attack_hitbox.monitoring = false

func _process(delta: float) -> void:
	if attack_timer > 0.0:
		attack_timer -= delta

func can_attack() -> bool:
	return attack_timer <= 0.0

func trigger_hitbox(from_node: CharacterBody2D, dir: Vector2) -> void:
	if not can_attack():
		return

	attack_timer = randf_range(min_attack_cooldown, max_attack_cooldown)
	attacker = from_node
	facing_direction = dir

	# Angepasste Richtungsoffsets für bessere Ausrichtung
	var offsets := {
		Vector2.RIGHT: Vector2(0, 0),
		Vector2.LEFT: Vector2(16, 16),
		Vector2.UP: Vector2(0, 16),
		Vector2.DOWN: Vector2(16, 0)
	}
	attack_hitbox.global_position = from_node.global_position + offsets.get(dir, Vector2.ZERO)
	attack_hitbox.rotation = dir.angle()
	attack_hitbox.set("attacker_id", from_node.get_instance_id())
	attack_hitbox.monitoring = true

	await get_tree().create_timer(0.1).timeout
	attack_hitbox.monitoring = false



func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	if area is HitboxComponent:
		var target = area.get_parent()
		while target and not (target is CharacterBody2D):
			target = target.get_parent()
		if not target or (attacker and target.get_instance_id() == attacker.get_instance_id()):
			return

		var attack = AttackComponent.new()
		attack.attack_damage = attack_damage
		attack.knockback_force = knockback_force
		attack.attack_position = global_position
		attack.stun_time = stun_time
		area.damage(attack)
