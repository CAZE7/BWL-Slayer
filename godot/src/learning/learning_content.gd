class_name LearningContent
extends RefCounted

## Fassade für den Lerncontent.
##
## Bündelt den Zugriff auf Welten, Originalaufgaben und Trainer, damit UI
## und Advisor nicht die Rohstruktur kennen müssen.


## Alle Welten.
static func get_worlds() -> Array[WorldContent]:
	return ContentLoader.get_worlds()


## Eine Welt nach ID.
static func get_world(world_id: String) -> WorldContent:
	return ContentLoader.get_world(world_id)


## Die Originalaufgaben einer Welt.
static func get_lab_tasks(world_id: String) -> Array[LabTask]:
	var w := ContentLoader.get_world(world_id)
	if w == null:
		return []
	return w.lab_tasks


## Die Quizfragen einer Welt (aus den Konzept-Minispielen).
static func get_quiz_questions(world_id: String) -> Array:
	var w := ContentLoader.get_world(world_id)
	if w == null:
		return []
	var out: Array = []
	for item in w.concept_items:
		for q in item.questions:
			out.append({
				"world": world_id,
				"item_title": item.title,
				"q": String(q.get("q", "")),
				"options": q.get("options", []),
				"a": int(q.get("a", 0)),
				"why": String(q.get("why", "")),
			})
	return out


## Die Sortier-/Ordnungsaufgaben einer Welt.
static func get_order_items(world_id: String) -> Array:
	var w := ContentLoader.get_world(world_id)
	if w == null:
		return []
	var out: Array = []
	for item in w.concept_items:
		if item.kind == "sort" or item.kind == "order":
			out.append({
				"world": world_id,
				"kind": item.kind,
				"title": item.title,
				"intro": item.intro,
				"categories": item.categories,
				"items": item.items,
			})
	return out


## Der Endlos-Trainer einer Welt.
static func get_trainer(world_id: String) -> EndlessTrainer:
	var w := ContentLoader.get_world(world_id)
	if w == null:
		return null
	return EndlessTrainer.new(w)


## Alle Welten einer Prüfseite.
static func get_worlds_by_side(side: String) -> Array[WorldContent]:
	return ContentLoader.get_worlds_by_side(side)


## Summe der Punkte je Seite (60 Punkte je Seite, wie in der Modulprüfung).
static func side_points(side: String, progress: PlayerProgress) -> int:
	var worlds := get_worlds_by_side(side)
	if worlds.is_empty():
		return 0
	var raw := 0.0
	for w in worlds:
		for stage in range(3):
			raw += float(progress.get_stage_points(w.id, stage))
	return int(round((raw / (worlds.size() * 30.0)) * 60.0))


## Eine Welt gilt als gemeistert, wenn alle 3 Stufen abgeschlossen sind.
static func is_world_mastered(world_id: String, progress: PlayerProgress) -> bool:
	for stage in range(3):
		if not progress.is_stage_done(world_id, stage):
			return false
	return true
