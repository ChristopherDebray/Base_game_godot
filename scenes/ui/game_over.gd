extends Control

## Écran de fin de partie : affiché à la mort du joueur (`SignalManager.on_player_died`), il met
## le jeu en pause et propose de rejouer ou de retourner au menu principal.
class_name GameOver

@onready var retry_button: Button = %RetryButton
@onready var main_menu_button: Button = %MainMenuButton

func _ready() -> void:
	retry_button.pressed.connect(_on_retry_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	SignalManager.on_player_died.connect(_on_player_died)

## Affiche l'écran et met le jeu en pause (ce node tourne en process_mode ALWAYS).
func _on_player_died() -> void:
	show()
	get_tree().paused = true
	retry_button.grab_focus()

func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	GameManager.load_main_scene()
