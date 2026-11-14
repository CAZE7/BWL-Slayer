class_name PlayerProgress
extends RefCounted

## Fortschritt des Spielers: Welten, Stufen, XP, Reputation.
##
## Zentrale Invariante: Eine Stufe kann nur EINMAL XP belohnen.
## `complete_stage` liefert deshalb bei einer Wiederholung keine
## Erfahrungspunkte. Die Punktstaende werden dagegen per Maximum
## gefuehrt: ein besserer Wert ersetzt den schlechteren, ein
## schlechterer veraendert nichts.

var xp: int = 0
var reputation: float = 12.0
## world_id -> {stages: [bool x3], points: [int x3]}
var worlds: Dictionary = {}
## absolvierte Einzelaufgaben (Anti-Exploit gegen Belohnungsmanipulation)
var solved_tasks: Dictionary = {}
## Statistik
var stats := {
	"questions_solved": 0,
	"correct_answers": 0,
	"missions_completed": 0,
	"bosses_beaten": 0,
	"streak": 0,
	"best_streak": 0,
	"crises_survived": 0,
	"exam_best": 0,
	"exam_attempts": 0,
}


## Stufe 0-basiert.
func is_stage_done(world_id: String, stage: int) -> bool:
	var entry = worlds.get(world_id)
	if entry == null:
		return false
	var stages: Array = entry.get("stages", [])
	if stage < 0 or stage >= stages.size():
		return false
	return bool(stages[stage])


## Punktestand einer Stufe.
func get_stage_points(world_id: String, stage: int) -> int:
	var entry = worlds.get(world_id)
	if entry == null:
		return 0
	var points: Array = entry.get("points", [])
	if stage < 0 or stage >= points.size():
		return 0
	return int(points[stage])


## Eine Welt ist freigeschaltet, wenn die vorherige Welt Stufe 0 abgeschlossen hat.
func is_world_unlocked(world_id: String) -> bool:
	var worlds_list := LearningContent.get_worlds()
	for i in range(worlds_list.size()):
		var w: WorldContent = worlds_list[i]
		if w.id == world_id:
			if i == 0:
				return true
			return is_stage_done(worlds_list[i - 1].id, 0)
	return true


## Abschließt eine Stufe und gewährt die Belohnung – idempotent.
##
## Rückgabe: {xp, points, first_time, level_up}
##
##  - xp:     neu vergebene Erfahrungspunkte (nur beim ersten Mal)
##  - points: der Punktestand der Stufe nach der Aktualisierung.
##            Punkte werden pro Maximum gefuehrt: ein besserer Wert
##            ersetzt den schlechteren, ein schlechterer veraendert
##            nichts.
##  - first_time: true, wenn die Stufe zuvor noch nicht abgeschlossen war
func complete_stage(world_id: String, stage: int, points: int) -> Dictionary:
	_ensure_world(world_id)
	var entry: Dictionary = worlds[world_id]
	var stages: Array = entry["stages"]
	var point_list: Array = entry["points"]

	var first_time := not bool(stages[stage])
	var awarded_xp := 0

	if first_time:
		stages[stage] = true
		awarded_xp = _xp_for(points)
		xp += awarded_xp
		stats["missions_completed"] = int(stats["missions_completed"]) + 1
		# Streak pflegen
		stats["streak"] = int(stats["streak"]) + 1
		stats["best_streak"] = maxi(int(stats["best_streak"]), int(stats["streak"]))

	# Punkte per Maximum fuehren: ein besserer Wert zaehlt, ein
	# schlechterer veraendert den Punktestand nicht.
	point_list[stage] = maxi(int(point_list[stage]), points)

	return {
		"xp": awarded_xp,
		"points": int(point_list[stage]),
		"first_time": first_time,
		"level_up": level_up_count(awarded_xp),
	}


## XP für einen Punktestand (Skala: 1 Punkt ≈ 2,2 XP, gedeckelt).
func _xp_for(points: int) -> int:
	return int(round(clampf(float(points) * 2.2, 20.0, 400.0)))


## Aktuelles Level aus der Gesamtkurve.
func level() -> int:
	var level := 1
	var remaining := xp
	while remaining >= _xp_for_next(level) and level < 99:
		remaining -= _xp_for_next(level)
		level += 1
	return level


## XP bis zum nächsten Level.
func xp_for_next_level() -> int:
	return _xp_for_next(level())


## XP-Kurve: Basis + Wachstum je Level.
func _xp_for_next(level: int) -> int:
	return 220 + 85 * (level - 1)


## Wie viele Level durch eine XP-Gutschrift erreicht wurden.
func level_up_count(gained_xp: int) -> int:
	if gained_xp <= 0:
		return 0
	var before := _level_at(xp - gained_xp)
	var after := _level_at(xp)
	return maxi(0, after - before)


