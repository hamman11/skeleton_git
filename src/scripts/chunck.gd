
extends Area3D

@export var gravity_strength: float = 9.8
@export var lifetime: float = 8.0
@export var warning_scene: PackedScene
@export var floor_y: float = -0.5

var velocity: Vector3 = Vector3.ZERO
var warning: Node3D
var rotation_speed: Vector3


func _ready() -> void:
	get_tree().create_timer(lifetime).timeout.connect(
		func():
			if is_instance_valid(self):
				queue_free()
	)
	rotation_speed = Vector3(
		0,
		randf_range(-TAU, TAU), 
		randf_range(-TAU, TAU)  
	)

func launch(direction: Vector3, speed: float) -> void:
	velocity = direction * speed
	spawn_warning()


func spawn_warning() -> void:
	if warning_scene == null:
		return

	var height := global_position.y - floor_y

	if height <= 0.0:
		return

	var discriminant := velocity.y * velocity.y + 2.0 * gravity_strength * height

	if discriminant < 0.0:
		return

	var time_to_ground := (
		velocity.y + sqrt(discriminant)
	) / gravity_strength

	if time_to_ground <= 0.0:
		return

	var landing_position := Vector3(
		global_position.x + velocity.x * time_to_ground,
		floor_y + 0.025,
		global_position.z + velocity.z * time_to_ground
	)

	warning = warning_scene.instantiate() as Node3D

	if warning == null:
		return

	get_tree().current_scene.add_child(warning)
	warning.global_position = landing_position


func _physics_process(delta: float) -> void:
	rotate_object_local(Vector3.UP, rotation_speed.y * delta)
	rotate_object_local(Vector3.FORWARD, rotation_speed.z * delta)
	var previous_position := global_position

	global_position += velocity * delta
	velocity.y -= gravity_strength * delta

	if previous_position.y > floor_y and global_position.y <= floor_y:
		if is_instance_valid(warning):
			warning.queue_free()
		queue_free()
