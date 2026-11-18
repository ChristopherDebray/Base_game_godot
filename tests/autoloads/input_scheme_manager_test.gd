class_name InputSchemeManagerTest
extends GdUnitTestSuite

## Tests de l'InputSchemeManager (détection clavier/manette).
##
## On appelle `_unhandled_input` directement : c'est le point d'entrée du moteur, et
## l'injecter via le viewport rendrait le test dépendant de la fenêtre. La détection du TYPE
## de manette (Xbox/PlayStation) lit `Input.get_joy_name`, donc le matériel : elle n'est pas
## testée ici (voir la description de la PR).
## Hypothèse : aucune manette n'est branchée pendant les tests (headless/CI).

const INPUT_SCHEME_MANAGER_SCRIPT := "res://autoloads/input_scheme_manager.gd"
const SCHEME_CHANGED_SIGNAL := "scheme_changed"
const UNUSED_DEVICE_ID := 0

var _manager: Node
# `is_not_emitted` de gdUnit n'écoute qu'À PARTIR du `await` : une émission déjà passée n'est pas vue.
# Pour prouver qu'un signal n'est PAS émis, on le collecte dès l'arrivée du manager.
var _emitted_schemes: Array[int] = []


func before_test() -> void:
	_manager = auto_free(load(INPUT_SCHEME_MANAGER_SCRIPT).new())
	add_child(_manager)
	_emitted_schemes.clear()
	_manager.scheme_changed.connect(func(scheme: int) -> void: _emitted_schemes.append(scheme))


func test_default_scheme_is_keyboard() -> void:
	assert_int(_manager.current_scheme).is_equal(_manager.SCHEME.KEYBOARD)


func test_key_event_on_keyboard_scheme_emits_nothing() -> void:
	_manager._unhandled_input(InputEventKey.new())

	assert_array(_emitted_schemes).is_empty()


func test_key_event_switches_back_to_keyboard() -> void:
	_manager.current_scheme = _manager.SCHEME.XBOX

	_manager._unhandled_input(InputEventKey.new())

	assert_int(_manager.current_scheme).is_equal(_manager.SCHEME.KEYBOARD)


func test_key_event_emits_scheme_changed_with_keyboard() -> void:
	_manager.current_scheme = _manager.SCHEME.XBOX
	monitor_signals(_manager, false)

	_manager._unhandled_input(InputEventKey.new())

	await assert_signal(_manager).is_emitted(SCHEME_CHANGED_SIGNAL, [_manager.SCHEME.KEYBOARD])


func test_mouse_motion_switches_back_to_keyboard() -> void:
	_manager.current_scheme = _manager.SCHEME.PLAYSTATION

	_manager._unhandled_input(InputEventMouseMotion.new())

	assert_int(_manager.current_scheme).is_equal(_manager.SCHEME.KEYBOARD)


func test_mouse_button_switches_back_to_keyboard() -> void:
	_manager.current_scheme = _manager.SCHEME.PLAYSTATION

	_manager._unhandled_input(InputEventMouseButton.new())

	assert_int(_manager.current_scheme).is_equal(_manager.SCHEME.KEYBOARD)


func test_gamepad_event_without_connected_gamepad_falls_back_to_keyboard() -> void:
	_manager.current_scheme = _manager.SCHEME.XBOX

	_manager._unhandled_input(InputEventJoypadButton.new())

	assert_int(_manager.current_scheme).is_equal(_manager.SCHEME.KEYBOARD)


func test_unrelated_event_keeps_current_scheme() -> void:
	_manager.current_scheme = _manager.SCHEME.XBOX

	_manager._unhandled_input(InputEventAction.new())

	assert_int(_manager.current_scheme).is_equal(_manager.SCHEME.XBOX)


func test_unrelated_event_emits_nothing() -> void:
	_manager.current_scheme = _manager.SCHEME.XBOX

	_manager._unhandled_input(InputEventAction.new())

	assert_array(_emitted_schemes).is_empty()


func test_gamepad_motion_without_connected_gamepad_falls_back_to_keyboard() -> void:
	_manager.current_scheme = _manager.SCHEME.PLAYSTATION

	_manager._unhandled_input(InputEventJoypadMotion.new())

	assert_int(_manager.current_scheme).is_equal(_manager.SCHEME.KEYBOARD)


func test_last_gamepad_disconnected_switches_back_to_keyboard() -> void:
	_manager.current_scheme = _manager.SCHEME.XBOX
	monitor_signals(_manager, false)

	Input.joy_connection_changed.emit(UNUSED_DEVICE_ID, false)

	assert_int(_manager.current_scheme).is_equal(_manager.SCHEME.KEYBOARD)
	await assert_signal(_manager).is_emitted(SCHEME_CHANGED_SIGNAL, [_manager.SCHEME.KEYBOARD])


func test_gamepad_disconnected_on_keyboard_scheme_emits_nothing() -> void:
	Input.joy_connection_changed.emit(UNUSED_DEVICE_ID, false)

	assert_array(_emitted_schemes).is_empty()
