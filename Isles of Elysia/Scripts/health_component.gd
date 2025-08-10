extends Node2D
class_name HealthComponent

@export var level_component : LevelComponent
@export var MAX_HEALTH := 100.0
@export var health := 100.0

@onready var sound_component: Node = get_component("SoundComponent")

var health_bar: TextureProgressBar
var is_alive := true
var player_level_component: LevelComponent

signal died(exp_reward: float)
signal health_changed(new_health: float)

func _ready() -> void:
	update_max_health()
	health_bar = get_node_or_null("HealthBar")
	
	if health_bar:
		health_bar.max_value = MAX_HEALTH
		health_bar.value = health
		connect("health_changed", health_bar._on_health_changed)

	if get_parent() is Enemy or NPC:
		var player = get_tree().get_root().find_child("Player", true, false)
		if player and player.has_node("LevelComponent"):
			player_level_component = player.get_node("LevelComponent")
			connect("died", player_level_component.gain_exp)

func get_component(name: String) -> Node:
	var components_node = get_node_or_null("Components")
	if components_node and components_node.has_node(name):
		return components_node.get_node(name)
	return null

func update_max_health():
	if level_component:
		MAX_HEALTH = 100 + level_component.current_lvl * 12
	else:
		MAX_HEALTH = 100

	health = MAX_HEALTH
	if health_bar:
		health_bar.max_value = MAX_HEALTH
		health_bar.value = health

func damage(attack: AttackComponent):
	if not is_alive:
		return
	# Prüfe, ob gerade eine Attack-Animation läuft
	var anim = get_parent().get_parent().animplayer
	var node_name = get_parent().get_parent().name if get_parent().get_parent() else "?"
	if anim and (anim.current_animation == "attack") and is_in_group("Entity"):
		print("Animation 'hurt' wird von Node: ", node_name, " ausgeführt")
		anim.play("hurt", -1, 1.5)

	health -= attack.attack_damage

	if health_bar:
		emit_signal("health_changed", health)

	if health <= 0:	
		if sound_component:
			sound_component.play_sound("Monster_Death")
		if anim:
			print("Animation 'death' wird von Node: ", node_name, " ausgeführt")
			anim.play("death", -1, 0.8)
		is_alive = false
		var entity = get_parent().get_parent()
		if entity:
			Tilemanager.release_tile(entity.position, entity)
		var collider = get_parent().get_node_or_null("Hitbox")
		if collider and collider.has_method("set_deferred"):
			collider.set_deferred("disabled", true)
		emit_signal("died", level_component.exp_reward)
		await get_tree().create_timer(1).timeout
		get_parent().queue_free()
	else:
		if anim:
			print("Animation 'hurt' wird von Node: ", node_name, " ausgeführt")
			anim.play("hurt")
		
func _on_health_bar_value_changed(value: float) -> void:
	pass
