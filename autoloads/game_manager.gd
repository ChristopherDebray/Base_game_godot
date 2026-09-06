extends Node

enum RESOURCE_TYPE { LIFE }
enum CONTROLS_TYPE { XBOX, PLAYSATION, KEYBOARD }

var current_run_gold := 0
var blood := 0
var current_health: float
var max_health: float
var camera_shake_noise: FastNoiseLite
var used_controls := CONTROLS_TYPE.KEYBOARD

func _ready() -> void:
	camera_shake_noise = FastNoiseLite.new()
	set_used_controls()

func modify_current_health(amount: float):
	current_health = current_health + amount

func set_player_health(amount: float):
	current_health = amount
	max_health = amount

func load_main_scene() -> void:
	var scene = load("res://scenes/ui/main_menu_ui/main_menu_ui.tscn")
	get_tree().change_scene_to_packed(scene)

func load_level(level: String):
	var level_path = "res://scenes/level/levels/%s.tscn" % level
	if false == ResourceLoader.exists(level_path, "PackedScene"):
		load_main_scene()
		return
	
	var level_scene = load(level_path)
	get_tree().change_scene_to_packed(level_scene)

func set_used_controls():
	if Input.get_connected_joypads().is_empty():
		used_controls = CONTROLS_TYPE.KEYBOARD
	elif !Input.get_connected_joypads().is_empty():
		used_controls = CONTROLS_TYPE.XBOX
