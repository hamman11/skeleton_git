
class_name Player
extends CharacterBody3D

const START_MAX_SPEED := 8.0
const ACCELERATION := 14.0
const FRICTION := 8.0

@export var death_screen: PackedScene
@export var rotation_speed := TAU * 3.0
@export var anim: AnimationPlayer
@export var anim_death: AnimationPlayer
@export var head: CharacterBody3D
@export var mesh: Node3D
@export var body_collision: CollisionShape3D
@export var max_health := 3

@onready var death_anim: Node3D = $Death
@onready var hearts_container: HBoxContainer = $CanvasLayer/HBoxContainer

var camera: Camera3D
var current_health := 3
var hearts_list: Array[TextureRect] = []
var is_alive := true
var move_direction := Vector3.FORWARD
var has_moved := false
var max_speed := START_MAX_SPEED

func _ready() -> void:
	camera = get_viewport().get_camera_3d()
	current_health = max_health

	for child in hearts_container.get_children():
		if child is TextureRect:
			hearts_list.append(child)

	mesh.visible = true
	head.visible = true
	death_anim.visible = false
	head.setup_player(self)
	update_heart_display()

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	if head.is_thrown:
		velocity = Vector3.ZERO
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
		anim.play("Idle_001")

		var target_angle := atan2(-input_dir.x, -input_dir.z)

		mesh.rotation.y = rotate_toward(
		mesh.rotation.y,
		target_angle,
		rotation_speed * delta
	)
	else:
		anim.play("Idle")

	var weight := minf(
		delta * (ACCELERATION if input_dir.length_squared() > 0.0 else FRICTION),
		1.0
	)

	velocity.x = lerpf(velocity.x, input_dir.x * max_speed, weight)
	velocity.z = lerpf(velocity.z, input_dir.z * max_speed, weight)

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if not is_alive or not event.is_action_pressed("throw"):
		return

	if head.is_thrown:
		head.return_to_player()
	else:
		head.throw_head(mesh.global_transform.basis.z)

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

	mesh.visible = false
	head.visible = false
	death_anim.visible = true

	if death_screen != null:
		var screen = death_screen.instantiate()
		get_tree().current_scene.add_child(screen)

	anim_death.play("deathanim")
