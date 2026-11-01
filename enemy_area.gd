extends Area3D

@export var knockback_force := 12.0

var current_health := 100.0
var max_health := 100.0

@export var health_bar: ProgressBar
@export var enemy: CharacterBody3D

func _ready() -> void:
	health_bar.value = current_health

func get_knockback_force() -> float:
	return knockback_force

func deal_damage(dmg: float):
	current_health -= dmg
	health_bar.value = current_health
	if current_health <= 0:
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
		enemy.hide()


func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("bullet"):
		area.queue_free()
		deal_damage(0.5)
