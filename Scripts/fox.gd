extends Node2D

enum Mood{
	NEUTRAL,
	ANNOYED,
	HAPPY
}


var mood: Mood = Mood.NEUTRAL
signal dialog_finished
var already_talked = false
var dialog_in_progress = false

func _ready():
	pass

func start_initial_dialog():
	dialog_in_progress = true
	var lines = ["О, ты проснулся. Я уж думала, ты останешься тут навсегда.",
		"Меня зовут.... Просто называй меня лисой. Я тут, чтобы тебя не отпускать бездарно умирать."]
	show_dialog(lines, "main")

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
	for line in lines:
		print(line)
		await get_tree().create_timer(1.0).timeout
	dialog_in_progress = false

	if source == "main":
		emit_signal("dialog_finished")
	
	

func _input(event):
	if event.is_action_pressed("ui_select") and not dialog_in_progress:
		if not already_talked:
			already_talked = true
			start_initial_dialog()
		else:
			start_followup_dialog()

func suggest_next_step(text: String):
	if dialog_in_progress:
		return
	dialog_in_progress = true
	show_dialog([text], "hint")
	dialog_in_progress = false 
