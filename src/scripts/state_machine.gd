extends Node3D

@onready var state_1: CharacterBody3D = $state1

func _ready() -> void:
	state_1.start_state()
