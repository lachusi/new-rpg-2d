extends Node2D
class_name MoveComponent

@export var tile_size: int = 16
@export var move_speed: float = 4.0
@export var enforce_step_sync: bool = true

var is_moving := false
var can_turn := false
var move_direction := Vector2.ZERO
var initial_position := Vector2.ZERO
var percent_moved := 0.0
var last_direction := Vector2.RIGHT  # Standard = nach rechts
var entity: CharacterBody2D
var animplayer: AnimationPlayer
var ray: RayCast2D
var state_machine: Node = null
var world_state_machine: Node = null
var step_manager: Node = null

func _ready():
	last_direction = Vector2.RIGHT

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

func is_in_battle_state() -> bool:
	return world_state_machine and world_state_machine.current_state and world_state_machine.current_state.get_class() == "BattleState"

func _physics_process(delta):
	if not is_instance_valid(entity) or not is_moving:
		return
	_move_step(delta)

func start_move(direction: Vector2) -> bool:
# Schritt-Sync erzwingen: Player triggert Tick, Enemies dürfen nur im Tick ziehen
	if enforce_step_sync and step_manager:
		if entity.is_in_group("Player"):
			# Wenn noch kein Tick läuft → Tick starten (dieser ruft dann erneut start_move für den Player auf)
			if not step_manager.is_stepping:
				return step_manager.start_step(direction)
			# Wenn Tick schon läuft, nur ziehen wenn freigegeben
			if not step_manager.can_entity_move(entity):
				return false
		elif entity.is_in_group("Enemy"):
			# Gegner dürfen nur im aktiven Tick und wenn freigegeben
			if not step_manager.can_entity_move(entity):
				return false
		# NPCs u. a. sind nicht betroffen

	
	if is_moving or direction == Vector2.ZERO:
		return false
	# Kachelprüfung
	var target_pos := entity.position + direction * tile_size
	if Tilemanager.is_tile_occupied(target_pos):
		return false
	if ray:
		ray.target_position = direction * tile_size
		ray.force_raycast_update()
		if ray.is_colliding():
			return false
	# Tile-Reservierung
	Tilemanager.release_tile(entity.position, entity)
	if not Tilemanager.reserve_tile(target_pos, entity):
		return false
	# Bewegung starten
	is_moving = true
	initial_position = entity.position
	move_direction = direction
	percent_moved = 0.0
	return true
	if direction.x > 0:
		last_direction = Vector2.RIGHT
		entity.sprite.flip_h = false
	elif direction.x < 0:
		last_direction = Vector2.LEFT
		entity.sprite.flip_h = true
	elif direction.y > 0:
		last_direction = Vector2.DOWN
	elif direction.y < 0:
		last_direction = Vector2.UP
		
	if entity == null:
		push_error("MoveComponent: 'entity' is not set. Did you forget to call init()?")
		return false

	# Battle-Logik: Nur ein Tile pro Runde
	if is_in_battle_state():
		# Hier ggf. prüfen, ob der Zug erlaubt ist (z.B. nur 1 Tile pro Runde)
		# Nach Bewegung: Turn beenden
		var moved = false
		move_direction = direction
		if Tilemanager.is_tile_occupied(target_pos):
			return false
		if ray:
			ray.target_position = direction * tile_size
			ray.force_raycast_update()
			if ray.is_colliding():
				return false
		if not Tilemanager.reserve_tile(target_pos, entity):
			return false
		Tilemanager.release_tile(entity.position, entity)
		initial_position = entity.position
		percent_moved = 0.0
		is_moving = true
		last_direction = direction
		if entity.has_method("facing_direction"):
			entity.facing_direction = direction
		_play_animation(direction)
		moved = true
		return moved
	# Normale Bewegung (wie gehabt)
	move_direction = direction
	if Tilemanager.is_tile_occupied(target_pos):
		return false
	if ray:
		ray.target_position = direction * tile_size
		ray.force_raycast_update()
		if ray.is_colliding():
			return false
	if not Tilemanager.reserve_tile(target_pos, entity):
		return false
	Tilemanager.release_tile(entity.position, entity)
	initial_position = entity.position
	percent_moved = 0.0
	is_moving = true
	last_direction = direction
	if entity.has_method("facing_direction"):
		entity.facing_direction = direction
	_play_animation(direction)
	return true

func can_attack(target: CharacterBody2D) -> bool:
	var diff = target.position - entity.position
	return abs(diff.x) + abs(diff.y) == tile_size
	
func _move_step(delta):
	percent_moved += move_speed * delta
	if percent_moved >= 1.0:
		entity.position = initial_position + move_direction * tile_size
		is_moving = false
		percent_moved = 0.0
		if entity.has_signal("move_completed"):
			entity.emit_signal("move_completed")
	else:
		entity.position = initial_position + move_direction * tile_size * percent_moved
		# Laufanimation aktiv halten
		_play_animation(move_direction)

func _play_animation(dir: Vector2):
	if animplayer == null or entity == null:
		return

	if entity is Player:
		# Player: Standard-Animationen
		if dir.x != 0:
			animplayer.play("move_right")
			var sprite = entity.get_node_or_null("Sprite2D")
			if sprite:
				sprite.flip_h = dir.x < 0
		elif dir.y > 0:
			animplayer.play("move_down")
		elif dir.y < 0:
			animplayer.play("move_up")
	elif entity is Enemy:
		# Enemy: jump_right, jump_left, oder letzte Blickrichtung
		if dir.x > 0:
			animplayer.play("jump_right")
		elif dir.x < 0:
			animplayer.play("jump_left")
		elif dir.y != 0:
			# Nach oben/unten: letzte Blickrichtung verwenden
			if last_direction.x > 0:
				animplayer.play("jump_right")
			else:
				animplayer.play("jump_left")
