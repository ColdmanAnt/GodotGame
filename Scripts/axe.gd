extends Node2D

signal axe_picked
var picked = false

func _input(event):
	if event.is_action_pressed("ui_focus_next") and not picked:
		print("Axe: Поднят топор")
		picked = true
		emit_signal("axe_picked")
