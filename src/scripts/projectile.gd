extends Area3D

@export var speed: float = 10
var camera_basis: Basis
@onready var anim: AnimationPlayer = $seed3/AnimationPlayer
const hit_particles = preload("res://src/scenes/pumpkin_particles.tscn")
@export var mesh: MeshInstance3D
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
	
