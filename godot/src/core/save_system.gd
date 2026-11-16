class_name SaveSystem
extends RefCounted

## Spielstand-Logik: Versionierung, Migration, Sanitisierung.
##
## Reines Datenmodell ohne Dateizugriff – dadurch direkt testbar.
## Der Dateizugriff liegt in `SaveStore`, der Autoload-Zugriff in `SaveService`.
##
## Diese Klasse ist bewusst KEIN Autoload: der Autoload heißt `SaveService`,
## sonst kollidiert der Klassenname mit dem Singleton-Namen.

const CURRENT_VERSION := 3
const SAVE_DIR := "user://saves"


## Einen neuen Standard-Spielstand erzeugen.
static func create_default_save(slot_id: String, player_name: String = "CFO Delizioso") -> Dictionary:
	var now := Time.get_unix_time_from_system()
	return {
		"version": CURRENT_VERSION,
		"id": slot_id,
		"player_name": player_name,
		"created_at": now,
		"updated_at": now,
		"career_started_at": now,
		"day": 0,
		"year": 1,
		"economy": {
			"cash": 50000.0,
			"equity": 50000.0,
			"debt": 0.0,
			"debt_rate": 0.06,
			"revenue_total": 0.0,
			"costs_total": 0.0,
			"revenue_current_year": 0.0,
			"costs_current_year": 0.0,
			"fixed_costs_year": 0.0,
			"depreciation_year": 0.0,
			"imputed_interest_year": 0.0,
			"interest_paid_year": 0.0,
			"repayment_year": 0.0,
			"receivables": 0.0,
			"inventory_value": 0.0,
			"dividends_paid": 0.0,
			"dividend_current_year": 0.0,
			"reputation": 12.0,
		},
		"progress": {
			"xp": 0,
			"reputation": 12.0,
			"worlds": {},
			"solved_tasks": {},
			"stats": {},
		},
		"simulation": {},
		"company": {
			"name": "Delizioso AG",
			"departments": [],
			"employees": [],
			"assets": [],
			"contracts": [],
			"milestones": [],
		},
		"settings": {
			"music_volume": 0.35,
			"sfx_volume": 0.6,
			"reduced_motion": false,
			"language": "de-DE",
			"autosave": true,
			"camera_speed": 1.0,
		},
		"advisor_history": [],
	}


## Migriert einen Spielstand auf die aktuelle Version.
static func migrate_save(raw: Variant, from_version: int) -> Dictionary:
	var base := create_default_save("recovered")
	if typeof(raw) != TYPE_DICTIONARY:
		return base

	var data: Dictionary = raw
	if from_version >= CURRENT_VERSION:
		var merged := base.duplicate(true)
		for key in data:
			merged[key] = data[key]
		merged["version"] = CURRENT_VERSION
		return sanitize_save(merged)

	# v1 → v2: Karrierefelder ergänzen
	if from_version < 2:
		data["progress"] = data.get("progress", {})
		data["progress"]["xp"] = int(data.get("xp", data["progress"].get("xp", 0)))
		data["progress"]["reputation"] = float(data.get("reputation", data["progress"].get("reputation", 12.0)))
		if data.has("economy") and data["economy"] is Dictionary:
			data["economy"]["reputation"] = float(data["economy"].get("reputation", 12.0))
		data["company"] = data.get("company", base["company"])
		# v1 legte das Kapital direkt auf der obersten Ebene ab.
		# Ab v2 liegt es im Bereich "economy".
		if data.has("cash") and not (data.has("economy") and data["economy"] is Dictionary and (data["economy"] as Dictionary).has("cash")):
			var economy: Dictionary = data.get("economy", {}) as Dictionary
			economy["cash"] = float(data.get("cash", 0.0))
			data["economy"] = economy
		# v1 nutzte camelCase für den Spielernamen.
		if data.has("playerName") and not data.has("player_name"):
			data["player_name"] = String(data.get("playerName", "CFO Delizioso"))

	# v2 → v3: Statistiken, Einstellungen, Unternehmen
	if from_version < 3:
		data["settings"] = data.get("settings", base["settings"])
		data["company"] = data.get("company", base["company"])
		data["advisor_history"] = data.get("advisor_history", [])

	data["version"] = CURRENT_VERSION
	# Pflichtfelder sicherstellen
	for key in base:
		if not data.has(key):
			data[key] = base[key]
	return sanitize_save(data)


