extends Node

const MAIN_MENU_PATH := "res://scenes/ui/main_menu.tscn"
const LEVELS_DIR := "res://scenes/levels/"
## Niveau lancé par le bouton Play (chemin relatif à LEVELS_DIR, sans extension).
const FIRST_LEVEL := "part_1/level_1"

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

## Ajoute `amount` (négatif pour des dégâts) à la santé courante, sans borne ni signal.
func modify_current_health(amount: float) -> void:
	current_health = current_health + amount

## Initialise la santé courante ET maximale à `amount` (début de partie / réinitialisation).
func set_player_health(amount: float) -> void:
	current_health = amount
	max_health = amount

## Charge le menu principal. Sans effet (avec une erreur) si la scène est introuvable.
func load_main_scene() -> void:
	_change_scene(MAIN_MENU_PATH)

## Charge un niveau de `res://scenes/levels/` à partir de son chemin relatif sans extension
## (ex. "part_1/level_1"). Retombe sur le menu principal si le niveau est invalide ou absent.
func load_level(level: String) -> void:
	if level.is_empty() or ".." in level:
		push_warning("Nom de niveau invalide : '%s'" % level)
		load_main_scene()
		return

	var level_path := LEVELS_DIR + "%s.tscn" % level
	if not ResourceLoader.exists(level_path, "PackedScene"):
		push_warning("Niveau introuvable : %s" % level_path)
		load_main_scene()
		return

	_change_scene(level_path)

## Met à jour `used_controls` : XBOX si au moins une manette est connectée, sinon KEYBOARD.
func set_used_controls() -> void:
	if Input.get_connected_joypads().is_empty():
		used_controls = CONTROLS_TYPE.KEYBOARD
	elif !Input.get_connected_joypads().is_empty():
		used_controls = CONTROLS_TYPE.XBOX

## Change de scène avec vérification du chargement.
func _change_scene(scene_path: String) -> void:
	var scene := load(scene_path) as PackedScene
	if scene == null:
		push_error("Impossible de charger la scène : %s" % scene_path)
		return
	get_tree().change_scene_to_packed(scene)
