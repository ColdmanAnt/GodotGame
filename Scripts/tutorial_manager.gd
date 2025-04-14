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
		"Пень не портал в другой мир. Проверь.",
		"Не засыпай. Я тебя знаю."
	],
	Stage.STANDING_UP: [
		"Перед тобой враг. Дай ему понять, что ты — не просто лесной турист.",
		"Ты с топором. Он с глазами. Уравни уравнение.",
		"Ну давай, махни. Это не экзамен, это просто агрессивное знакомство."
	]
}

var hint_indices := {}

var idle_timer := 0.0
var idle_threshold := 15.0
var stage_last_updated_time := 0.0

func _ready():
	print("Tutorial started. Current stage:", current_stage)
	setup_connections()

func setup_connections():
	var fox = FoxController.spawn_fox()

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
			FoxController.fox_instance.suggest_next_step(message)
			hint_indices[stage] = idx + 1
		else:
			# Всё. Она больше не будет повторяться. Считай, ты её утомил.
			pass
func on_dialog_finished():
	current_stage = Stage.AFTER_DIALOG
	idle_timer = 0.0
	stage_last_updated_time = 0.0
	print("Диалог завершён. Теперь подними топор.")

func on_axe_picked():
	if current_stage != Stage.AFTER_DIALOG:
		print("Рановато хвататься за оружие, воин.")
		return
	idle_timer = 0.0
	stage_last_updated_time = 0.0
	current_stage = Stage.GOT_AXE
	update_fox_mood()
	print("Топор взят. Теперь сядь.")

func on_sit_down():
	match current_stage:
		Stage.START, Stage.AFTER_DIALOG:
			print("Сначала нужно взять топор, а не искать где сесть.")
			return
		Stage.GOT_AXE:
			current_stage = Stage.SAT_DOWN
			get_parent().get_node("Stump").set_sitting(true)
			idle_timer = 0.0
			stage_last_updated_time = 0.0
			update_fox_mood()
			print("Игрок сел.")
		_:
			print("Ты уже сел. Второй раз не надо.")

func on_stand_up():
	if current_stage != Stage.SAT_DOWN:
		print("А ты что, уже сидел?! Я такого не помню.")
		return
	current_stage = Stage.STANDING_UP
	get_parent().get_node("Stump").set_sitting(false)
	idle_timer = 0.0
	stage_last_updated_time = 0.0
	update_fox_mood()
	print("Игрок встал, вызываю врага")

func on_enemy_defeated():
	if current_stage != Stage.STANDING_UP:
		print("Может все таки встанешь уже? Чего прохлаждаешься")
		return
	current_stage = Stage.ENEMY_DEFEATED
	print("Урок окончен.")
	# TODO: Заменить на переход к экрану завершения или меню
	get_tree().quit()

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
	if idle_timer < 7.0:
		FoxController.fox_instance.mood = FoxController.fox_instance.Mood.HAPPY
	elif idle_timer < idle_threshold:
		FoxController.fox_instance.mood = FoxController.fox_instance.Mood.NEUTRAL
	else:
		FoxController.fox_instance.mood = FoxController.fox_instance.Mood.ANNOYED
		
