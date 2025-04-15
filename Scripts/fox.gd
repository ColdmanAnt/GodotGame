extends Node2D

enum Mood{
	NEUTRAL,
	ANNOYED,
	HAPPY
}

var dialog_ui_instance: DialogUI = null
var mood: Mood = Mood.NEUTRAL
signal dialog_finished
var already_talked = false
var dialog_in_progress = false

func _ready():
	pass

func set_dialog_ui(ui: DialogUI) -> void:
	dialog_ui_instance = ui

func initial():	
	show_dialog(["Хммм"], "main")

func start_followup_dialog():
	dialog_in_progress = true
	var lines = []
	match mood:
		Mood.HAPPY:
			lines = ["Молодец. Быстро соображаешь, я почти горжусь"]
		Mood.NEUTRAL:
			lines = ["Ты даже что-то умеешь? Посмотрим, время покажет случайность ли это"]
		Mood.ANNOYED:
			lines = ["Ты настолько.... медленный. Я ожидала большего"]
	show_dialog(lines, "chat")

func show_dialog(lines: Array, source: String = "main"):
	print("Fox:")
	if dialog_ui_instance:
		dialog_ui_instance.show_dialog(lines, Callable(self, "_on_dialog_finished"))
	else:
		print(lines)
	if source == "main":
		emit_signal("dialog_finished")


func _input(event):
	if event.is_action_pressed("ui_select") and not dialog_in_progress:
		if not already_talked:
			already_talked = true
			
			initial()
		else:
			start_followup_dialog()

func suggest_next_step(text: String):
	if dialog_in_progress:
		return
	dialog_in_progress = true
	show_dialog([text], "hint")
	dialog_in_progress = false 
