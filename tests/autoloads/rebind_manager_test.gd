class_name RebindManagerTest
extends GdUnitTestSuite

## Tests du RebindManager (bindings par défaut, sauvegarde/chargement des touches).
##
## Le manager modifie l'`InputMap` global et écrit `user://controls.cfg` (chemin en dur) : on
## sauvegarde l'état de l'InputMap et le fichier réel avant chaque test, puis on les restaure.
## Le fichier est mis de côté sous un nom UNIQUE pour qu'un run interrompu ne puisse jamais
## écraser les vrais bindings du joueur.
## Non testé : `start_capture` / `_input` (retournent immédiatement, code désactivé).

const REBIND_MANAGER_SCRIPT := "res://autoloads/rebind_manager.gd"
const BACKUP_SUFFIX_PREFIX := ".bak_test_"
const ACTION_ACCEPT := &"ui_accept"
const ACTION_FOCUS_PREV := &"ui_focus_prev"
const ACTION_UP := &"up"
const ACTION_USE_SPELL := &"use_spell"
const CUSTOM_KEYCODE := KEY_F9
const UNPARSABLE_BINDING := "ceci n'est pas un InputEvent"
const NON_STRING_BINDING := 42
const UNREADABLE_CONFIG := "[section\nceci n'est pas un cfg valide ===\n"

var _manager: Node
var _backup_suffix: String
var _can_touch_config: bool = false
var _input_map_snapshot: Dictionary = {}


func before_test() -> void:
	_manager = auto_free(load(REBIND_MANAGER_SCRIPT).new())
	_snapshot_input_map()
	_backup_suffix = BACKUP_SUFFIX_PREFIX + str(Time.get_ticks_usec())
	_can_touch_config = true
	if FileAccess.file_exists(_manager.CONFIG_PATH):
		# Si la mise de côté échoue, le vrai fichier reste en place : `after_test` ne doit alors
		# ni le supprimer ni le restaurer.
		_can_touch_config = DirAccess.rename_absolute(_manager.CONFIG_PATH, _manager.CONFIG_PATH + _backup_suffix) == OK
		assert_bool(_can_touch_config).is_true()


func after_test() -> void:
	_restore_input_map()
	if not _can_touch_config:
		return
	DirAccess.remove_absolute(_manager.CONFIG_PATH)
	if FileAccess.file_exists(_manager.CONFIG_PATH + _backup_suffix):
		assert_int(DirAccess.rename_absolute(_manager.CONFIG_PATH + _backup_suffix, _manager.CONFIG_PATH)).is_equal(OK)


func _snapshot_input_map() -> void:
	_input_map_snapshot.clear()
	for action: StringName in InputMap.get_actions():
		_input_map_snapshot[action] = InputMap.action_get_events(action)


func _restore_input_map() -> void:
	for action: StringName in InputMap.get_actions():
		if not _input_map_snapshot.has(action):
			InputMap.erase_action(action)
			continue
		for existing_event: InputEvent in InputMap.action_get_events(action):
			InputMap.action_erase_event(action, existing_event)
		for saved_event: InputEvent in _input_map_snapshot[action]:
			InputMap.action_add_event(action, saved_event)


func _has_key_event(action: StringName, keycode: Key) -> bool:
	return InputMap.action_get_events(action).any(
		func(event: InputEvent) -> bool: return event is InputEventKey and event.keycode == keycode)


func _save_config_for_accept(serialized_events: Array) -> void:
	var config := ConfigFile.new()
	config.set_value(_manager.SECTION, ACTION_ACCEPT, serialized_events)
	config.save(_manager.CONFIG_PATH)


func _custom_key_event() -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = CUSTOM_KEYCODE
	return event


# ---------- reset_to_defaults ----------

func test_reset_to_defaults_binds_special_keys_as_keyboard_events() -> void:
	_manager.reset_to_defaults(false)

	assert_bool(_has_key_event(ACTION_ACCEPT, KEY_ENTER)).is_true()


func test_reset_to_defaults_keeps_shift_modifier_on_key_binding() -> void:
	_manager.reset_to_defaults(false)

	var shift_events := InputMap.action_get_events(ACTION_FOCUS_PREV).filter(
		func(event: InputEvent) -> bool: return event is InputEventKey and event.shift_pressed)
	assert_array(shift_events).has_size(1)


func test_reset_to_defaults_binds_mouse_button() -> void:
	_manager.reset_to_defaults(false)

	var mouse_events := InputMap.action_get_events(ACTION_USE_SPELL).filter(
		func(event: InputEvent) -> bool: return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT)
	assert_array(mouse_events).has_size(1)


