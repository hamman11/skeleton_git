extends Area3D

@export var speed := 15.0
@export var lifetime := 3.0
@export var anim: AnimationPlayer
var direction := Vector3.FORWARD


func _ready() -> void:
	monitoring = true
	anim.play("Start", -1, 6)
	await anim.animation_finished
	anim.play("Idle")
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta


func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("enemy"):
		pass
