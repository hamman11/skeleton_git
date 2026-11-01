extends Area3D

@export var knockback_force := 12.0

var current_health := 100.0
var max_health := 100.0

@export var health_bar: ProgressBar
@export var enemy: CharacterBody3D

@export var win_screen: Control
func _ready() -> void:
	win_screen.visible = false
	health_bar.value = current_health

func get_knockback_force() -> float:
	return knockback_force

func deal_damage(dmg: float):
	current_health -= dmg
	health_bar.value = current_health
	if current_health <= 0:
		if win_screen != null:
			win_screen.visible = true
		enemy.call_deferred("queue_free")


func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("bullet"):
		area.queue_free()
		deal_damage(1.5)
