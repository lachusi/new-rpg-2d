extends Node2D
class_name HealthComponent

@export var level_component : LevelComponent
@export var MAX_HEALTH := 100.0
@export var health := 100.0
@export var hurt_lock_min: float = 0.15

@onready var sound_component: Node = get_component("SoundComponent")

var move_lock_timer: float = 0.0
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

func _process(delta: float) -> void:
	if move_lock_timer > 0.0:
		move_lock_timer -= delta
		if move_lock_timer < 0.0:
			move_lock_timer = 0.0

func is_movement_locked() -> bool:
	return (not is_alive) or is_dying or move_lock_timer > 0.0

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
		var mc: MoveComponent = entity.get_node_or_null("Components/MoveComponent")
		if mc and mc.is_moving:
			mc.cancel_move_interrupted()

	health -= attack.attack_damage
	# Lock (nur wenn noch lebend)
	if health > 0:
		var stun_len = 0.0
		if attack and attack.stun_time > 0.0:
			stun_len = attack.stun_time
		# mind. hurt_lock_min
		move_lock_timer = max(move_lock_timer, max(hurt_lock_min, stun_len))
		
	if health_bar:
		emit_signal("health_changed", health)

	if health <= 0:
		# Tod behandeln
		is_alive = false
		is_dying = true
		
		# DEBUG: Todes-Info
		var ent := entity
		var mc_debug := ""
		var held_keys: Array = []
		for k in Tilemanager.occupied_tiles.keys():
			if Tilemanager.occupied_tiles[k] == ent:
				held_keys.append(k)
		if ent:
			var mc: MoveComponent = ent.get_node_or_null("Components/MoveComponent")
			if mc:
				mc_debug = " reserved_key=%s target_key=%s is_moving=%s" % [mc.reserved_key, mc.target_key, str(mc.is_moving)]
			var tile_size := 16
			if mc: tile_size = mc.tile_size
			var snapped = ent.global_position.snapped(Vector2(tile_size, tile_size))
			print("[DeathDebug] entity=", ent.name, " pos=", ent.global_position, " snapped=", snapped, " held_tiles=", held_keys, mc_debug)
		move_lock_timer = 99999.0
		if anim:
			anim.play("death", -1, 0.8)

		# Tile freigeben
		if entity:
			# SICHERES Freigeben: erst über gespeicherten Key (MoveComponent), dann Fallback
			var mc: MoveComponent = entity.get_node_or_null("Components/MoveComponent")
			if mc:
				mc.is_moving = false
				mc.target_key = ""
				mc.reserved_key = ""
			Tilemanager.release_entity(entity)
			Tilemanager.call_deferred("sweep")
			# StepManager informieren (falls Step noch läuft)
			var sm = get_tree().get_root().get_node_or_null("StepManager")
			if sm and sm.has_method("notify_entity_removed"):
				sm.notify_entity_removed(entity)
				
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
