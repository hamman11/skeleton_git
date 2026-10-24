extends Area3D

var speed: float = 30.0
var camera_basis: Basis
@onready var anim: AnimationPlayer = $seed3/AnimationPlayer

func _ready() -> void:
	await get_tree().create_timer(6.0).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	var move_dir = global_transform.basis.z
	move_dir.y = 0.0
	move_dir = move_dir.normalized() 

	global_position -= move_dir * speed * delta
