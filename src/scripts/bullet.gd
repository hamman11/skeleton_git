extends Area3D

@export var speed := 15.0
@export var lifetime := 3.0

var direction := Vector3.FORWARD


func _ready() -> void:
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
