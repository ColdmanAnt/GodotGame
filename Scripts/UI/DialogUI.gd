extends Control
class_name DialogUI

signal dialog_finished

@export var typing_speed: float = 0.05

var dialog_lines: Array = []
var current_line_index: int = 0

var full_text: String = ""
var current_text: String = ""
var is_typing: bool = false
var sound_delay = 2
var on_dialog_finished_callback: Callable = Callable()

# Эти переменные нужны для покадровой логики:
var _typing_index: int = 0     # индекс текущего символа в строке
var _timer: float = 0.0        # счётчик времени для вывода следующей буквы

@onready var letter_sound: AudioStreamPlayer = $Panel/LetterSound
var sound = load("res://Assets/Audio/Dialog/mixkit-sci-fi-typewriter-sound-1370-_1_.wav")
@onready var label: Label = $Panel/Label

func _ready() -> void:
	visible = false  # По умолчанию окно диалога скрыто.

# Запустить диалог:
# lines — массив строк для показа,
# callback (необязательно) — вызывается, когда диалог закончился
func show_dialog(lines: Array, callback: Callable = Callable()) -> void:
	if label == null:
		push_error("❌ Label не инициализирован. Проверь порядок вызова!")
		return
	dialog_lines = lines
	current_line_index = 0
	on_dialog_finished_callback = callback
	visible = true
	_show_current_line()

func _show_current_line() -> void:
	if current_line_index >= dialog_lines.size():
		_finish_dialog()
		return  
	full_text = dialog_lines[current_line_index]
	current_text = ""
	label.text = ""
	_typing_index = 0
	_timer = 0.0
	is_typing = true

# Вместо yield или async используем покадровую логику в _process().
func _process(delta: float) -> void:
	if is_typing:
		_timer += delta
		# Когда накопится времени >= typing_speed — выведем следующую букву
		if _timer >= typing_speed:
			_timer = 0.0
			# Если ещё есть буквы для вывода:
			if _typing_index < full_text.length():
				var next_char = full_text[_typing_index]
				current_text += next_char
				_typing_index += 1
				label.text = current_text
				if next_char != " ":
					letter_sound.play()
			else:
				# Все буквы уже выведены, завершаем процесс печати
				label.text = full_text
				letter_sound.stop()  # Останавливаем звук, когда текст полностью выведен
				is_typing = false

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
		_on_next_pressed()

func _on_next_pressed() -> void:
	if is_typing:
		# Если печать не закончена, прерываем и сразу показываем весь текст
		is_typing = false
		label.text = full_text
	else:
		# Переходим к следующей строке или завершаем диалог
		current_line_index += 1
		_show_current_line()

func _finish_dialog() -> void:
	visible = false
	emit_signal("dialog_finished")
	# Вызываем callback, если он задан
	if on_dialog_finished_callback.is_valid():
		on_dialog_finished_callback.call()
