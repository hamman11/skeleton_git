extends RigidBody3D

@export var force_magnitude: float = 10.0

var player: CharacterBody3D
var mesh: Node3D
var is_thrown: bool = false
var original_transform: Transform3D
@export var skeleton_mesh: Node3D

const MY_SCENE = preload("res://src/scenes/death_anim.tscn")

func spawn_at_location(target_position: Vector3):
	var instance = MY_SCENE.instantiate()
	get_parent().get_parent().add_child(instance)
	instance.global_position = target_position
	
func _ready() -> void:
	player = get_parent().get_parent() as CharacterBody3D
	mesh = get_parent() as Node3D
	original_transform = transform

	freeze = true
	sleeping = true

func throw_head(direction: Vector3) -> void:
	if is_thrown:
		return_to_player()
		return

	if not player:
		return

	is_thrown = true
	reparent(get_tree().current_scene, true)

	freeze = false
	sleeping = false
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	direction.y = 0.0

	if direction.length_squared() > 0.001:
		apply_central_impulse(direction.normalized() * force_magnitude)

	mesh.release_anim()

func return_to_player() -> void:
	if not player:
		return
		
	var head_position := global_position
	var player_position := player.global_position
	skeleton_mesh.visible = false
	spawn_at_location(player_position)

	player.global_position = Vector3(
		head_position.x,
		player_position.y,
		head_position.z
	)

	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	sleeping = true

	reparent(mesh, false)
	transform = original_transform
	mesh.return_anim()

	is_thrown = false
