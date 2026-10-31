extends Node3D


@onready var control_2: Control = $Control2
@onready var control: Control = $Control

func _ready() -> void:
	Music.play_level_music()

func _on_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/world.tscn")


func _on_button_pressed() -> void:
	control.visible = false
	control_2.visible = true
