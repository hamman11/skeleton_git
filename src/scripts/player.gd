
class_name Player
extends CharacterBody3D

enum MovementMode { BODY, HEAD }

@export var body_speed := 8.0
@export var body_acceleration := 14.0
@export var body_friction := 8.0

@export var head_speed := 12.0
@export var head_acceleration := 5.0
@export var head_drag := 0.985
@export var head_rotation_speed := 1.5

@export var death_screen: PackedScene
@export var anim: AnimationPlayer
@export var anim_death: AnimationPlayer
@export var body: Node3D
@export var head: Node3D
@export var mesh: Node3D
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

func _ready() -> void:
	camera = get_viewport().get_camera_3d()
	current_health = max_health

	for child in hearts_container.get_children():
		if child is TextureRect:
			hearts_list.append(child)

	body.visible = true
	head.visible = true
	death_anim.visible = false

	update_heart_display()
	update_movement_mode()

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	if Input.is_action_just_pressed("throw"):
		switch_movement_mode()

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

	match movement_mode:
		MovementMode.BODY:
			process_body_movement(input_dir, delta)
		MovementMode.HEAD:
			process_head_movement(input_dir, delta)

	velocity.y = 0.0
	move_and_slide()

	var horizontal := Vector2(velocity.x, velocity.z)
	var max_speed := body_speed if movement_mode == MovementMode.BODY else head_speed

	if horizontal.length() > max_speed:
		horizontal = horizontal.normalized() * max_speed
		velocity.x = horizontal.x
		velocity.z = horizontal.y

func process_body_movement(input_dir: Vector3, delta: float) -> void:
	var target := Vector2(input_dir.x, input_dir.z) * body_speed
	var horizontal := Vector2(velocity.x, velocity.z)
	var acceleration := body_acceleration if input_dir.length_squared() > 0.0 else body_friction

	horizontal = horizontal.move_toward(target, acceleration * delta)

	velocity.x = horizontal.x
	velocity.z = horizontal.y

	if input_dir.length_squared() > 0.0:
		rotate_mesh(input_dir, delta)
		anim.play("Idle_001")
	else:
		anim.play("Idle")

func process_head_movement(input_dir: Vector3, delta: float) -> void:
	var target := Vector2(input_dir.x, input_dir.z) * head_speed
	var horizontal := Vector2(velocity.x, velocity.z)

	horizontal = horizontal.move_toward(
		target,
		head_acceleration * delta
	)

	if input_dir.length_squared() == 0.0:
		horizontal *= pow(head_drag, delta * 60.0)

	velocity.x = horizontal.x
	velocity.z = horizontal.y

	if input_dir.length_squared() > 0.0:
		rotate_mesh(input_dir, delta)

func rotate_mesh(direction: Vector3, delta: float) -> void:
	var target_angle := atan2(-direction.x, -direction.z)
	var speed := head_rotation_speed if movement_mode == MovementMode.HEAD else TAU * 3.0

	mesh.rotation.y = rotate_toward(
		mesh.rotation.y,
		target_angle,
		speed * delta
	)

func switch_movement_mode() -> void:
	if movement_mode == MovementMode.BODY:
		movement_mode = MovementMode.HEAD
	else:
		movement_mode = MovementMode.BODY

	update_movement_mode()

func update_movement_mode() -> void:
	var is_head := movement_mode == MovementMode.HEAD
	body.visible = not is_head
	head.visible = true

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
