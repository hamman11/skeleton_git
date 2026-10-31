class_name Player
extends CharacterBody3D

enum MovementMode { BODY, HEAD }

@export var body_speed := 8.0
@export var body_acceleration := 14.0
@export var body_friction := 8.0
@export var rotation_speed := TAU * 3.0

@export var head_speed := 12.0
@export var head_boost_speed := 22.0
@export var head_boost_duration := 0.35
@export var head_acceleration := 5.0
@export var head_drag := 0.985
@export var head_rotation_speed := 1.5

@export var knockback_duration := 0.2
@export var flash_interval := 0.08
@export var flash: Node3D

@export var projectile_scene: PackedScene
@export var shoot_point: Marker3D
@export var shoot_cooldown := 0.4
@export var shoot_delay := 0.08
@export var projectile_speed := 15.0

@export var switch_cooldown := 0.35

@export var death_screen: PackedScene
@export var anim: AnimationPlayer
@export var anim_death: AnimationPlayer
@export var book_anim: AnimationPlayer
@export var body: Node3D
@export var head: Node3D
@export var mesh: Node3D
@export var book: Node3D
@export var shadow: MeshInstance3D

@onready var death_anim: Node3D = $Death
@onready var shoot_timer: Timer = $ShootTimer

var camera: Camera3D
var is_alive := true
var has_moved := false
var is_head_mode := false
var is_shooting := false
var can_shoot := true
var can_switch := true
var movement_mode := MovementMode.BODY
var move_direction := Vector3.FORWARD
var head_boost_timer := 0.0
var shoot_delay_timer := 0.0
var pending_shot := false
var switch_timer := 0.0

var knockback_velocity := Vector3.ZERO
var knockback_timer := 0.0

var is_flashing := false
var flash_timer := 0.0
var flash_visible := true


func _ready() -> void:
	camera = get_viewport().get_camera_3d()

	body.visible = true
	head.visible = true
	death_anim.visible = false
	shadow.visible = false
	flash.visible = true
	book.visible = true

	shoot_timer.timeout.connect(_on_shoot_timer_timeout)

	update_movement_mode()
	book_anim.play_backwards("BookHide")
	await book_anim.animation_finished
	book_anim.play("BookFloat")
	
func _input(event: InputEvent) -> void:
	if event.is_action_released("shoot") and not is_head_mode:
		book_anim.play("BookFloat")
	if event.is_action_pressed("shoot") and not is_head_mode:
		book_anim.play("BookShoot")

func _process(delta: float) -> void:
	is_shooting = Input.is_action_pressed("shoot") and not is_head_mode

	if switch_timer > 0.0:
		switch_timer = maxf(switch_timer - delta, 0.0)
		can_switch = switch_timer <= 0.0

	if is_shooting and can_shoot and not pending_shot:
		pending_shot = true
		shoot_delay_timer = shoot_delay

	if pending_shot:
		shoot_delay_timer -= delta

		if shoot_delay_timer <= 0.0:
			pending_shot = false
			shoot()

	if not is_shooting:
		pending_shot = false

	if is_flashing:
		flash_timer -= delta
		if flash_timer <= 0.0:
			flash_timer = flash_interval
			flash_visible = not flash_visible
			flash.visible = flash_visible


func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	if Input.is_action_just_pressed("throw") and can_switch and knockback_timer <= 0.0:
		switch_movement_mode()

	head_boost_timer = maxf(head_boost_timer - delta, 0.0)

	if knockback_timer > 0.0:
		knockback_timer = maxf(knockback_timer - delta, 0.0)
		velocity = Vector3(knockback_velocity.x, 0.0, knockback_velocity.z)
		move_and_slide()
		return

	knockback_velocity = Vector3.ZERO

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

	if is_head_mode and is_on_wall():
		for i in range(get_slide_collision_count()):
			velocity = velocity.bounce(get_slide_collision(i).get_normal()) * 0.67

	move_and_slide()


