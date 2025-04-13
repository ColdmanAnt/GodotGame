extends Node2D

signal sit_down_requested
signal stand_up_requested

var is_sitting = false

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if is_sitting:
			print("Stump: Игрок хочет встать")
			emit_signal("stand_up_requested")
		else:
			print("Stump: Игрок хочет сесть")
			emit_signal("sit_down_requested")

func  set_sitting(value: bool):
	is_sitting = value
