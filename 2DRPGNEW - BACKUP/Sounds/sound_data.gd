@icon("res://Icons/Speaker.svg")
extends Resource
class_name SoundData


@export var stream: AudioStream
@export_range(-80, 6, 1, "or_greater") var volume_db: float = 0.0
@export var is_2d: bool = false
@export var use_random_pitch: bool = false
@export_range(0.1, 3.0, 0.1) var pitch_min: float = 1.0
@export_range(0.1, 3.0, 0.1) var pitch_max: float = 1.0
@export var pitch_fixed: float = 1.0
@export var max_distance: float = 100.0
