extends Node

enum Stage {
	START,
	AFTER_DIALOG,
	GOT_AXE,
	SAT_DOWN,
	STANDING_UP,
	ENEMY_DEFEATED
}
var current_stage = Stage.START
var fox_score := 0
var DialogUIScene = preload("res://Scenes/UI/DialogUI.tscn")
var dialog_ui_instance: DialogUI



var hint_messages := {
	Stage.AFTER_DIALOG: [
		"Ты вроде как должен взять топор. Он рядом. Не бойся.",
		"Попробуй взять топор. Это тот, что блестит.",
		"Если не возьмёшь топор — я возьму. И начну урок заново."
	],
	Stage.GOT_AXE: [
		"Пеньок рядом. Не стесняйся. Он тебя не укусит.",
		"Сядь. Это часть обучения. Или просто расслабься.",
		"Топор в руках, а ты стоишь. Надеюсь, у тебя план, а не ступор."
	],
	Stage.SAT_DOWN: [
		"Ты сел. Молодец. Теперь надо встать. Это делается ногами.",
		"Пень не портал в другой мир. Поверь.",
		"Не засыпай. Я тебя знаю."
	],
	Stage.STANDING_UP: [
		"Перед тобой враг. Дай ему понять, что ты — не просто лесной турист.",
		"Ты с топором. Он с глазами. Уравни уравнение.",
		"Ну давай, махни. Это не экзамен, это просто агрессивное знакомство."
	]
}

var initial_dialog = ["О, ты проснулся. Я уж думала, ты останешься тут навсегда.",
		"Меня зовут.... Просто называй меня лисой. Я тут, чтобы тебя не отпускать бездарно умирать."]

var hint_indices := {}

var idle_timer := 0.0
var idle_threshold := 4.0
var stage_last_updated_time := 0.0

func _ready():
	await get_tree().process_frame
	print("Tutorial started. Current stage:", current_stage)
	setup_connections()

func setup_connections():
	var fox = FoxController.spawn_fox()
	dialog_ui_instance = DialogUIScene.instantiate()
	get_parent().call_deferred("add_child", dialog_ui_instance)
	await get_tree().process_frame
	
	dialog_ui_instance.show_dialog(initial_dialog)
	fox.initial()
	dialog_ui_instance.connect("dialog_finished", Callable(self, "_on_dialog_finished"))
	

	get_parent().call_deferred("add_child", fox) # или get_tree().get_root().add_child(fox)
	fox.connect("dialog_finished",Callable(self, "on_dialog_finished"))
	
	var axe = get_parent().get_node("Axe")
	axe.connect("axe_picked", Callable(self, "on_axe_picked"))
	
	var stump = get_parent().get_node("Stump")
	stump.connect("sit_down_requested", Callable(self, "on_sit_down"))
	stump.connect("stand_up_requested", Callable(self, "on_stand_up"))
	
	var enemy = get_parent().get_node("Enemy")
	enemy.connect("enemy_defeated", Callable(self, "on_enemy_defeated"))
	



func _process(delta: float):
	idle_timer += delta
	stage_last_updated_time += delta
	check_idle_hint()

func check_idle_hint():
	var stage = current_stage

	if stage in hint_messages and idle_timer >= idle_threshold:
		idle_timer = 0.0

		var idx = hint_indices.get(stage, 0)
		var messages = hint_messages[stage]

		if idx < messages.size():
			var message = messages[idx]
			dialog_ui_instance.show_dialog([message])
			hint_indices[stage] = idx + 1
		else:
			# Всё. Она больше не будет повторяться. Считай, ты её утомил.
			pass


func on_dialog_finished():
	current_stage = Stage.AFTER_DIALOG
	update_fox_mood()
	idle_timer = 0.0
	stage_last_updated_time = 0.0
	dialog_ui_instance.show_dialog(["Диалог завершён. Теперь подними топор."])

func on_axe_picked():
	if current_stage != Stage.AFTER_DIALOG:
		dialog_ui_instance.show_dialog(["Рановато хвататься за оружие, воин."])
		return
	update_fox_mood()
	idle_timer = 0.0
	stage_last_updated_time = 0.0
	current_stage = Stage.GOT_AXE
	dialog_ui_instance.show_dialog(["Он хоть и старый, но на первое время поможет, теперь сядь на пенек"])

func on_sit_down():
	match current_stage:
		Stage.START, Stage.AFTER_DIALOG:
			dialog_ui_instance.show_dialog(["Сначала нужно взять топор, а не искать где сесть."])
			return
		Stage.GOT_AXE:
			current_stage = Stage.SAT_DOWN
			get_parent().get_node("Stump").set_sitting(true)
			update_fox_mood()
			idle_timer = 0.0
			stage_last_updated_time = 0.0
			dialog_ui_instance.show_dialog(["Если ты сядешь отдохнуть, то выносливость будет востанавливаться быстрее, а теперь давай вставай, пора в путь"])
		_:
			dialog_ui_instance.show_dialog(["Ты уже сел. Второй раз не надо."])

func on_stand_up():
	if current_stage != Stage.SAT_DOWN:
		dialog_ui_instance.show_dialog(["А ты что, уже сидел?! Я такого не помню. Отдыхать - важно"])
		return
	current_stage = Stage.STANDING_UP
	get_parent().get_node("Stump").set_sitting(false)
	update_fox_mood()
	idle_timer = 0.0
	stage_last_updated_time = 0.0
	dialog_ui_instance.show_dialog(["Игрок встал, вызываю врага"])

func on_enemy_defeated():
	if current_stage != Stage.STANDING_UP:
		dialog_ui_instance.show_dialog(["Может всё таки встанешь уже? Чего прохлаждаешься"])
		return
	current_stage = Stage.ENEMY_DEFEATED
	dialog_ui_instance.show_dialog(["Урок окончен."])

	show_fox_final_comment()


func _input(event):
	if event.is_action_pressed("attack"): # <- это action типа "LMB"
		try_attack()

func try_attack():
	if current_stage != Stage.STANDING_UP:
		return
	
	var enemy = get_parent().get_node("Enemy")
	
	if not enemy:
		print("Враг куда-то делся. Возможно, испарился от страха.")
		return

	# Простая проверка — игрок рядом:
	enemy.die()

func update_fox_mood():
	if idle_timer < idle_threshold/2:
		fox_score += 2
		print("FoxScore:", fox_score)
		FoxController.fox_instance.mood = FoxController.fox_instance.Mood.HAPPY
	elif idle_timer < idle_threshold:
		fox_score+= 1
		print("FoxScore:", fox_score)
		FoxController.fox_instance.mood = FoxController.fox_instance.Mood.NEUTRAL
	else:
		fox_score -= 2
		print("FoxScore:", fox_score)
		FoxController.fox_instance.mood = FoxController.fox_instance.Mood.ANNOYED

func show_fox_final_comment():
	var fox = FoxController.fox_instance
	var line = ""

	if fox_score >= 6:
		line = "Ты справился. Быстро, точно. Приятно удивлённа."
	elif fox_score >= 3:
		line = "Ну, ты не худший ученик. В лесу мог бы и выжить."
	else:
		line = "Ты жив. Это уже победа. Но мы с тобой ещё поработаем."
	
	print("Final fox_score: ", fox_score)
	dialog_ui_instance.show_dialog([line])
	fox.suggest_next_step(line)
	Global.set_reputation("fox", fox_score)

	await get_tree().create_timer(3.5).timeout
	get_tree().quit()  # Теперь можно завершить
