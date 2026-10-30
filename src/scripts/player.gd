
class_name Player
extends CharacterBody3D

enum MovementMode { BODY, HEAD }

@export_group("Body Movement")
@export var body_speed := 8.0
@export var body_acceleration := 14.0
@export var body_friction := 8.0
@export var rotation_speed := TAU * 3.0

@export_group("Head Movement")
@export var head_speed := 12.0
@export var head_acceleration := 5.0
@export var head_drag := 0.985
@export var head_rotation_speed := 1.5

@export_group("Head Floating")
@export var head_bob_amount := 0.12
@export var head_bob_speed := 3.0
@export var head_height_smoothness := 5.0

@export_group("References")
@export var death_screen: PackedScene
@export var anim: AnimationPlayer
@export var anim_death: AnimationPlayer
@export var body: Node3D
@export var mesh: Node3D
@export var head: Node3D
@export var max_health := 3

@onready var death_anim: Node3D = $Death
@onready var hearts_container: HBoxContainer = $CanvasLayer/HBoxContainer

var camera: Camera3D
var current_health := 3
var hearts_list: Array[TextureRect] = []
var is_alive := true
var has_moved := false
var move_direction := Vector3.FORWARD
var movement_mode := MovementMode.BODY
var head_original_transform: Transform3D
var head_mode_position := Vector3.ZERO
var head_bob_time := 0.0

func _ready() -> void:
	camera = get_viewport().get_camera_3d()
	current_health = max_health

	for child in hearts_container.get_children():
		if child is TextureRect:
			hearts_list.append(child)

	head_original_transform = head.transform

	body.visible = true
	head.visible = true
	death_anim.visible = false

	update_heart_display()

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

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

		var target_angle := atan2(-input_dir.x, -input_dir.z)
		var turn_speed := head_rotation_speed if movement_mode == MovementMode.HEAD else rotation_speed

		mesh.rotation.y = rotate_toward(
			mesh.rotation.y,
			target_angle,
			turn_speed * delta
		)

	if movement_mode == MovementMode.HEAD:
		_process_head_movement(input_dir, delta)
	else:
		_process_body_movement(input_dir, delta)

	move_and_slide()

func _process_body_movement(input_dir: Vector3, delta: float) -> void:
	var weight := minf(
		delta * (body_acceleration if input_dir.length_squared() > 0.0 else body_friction),
		1.0
	)

	velocity.x = lerpf(velocity.x, input_dir.x * body_speed, weight)
	velocity.z = lerpf(velocity.z, input_dir.z * body_speed, weight)
	velocity.y = 0.0

	if input_dir.length_squared() > 0.0:
		anim.play("Idle_001")
	else:
		anim.play("Idle")

func _process_head_movement(input_dir: Vector3, delta: float) -> void:
	velocity.y = 0.0

	if input_dir.length_squared() > 0.0:
		var target_velocity := input_dir * head_speed

		velocity.x = move_toward(
			velocity.x,
			target_velocity.x,
			head_acceleration * delta
		)

		velocity.z = move_toward(
			velocity.z,
			target_velocity.z,
			head_acceleration * delta
		)
	else:
		var drag := pow(head_drag, delta * 60.0)
		velocity.x *= drag
		velocity.z *= drag

	head_bob_time += delta

	var target_height := head_mode_position.y + sin(head_bob_time * head_bob_speed) * head_bob_amount

	head.position.y = lerpf(
		head.position.y,
		target_height,
		minf(head_height_smoothness * delta, 1.0)
	)

func _unhandled_input(event: InputEvent) -> void:
	if not is_alive or not event.is_action_pressed("throw"):
		return

	if movement_mode == MovementMode.BODY:
		throw_head()
	else:
		return_head()

func throw_head() -> void:
	if movement_mode != MovementMode.BODY:
		return

	var head_position := head.global_position

	global_position = head_position
	head.position = Vector3.ZERO
	head_mode_position = head.position
	head_bob_time = 0.0

	body.visible = false
	movement_mode = MovementMode.HEAD

	if mesh.has_method("release_anim"):
		mesh.call("release_anim")

func return_head() -> void:
	if movement_mode != MovementMode.HEAD:
		return

	head.transform = head_original_transform

	body.visible = true
	movement_mode = MovementMode.BODY

	if mesh.has_method("return_anim"):
		mesh.call("return_anim")

func _on_player_first_move() -> void:
	if camera and camera.has_method("zoom_out_anim"):
		camera.zoom_out_anim()

func update_heart_display() -> void:
	for i in range(hearts_list.size()):
		hearts_list[i].visible = i < current_health

func death() -> void:
	if not is_alive:
		return

	is_alive = false
	current_health = 0
	update_heart_display()
	velocity = Vector3.ZERO

	body.visible = false
	head.visible = false
	death_anim.visible = true

	if death_screen != null:
		var screen = death_screen.instantiate()
		get_tree().current_scene.add_child(screen)

	anim_death.play("deathanim")
