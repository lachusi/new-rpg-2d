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

func _ready():
	player = AudioStreamPlayer.new()
	add_child(player)
	play_next_track()

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
	var tween := create_tween()
	tween.tween_property(player, "volume_db", -40.0, fade_time).as_relative()
	tween.tween_callback(_on_fade_out_done)

func _on_fade_out_done():
	player.stop()
	player.volume_db = 0.0
	play_next_track()
