extends Node

var hero_instance: Node2D = null
var hero_scene = preload("res://Characters/Hero.tscn") # путь к сцене с Героем

func spawn_hero() -> Node2D:
	if hero_instance:
		return hero_instance

	hero_instance = hero_scene.instantiate()
	return hero_instance
