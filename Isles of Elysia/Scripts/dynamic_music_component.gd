extends Node
class_name DynamicMusicComponent

var music_states := {
	"explore": [
		preload("res://FX/WorldSFX.mp3"),
		preload("res://FX/WorldSFX_2.mp3"),
		preload("res://FX/WorldSFX_4.mp3"),
		preload("res://FX/WorldSFX_3.mp3")
	],
	"battle": [
		preload("res://FX/BattleSFX.mp3"),
		preload("res://FX/BattleSFX_2.mp3"),
		preload("res://FX/BattleSFX_3.mp3"),
		preload("res://FX/BattleSFX_4.mp3"),
	],
	"boss": [
		preload("res://FX/BossSFX.mp3"),
		preload("res://FX/BossSFX_2.mp3")
	]
}

var current_state: String = "explore"
var current_track_index: int = 0
var player: AudioStreamPlayer
var fade_time := 1.5

var world_state_machine: Node = null

func _ready():
	player = AudioStreamPlayer.new()
	add_child(player)

	_connect_world_state_machine()
	_apply_initial_state()

func _connect_world_state_machine():
	# Pfad analog zu world_state_label.gd
	world_state_machine = get_node_or_null("/root/World/WorldStateMachine")
	if world_state_machine and world_state_machine.has_signal("state_changed"):
		world_state_machine.connect("state_changed", Callable(self, "_on_world_state_changed"))

func _apply_initial_state():
	if world_state_machine and world_state_machine.current_state:
		_on_world_state_changed(world_state_machine.current_state)
	else:
		# Fallback: Explore starten
		play_next_track()

func _on_world_state_changed(new_state):
	var name := ""
	if new_state and "name" in new_state:
		name = String(new_state.name)

# Bei BattleState battle_kind aus WorldStateMachine lesen ("boss" oder "battle")
	if name.findn("Battle") != -1:
		var kind := "battle"
		if world_state_machine and world_state_machine.has_meta("battle_kind"):
			kind = String(world_state_machine.get_meta("battle_kind"))
		if kind == "boss":
			change_state("boss")
		else:
			change_state("battle")
	elif name.findn("Explore") != -1:
		change_state("explore")

func play_next_track():
	var tracks = music_states.get(current_state, [])
	if tracks.is_empty():
		return

	current_track_index = (current_track_index + 1) % tracks.size()
	player.stream = tracks[current_track_index]
	player.play()

func _process(_delta):
	if not player.playing:
		play_next_track()

func change_state(new_state: String):
	if not music_states.has(new_state):
		push_warning("Music state '%s' not found." % new_state)
		return
	if new_state == current_state:
		return

	current_state = new_state
	current_track_index = -1
	_transition_to_next()

func _transition_to_next():
	# Sanftes Ausblenden des aktuellen Tracks, dann nächsten starten
	var tween := create_tween()
	tween.tween_property(player, "volume_db", -30.0, fade_time) # absolut
	tween.tween_callback(_on_fade_out_done)

func _on_fade_out_done():
	player.stop()
	player.volume_db = 0.0
	play_next_track()
