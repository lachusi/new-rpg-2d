extends Area2D
class_name DialogueComponent

@export var dialogue_resource: DialogueResource
@export var start_title := "Start"

@onready var world_state_machine = get_tree().get_root().find_child("World", true, false).get_node("WorldStateMachine")

var player_in_range := false
var dialogue_running := false

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _process(delta):
	if player_in_range and not dialogue_running:
		if world_state_machine and world_state_machine.current_state and world_state_machine.current_state.name == "ExploreState":
			if Input.is_action_just_pressed("ui_accept"):
				start_dialogue()
		else:
			push_warning("Explore State not assigned!")
			return

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false

func start_dialogue():
	if dialogue_resource:
		dialogue_running = true
		get_tree().paused = true
		DialogueManager.show_dialogue_balloon(dialogue_resource, start_title)

		if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
			DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	else:
		push_warning("Dialogue resource not assigned!")

func _on_dialogue_ended(resource):
	dialogue_running = false
	get_tree().paused = false
