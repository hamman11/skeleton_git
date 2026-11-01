extends Node3D
class_name TargetManager

var current_score := 0
var amount := 1
@export var finished_score := 5

@export var boss : Node3D
func add_target_score():
	current_score += amount
	if current_score >= finished_score:
		boss.start_state()
	print("mango")
