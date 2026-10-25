extends Node3D

enum State {ONE, TWO, THREE}

var current_state: State = State.ONE
@onready var state_1: CharacterBody3D = $state1
@onready var state_2: CharacterBody3D = $state2
@onready var state_3: CharacterBody3D = $state3
@onready var sad_pumpkin: CharacterBody3D = $sad_pumpkin

var current_health: int

@export var win_screen: PackedScene

@export var state1_health: int
@export var state2_health: int
@export var state3_health: int

func _ready() -> void:
	state_1.process_mode = CharacterBody3D.PROCESS_MODE_DISABLED
	state_2.process_mode = CharacterBody3D.PROCESS_MODE_DISABLED
	state_3.process_mode = CharacterBody3D.PROCESS_MODE_DISABLED

func start_state1():
	current_state = State.ONE
	await get_tree().create_timer(0.6).timeout
	state_1.process_mode = CharacterBody3D.PROCESS_MODE_INHERIT
	current_health =state1_health
	state_1.start_state()
	
func remove_state_1_health(dmg: int):
	current_health -= dmg
	print(current_health)
	if current_health <= 0:
		stop_state_1()
		start_state2()
		

func stop_state_1():
	print("yessir")
	state_1.end_state()
	
func start_state2():
	current_state = State.TWO
	await get_tree().create_timer(0.6).timeout
	current_health =state2_health
	state_2.process_mode = CharacterBody3D.PROCESS_MODE_INHERIT
	state_2.start_state()
	sad_pumpkin.process_mode = Node.PROCESS_MODE_INHERIT
	sad_pumpkin.start_state()
	
func remove_state_2_health(dmg: int):
	current_health -= dmg
	print(current_health)
	if current_health <= 0:
		stop_state_2()
		sad_pumpkin.end_state()
		state_3.process_mode = CharacterBody3D.PROCESS_MODE_INHERIT
		start_state3()

func stop_state_2():
	print("yessir")
	state_2.end_state()
	sad_pumpkin.end_state()
	
	
func start_state3():
	current_state = State.THREE
	await get_tree().create_timer(0.6).timeout
	current_health =state3_health
	state_3.start_state()
	
func remove_state_3_health(dmg: int):
	current_health -= dmg
	print(current_health)
	if current_health <= 0:
		stop_state_3()

func stop_state_3():
	state_3.end_state()
	var screen = win_screen.instantiate()
	get_tree().current_scene.add_child(screen)
	

func player_died():
	match current_state:
		State.ONE:
			state_1.beat_player()
		State.TWO:
			sad_pumpkin.end_state()
			state_2.beat_player()
		State.THREE:
			state_3.beat_player()