func test_reset_to_defaults_binds_joypad_axis_with_direction() -> void:
	_manager.reset_to_defaults(false)

	var axis_events := InputMap.action_get_events(ACTION_UP).filter(
		func(event: InputEvent) -> bool: return event is InputEventJoypadMotion and event.axis == JOY_AXIS_LEFT_Y and event.axis_value < 0.0)
	assert_array(axis_events).has_size(1)


func test_reset_to_defaults_binds_joypad_button() -> void:
	_manager.reset_to_defaults(false)

	var button_events := InputMap.action_get_events(ACTION_ACCEPT).filter(
		func(event: InputEvent) -> bool: return event is InputEventJoypadButton and event.button_index == JOY_BUTTON_A)
	assert_array(button_events).has_size(1)


func test_reset_to_defaults_replaces_custom_binding() -> void:
	InputMap.action_add_event(ACTION_ACCEPT, _custom_key_event())

	_manager.reset_to_defaults(false)

	assert_bool(_has_key_event(ACTION_ACCEPT, CUSTOM_KEYCODE)).is_false()


func test_reset_to_defaults_without_save_does_not_write_file() -> void:
	_manager.reset_to_defaults(false)

	assert_bool(FileAccess.file_exists(_manager.CONFIG_PATH)).is_false()


func test_reset_to_defaults_with_save_writes_file() -> void:
	_manager.reset_to_defaults(true)

	assert_bool(FileAccess.file_exists(_manager.CONFIG_PATH)).is_true()


# ---------- save / load ----------

func test_load_bindings_restores_saved_custom_binding() -> void:
	_manager.reset_to_defaults(false)
	InputMap.action_add_event(ACTION_ACCEPT, _custom_key_event())
	_manager.save_bindings()
	_manager.reset_to_defaults(false)

	_manager.load_bindings()

	assert_bool(_has_key_event(ACTION_ACCEPT, CUSTOM_KEYCODE)).is_true()


func test_load_bindings_without_file_keeps_current_bindings() -> void:
	_manager.reset_to_defaults(false)
	InputMap.action_add_event(ACTION_ACCEPT, _custom_key_event())

	_manager.load_bindings()

	assert_bool(_has_key_event(ACTION_ACCEPT, CUSTOM_KEYCODE)).is_true()


func test_load_bindings_ignores_unparsable_string_entry() -> void:
	_save_config_for_accept([var_to_str(_custom_key_event()), UNPARSABLE_BINDING])

	_manager.load_bindings()

	assert_array(InputMap.action_get_events(ACTION_ACCEPT)).has_size(1)
	assert_bool(_has_key_event(ACTION_ACCEPT, CUSTOM_KEYCODE)).is_true()


func test_load_bindings_ignores_non_string_entry() -> void:
	_save_config_for_accept([var_to_str(_custom_key_event()), NON_STRING_BINDING])

	_manager.load_bindings()

	assert_array(InputMap.action_get_events(ACTION_ACCEPT)).has_size(1)
	assert_bool(_has_key_event(ACTION_ACCEPT, CUSTOM_KEYCODE)).is_true()


func test_load_bindings_restores_several_events_of_one_action() -> void:
	_manager.reset_to_defaults(false)
	var expected_event_count := InputMap.action_get_events(ACTION_ACCEPT).size()
	_manager.save_bindings()
	_manager.reset_to_defaults(false)

	_manager.load_bindings()

	assert_array(InputMap.action_get_events(ACTION_ACCEPT)).has_size(expected_event_count)


func test_load_bindings_with_unreadable_file_keeps_current_bindings() -> void:
	_manager.reset_to_defaults(false)
	InputMap.action_add_event(ACTION_ACCEPT, _custom_key_event())
	var file := FileAccess.open(_manager.CONFIG_PATH, FileAccess.WRITE)
	file.store_string(UNREADABLE_CONFIG)
	file.close()

	_manager.load_bindings()

	assert_bool(_has_key_event(ACTION_ACCEPT, CUSTOM_KEYCODE)).is_true()


func test_load_bindings_applies_defaults_to_action_left_without_events() -> void:
	var config := ConfigFile.new()
	config.set_value(_manager.SECTION, ACTION_ACCEPT, [])
	config.save(_manager.CONFIG_PATH)

	_manager.load_bindings()

	assert_bool(_has_key_event(ACTION_ACCEPT, KEY_ENTER)).is_true()
