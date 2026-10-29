extends CharacterBody3D

var is_chasing := false

@export var player: CharacterBody3D
@export var anim: AnimationPlayer

var is_alive := true

var state_machine: Node3D

@export var speed: float = 1.0

@export var acceleration: float = 10.0
@export var rotation_speed: float = 24

func _ready() -> void:
	visible = true
	anim.play("Jump")
	await anim.animation_finished
	anim.play("Roll")
	is_chasing = true
	

func _process(delta: float) -> void:
	if not player:
		return
		
	var direction := player.global_position - global_position
	direction.y = 0.0

	if direction.length_squared() < 0.001:
		return

	var target_angle := atan2(direction.x, direction.z) + PI
	var weight := 1.0 - exp(-rotation_speed * delta)

	rotation.y = lerp_angle(rotation.y, target_angle, weight)

func _physics_process(delta: float) -> void:
	if not player:
		return
	if not is_chasing:
		return
	if not is_alive:
		return
	var direction = (player.global_position - global_position)
	direction.y = 0.0 
	direction = direction.normalized()

	var target_velocity_x = direction.x * speed
	var target_velocity_z = direction.z * speed

	velocity.x = move_toward(velocity.x, target_velocity_x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity_z, acceleration * delta)

	move_and_slide()
	
