extends CharacterBody3D

var is_chasing := false

enum State {SHOOTING, CHASING}
@export var current_state: State = State.SHOOTING

@export var player: CharacterBody3D
@export var anim: AnimationPlayer

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
	if current_state == State.CHASING:
		current_state = State.SHOOTING
	else:
		current_state = State.CHASING
	enter_state(current_state)
	state_machine.remove_state_1_health(1)

func enter_state(new_state: State) -> void:
	match  new_state:
		State.SHOOTING:
			is_chasing = false
			anim.play("Shooting")
			shoot_timer.start()
		State.CHASING:
			is_chasing = true
			anim.play("Chase")
			shoot_timer.stop()

func _on_state_timer_timeout() -> void:
	pick_state()
	
func end_state():
	print("end state is good state")
	is_alive = false
	anim.stop()
	anim.play("Bury")
	await anim.animation_finished
	queue_free()
	
func beat_player():
	is_alive = false
	anim.stop()
	state_timer.stop()
	anim.play("Laugh_Normal")
	look_at(camera.position)
