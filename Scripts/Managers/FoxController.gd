extends Node

var fox_instance: Node2D = null
var fox_scene = preload("res://Characters/Fox.tscn") # путь к твоей сцене с лисой

func spawn_fox() -> Node2D:
	if fox_instance:
		return fox_instance

	fox_instance = fox_scene.instantiate()
	return fox_instance
