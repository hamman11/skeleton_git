
extends CharacterBody3D

var tween: Tween

@export var player: CharacterBody3D
@export var anim: AnimationPlayer
@export var barth_anim: AnimationPlayer
@export var gutsv_2: Node3D
@export var anim_guts: AnimationPlayer


@onready var barth: Node3D = $barth
@onready var muzzle: Node3D = $ShootPoint
@onready var shoot_timer: Timer = $shoot_timer
@onready var state_timer: Timer = $state_timer
@export var camera: Camera3D

@export var bullet_scene: PackedScene

@export var shoot_interval: float = 0.2
@export var bullet_speed: float = 15.0
@export var upward_force: float = 12.0
@export var horizontal_spread: float = 6.0

var is_alive := true
var state_machine: Node3D

@export var rotation_speed: float = 1.0


func _ready() -> void:
	gutsv_2.visible = false
	barth.visible = false
	is_alive = false

	anim.play("Die")
	barth_anim.play_backwards("Start")
	anim_guts.play_backwards("guts")
	visible = false

	state_machine = get_tree().get_first_node_in_group("state")

	shoot_timer.wait_time = shoot_interval
	shoot_timer.one_shot = false

	if not shoot_timer.timeout.is_connected(shoot):
		shoot_timer.timeout.connect(shoot)


func shoot() -> void:
	if not is_alive or bullet_scene == null:
		return

	var bullet = bullet_scene.instantiate()

	var direction := Vector3(
		randf_range(-horizontal_spread, horizontal_spread),
		upward_force,
		randf_range(-horizontal_spread, horizontal_spread)
	).normalized()

	get_tree().current_scene.add_child(bullet)
	bullet.global_position = muzzle.global_position

	if bullet.has_method("launch"):
		bullet.launch(direction, bullet_speed)


func start_state() -> void:
	visible = true

	anim.play_backwards("Die")
	await anim.animation_finished

	barth_anim.play("Start")
	barth.visible = true
	await barth_anim.animation_finished

	barth_anim.play("Idle_Barth")
	anim.play_backwards("Barth")

	is_alive = true
	pick_state()

	shoot_timer.wait_time = shoot_interval
	shoot_timer.start()

	var rot_a := Vector3(0.0, deg_to_rad(180.0), 0.0)
	var rot_b := Vector3(0.0, deg_to_rad(-180.0), 0.0)
	
	if not is_alive:
		return
	if tween:
		tween.kill()

	tween = create_tween().set_loops()
	tween.tween_property(self, "rotation", rot_a, 9.0)\
		.as_relative().set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "rotation", rot_b, 7.0)\
		.as_relative().set_trans(Tween.TRANS_QUAD)


func pick_state() -> void:
	print("bugged")

	if is_instance_valid(state_machine):
		state_machine.remove_state_3_health(1)


func _on_state_timer_timeout() -> void:
	pick_state()


func end_state() -> void:
	print("3 state end")

	is_alive = false
	shoot_timer.stop()

	if tween:
		tween.kill()

	anim.stop()
	barth_anim.stop()
	barth_anim.play_backwards("Start")
	await barth_anim.animation_finished

	anim.play("Die")
	await get_tree().create_timer(0.03).timeout
	gutsv_2.visible = true
	anim_guts.play("guts", 0.5)
	await anim.animation_finished

	queue_free()


func _on_shoot_timer_timeout() -> void:
	shoot()

func beat_player():
	state_timer.stop()
	is_alive = false
	anim.stop()
	anim.play("Laugh")
	look_at(camera.position)
