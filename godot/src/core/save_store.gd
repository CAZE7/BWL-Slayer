class_name SaveStore
extends RefCounted

## Dateibasierte Persistenz.
##
## Anforderungen:
##  - atomare Schreibvorgänge (Temp-Datei + rename)
##  - automatische, rotierende Backups
##  - Migration beim Laden
##  - mehrere lokale Spielstände
##
## Die Pfade liegen unter `user://` – plattformunabhängig (Windows:
## %APPDATA%\Godot\app_userdata\BWL Slayer).

const SAVE_FILE := "slot.json"
const BACKUP_DIR := "backups"
const BACKUP_COUNT := 5

var root: String = "user://saves"


func _init(p_root: String = "user://saves") -> void:
	root = p_root


## Ordnerstruktur anlegen.
##
## Wichtig: Die Verzeichnisse werden mit der statischen Variante
## make_dir_recursive_absolute() angelegt. Die Instanzmethode
## make_dir_recursive() blockiert im Headless-Betrieb.
func ensure_root() -> bool:
	var absolute := ProjectSettings.globalize_path(root)
	if not DirAccess.dir_exists_absolute(absolute):
		DirAccess.make_dir_recursive_absolute(absolute)
	return DirAccess.dir_exists_absolute(absolute)


func slot_dir(slot_id: String) -> String:
	return root.path_join(slot_id)


func save_path(slot_id: String) -> String:
	return slot_dir(slot_id).path_join(SAVE_FILE)


## Schreibt einen Spielstand atomar (mit Backup der Vorgängerversion).
func write_slot(save: Dictionary) -> bool:
	if not ensure_root():
		return false
	var slot_id := String(save.get("id", ""))
	if slot_id.is_empty():
		return false

	var dir := slot_dir(slot_id)
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)

	var target := save_path(slot_id)

	# Backup der bestehenden Version
	if FileAccess.file_exists(target):
		var backup_dir := dir.path_join(BACKUP_DIR)
		if not DirAccess.dir_exists_absolute(backup_dir):
			DirAccess.make_dir_recursive_absolute(backup_dir)
		var stamp := Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
		var backup := backup_dir.path_join("%s-%s.json" % [slot_id, stamp])
		var copy := FileAccess.open(backup, FileAccess.WRITE)
		if copy != null:
			copy.store_string(FileAccess.get_file_as_string(target))
			copy.close()
			_prune_backups(backup_dir)

	# Atomar schreiben: erst Temp-Datei, dann umbenennen
	var payload := save.duplicate(true)
	payload["updated_at"] = Time.get_unix_time_from_system()
	var temp := target + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload, "  "))
	file.close()

	var err := DirAccess.rename_absolute(temp, target)
	if err != OK:
		# Fallback: direkt schreiben, falls rename scheitert
		var fallback := FileAccess.open(target, FileAccess.WRITE)
		if fallback == null:
			return false
		fallback.store_string(JSON.stringify(payload, "  "))
		fallback.close()
		DirAccess.remove_absolute(temp)
	return true


## Lädt einen Spielstand und migriert ihn.
func load_slot(slot_id: String) -> Variant:
	var target := save_path(slot_id)
	if not FileAccess.file_exists(target):
		return null
	var text := FileAccess.get_file_as_string(target)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Spielstand %s ist beschädigt." % slot_id)
		return null
	var data: Dictionary = parsed
	var version := int(data.get("version", 1))
	return SaveSystem.migrate_save(data, version)


## Löscht einen Spielstand inkl. Backups.
func delete_slot(slot_id: String) -> bool:
	# Ein Verzeichnis laesst sich nur leer entfernen. Die Backups
	# liegen darin, deshalb muss zuerst der Inhalt rekursiv entfernt
	# werden.
	var target := slot_dir(slot_id)
	if not DirAccess.dir_exists_absolute(target):
		return true
	if not _remove_recursive(target):
		return false
	return not DirAccess.dir_exists_absolute(target)


## Entfernt ein Verzeichnis mit seinem gesamten Inhalt.
func _remove_recursive(path: String) -> bool:
	if not DirAccess.dir_exists_absolute(path):
		return DirAccess.remove_absolute(path) == OK
	var dir := DirAccess.open(path)
	if dir == null:
		return false
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name != "." and name != "..":
			var child := path.path_join(name)
			if dir.current_is_dir():
				if not _remove_recursive(child):
					dir.list_dir_end()
					return false
			else:
				DirAccess.remove_absolute(child)
		name = dir.get_next()
	dir.list_dir_end()
	return true


## Liste aller vorhandenen Spielstände (neueste zuerst).
func list_slots() -> Array:
	var out: Array = []
	if not DirAccess.dir_exists_absolute(root):
		return out
	var dir := DirAccess.open(root)
	if dir == null:
		return out
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if dir.current_is_dir() and not name.begins_with("."):
			var save: Variant = load_slot(name)
			if typeof(save) == TYPE_DICTIONARY:
				var eco: Dictionary = save.get("economy", {})
				var prog: Dictionary = save.get("progress", {})
				out.append({
					"id": name,
					"player_name": String(save.get("player_name", name)),
					"updated_at": float(save.get("updated_at", 0.0)),
					"created_at": float(save.get("created_at", 0.0)),
					"cash": float(eco.get("cash", 0.0)),
					"xp": int(prog.get("xp", 0)),
					"reputation": float(prog.get("reputation", 0.0)),
				})
		name = dir.get_next()
	dir.list_dir_end()
	out.sort_custom(func(a, b): return float(a["updated_at"]) > float(b["updated_at"]))
	return out


## Letzte Backups eines Spielstands (neueste zuerst).
func list_backups(slot_id: String) -> Array:
	var out: Array = []
	var dir_path := slot_dir(slot_id).path_join(BACKUP_DIR)
	if not DirAccess.dir_exists_absolute(dir_path):
		return out
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not dir.current_is_dir() and name.ends_with(".json"):
			out.append(name)
		name = dir.get_next()
	dir.list_dir_end()
	out.sort()
	out.reverse()
	return out


## Stellt einen Spielstand aus einem Backup wieder her.
func restore_backup(slot_id: String, file_name: String) -> Variant:
	# Pfad-Traversal ausschließen
	if file_name.contains("/") or file_name.contains("\\") or file_name.contains(".."):
		return null
	var source := slot_dir(slot_id).path_join(BACKUP_DIR).path_join(file_name)
	if not FileAccess.file_exists(source):
		return null
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(source))
	if typeof(parsed) != TYPE_DICTIONARY:
		return null
	var data: Dictionary = parsed
	var version := int(data.get("version", 1))
	var save := SaveSystem.migrate_save(data, version)
	write_slot(save)
	return save


## Alte Backups entfernen, die letzten BACKUP_COUNT behalten.
func _prune_backups(backup_dir: String) -> void:
	var files := _list_json_files(backup_dir)
	if files.size() <= BACKUP_COUNT:
		return
	var excess := files.size() - BACKUP_COUNT
	for i in range(excess):
		DirAccess.remove_absolute(backup_dir.path_join(files[i]))


func _list_json_files(dir_path: String) -> Array:
	var out: Array = []
	if not DirAccess.dir_exists_absolute(dir_path):
		return out
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not dir.current_is_dir() and name.ends_with(".json"):
			out.append(name)
		name = dir.get_next()
	dir.list_dir_end()
	out.sort()
	return out