func _level_at(total_xp: int) -> int:
	var lvl := 1
	var remaining := total_xp
	while remaining >= _xp_for_next(lvl) and lvl < 99:
		remaining -= _xp_for_next(lvl)
		lvl += 1
	return lvl


## Karriererang. Die Karriere ergibt sich aus dem erreichten Rang,
## nicht aus einer XP-Ballast.
func rank() -> Dictionary:
	var lvl := level()
	var ranks := [
		{"min": 1, "id": "JUNIOR_ANALYST", "title": "Junior Analyst", "salary": 1800.0},
		{"min": 4, "id": "ANALYST", "title": "Analyst", "salary": 2600.0},
		{"min": 8, "id": "SENIOR_ANALYST", "title": "Senior Analyst", "salary": 3600.0},
		{"min": 13, "id": "TEAMLEITER", "title": "Teamleiter Controlling", "salary": 4800.0},
		{"min": 19, "id": "CONTROLLER", "title": "Controller", "salary": 6200.0},
		{"min": 26, "id": "FINANZLEITER", "title": "Finanzleiter", "salary": 8000.0},
		{"min": 34, "id": "CFO", "title": "Chief Financial Officer", "salary": 11500.0},
	]
	var current: Dictionary = ranks[0]
	for r in ranks:
		if lvl >= int(r["min"]):
			current = r
	current["level"] = lvl
	current["next"] = null
	for r in ranks:
		if int(r["min"]) > lvl:
			current["next"] = r
			break
	return current


## Ein Weltfortschrittsobjekt sicherstellen.
func _ensure_world(world_id: String) -> void:
	if not worlds.has(world_id):
		worlds[world_id] = {
			"stages": [false, false, false],
			"points": [0, 0, 0],
		}


## Zählt gelöste Einzelaufgaben (für Statistik & Anti-Exploit).
func mark_task_solved(task_id: String, correct: bool) -> bool:
	if solved_tasks.has(task_id):
		return false
	solved_tasks[task_id] = correct
	stats["questions_solved"] = int(stats["questions_solved"]) + 1
	if correct:
		stats["correct_answers"] = int(stats["correct_answers"]) + 1
	return true


## ----------------------------------------------------------
# Konzept-Teilaufgaben
#
# Eine Konzeptstufe besteht aus mehreren Einzelaufgaben (Quizfragen,
# Zuordnungsrunden, Ordnungsaufgaben). Erst wenn ALLE gelöst sind,
# gilt die Stufe als bearbeitet. Vorher genügte eine einzige richtige
# Antwort, um die ganze Welt freizuschalten.
#
# Die Teilaufgaben werden innerhalb der Stufe fortlaufend nummeriert
# ("part"), unabhängig von ihrer Art. So lässt sich die Vollständigkeit
# prüfen, ohne die Sortierung der Inhalte zu kennen.
# ----------------------------------------------------------

## Schlüssel einer Konzept-Teilaufgabe.
static func concept_key(world_id: String, stage: int, part: int) -> String:
	return "%s:s%d:part:%d" % [world_id, stage, part]


## Ist eine Konzept-Teilaufgabe bereits erfolgreich gelöst?
func is_concept_solved(world_id: String, stage: int, part: int) -> bool:
	var key := concept_key(world_id, stage, part)
	return bool(solved_tasks.get(key, false))


## Markiert eine Konzept-Teilaufgabe als gelöst.
##
## Rückgabe: true, wenn sie neu dazukam.
func mark_concept_solved(world_id: String, stage: int, part: int) -> bool:
	return mark_task_solved(concept_key(world_id, stage, part), true)


## Sind alle Konzept-Teilaufgaben einer Stufe gelöst?
func is_concept_stage_complete(world_id: String, stage: int, total_parts: int) -> bool:
	if total_parts <= 0:
		return false
	for part in range(total_parts):
		if not is_concept_solved(world_id, stage, part):
			return false
	return true


## Serialisierbarer Zustand.
func to_dict() -> Dictionary:
	return {
		"xp": xp,
		"reputation": reputation,
		"worlds": worlds,
		"solved_tasks": solved_tasks,
		"stats": stats,
	}


## Stellt den Zustand aus einem Save wieder her.
static func from_dict(data: Dictionary) -> PlayerProgress:
	var p := PlayerProgress.new()
	p.xp = int(data.get("xp", 0))
	p.reputation = float(data.get("reputation", 12.0))
	p.worlds = data.get("worlds", {})
	p.solved_tasks = data.get("solved_tasks", {})
	var s: Dictionary = data.get("stats", {})
	for key in p.stats.keys():
		p.stats[key] = int(s.get(key, 0))
	return p
