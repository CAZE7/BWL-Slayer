extends Node
class_name GameStateStore

## Der globale Spielzustand.
##
## Hält Fortschritt, Einstellungen und den aktuellen Bildschirm.
## Greift auf den EventBus zu, damit UI und Simulation entkoppelt bleiben.
##
## Der Klassenname `GameStateStore` weicht bewusst vom Autoload-Namen
## `GameState` ab: Godot verbietet es, dass eine `class_name` einen
## Autoload-Singleton verdeckt. Mit dem abweichenden Namen bleibt die
## Klasse instanziierbar – so koennen Tests mit einem isolierten
## Spielzustand arbeiten, ohne den laufenden zu veraendern.

var progress := PlayerProgress.new()
## Der Name des Spielers (CEO der Delizioso AG).
var player_name: String = "CFO Delizioso"
var settings := {
	"music_volume": 0.35,
	"sfx_volume": 0.6,
	"reduced_motion": false,
	"language": "de-DE",
	"autosave": true,
	"camera_speed": 1.0,
}
var current_screen: String = "hud"
var company := {
	"name": "Delizioso AG",
	"departments": [],
	"employees": [],
	"assets": [],
	"contracts": [],
	"milestones": [],
}
var advisor_history: Array = []
var current_slot_id: String = ""


func _ready() -> void:
	EventBus.reputation_changed.connect(func(value: float): progress.reputation = value)
	EventBus.settings_changed.connect(_on_settings_changed)


func _on_settings_changed(new_settings: Dictionary) -> void:
	for key in new_settings:
		settings[key] = new_settings[key]
	EventBus.settings_changed.emit(settings)


## Wechselt den Bildschirm.
func go_to(screen_id: String) -> void:
	current_screen = screen_id
	EventBus.screen_changed.emit(screen_id)


## Aktualisiert die Reputation (0..100).
func set_reputation(value: float) -> void:
	progress.reputation = clampf(value, 0.0, 100.0)
	EventBus.reputation_changed.emit(progress.reputation)


## Registriert einen abgeschlossenen Lernabschnitt.
func complete_stage(world_id: String, stage: int, points: int) -> Dictionary:
	var result := progress.complete_stage(world_id, stage, points)
	if bool(result.get("first_time", false)):
		EventBus.learning_progress_changed.emit(world_id, stage, true)
	return result


## Serialisierbarer Zustand.
func to_dict() -> Dictionary:
	return {
		"progress": progress.to_dict(),
		"settings": settings.duplicate(true),
		"company": company.duplicate(true),
		"advisor_history": advisor_history,
		"player_name": player_name,
	}


## Stellt den Zustand aus einem Save wieder her.
func from_dict(data: Dictionary) -> void:
	progress = PlayerProgress.from_dict(data.get("progress", {}))
	var s: Dictionary = data.get("settings", {})
	for key in settings:
		if s.has(key):
			settings[key] = s[key]
	company = data.get("company", company)
	advisor_history = data.get("advisor_history", [])
	player_name = String(data.get("player_name", player_name))


## Setzt den Spielzustand auf den Ausgangszustand zurueck.
##
## Wird fuer ein neues Spiel benoetigt. Die Einstellungen bleiben
## erhalten – sie gehoeren zur App, nicht zum Spielstand.
func reset() -> void:
	progress = PlayerProgress.new()
	company = {
		"name": "Delizioso AG",
		"departments": [],
		"employees": [],
		"assets": [],
		"contracts": [],
		"milestones": [],
	}
	advisor_history.clear()
	current_slot_id = ""
	current_screen = "hud"
