extends Node3D

var tween: Tween
var head_tween: Tween
var skeleton_tween: Tween

@export var pivot: Node3D
@export var head_mesh: Node3D
@export var skeleton_mesh: Node3D

func _ready() -> void:
	skeleton_mesh.visible = true

func release_anim():
	if tween:
		tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_EXPO)
	if head_tween:
		head_tween.kill()
	head_tween = create_tween().set_trans(Tween.TRANS_BOUNCE)
	
	tween.tween_property(pivot, "scale", Vector3(1.0, 0.5, 1.0), 0.1)
	head_tween.tween_property(head_mesh, "scale", Vector3(1.0, 0.35, 1.0), 0.1)
	head_tween.tween_property(head_mesh, "scale", Vector3(1.0, 1.0, 1.0), 0.1).set_delay(0.1)
	tween.tween_property(pivot, "scale", Vector3(1.0, 1.0, 1.0), 0.1).set_delay(0.1)
	
func return_anim():
	skeleton_mesh.scale = Vector3(1.0, 0.0, 1.0)
	skeleton_mesh.visible = true
	if skeleton_tween:
		skeleton_tween.kill()
	skeleton_tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	skeleton_tween.tween_property(skeleton_mesh, "scale", Vector3(1.0, 1.0, 1.0), 0.3)
