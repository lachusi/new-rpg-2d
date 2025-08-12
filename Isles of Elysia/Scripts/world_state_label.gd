extends Label

var world_state_machine

func _ready():
	world_state_machine = get_node_or_null("/root/World/WorldStateMachine")
	if world_state_machine:
		world_state_machine.connect("state_changed", Callable(self, "_on_state_changed"))
		# Falls current_state schon da ist, sofort anzeigen:
		if world_state_machine.current_state:
			_on_state_changed(world_state_machine.current_state)
		else:
			text = "Warte auf State..."
	else:
		text = "StateMachine nicht gefunden"

func _on_state_changed(new_state):
	text = "%s" % new_state.name