## Repariert ungültige Werte. Ergebnis ist immer spielbar.
static func sanitize_save(save: Dictionary) -> Dictionary:
	var base := create_default_save(String(save.get("id", "recovered")), String(save.get("player_name", "CFO Delizioso")))
	var out := base.duplicate(true)
	for key in save:
		out[key] = save[key]

	out["version"] = CURRENT_VERSION
	out["xp"] = maxi(0, int(out.get("xp", 0)))

	var eco: Dictionary = out.get("economy", {})
	var eco_base: Dictionary = base["economy"]
	for key in eco_base:
		if not eco.has(key):
			eco[key] = eco_base[key]
		else:
			eco[key] = _safe_float(eco[key], eco_base[key])
	eco["cash"] = maxf(0.0, eco["cash"])
	eco["debt"] = maxf(0.0, eco["debt"])
	eco["equity"] = eco["equity"]
	out["economy"] = eco

	var prog: Dictionary = out.get("progress", {})
	prog["xp"] = maxi(0, int(prog.get("xp", 0)))
	prog["reputation"] = clampf(_safe_float(prog.get("reputation", 12.0), 12.0), 0.0, 100.0)
	if typeof(prog.get("worlds", {})) != TYPE_DICTIONARY:
		prog["worlds"] = {}
	if typeof(prog.get("solved_tasks", {})) != TYPE_DICTIONARY:
		prog["solved_tasks"] = {}
	out["progress"] = prog

	# Reputation auch auf der obersten Ebene begrenzen. In aelteren
	# Ständen stand sie dort, in neueren unter "progress".
	out["reputation"] = clampf(_safe_float(out.get("reputation", 12.0), 12.0), 0.0, 100.0)

	# Weltenfortschritt: Stufen sind immer boolesch, Punkte immer Zahlen.
	out["worlds"] = _sanitize_worlds(out.get("worlds", {}))

	# Statistiken und Aufgabenlisten sicherstellen
	if typeof(out.get("statistics", {})) != TYPE_DICTIONARY:
		out["statistics"] = base["statistics"]
	if typeof(out.get("solved_tasks", {})) != TYPE_DICTIONARY:
		out["solved_tasks"] = {}

	if typeof(out.get("company", {})) != TYPE_DICTIONARY:
		out["company"] = base["company"]
	if typeof(out.get("settings", {})) != TYPE_DICTIONARY:
		out["settings"] = base["settings"]

	return out


## Repariert den Weltenfortschritt: Stufen boolesch, Punkte Zahlen.
static func _sanitize_worlds(raw: Variant) -> Dictionary:
	var out: Dictionary = {}
	if typeof(raw) != TYPE_DICTIONARY:
		return out
	var source: Dictionary = raw
	for world_id in source:
		var entry: Variant = source[world_id]
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var world_entry: Dictionary = entry
		var stages: Array = []
		var raw_stages: Variant = world_entry.get("stages", [])
		if typeof(raw_stages) == TYPE_ARRAY:
			for stage in (raw_stages as Array):
				stages.append(bool(stage))
		var points: Array = []
		var raw_points: Variant = world_entry.get("points", [])
		if typeof(raw_points) == TYPE_ARRAY:
			for point in (raw_points as Array):
				points.append(maxi(0, int(point)))
		out[String(world_id)] = {"stages": stages, "points": points}
	return out


## Wandelt einen Variant in eine Zahl um – ungültige Werte ergeben den Standard.
static func _safe_float(value: Variant, fallback: float) -> float:
	if typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT:
		return float(value)
	return fallback
