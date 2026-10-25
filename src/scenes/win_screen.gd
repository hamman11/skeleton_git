extends Control
@onready var label: Label = $Label

var tween: Tween
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "scale:y", 1, 0.3)
