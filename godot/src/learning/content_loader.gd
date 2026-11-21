class_name ContentLoader
extends RefCounted

## Lädt den Lerncontent aus dem JSON-Sidecar.
##
## Das Sidecar wird von `tools/export_content.cjs` aus den bestehenden
## JS-Dateien (src/data1.js … data3.js) erzeugt. Der Content bleibt damit
## an einer Stelle gepflegt; Godot liest nur eine normalisierte Datei.
##
## Fehlt das Sidecar (z. B. direkt geklont), nutzen die Welten-Metadaten
## einen eingebauten Fallback, damit das Spiel nie leer startet.

const CONTENT_PATH := "res://content/worlds.json"

static var _cache: Array[WorldContent] = []
static var _loaded: bool = false


## Alle Welten (zwischengespeichert).
static func get_worlds() -> Array[WorldContent]:
	if not _loaded:
		_load()
	return _cache


## Eine Welt nach ID.
static func get_world(world_id: String) -> WorldContent:
	for w in get_worlds():
		if w.id == world_id:
			return w
	return null


## Die Welten einer Prüfseite (INV / FIN).
static func get_worlds_by_side(side: String) -> Array[WorldContent]:
	var out: Array[WorldContent] = []
	for w in get_worlds():
		if w.side == side:
			out.append(w)
	return out


static func _load() -> void:
	_loaded = true
	_cache.clear()
	if not FileAccess.file_exists(CONTENT_PATH):
		push_warning("Content-Sidecar fehlt: %s – nutze Fallback-Welten." % CONTENT_PATH)
		_cache = _fallback_worlds()
		return

	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONTENT_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Content-Sidecar nicht lesbar – nutze Fallback-Welten.")
		_cache = _fallback_worlds()
		return

	for raw in (parsed as Dictionary).get("worlds", []):
		var world := _to_world_content(raw)
		if world != null:
			_cache.append(world)
	_cache.sort_custom(func(a: WorldContent, b: WorldContent) -> bool: return a.no < b.no)

	if _cache.is_empty():
		_cache = _fallback_worlds()


static func _to_world_content(raw: Dictionary) -> WorldContent:
	if raw == null or not raw.has("id"):
		return null
	var w := WorldContent.new()
	w.id = String(raw.get("id", ""))
	w.no = int(raw.get("no", 0))
	w.side = String(raw.get("side", "INV"))
	w.title = String(raw.get("title", ""))
	w.tag = String(raw.get("tag", ""))
	w.icon = String(raw.get("icon", ""))
	w.color = String(raw.get("color", "#d9a441"))
	w.sources = String(raw.get("sources", ""))
	w.briefing = raw.get("briefing", [])

	var concept: Dictionary = raw.get("concept", {})
	w.concept_intro = String(concept.get("intro", ""))
	for item_raw in concept.get("items", []):
		w.concept_items.append(ConceptItem.from_dict(item_raw))

	var lab: Dictionary = raw.get("lab", {})
	w.lab_intro = String(lab.get("intro", ""))
	for task_raw in lab.get("tasks", []):
		w.lab_tasks.append(LabTask.from_dict(task_raw, w.id))

	w.trainer_params = raw.get("trainer", {})
	w.has_trainer = typeof(w.trainer_params) == TYPE_DICTIONARY and not w.trainer_params.is_empty()
	return w


## Fallback: Welt-Metadaten eingebaut, damit das Spiel nie ohne Inhalte startet.
static func _fallback_worlds() -> Array[WorldContent]:
	var meta := [
		["W1", 1, "INV", "Grundlagen & Einführung", "Cashflow-Tinder & Bilanz-Architekt", "🧭"],
		["W2", 2, "INV", "Statische Investitionsrechnung", "Fuhrpark- & Abfüllanlagen-Duell", "🚚"],
		["W3", 3, "INV", "Dynamische Investitionsrechnung", "Zeitwert-Zeitmaschine & IRR-Laser", "⏳"],
		["W4", 4, "INV", "Festverzinsliche Wertpapiere", "Bond-Desk & Arbitrage-Labor", "📈"],
		["W5", 5, "FIN", "Finanzplanung & Finanzkontrolle", "Working-Capital-Defense & Du-Pont-Reaktor", "💧"],
		["W6", 6, "FIN", "Innenfinanzierung", "Lohmann-Ruchti-Fabrik & Stille-Reserven-Tresor", "♻️"],
		["W7", 7, "FIN", "Beteiligungsfinanzierung", "Roadshow-Tycoon & Bezugsrechts-Rechner", "🤝"],
		["W8", 8, "FIN", "Fremdfinanzierung, Leasing & Optimierung", "Skonto-Schocker & Leverage-Boss", "⚖️"],
		["W9", 9, "INV", "Aktien & Aktienbewertung", "Bewertungs-Terminal & Gordon-Reaktor", "📊"],
	]
	var out: Array[WorldContent] = []
	for entry in meta:
		var w := WorldContent.new()
		w.id = String(entry[0])
		w.no = int(entry[1])
		w.side = String(entry[2])
		w.title = String(entry[3])
		w.tag = String(entry[4])
		w.icon = String(entry[5])
		w.sources = "Vorlesungsfolien Investition & Finanzierung 1"
		w.briefing = [{"h": "Inhalt", "p": "Dieser Bereich wird geladen, sobald das Content-Sidecar vorliegt."}]
		out.append(w)
	return out
