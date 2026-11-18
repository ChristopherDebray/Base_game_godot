extends Control

## Menu principal : bascule entre le panneau principal (jouer, options, quitter) et le panneau
## d'options, en gérant le focus pour la navigation à la manette.
class_name MainMenu

@onready var main_panel: Control = %MainPanel
@onready var options_panel: Control = %OptionsPanel
@onready var play_button: Button = %PlayButton
@onready var options_button: Button = %OptionsButton
@onready var quit_button: Button = %QuitButton
@onready var back_button: Button = %BackButton

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	back_button.pressed.connect(_on_back_pressed)
	_show_main_panel()

## Alterne entre le panneau principal et les options, et donne le focus au premier bouton
## du panneau affiché pour pouvoir naviguer à la manette.
func _show_main_panel() -> void:
	options_panel.hide()
	main_panel.show()
	play_button.grab_focus()

func _show_options_panel() -> void:
	main_panel.hide()
	options_panel.show()
	back_button.grab_focus()

func _on_play_pressed() -> void:
	GameManager.load_level(GameManager.FIRST_LEVEL)

func _on_options_pressed() -> void:
	_show_options_panel()

func _on_back_pressed() -> void:
	_show_main_panel()

func _on_quit_pressed() -> void:
	get_tree().quit()
