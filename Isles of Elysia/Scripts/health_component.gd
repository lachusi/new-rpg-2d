extends Node2D
class_name HealthComponent

@export var level_component : LevelComponent
@export var MAX_HEALTH := 100.0
@export var health := 100.0

@onready var sound_component: Node = get_component("SoundComponent")

var health_bar: TextureProgressBar
var is_alive := true
var is_dying := false
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
	if not is_alive or is_dying:
		return
	# Prüfe, ob gerade eine Attack-Animation läuft
	var entity := get_parent().get_parent()
	var anim: AnimationPlayer = null
	
	if entity:
		anim = entity.get_node_or_null("AnimationPlayer")

	health -= attack.attack_damage

	if health_bar:
		emit_signal("health_changed", health)

	if health <= 0:
		# Tod behandeln
		is_alive = false
		is_dying = true
			
		if anim:
			anim.play("death", -1, 0.8)

		# Tile freigeben
		if entity:
			# SICHERES Freigeben: erst über gespeicherten Key (MoveComponent), dann Fallback
			var mc: MoveComponent = entity.get_node_or_null("Components/MoveComponent")
			if mc and mc.reserved_key != "":
				Tilemanager.release_tile(entity.position, entity)  # Versuch normal
				Tilemanager.release_entity(entity)                 # Fallback falls Key nicht passte
				mc.reserved_key = ""
			else:
				Tilemanager.release_entity(entity)
			
		# Kollisionen deaktivieren
		var collider = get_parent().get_node_or_null("Hitbox")
		if collider and collider.has_method("set_deferred"):
			collider.set_deferred("disabled", true)
			
		emit_signal("died", level_component.exp_reward)
		
		# Auf Anim-Ende warten oder kurz verzögern
		if anim:
			await anim.animation_finished
		else:
			await get_tree().create_timer(0.8).timeout

		# Richtige Node entfernen: die Entity, nicht "Components"
		if entity:
			entity.call_deferred("queue_free")
		return
	else:
		# Hurt sofort abspielen; MoveComponent überschreibt es dank Guard nicht mehr
		if anim:
			anim.play("hurt")
		
func _on_health_bar_value_changed(value: float) -> void:
	pass
