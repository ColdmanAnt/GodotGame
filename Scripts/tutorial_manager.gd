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

func on_dialog_finished():
	current_stage = Stage.AFTER_DIALOG
	print("Диалог завершён. Теперь подними топор.")

func on_axe_picked():
	if current_stage != Stage.AFTER_DIALOG:
		print("Рановато хвататься за оружие, воин.")
		return
	current_stage = Stage.GOT_AXE
	print("Топор взят. Теперь сядь.")

func on_sit_down():
	match current_stage:
		Stage.START, Stage.AFTER_DIALOG:
			print("Сначала нужно взять топор, а не искать где сесть.")
			return
		Stage.GOT_AXE:
			current_stage = Stage.SAT_DOWN
			get_parent().get_node("Stump").set_sitting(true)
			print("Игрок сел.")
		_:
			print("Ты уже сел. Второй раз не надо.")

func on_stand_up():
	if current_stage != Stage.SAT_DOWN:
		print("А ты что, уже сидел?! Я такого не помню.")
		return
	current_stage = Stage.STANDING_UP
	get_parent().get_node("Stump").set_sitting(false)
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
