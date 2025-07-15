extends CanvasLayer

@onready var label = $MarginContainer/MarginContainer/HBoxContainer/Text

var dialogue_resource: DialogueResource
var dialogue_line: DialogueLine

func _ready():
	# Lade die .dialogue-Datei
	dialogue_resource = load("res://dialoguefiles/test.dialogue") as DialogueResource
	
	# Starte den Dialog bei Title "Start"
	start_dialogue("Start")

func start_dialogue(start_title: String):
	# Coroutine starten, weil get_next_dialogue_line asynchron ist
	_advance_dialogue(start_title)

func _input(event):
	if event.is_action_pressed("ui_accept") and dialogue_line != null and dialogue_line.next_id != "":
		_advance_dialogue(dialogue_line.next_id)

func _advance_dialogue(title: String) -> void:
	# asynchronen Dialogabruf als Coroutine
	# 'await' nur in async-Funktion oder über Aufruf in separater Funktion
	call_deferred("_continue_dialogue", title)

func _continue_dialogue(title: String) -> void:
	dialogue_line = await DialogueManager.get_next_dialogue_line(dialogue_resource, title)
	
	if dialogue_line:
		label.text = dialogue_line.text
	else:
		label.text = "Dialogue finished."
