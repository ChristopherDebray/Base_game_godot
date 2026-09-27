extends Control

signal on_menu_toggle(state: bool)

@onready var menu_boostrap: Control = $MenuBootstrap

@export var sheet: Texture2D
@export var cell_size: Vector2i = Vector2i(32, 32)

var _cache: Dictionary = {}

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		var is_paused = get_tree().paused
		get_tree().paused = !is_paused
		if is_paused:
			hide()
			on_menu_toggle.emit(false)
			MenuManager.pop()
		else:
			show()
			menu_boostrap._on_open_menu()
			on_menu_toggle.emit(true)
			MenuManager.push(self)