func process_body_movement(input_dir: Vector3, delta: float) -> void:
	var target := Vector2(input_dir.x, input_dir.z) * body_speed
	var horizontal := Vector2(velocity.x, velocity.z)

	if input_dir.length_squared() > 0.0:
		horizontal = horizontal.move_toward(target, body_acceleration * delta)
		anim.play("Idle_001")
	else:
		horizontal = horizontal.move_toward(Vector2.ZERO, body_friction * delta)
		anim.play("Idle")

	if is_shooting:
		var mouse_dir := get_mouse_direction()
		if mouse_dir.length_squared() > 0.0:
			rotate_mesh(mouse_dir, delta, rotation_speed)
	elif input_dir.length_squared() > 0.0:
		rotate_mesh(input_dir, delta, rotation_speed)

	velocity.x = horizontal.x
	velocity.z = horizontal.y


func process_head_movement(input_dir: Vector3, delta: float) -> void:
	var target := Vector2(input_dir.x, input_dir.z) * get_head_speed()
	var horizontal := Vector2(velocity.x, velocity.z)

	horizontal = horizontal.move_toward(target, head_acceleration * delta)

	if input_dir.length_squared() == 0.0:
		horizontal *= pow(head_drag, delta * 60.0)
	else:
		rotate_mesh(input_dir, delta, head_rotation_speed)

	velocity.x = horizontal.x
	velocity.z = horizontal.y


func get_mouse_direction() -> Vector3:
	if camera == null:
		return Vector3.ZERO

	var mouse_pos := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_direction := camera.project_ray_normal(mouse_pos)
	var hit = Plane(Vector3.UP, global_position.y).intersects_ray(ray_origin, ray_direction)

	if hit == null:
		return Vector3.ZERO

	var direction: Vector3 = hit - global_position
	direction.y = 0.0
	return direction.normalized()


func get_head_speed() -> float:
	if head_boost_timer > 0.0:
		return lerp(head_speed, head_boost_speed, head_boost_timer / head_boost_duration)

	return head_speed


func rotate_mesh(direction: Vector3, delta: float, speed: float) -> void:
	var target_angle := atan2(-direction.x, -direction.z)
	mesh.rotation.y = rotate_toward(mesh.rotation.y, target_angle, speed * delta)


func shoot() -> void:
	if not can_shoot or is_head_mode or not is_alive:
		return

	if projectile_scene == null or shoot_point == null:
		return

	var direction := get_mouse_direction()
	if direction.length_squared() == 0.0:
		return

	can_shoot = false

	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)

	projectile.global_position = shoot_point.global_position
	projectile.direction = direction
	projectile.speed = projectile_speed

	shoot_timer.start(shoot_cooldown)


func _on_shoot_timer_timeout() -> void:
	can_shoot = true


func switch_movement_mode() -> void:
	if not can_switch:
		return

	can_switch = false
	switch_timer = switch_cooldown

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
	is_head_mode = movement_mode == MovementMode.HEAD
	pending_shot = false
	body.visible = not is_head_mode
	head.visible = true
	shadow.visible = is_head_mode

	if is_head_mode:
		book_anim.play("BookHide")
		await book_anim.animation_finished
		book.visible = false
	else:
		book.visible = true
		book_anim.play_backwards("BookHide")
		await book_anim.animation_finished
		book_anim.play("BookFloat")


func apply_knockback(source: Node3D, force: float) -> void:
	var direction := global_position - source.global_position
	direction.y = 0.0

	if direction.length_squared() < 0.001:
		direction = -global_transform.basis.z

	knockback_velocity = direction.normalized() * force
	knockback_timer = knockback_duration
	velocity.x = knockback_velocity.x
	velocity.z = knockback_velocity.z


func set_invincibility_flash(active: bool) -> void:
	is_flashing = active
	flash_timer = 0.0
	flash_visible = true
	flash.visible = true


func _on_player_first_move() -> void:
	if camera and camera.has_method("zoom_out_anim"):
		camera.zoom_out_anim()


func death() -> void:
	if not is_alive:
		return

	is_alive = false
	velocity = Vector3.ZERO
	knockback_velocity = Vector3.ZERO
	pending_shot = false
	set_invincibility_flash(false)

	body.visible = false
	head.visible = false
	death_anim.visible = true

	if death_screen != null:
		get_tree().current_scene.add_child(death_screen.instantiate())

	anim_death.play("deathanim")
