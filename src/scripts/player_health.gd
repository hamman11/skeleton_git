class_name Player_Health
extends Area3D

@onready var hearts_container: HBoxContainer = $"../CanvasLayer/HBoxContainer"
var current_health := 3
var hearts_list: Array[TextureRect] = []
@export var max_health := 3
@onready var i_timer: Timer = $"../InvincibiltyTimer"
var is_invincible := false

var player: Player
# Called when the node enters the scene tree for the first time.
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

func take_damage():
	var dmg = 1
	current_health -= dmg
	update_heart_display()
	if current_health <= 0:
		player.death()
	else :
		start_invincibility()

func update_heart_display() -> void:
	for i in range(hearts_list.size()):
		hearts_list[i].visible = i < current_health
		
func start_invincibility() -> void:
	is_invincible = true
	i_timer.start()


func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("enemy") and not is_invincible:
		take_damage()


func _on_invincibilty_timer_timeout() -> void:
	print('stopped invic')
	is_invincible = false
	
	var overlarpping_areas = get_overlapping_areas()
	print(overlarpping_areas.size)
	for area in overlarpping_areas:
		if area.is_in_group("enemy"):
			print("enemy is rapping me")
			take_damage()
			break
