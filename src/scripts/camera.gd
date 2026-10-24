extends Camera3D

@export var shake_intensity: float = 0.15
@export var shake_duration: float = 0.2

var shake_time: float = 0.0
var original_position: Vector3

func _ready() -> void:
	original_position = position

func _process(delta: float) -> void:
	if shake_time > 0.0:
		shake_time -= delta

		position = original_position + Vector3(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity),
			0.0
		)
	else:
		position = original_position

func shake(intensity: float = -1.0, duration: float = -1.0) -> void:
	if intensity < 0.0:
		intensity = shake_intensity

	if duration < 0.0:
		duration = shake_duration

	shake_intensity = intensity
	shake_duration = duration
	shake_time = duration
