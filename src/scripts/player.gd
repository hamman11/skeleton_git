class_name Player
extends CharacterBody3D

const max_speed: int = 8
const acceleration: int = 14
const friction: int = 8

@export var rotation_speed: float = TAU * 3

@export var anim: AnimationPlayer
@export var anim_death: AnimationPlayer
@export var head: RigidBody3D
@export var mesh: Node3D
@export var camera: Camera3D

@export var pumpkin_damage: int = 1
@export var pumpkin_knockback: float = 80.0

@onready var dmg_timer: Timer = $DamageCooldown
@onready var death_anim: Node3D = $Death

const hit_particles = preload("res://src/scenes/hitparticles.tscn")

var max_health: int = 3
var current_health: int = 3

var hearts_list: Array[TextureRect] = []

var is_alive: bool = true
var can_throw: bool = true
var move_direction: Vector3 = Vector3.FORWARD


func _ready() -> void:
	var hearts_parent = $CanvasLayer/HBoxContainer

	for child in hearts_parent.get_children():
		if child is TextureRect:
			hearts_list.append(child)

	current_health = max_health

	mesh.visible = true
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

	if input_dir:
		move_direction = input_dir

		anim.play("Idle_001")

		mesh.rotation.y = rotate_toward(
			mesh.rotation.y,
			Vector2(input_dir.x, -input_dir.z).angle(),
			rotation_speed * delta
		)
	else:
		anim.play("Idle")

	var lerp_weight := delta * (
		acceleration if input_dir else friction
	)

	velocity.x = lerp(
		velocity.x,
		input_dir.x * max_speed,
		lerp_weight
	)

	velocity.z = lerp(
		velocity.z,
		input_dir.z * max_speed,
		lerp_weight
	)

	move_and_slide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("throw") and can_throw and is_alive:
		head.throw_head(move_direction)


func _on_detection_area_body_entered(body: Node3D) -> void:
	if not is_alive:
		return

	if body.is_in_group("pumpkin"):
		damage(pumpkin_damage, body, pumpkin_knockback)


func damage(
	dmg: int,
	knockback_source: Node3D = null,
	knockback_strength: float = 10.0
) -> void:
	if not dmg_timer.is_stopped() or not is_alive:
		return

	current_health = max(current_health - dmg, 0)

	dmg_timer.start()

	update_heart_display()

	if camera:
		camera.shake(0.15, 0.21)

	if knockback_source:
		var knockback_dir := global_position - knockback_source.global_position
		knockback_dir.y = 0.0

		if knockback_dir.length_squared() > 0.001:
			knockback_dir = knockback_dir.normalized()
		else:
			knockback_dir = -global_transform.basis.z

		velocity.x = knockback_dir.x * knockback_strength
		velocity.z = knockback_dir.z * knockback_strength

	if current_health <= 0:
		is_alive = false
		death()

	spawn_hit_particles()


func spawn_hit_particles() -> void:
	var instance = hit_particles.instantiate()

	get_parent().add_child(instance)
	instance.global_position = global_position
	instance.emitting = true
	instance.finished.connect(instance.queue_free)


func death() -> void:
	mesh.visible = false
	head.visible = false

	death_anim.visible = true
	anim_death.play("deathanim")


func update_heart_display() -> void:
	for i in range(hearts_list.size()):
		hearts_list[i].visible = i < current_health
