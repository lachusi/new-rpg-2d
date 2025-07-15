extends Camera2D

const CAMERA_SMOOTHNESS = 0.0  # je höher, desto träger

func _physics_process(delta: float) -> void:
	position = position.lerp(get_parent().position, clamp(delta * CAMERA_SMOOTHNESS, 0, 1))
