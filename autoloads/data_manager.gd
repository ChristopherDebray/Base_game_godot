extends Node

const PATH_SETTINGS := "user://settings.cfg"
const PATH_BINDINGS := "user://bindings.cfg"
const PATH_META     := "user://meta.json"
const PATH_RUN      := "user://run.json"

const META_SCHEMA_VERSION := 1
const RUN_SCHEMA_VERSION  := 1

# ---------- Public API ----------
## Charge les réglages depuis `PATH_SETTINGS`. Renvoie un `ConfigFile` vide si le fichier est absent.
func load_settings() -> ConfigFile:
	var cfg := ConfigFile.new()
	cfg.load(PATH_SETTINGS)
	return cfg

## Sauvegarde `cfg` dans `PATH_SETTINGS` par écriture atomique (fichier temporaire puis renommage).
func save_settings(cfg: ConfigFile) -> void:
	_save_cfg_atomic(cfg, PATH_SETTINGS)

## Charge les bindings depuis `PATH_BINDINGS`. Renvoie un `ConfigFile` vide si le fichier est absent.
func load_bindings() -> ConfigFile:
	var cfg := ConfigFile.new()
	cfg.load(PATH_BINDINGS)
	return cfg

## Sauvegarde `cfg` dans `PATH_BINDINGS` par écriture atomique.
func save_bindings(cfg: ConfigFile) -> void:
	_save_cfg_atomic(cfg, PATH_BINDINGS)

## Charge la méta-progression (`PATH_META`) en appliquant les migrations de schéma. Renvoie un
## dictionnaire à jour de version, minimal si le fichier est absent ou corrompu.
func load_meta() -> Dictionary:
	return _load_json_versioned(PATH_META, META_SCHEMA_VERSION, _migrate_meta)

## Sauvegarde `meta` (dont `schema_version` est forcé à la version courante, `meta` est donc
## modifié) dans `PATH_META` par écriture atomique.
func save_meta(meta: Dictionary) -> void:
	meta["schema_version"] = META_SCHEMA_VERSION
	_save_json_atomic(meta, PATH_META)

## Charge l'état de la partie en cours (`PATH_RUN`) avec migrations de schéma. Même comportement
## que `load_meta` pour un fichier absent ou corrompu.
func load_run() -> Dictionary:
	return _load_json_versioned(PATH_RUN, RUN_SCHEMA_VERSION, _migrate_run)

## Sauvegarde `run_state` (dont `schema_version` est forcé, `run_state` est donc modifié) dans
## `PATH_RUN` par écriture atomique.
func save_run(run_state: Dictionary) -> void:
	run_state["schema_version"] = RUN_SCHEMA_VERSION
	_save_json_atomic(run_state, PATH_RUN)

## Supprime la sauvegarde de la partie en cours si elle existe.
func clear_run() -> void:
	if FileAccess.file_exists(PATH_RUN):
		DirAccess.remove_absolute(PATH_RUN)

# ---------- Private helpers ----------
func _load_json_versioned(path: String, expected_version: int, migrator: Callable) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"schema_version": expected_version}
	var text := FileAccess.get_file_as_string(path)
	var data: Variant = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("Corrupted JSON at %s, recreating." % path)
		return {"schema_version": expected_version}
	var schema_version := int(data.get("schema_version", 0))
	while schema_version < expected_version:
		data = migrator.call(data, schema_version)
		schema_version += 1
	data["schema_version"] = expected_version
	return data

func _save_json_atomic(obj: Dictionary, path: String) -> void:
	var tmp := "%s.tmp" % path
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	file.store_string(JSON.stringify(obj))
	file.flush()
	file.close()
	DirAccess.remove_absolute(path) # ignore error
	DirAccess.rename_absolute(tmp, path)

func _save_cfg_atomic(cfg: ConfigFile, path: String) -> void:
	var tmp := "%s.tmp" % path
	cfg.save(tmp)
	DirAccess.remove_absolute(path)
	DirAccess.rename_absolute(tmp, path)

# ---------- Migrators ----------
func _migrate_meta(old: Dictionary, from_version: int) -> Dictionary:
	var migrated := old.duplicate(true)
	match from_version:
		0:
			# Example: rename "coins" -> "shards"
			if migrated.has("coins"):
				migrated["shards"] = migrated["coins"]
				migrated.erase("coins")
	return migrated

func _migrate_run(old: Dictionary, from_version: int) -> Dictionary:
	var migrated := old.duplicate(true)
	# Add future steps here
	return migrated
