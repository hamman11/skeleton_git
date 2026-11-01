extends Area3D

@export var speed: float = 10
var camera_basis: Basis
const hit_particles = preload("res://src/scenes/pumpkin_particles.tscn")
@export var mesh: MeshInstance3D

@export var knockback_force := 12.0

func get_knockback_force() -> float:
	return knockback_force
func _ready() -> void:
	await get_tree().create_timer(2).timeout
	mesh.visible = false
	var instance = hit_particles.instantiate()
	get_parent().add_child(instance)
	instance.global_position = global_position
	instance.emitting = true
	instance.finished.connect(instance.queue_free)
	instance.finished.connect(queue_free)

func _physics_process(delta: float) -> void:
	var move_dir = global_transform.basis.z
	move_dir.y = 0.0
	move_dir = move_dir.normalized() 

	global_position -= move_dir * speed * delta

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		await get_tree().process_frame
		queue_free()
