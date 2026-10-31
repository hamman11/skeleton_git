
class_name Player_Health
extends Area3D

@export var max_health := 3

@onready var hearts_container: HBoxContainer = $"../CanvasLayer/HBoxContainer"
@onready var i_timer: Timer = $"../InvincibiltyTimer"

var current_health := 3
var hearts_list: Array[TextureRect] = []
var is_invincible := false
var player: Player

func _ready() -> void:
	current_health = max_health

	player = get_tree().get_first_node_in_group("player") as Player

	for child in hearts_container.get_children():
		if child is TextureRect:
			hearts_list.append(child)

	update_heart_display()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		take_damage()

func take_damage(source: Node3D = null) -> void:
	if is_invincible:
		return

	current_health -= 1
	update_heart_display()

	if current_health <= 0:
		player.death()
	else:
		if source != null and source.has_method("get_knockback_force"):
			player.apply_knockback(source, source.get_knockback_force())

		start_invincibility()

func update_heart_display() -> void:
	for i in range(hearts_list.size()):
		hearts_list[i].visible = i < current_health

func start_invincibility() -> void:
	is_invincible = true
	player.set_invincibility_flash(true)
	i_timer.start()

func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("enemy") and not is_invincible:
		take_damage(area)

func _on_invincibilty_timer_timeout() -> void:
	is_invincible = false
	player.set_invincibility_flash(false)

	for area in get_overlapping_areas():
		if area.is_in_group("enemy"):
			take_damage(area)
			break
