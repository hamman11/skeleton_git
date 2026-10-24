extends Node3D

@export var player: CharacterBody3D
@export var follow_speed: float = 5.0
@export var offset: Vector3 = Vector3(0, 5, 10)

@export var min_limit: Vector3 = Vector3(-50, 0, -50)
@export var max_limit: Vector3 = Vector3(50, 20, 50)

func _physics_process(delta: float) -> void:
	if not player:
		return

	var target_pos = player.global_position + offset

	target_pos.x = clamp(target_pos.x, min_limit.x, max_limit.x)
	target_pos.y = clamp(target_pos.y, min_limit.y, max_limit.y)
	target_pos.z = clamp(target_pos.z, min_limit.z, max_limit.z)

	global_position = global_position.lerp(target_pos, follow_speed * delta)
