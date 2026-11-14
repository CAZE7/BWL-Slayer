extends Node

## Autoload für den Spielstand-Zugriff.
##
## Wichtig: dieses Skript darf KEIN `class_name` tragen. Ein `class_name`
## mit demselben Namen wie ein Autoload-Singleton führt beim Import zu
##   "Class \"SaveService\" hides an autoload singleton"
## und verhindert den Start des Projekts.
##
## Die reine Spiellogik (Versionierung, Migration, Sanitisierung) liegt
## in der Klasse `SaveSystem` (`res://src/core/save_system.gd`), die
## statisch nutzbar ist. Hier geht es nur um den Zugriff auf den
## dateibasierten Speicher über `SaveStore`.

var store: SaveStore = null

## Aktuell geladener Spielstand (Dictionary) oder {}.
var current_save: Dictionary = {}


func _ready() -> void:
	store = SaveStore.new()


## Spielstand speichern. Gibt true zurück, wenn erfolgreich geschrieben.
func write_save(slot_id: String, data: Dictionary) -> bool:
	if store == null:
		store = SaveStore.new()
	var payload: Dictionary = data.duplicate(true)
	payload["id"] = slot_id
	var ok: bool = store.write_slot(payload)
	if ok:
		current_save = payload
	return ok


## Spielstand laden. Gibt {} zurück, wenn kein Spielstand existiert
## oder die Datei beschädigt ist.
func read_save(slot_id: String) -> Dictionary:
	if store == null:
		store = SaveStore.new()
	var loaded: Variant = store.load_slot(slot_id)
	if typeof(loaded) != TYPE_DICTIONARY:
		return {}
	current_save = loaded
	return loaded


## Alle vorhandenen Spielstände auflisten.
func list_slots() -> Array:
	if store == null:
		store = SaveStore.new()
	return store.list_slots()


## Spielstand löschen.
func delete_save(slot_id: String) -> bool:
	if store == null:
		store = SaveStore.new()
	var ok: bool = store.delete_slot(slot_id)
	if ok:
		current_save = {}
	return ok


## Backups eines Spielstands auflisten.
func list_backups(slot_id: String) -> Array:
	if store == null:
		store = SaveStore.new()
	return store.list_backups(slot_id)


## Ein Backup wiederherstellen.
func restore_backup(slot_id: String, file_name: String) -> Dictionary:
	if store == null:
		store = SaveStore.new()
	var restored: Variant = store.restore_backup(slot_id, file_name)
	if typeof(restored) != TYPE_DICTIONARY:
		return {}
	current_save = restored
	return restored


## Standard-Spielstand anlegen und speichern.
func create_and_store(slot_id: String, player_name: String = "CFO Delizioso") -> Dictionary:
	var data: Dictionary = SaveSystem.create_default_save(slot_id, player_name)
	write_save(slot_id, data)
	return data
