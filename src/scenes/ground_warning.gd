
extends Node3D

@export var pulse_speed: float = 4.0
@export var pulse_amount: float = 0.15

var elapsed: float = 0.0


func _ready() -> void:
	scale = Vector3.ONE


func _process(delta: float) -> void:
	elapsed += delta

	var pulse := 1.0 + sin(elapsed * pulse_speed) * pulse_amount

	scale.x = pulse
	scale.z = pulse
