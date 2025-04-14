extends CanvasLayer

signal dialog_finished

var lines: Array = []
var current_index := 0
var is_active := false

func start_dialog(new_lines: Array):
	lines = new_lines
	current_index = 0
	is_active = true
	show()
	show_next_line()

func show_next_line():
	if current_index >= lines.size():
		hide()
		is_active = false
		emit_signal("dialog_finished")
		return
	$DialogueBox/DialogueText.text = lines[current_index]
	current_index += 1

func _input(event):
	if is_active and event.is_action_pressed("ui_accept"):
		show_next_line()
