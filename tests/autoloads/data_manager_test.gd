class_name DataManagerTest
extends GdUnitTestSuite

## Tests du DataManager (persistance `user://`, écriture atomique, migrations de schéma).
##
## Les chemins `user://` sont des constantes du script : on ne peut pas les rediriger vers un
## dossier temporaire. Pour ne jamais écraser les vraies sauvegardes du joueur, chaque test
## met de côté les fichiers existants (`before_test`) sous un nom UNIQUE, puis les restaure
## (`after_test`). Le nom unique garantit qu'un run précédent interrompu (crash, kill) ne peut
## jamais voir sa sauvegarde écrasée : au pire un `*.bak_test_*` orphelin reste à récupérer.
## On instancie un DataManager neuf plutôt que l'autoload pour ne partager aucun état.

const DATA_MANAGER_SCRIPT := "res://autoloads/data_manager.gd"
const BACKUP_SUFFIX_PREFIX := ".bak_test_"
const TEMP_SUFFIX := ".tmp"

const KEY_SCHEMA_VERSION := "schema_version"
const KEY_LEGACY_COINS := "coins"
const KEY_SHARDS := "shards"
const KEY_NAME := "name"
const KEY_LEVEL := "level"
const KEY_OLD := "old_key"
const KEY_NEW := "new_key"
const LEGACY_VERSION := 0
const COINS_AMOUNT := 5
const PLAYER_NAME := "hero"
const LEVEL_NAME := "forest"
const UNPARSABLE_JSON := "{ ceci n'est pas du json"
const JSON_ARRAY_TEXT := "[1, 2, 3]"
const UNPARSABLE_CONFIG := "[section\nce n'est pas un cfg valide ===\n"
const SETTINGS_SECTION := "audio"
const SETTINGS_KEY := "volume"
const VOLUME_VALUE := 0.5
const BINDINGS_SECTION := "keys"
const BINDINGS_KEY := "jump"
const JUMP_KEYCODE := 32

var _manager: Node
var _backup_suffix: String


func before_test() -> void:
	# Le manager est créé avant tout : ses constantes de chemin servent à `_all_paths`.
	_manager = auto_free(load(DATA_MANAGER_SCRIPT).new())
	_backup_suffix = BACKUP_SUFFIX_PREFIX + str(Time.get_ticks_usec())
	for path: String in _all_paths():
		if not FileAccess.file_exists(path):
			continue
		assert_int(DirAccess.rename_absolute(path, path + _backup_suffix)).is_equal(OK)


func after_test() -> void:
	for path: String in _all_paths():
		DirAccess.remove_absolute(path)
		DirAccess.remove_absolute(path + TEMP_SUFFIX)
		if FileAccess.file_exists(path + _backup_suffix):
			assert_int(DirAccess.rename_absolute(path + _backup_suffix, path)).is_equal(OK)


func _all_paths() -> Array[String]:
	return [_manager.PATH_SETTINGS, _manager.PATH_BINDINGS, _manager.PATH_META, _manager.PATH_RUN]


func _default_save() -> Dictionary:
	return {KEY_SCHEMA_VERSION: _manager.META_SCHEMA_VERSION}


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _read_raw_json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


# ---------- meta ----------

func test_load_meta_without_file_returns_current_schema_only() -> void:
	assert_dict(_manager.load_meta()).is_equal(_default_save())


func test_save_meta_then_load_meta_returns_saved_data() -> void:
	_manager.save_meta({KEY_SHARDS: COINS_AMOUNT})

	var meta: Dictionary = _manager.load_meta()

	assert_int(int(meta[KEY_SHARDS])).is_equal(COINS_AMOUNT)


func test_save_meta_writes_current_schema_version_in_file() -> void:
	_manager.save_meta({})

	var raw_file: Dictionary = _read_raw_json(_manager.PATH_META)

	assert_int(int(raw_file[KEY_SCHEMA_VERSION])).is_equal(_manager.META_SCHEMA_VERSION)


func test_save_meta_keeps_unrelated_keys() -> void:
	_manager.save_meta({KEY_NAME: PLAYER_NAME})

	var raw_file: Dictionary = _read_raw_json(_manager.PATH_META)

	assert_str(raw_file[KEY_NAME]).is_equal(PLAYER_NAME)


func test_save_meta_replaces_previous_content() -> void:
	_manager.save_meta({KEY_OLD: 1})
	_manager.save_meta({KEY_NEW: 2})

	var meta: Dictionary = _manager.load_meta()

	assert_bool(meta.has(KEY_OLD)).is_false()
	assert_bool(meta.has(KEY_NEW)).is_true()


func test_save_meta_leaves_no_temporary_file() -> void:
	_manager.save_meta({KEY_SHARDS: COINS_AMOUNT})

	assert_bool(FileAccess.file_exists(_manager.PATH_META + TEMP_SUFFIX)).is_false()


func test_load_meta_with_corrupted_json_returns_default() -> void:
	_write_text(_manager.PATH_META, UNPARSABLE_JSON)

	assert_dict(_manager.load_meta()).is_equal(_default_save())


func test_load_meta_with_non_dictionary_json_returns_default() -> void:
	# Un JSON valide mais de mauvais type (tableau) ne doit pas être traité comme une sauvegarde.
	_write_text(_manager.PATH_META, JSON_ARRAY_TEXT)

	assert_dict(_manager.load_meta()).is_equal(_default_save())


func test_load_meta_with_empty_file_returns_default() -> void:
	_write_text(_manager.PATH_META, "")

	assert_dict(_manager.load_meta()).is_equal(_default_save())


