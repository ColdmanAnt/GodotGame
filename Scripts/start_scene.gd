extends Node2D

var DialogueSystemScene = preload("res://Scenes/DialogueSystem.tscn")
var dialogue_instance

func _ready():
	dialogue_instance = DialogueSystemScene.instantiate()
	add_child(dialogue_instance)
	Global.dialogue_system = dialogue_instance
