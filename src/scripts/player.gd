class_name Player
extends CharacterBody3D

enum MovementMode { BODY, HEAD }

@export var body_speed := 8.0
@export var body_acceleration := 14.0
@export var body_friction := 8.0

@export var head_speed := 12.0
@export var head_boost_speed := 22.0
@export var head_boost_duration := 0.35
@export var head_acceleration := 5.0
@export var head_drag := 0.985
@export var head_rotation_speed := 1.5

@export var death_screen: PackedScene
@export var anim: AnimationPlayer
@export var anim_death: AnimationPlayer
@export var body: Node3D
@export var head: Node3D
@export var mesh: Node3D

@onready var death_anim: Node3D = $Death

var camera: Camera3D
var is_alive := true
var has_moved := false
var move_direction := Vector3.FORWARD
var movement_mode := MovementMode.BODY
var head_boost_timer := 0.0


func _ready() -> void:
	camera = get_viewport().get_camera_3d()

	body.visible = true
	head.visible = true
	death_anim.visible = false

	update_movement_mode()


func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	if Input.is_action_just_pressed("throw"):
		switch_movement_mode()

	if head_boost_timer > 0.0:
		head_boost_timer = maxf(head_boost_timer - delta, 0.0)

	var input_dir := Vector3(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		0.0,
		Input.get_action_strength("down") - Input.get_action_strength("up")
	).normalized()

	if input_dir.length_squared() > 0.0:
		if not has_moved:
			has_moved = true
			_on_player_first_move()

		move_direction = input_dir

	if movement_mode == MovementMode.BODY:
		process_body_movement(input_dir, delta)
	else:
		process_head_movement(input_dir, delta)

	velocity.y = 0.0
	move_and_slide()

	var horizontal := Vector2(velocity.x, velocity.z)
	var max_speed := body_speed if movement_mode == MovementMode.BODY else get_head_speed()

	if horizontal.length() > max_speed:
		horizontal = horizontal.normalized() * max_speed
		velocity.x = horizontal.x
		velocity.z = horizontal.y


func process_body_movement(input_dir: Vector3, delta: float) -> void:
	var target := Vector2(input_dir.x, input_dir.z) * body_speed
	var horizontal := Vector2(velocity.x, velocity.z)

	if input_dir.length_squared() > 0.0:
		horizontal = horizontal.move_toward(target, body_acceleration * delta)
		rotate_mesh(input_dir, delta)
		anim.play("Idle_001")
	else:
		horizontal = horizontal.move_toward(Vector2.ZERO, body_friction * delta)
		anim.play("Idle")

	velocity.x = horizontal.x
	velocity.z = horizontal.y


func process_head_movement(input_dir: Vector3, delta: float) -> void:
	var target := Vector2(input_dir.x, input_dir.z) * get_head_speed()
	var horizontal := Vector2(velocity.x, velocity.z)

	horizontal = horizontal.move_toward(target, head_acceleration * delta)

	if input_dir.length_squared() == 0.0:
		horizontal *= pow(head_drag, delta * 60.0)
	else:
		rotate_mesh(input_dir, delta)

	velocity.x = horizontal.x
	velocity.z = horizontal.y


func get_head_speed() -> float:
	if head_boost_timer > 0.0:
		var boost_amount := head_boost_timer / head_boost_duration
		return lerp(head_speed, head_boost_speed, boost_amount)

	return head_speed


func rotate_mesh(direction: Vector3, delta: float) -> void:
	var target_angle := atan2(-direction.x, -direction.z)
	var rotation_speed := TAU * 3.0

	if movement_mode == MovementMode.HEAD:
		rotation_speed = head_rotation_speed

	mesh.rotation.y = rotate_toward(mesh.rotation.y, target_angle, rotation_speed * delta)


func switch_movement_mode() -> void:
	if movement_mode == MovementMode.BODY:
		movement_mode = MovementMode.HEAD
		head_boost_timer = head_boost_duration

		var direction := Vector2(move_direction.x, move_direction.z).normalized()
		velocity.x = direction.x * head_boost_speed
		velocity.z = direction.y * head_boost_speed
	else:
		movement_mode = MovementMode.BODY
		head_boost_timer = 0.0

	update_movement_mode()


func update_movement_mode() -> void:
	var is_head := movement_mode == MovementMode.HEAD

	body.visible = not is_head
	head.visible = true


func _on_player_first_move() -> void:
	if camera and camera.has_method("zoom_out_anim"):
		camera.zoom_out_anim()




func death() -> void:
	if not is_alive:
		return

	is_alive = false

	velocity = Vector3.ZERO

	body.visible = false
	head.visible = false
	death_anim.visible = true

	if death_screen != null:
		var screen = death_screen.instantiate()
		get_tree().current_scene.add_child(screen)

	anim_death.play("deathanim")
