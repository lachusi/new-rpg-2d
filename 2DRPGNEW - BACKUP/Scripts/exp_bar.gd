extends TextureProgressBar

func _on_exp_changed(new_exp: float) -> void:
	var tween = create_tween().set_parallel()
	tween.tween_property(self, "value", new_exp, 1)
