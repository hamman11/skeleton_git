extends Node3D

@onready var anim = $skeleton/AnimationPlayer
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	anim.play("Crumble")
	await anim.animation_finished 
	queue_free()
