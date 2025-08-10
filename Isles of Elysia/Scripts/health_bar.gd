extends TextureProgressBar

func _ready() -> void:
	pass

func _on_health_changed(new_value: float):
	var tween = create_tween()
	tween.tween_property(self, "value", new_value, 0.2)
