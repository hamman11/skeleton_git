extends GPUParticles3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	emitting = true
	finished.connect(_on_finished)
	
func _on_finished() -> void:
	queue_free()
