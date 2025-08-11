extends CharacterBody2D
class_name NPC

enum MovementType { STATIC, RANDOM_WALK }

@export var movement_type: MovementType = MovementType.RANDOM_WALK

@onready var world_state_machine: WorldStateMachine = $"../WorldStateMachine"
@onready var state_machine: Node = $StateMachine
@onready var animplayer: AnimationPlayer = $AnimationPlayer
@onready var ray: RayCast2D = $RayCast2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var health_component = $Components/HealthComponent
@onready var move_component: MoveComponent = $Components/MoveComponent
@onready var wait_timer: Timer = $WaitTimer

var facing_direction: Vector2 = Vector2.DOWN

func _ready():
	wait_timer.timeout.connect(_on_wait_timeout)
	move_component.init(self, animplayer, state_machine)
	state_machine.init(self, world_state_machine, null, move_component, animplayer)
	print(animplayer)

	if movement_type == MovementType.RANDOM_WALK:
		print("warte")
		start_waiting()

func get_component(name: String) -> Node:
	var components_node = get_node_or_null("Components")
	if components_node and components_node.has_node(name):
		return components_node.get_node(name)
	return null

func _physics_process(delta):
	if health_component and not health_component.is_alive:
		return	
	state_machine._physics_process(delta)

func _unhandled_input(event):
	state_machine._unhandled_input(event)

func _process(delta):
	state_machine._process(delta)

# =============================
# RANDOM WALK LOGIK
# =============================

func _on_wait_timeout():
	if movement_type != MovementType.RANDOM_WALK:
		print("bin statisch")
		return

	var directions = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	directions.shuffle()

	for dir in directions:
		if can_move_in_direction(dir):
			print("kann mich in richtungen bewegen")
			facing_direction = dir
			move_component.start_move(dir)
			return

	start_waiting()  # Wenn keine Richtung möglich

func start_waiting():
	print("Timeout")
	wait_timer.wait_time = randf_range(1.0, 3.0)
	wait_timer.start()

# =============================
# HILFSMETHODEN
# =============================

func can_move_in_direction(direction: Vector2) -> bool:
	ray.target_position = direction.normalized() * 8  # Halbe Tile-Größe
	ray.force_raycast_update()
	return !ray.is_colliding()
