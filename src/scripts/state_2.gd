extends CharacterBody3D

var tween: Tween

var is_chasing := false

var is_moving := false

enum State {SHOOTING, SLAM}
@export var current_state: State = State.SHOOTING

@export var player: CharacterBody3D
@export var anim: AnimationPlayer

@export var pos_a: Marker3D
@export var pos_b: Marker3D

@export var bullet_scene: PackedScene
@onready var muzzle: Node3D = $ShootPoint
@onready var shoot_timer: Timer = $shoot_timer
@onready var state_timer: Timer = $state_timer
@export var camera: Camera3D

var is_alive := true

var state_machine: Node3D

@export var speed: float = 1.0

@export var acceleration: float = 10.0
@export var rotation_speed: float = 24

func _ready() -> void:
	anim.play("Bury")
	visible = false
	state_machine = get_tree().get_first_node_in_group("state")

func start_state():
	visible = true
	anim.play_backwards("Bury")
	await anim.animation_finished 
	pick_state()
	

func _process(delta: float) -> void:
	if not player:
		return
	if is_moving:
		return

	if is_alive:
		var direction := player.global_position - global_position
		direction.y = 0.0

		if direction.length_squared() < 0.001:
			return

		var target_angle := atan2(direction.x, direction.z) + PI
		var weight := 1.0 - exp(-rotation_speed * delta)

		rotation.y = lerp_angle(rotation.y, target_angle, weight)
	else:
		look_at(camera.position)

	
func shoot():
	if not bullet_scene:
		return
	if not is_alive:
		return
	var bullet = bullet_scene.instantiate() as Node3D
	
	get_tree().current_scene.add_child(bullet)
	
	bullet.global_transform = muzzle.global_transform

func _on_shoot_timer_timeout() -> void:
	shoot()


func pick_state():
	print("bugged")
	if current_state == State.SLAM:
		current_state = State.SHOOTING
	else:
		current_state = State.SLAM
	enter_state(current_state)
	state_machine.remove_state_2_health(1)

func enter_state(new_state: State) -> void:
	match  new_state:
		State.SHOOTING:
			is_chasing = false
			is_moving = false
			anim.play("Shooting")
			shoot_timer.start()
		State.SLAM:
			is_chasing = true
			anim.stop()
			shoot_timer.stop()
			slam_anim()
			is_moving = true

func _on_state_timer_timeout() -> void:
	pick_state()
	
	
func slam_anim():
	if tween:
			tween.kill()
	tween = create_tween()
	tween.set_trans(Tween.TRANS_EXPO)
	tween.tween_property(self, "global_position", pos_b.position, 0.4)
	anim.play("Shooting", 3)
	await tween.finished
	anim.stop()
	await get_tree().create_timer(0.1).timeout
	if tween:
			tween.kill()
	tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "global_position", pos_a.position, 0.6)
	anim.play("Shooting", 3)
	await tween.finished
	is_moving = false
	anim.stop()

func end_state():
	print("2 state end")
	is_alive = false
	anim.stop()
	anim.play("Bury")
	await anim.animation_finished
	queue_free()
	
func beat_player():
	state_timer.stop()
	is_alive = false
	anim.stop()
	anim.play("Laugh_Normal")
	look_at(camera.position)
