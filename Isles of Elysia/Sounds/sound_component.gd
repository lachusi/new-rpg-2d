# sound/SoundComponent.gd
extends Node
class_name SoundComponent

@export var sound_entries: Array[SoundEntry] = []

var sounds: Dictionary = {}
var players := {}

func _ready():
	if is_in_group("BOSS"):
		sounds.pitch_fixed = 0.3
	for entry in sound_entries:
		if typeof(entry.data) != TYPE_OBJECT or not entry.data is SoundData:
			push_error("SoundEntry '%s' hat kein gültiges SoundData-Objekt (Typ: %s)" % [entry.name, typeof(entry.data)])
			continue
		sounds[entry.name] = entry.data
		var data = entry.data
		var player = AudioStreamPlayer2D.new() if data.is_2d else AudioStreamPlayer.new()
		player.volume_db = data.volume_db
		if data.is_2d and player is AudioStreamPlayer2D:
			player.max_distance = data.max_distance
		add_child(player)
		players[entry.name] = player
func play_sound(name: String):
	if not sounds.has(name):
		push_warning("Sound '%s' not found in SoundComponent." % name)
		return
	var data: SoundData = sounds[name]
	var player = players.get(name)
	if not data.stream or not player:
		return

	player.stream = data.stream

	if data.use_random_pitch:
		player.pitch_scale = randf_range(data.pitch_min, data.pitch_max)
	else:
		player.pitch_scale = data.pitch_fixed

	player.play()
