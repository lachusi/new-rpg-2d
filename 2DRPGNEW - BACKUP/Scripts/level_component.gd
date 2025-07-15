extends Node2D
class_name LevelComponent

@export var exp_reward: float = 10.0
@export var exp := 0.0
@export var lvl := 1
@export var entity_name: String = "Unbenannt"

@onready var sound_component = get_node_or_null("SoundComponent")
@onready var name_label: Label = $Control/MarginContainer/HBoxContainer/Name
@onready var health_component = get_node_or_null("HealthComponent")

var level_text : Label
var exp_bar: TextureProgressBar
var current_lvl: int
var max_exp: float
const max_lvl := 100
const log_base := 1.5
const a := 5.0

signal exp_changed(new_exp: float)

func _ready() -> void:
	if exp_bar:
		connect("exp_changed", exp_bar._on_exp_changed)
	name_label.text = entity_name
	level_text = $Control/MarginContainer/HBoxContainer/Level
	exp_bar = $Control/EXPBar
	current_lvl = lvl
	update_max_exp()
	update_exp_bar()
	level_text.text = "Lv " + str(lvl)


func get_xp(lvl: int, log_base: float, a: float) -> float:
	var xp = log(lvl) / log(log_base) + a
	return ceil(xp)

func update_max_exp() -> void:
	max_exp = get_xp(current_lvl, log_base, a)
	if exp_bar:
		exp_bar.max_value = max_exp

func update_exp_bar() -> void:
	if exp_bar:
		exp_bar.value = exp
	pass

func gain_exp(amount: float) -> void:
	if current_lvl >= max_lvl:
		return
	exp += amount
	emit_signal("exp_changed", exp)
	while exp >= max_exp and current_lvl < max_lvl:
		exp -= max_exp
		level_up()
	emit_signal("exp_changed", exp)
	update_exp_bar()


func level_up() -> void:
	var sound_component = get_parent().get_node_or_null("SoundComponent")
	var health_component = get_parent().get_node_or_null("HealthComponent")

	if sound_component:
		sound_component.play_sound("LVLUP")

	current_lvl += 1
	lvl = current_lvl
	update_max_exp()

	if health_component:
		health_component.update_max_health()

	level_text.text = "Lv " + str(current_lvl)
	print("Level up! New level:", current_lvl)
	print("Max Health: " + str(health_component.MAX_HEALTH))
