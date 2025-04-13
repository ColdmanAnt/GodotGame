extends Node2D

signal dialog_finished
var already_talked = false
func  _input(event):
	if event.is_action_pressed("ui_select") and not already_talked:
		already_talked = true
		print("Fox: Диалог завершен")
		emit_signal("dialog_finished")
