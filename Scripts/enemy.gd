extends Node2D

signal enemy_defeated

func die():
	print("Враг повержен")
	emit_signal("enemy_defeated")
	queue_free()
