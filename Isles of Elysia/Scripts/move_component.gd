extends Node2D
class_name MoveComponent

@export var tile_size: int = 16
@export var move_speed: float = 4.0
@export var enforce_step_sync: bool = true

var is_moving := false
var move_direction := Vector2.ZERO
var initial_position := Vector2.ZERO
var percent_moved := 0.0
var last_direction := Vector2.RIGHT
var entity: CharacterBody2D = null
var animplayer: AnimationPlayer
var ray: RayCast2D
var state_machine: Node = null
var world_state_machine: Node = null
var step_manager: Node = null

var reserved_key: String = ""   # aktuelles Tile
var target_key: String = ""     # reserviertes ZielTile während Bewegung

func _ready():
	if entity == null:
		var p = get_parent()
		if p and p.get_parent():
			entity = p.get_parent() as CharacterBody2D
	if entity:
		_reserve_start_tile()

func init(_entity: CharacterBody2D, _animplayer: AnimationPlayer, _state_machine: Node = null, _world_state_machine: Node = null) -> void:
	entity = _entity
	animplayer = _animplayer
	state_machine = _state_machine
	world_state_machine = _world_state_machine
	ray = entity.get_node_or_null("RayCast2D")
	if ray:
		ray.enabled = true
		ray.exclude_parent = true
	step_manager = get_node_or_null("/root/StepManager")
	_reserve_start_tile()

func _reserve_start_tile():
	if entity and reserved_key == "" and not Tilemanager.is_tile_occupied(entity.position):
		if Tilemanager.reserve_tile(entity.position, entity):
			reserved_key = Tilemanager.tile_key(entity.position)

func _physics_process(delta):
	if is_moving:
		_move_step(delta)

func start_move(direction: Vector2) -> bool:
	if entity == null:
		return false

	# Schritt-Sync Gating
	if enforce_step_sync and step_manager:
		if entity.is_in_group("Player"):
			if not step_manager.is_stepping:
				return step_manager.start_step(direction) # delegiert, danach erneuter Aufruf im Dispatch
			if not step_manager.can_entity_move(entity):
				return false
		elif entity.is_in_group("Enemy"):
			if not step_manager.can_entity_move(entity):
				return false

	if is_moving or direction == Vector2.ZERO:
		return false

	var target_pos := entity.position + direction * tile_size

	if Tilemanager.is_tile_occupied(target_pos):
		return false

	if ray:
		ray.target_position = direction * tile_size
		ray.force_raycast_update()
		if ray.is_colliding():
			return false

	# Ziel reservieren (Start-Tile bleibt bis Abschluss blockiert)
	if not Tilemanager.reserve_tile(target_pos, entity):
		return false
	target_key = Tilemanager.tile_key(target_pos)

	# Bewegung initialisieren
	is_moving = true
	initial_position = entity.position
	move_direction = direction
	percent_moved = 0.0
	last_direction = direction
	if "facing_direction" in entity:
		entity.facing_direction = direction
	_play_animation(direction)
	return true

func _move_step(delta):
	percent_moved += move_speed * delta
	if percent_moved >= 1.0:
		entity.position = initial_position + move_direction * tile_size
		is_moving = false
		percent_moved = 0.0
		# Start-Tile freigeben, neues übernehmen
		if target_key != "":
			# Altes (initial_position) explizit freigeben
			Tilemanager.release_tile(initial_position, entity)
			reserved_key = target_key
			target_key = ""
		if entity.has_signal("move_completed"):
			entity.emit_signal("move_completed")
	else:
		entity.position = initial_position + move_direction * tile_size * percent_moved
		_play_animation(move_direction)

func cancel_move_interrupted(snap: bool = true):
	if not is_moving:
		return
	is_moving = false
	percent_moved = 0.0
	# Optional: auf Starttile zurück (verhindert Halb-Positionen)
	if snap:
		entity.position = initial_position
	# Signal auslösen, damit StepManager den Step beenden kann
	if entity.has_signal("move_completed"):
		entity.emit_signal("move_completed")

func _play_animation(dir: Vector2):
	if animplayer == null:
		return
	var cur := animplayer.current_animation
	if cur in ["hurt", "death", "attack"]:
		return
	if entity and entity.is_in_group("Player"):
		if dir.x != 0:
			animplayer.play("move_right")
			var sprite = entity.get_node_or_null("Sprite2D")
			if sprite:
				sprite.flip_h = dir.x < 0
		elif dir.y > 0:
			animplayer.play("move_down")
		elif dir.y < 0:
			animplayer.play("move_up")
	else:
		if dir.x > 0:
			animplayer.play("jump_right")
		elif dir.x < 0:
			animplayer.play("jump_left")
		elif dir.y != 0:
			if last_direction.x >= 0:
				animplayer.play("jump_right")
			else:
				animplayer.play("jump_left")

func can_attack(target: CharacterBody2D) -> bool:
	if entity == null or target == null:
		return false
	var diff = target.position - entity.position
	return abs(diff.x) + abs(diff.y) == tile_size
