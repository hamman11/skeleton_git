
class_name Player
extends CharacterBody3D

const max_speed := 8
const acceleration := 14
const friction := 8
const hit_particles = preload("res://src/scenes/hitparticles.tscn")
@export var death_screen: PackedScene

@export var rotation_speed := TAU * 3
@export var anim: AnimationPlayer
@export var anim_death: AnimationPlayer
@export var head: RigidBody3D
@export var mesh: Node3D
@export var pumpkin_damage := 1
@export var pumpkin_knockback := 80.0

@onready var dmg_timer: Timer = $DamageCooldown
@onready var death_anim: Node3D = $Death
@onready var detection_area: Area3D = $Area3D

var camera: Camera3D
var max_health := 3
var current_health := 3
var hearts_list: Array[TextureRect] = []
var pumpkins_touching: Array[Node3D] = []
var is_alive := true
var can_throw := true
var move_direction := Vector3.FORWARD
var has_moved := false

func _ready() -> void:
	camera = get_viewport().get_camera_3d()
	for child in $CanvasLayer/HBoxContainer.get_children():
		if child is TextureRect:
			hearts_list.append(child)
	mesh.visible = true
	head.visible = true
	death_anim.visible = false
	update_heart_display()

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	var input_dir := Vector3(Input.get_action_strength("right") - Input.get_action_strength("left"), 0.0, Input.get_action_strength("down") - Input.get_action_strength("up")).normalized()
	if input_dir:
		if not has_moved:
			has_moved = true
			_on_player_first_move()
		move_direction = input_dir
		anim.play("Idle_001")
		mesh.rotation.y = rotate_toward(mesh.rotation.y, Vector2(input_dir.x, -input_dir.z).angle(), rotation_speed * delta)
	else:
		anim.play("Idle")
	var weight := delta * (acceleration if input_dir else friction)
	velocity.x = lerp(velocity.x, input_dir.x * max_speed, weight)
	velocity.z = lerp(velocity.z, input_dir.z * max_speed, weight)
	move_and_slide()

func _process(_delta: float) -> void:
	if not is_alive or not dmg_timer.is_stopped():
		return
	for i in range(pumpkins_touching.size() - 1, -1, -1):
		var pumpkin := pumpkins_touching[i]
		if not is_instance_valid(pumpkin) or not detection_area.overlaps_body(pumpkin):
			pumpkins_touching.remove_at(i)
			continue
		damage(pumpkin_damage, pumpkin, pumpkin_knockback)
		return

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("throw") and can_throw and is_alive:
		head.throw_head(move_direction)

func _on_detection_area_body_entered(body: Node3D) -> void:
	if not is_alive or not body.is_in_group("pumpkin"):
		return
	if not pumpkins_touching.has(body):
		pumpkins_touching.append(body)
	if dmg_timer.is_stopped():
		damage(pumpkin_damage, body, pumpkin_knockback)

func _on_detection_area_body_exited(body: Node3D) -> void:
	pumpkins_touching.erase(body)

func damage(dmg: int, knockback_source: Node3D = null, knockback_strength: float = 10.0) -> void:
	if not dmg_timer.is_stopped() or not is_alive:
		return
	current_health = max(current_health - dmg, 0)
	dmg_timer.start()
	update_heart_display()
	if camera:
		camera.shake(0.15, 0.21)
	if knockback_source:
		var dir := global_position - knockback_source.global_position
		dir.y = 0
		dir = dir.normalized() if dir.length_squared() > 0.001 else -global_transform.basis.z
		velocity = Vector3(dir.x * knockback_strength, 0, dir.z * knockback_strength)
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
	var screen = death_screen.instantiate()
	get_tree().current_scene.add_child(screen)
	anim_death.play("deathanim")

func _on_player_first_move() -> void:
	camera.zoom_out_anim()

func update_heart_display() -> void:
	for i in range(hearts_list.size()):
		hearts_list[i].visible = i < current_health
		
