
class_name Player
extends CharacterBody3D

@export_group("Movement")
@export var body_speed := 8.0
@export var body_acceleration := 14.0
@export var body_friction := 8.0
@export var rotation_speed := TAU * 3.0

@export_group("References")
@export var death_screen: PackedScene
@export var anim: AnimationPlayer
@export var anim_death: AnimationPlayer
@export var body: Node3D
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

func _ready() -> void:
	camera = get_viewport().get_camera_3d()
	current_health = max_health

	for child in hearts_container.get_children():
		if child is TextureRect:
			hearts_list.append(child)

	body.visible = true
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
		mesh.rotation.y = rotate_toward(
			mesh.rotation.y,
			target_angle,
			rotation_speed * delta
		)

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

	move_and_slide()

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
	death_anim.visible = true

	if death_screen != null:
		var screen = death_screen.instantiate()
		get_tree().current_scene.add_child(screen)

	anim_death.play("deathanim")
