extends Area3D

@export var target_manager: TargetManager
@export var anim : AnimationPlayer
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("bullet"):
		anim.play("Hit", -1, 1.4)
		area.queue_free()
		collision_mask = 0
		target_manager.add_target_score()