func test_load_meta_legacy_file_renames_coins_to_shards() -> void:
	_write_text(_manager.PATH_META, JSON.stringify({KEY_LEGACY_COINS: COINS_AMOUNT}))

	var meta: Dictionary = _manager.load_meta()

	assert_int(int(meta[KEY_SHARDS])).is_equal(COINS_AMOUNT)
	assert_bool(meta.has(KEY_LEGACY_COINS)).is_false()


func test_load_meta_legacy_file_is_upgraded_to_current_version() -> void:
	_write_text(_manager.PATH_META, JSON.stringify({KEY_SCHEMA_VERSION: LEGACY_VERSION}))

	var meta: Dictionary = _manager.load_meta()

	assert_int(int(meta[KEY_SCHEMA_VERSION])).is_equal(_manager.META_SCHEMA_VERSION)


func test_load_meta_legacy_file_keeps_unrelated_keys() -> void:
	_write_text(_manager.PATH_META, JSON.stringify({KEY_LEGACY_COINS: COINS_AMOUNT, KEY_NAME: PLAYER_NAME}))

	var meta: Dictionary = _manager.load_meta()

	assert_str(meta[KEY_NAME]).is_equal(PLAYER_NAME)


func test_load_meta_current_version_is_not_migrated() -> void:
	# Une sauvegarde déjà à jour ne doit pas voir ses clés renommées.
	var current_save := {KEY_SCHEMA_VERSION: _manager.META_SCHEMA_VERSION, KEY_LEGACY_COINS: COINS_AMOUNT}
	_write_text(_manager.PATH_META, JSON.stringify(current_save))

	var meta: Dictionary = _manager.load_meta()

	assert_bool(meta.has(KEY_LEGACY_COINS)).is_true()
	assert_bool(meta.has(KEY_SHARDS)).is_false()


# ---------- run ----------

func test_load_run_without_file_returns_current_schema_only() -> void:
	var expected_default := {KEY_SCHEMA_VERSION: _manager.RUN_SCHEMA_VERSION}

	assert_dict(_manager.load_run()).is_equal(expected_default)


func test_save_run_then_load_run_returns_saved_data() -> void:
	_manager.save_run({KEY_LEVEL: LEVEL_NAME})

	var run_state: Dictionary = _manager.load_run()

	assert_str(run_state[KEY_LEVEL]).is_equal(LEVEL_NAME)


func test_save_run_writes_current_schema_version_in_file() -> void:
	_manager.save_run({})

	var raw_file: Dictionary = _read_raw_json(_manager.PATH_RUN)

	assert_int(int(raw_file[KEY_SCHEMA_VERSION])).is_equal(_manager.RUN_SCHEMA_VERSION)


func test_load_run_legacy_file_keeps_data_and_gets_current_version() -> void:
	_write_text(_manager.PATH_RUN, JSON.stringify({KEY_LEVEL: LEVEL_NAME}))

	var run_state: Dictionary = _manager.load_run()

	assert_str(run_state[KEY_LEVEL]).is_equal(LEVEL_NAME)
	assert_int(int(run_state[KEY_SCHEMA_VERSION])).is_equal(_manager.RUN_SCHEMA_VERSION)


func test_load_run_with_corrupted_json_returns_default() -> void:
	_write_text(_manager.PATH_RUN, UNPARSABLE_JSON)

	var expected_default := {KEY_SCHEMA_VERSION: _manager.RUN_SCHEMA_VERSION}
	assert_dict(_manager.load_run()).is_equal(expected_default)


func test_clear_run_removes_saved_run() -> void:
	_manager.save_run({KEY_LEVEL: LEVEL_NAME})

	_manager.clear_run()

	assert_bool(FileAccess.file_exists(_manager.PATH_RUN)).is_false()


func test_clear_run_without_saved_run_does_nothing() -> void:
	_manager.clear_run()

	assert_bool(FileAccess.file_exists(_manager.PATH_RUN)).is_false()


# ---------- settings / bindings ----------

func test_load_settings_without_file_returns_empty_config() -> void:
	var config: ConfigFile = _manager.load_settings()

	assert_array(config.get_sections()).is_empty()


func test_load_settings_with_corrupted_file_returns_empty_config() -> void:
	_write_text(_manager.PATH_SETTINGS, UNPARSABLE_CONFIG)

	var config: ConfigFile = _manager.load_settings()

	assert_array(config.get_sections()).is_empty()


func test_save_settings_then_load_settings_returns_saved_value() -> void:
	var config := ConfigFile.new()
	config.set_value(SETTINGS_SECTION, SETTINGS_KEY, VOLUME_VALUE)
	_manager.save_settings(config)

	var loaded: ConfigFile = _manager.load_settings()

	assert_float(loaded.get_value(SETTINGS_SECTION, SETTINGS_KEY)).is_equal(VOLUME_VALUE)


func test_save_settings_leaves_no_temporary_file() -> void:
	_manager.save_settings(ConfigFile.new())

	assert_bool(FileAccess.file_exists(_manager.PATH_SETTINGS + TEMP_SUFFIX)).is_false()


func test_save_bindings_then_load_bindings_returns_saved_value() -> void:
	var config := ConfigFile.new()
	config.set_value(BINDINGS_SECTION, BINDINGS_KEY, JUMP_KEYCODE)
	_manager.save_bindings(config)

	var loaded: ConfigFile = _manager.load_bindings()

	assert_int(loaded.get_value(BINDINGS_SECTION, BINDINGS_KEY)).is_equal(JUMP_KEYCODE)


func test_settings_and_bindings_are_stored_separately() -> void:
	var config := ConfigFile.new()
	config.set_value(SETTINGS_SECTION, SETTINGS_KEY, VOLUME_VALUE)
	_manager.save_settings(config)

	assert_array(_manager.load_bindings().get_sections()).is_empty()
