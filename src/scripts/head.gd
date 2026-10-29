
extends CharacterBody3D

@export var force_magnitude: float = 10.0
@export var turn_speed: float = 2.5
@export var gravity_strength: float = 9.8
@export var skeleton_mesh: Node3D
@export var head_hit_sfx: AudioStreamPlayer3D
@export var throw: AudioStreamPlayer3D
@export var teleport: AudioStreamPlayer3D

var player: Player
var mesh: Node3D
var is_thrown := false
var original_transform: Transform3D

func setup_player(p: Player) -> void:
	player = p
	mesh = get_parent() as Node3D
	original_transform = transform

func _ready() -> void:
	set_physics_process(false)

func _physics_process(delta: float) -> void:
	if not is_thrown:
		return

	var steering := Input.get_action_strength("left") - Input.get_action_strength("right")
	rotation.y += steering * turn_speed * delta

	var forward := -global_transform.basis.z.normalized()
	velocity.x = forward.x * force_magnitude
	velocity.z = forward.z * force_magnitude
	velocity.y -= gravity_strength * delta

	move_and_slide()

	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		if collision.get_collider() != player and not head_hit_sfx.playing:
			head_hit_sfx.play()

func throw_head(direction: Vector3) -> void:
	if is_thrown or not is_instance_valid(player):
		return

	is_thrown = true
	throw.play()

	direction.y = 0.0

	if direction.length_squared() > 0.001:
		direction = direction.normalized()
		global_rotation.y = atan2(-direction.x, -direction.z) + PI

	reparent(get_tree().current_scene, true)

	mesh.visible = false

	if player.body_collision:
		player.body_collision.set_deferred("disabled", true)

	velocity = Vector3.ZERO
	set_physics_process(true)
	mesh.release_anim()

func return_to_player() -> void:
	if not is_thrown or not is_instance_valid(player):
		return

	teleport.play()

	var return_position := global_position
	return_position.y = player.global_position.y
	player.global_position = return_position

	velocity = Vector3.ZERO
	set_physics_process(false)

	reparent(mesh, false)
	transform = original_transform

	mesh.visible = true
	skeleton_mesh.visible = true

	if player.body_collision:
		player.body_collision.set_deferred("disabled", false)

	mesh.return_anim()
	is_thrown = false
