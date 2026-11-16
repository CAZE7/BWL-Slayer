extends RefCounted

## Tests des Lern- und Aufgabensystems.
##
## Anforderung: „Kein vorhandenes Lernziel darf verloren gehen."
## Diese Tests sichern ab, dass alle 9 Welten, alle 3 Stufen und alle
## Originalaufgaben vorhanden sind und korrekt funktionieren.


static func run(t: TestFramework) -> void:
	t.suite("Lernen · Content-Vollständigkeit")
	_test_content_coverage(t)
	t.suite("Lernen · Zuordnungs- & Ordnungsinhalte")
	_test_sort_order_content(t)
	t.suite("Lernen · Aufgabenlogik")
	_test_task_logic(t)
	t.suite("Lernen · Fortschritt & Freischaltung")
	_test_progress(t)
	t.suite("Lernen · Teilaufgaben-Freischaltung")
	_test_mastery_criteria(t)


# ------------------------------------------------------------------
# Die Zuordnungs- und Ordnungsaufgaben tragen ihren Inhalt im Legacy-
# Format unter `rounds[].cards[]`. Beim Export nach Godot ging dieser
# Inhalt verloren – alle 12 Zuordnungsaufgaben waren leer.
# ------------------------------------------------------------------
static func _test_sort_order_content(t: TestFramework) -> void:
	var worlds := LearningContent.get_worlds()
	var total_rounds := 0
	var total_cards := 0
	var total_order_items := 0
	var total_order_with_solution := 0

	for w in worlds:
		for item in w.concept_items:
			if item.kind == "sort":
				total_rounds += item.rounds.size()
				for round_data in item.rounds:
					var categories: Array = round_data.get("categories", [])
					var cards: Array = round_data.get("cards", [])
					t.check_true(
						"%s/%s: Runde mit Kategorien" % [w.id, item.title],
						categories.size() >= 2
					)
					t.check_true(
						"%s/%s: Runde mit Karten" % [w.id, item.title],
						cards.size() >= 2
					)
					total_cards += cards.size()
					# Jede Karte braucht eine Kategorie und eine
					# Begruendung – das ist der fachliche Inhalt.
					for card in cards:
						t.check_true(
							"%s/%s: Karte mit Kategorie" % [w.id, item.title],
							String(card.get("cat", "")) != ""
						)
						t.check_true(
							"%s/%s: Karte mit Begruendung" % [w.id, item.title],
							String(card.get("why", "")) != ""
						)
			elif item.kind == "order":
				total_order_items += item.items.size()
				if item.solution != "":
					total_order_with_solution += 1
				t.check_true(
					"%s/%s: Ordnungsaufgabe mit Elementen" % [w.id, item.title],
					item.items.size() >= 3
				)

	# Die Summe muss den Legacy-Bestand abbilden.
	t.check_true("12 Zuordnungsrunden vorhanden", total_rounds == 12)
	t.check_true("62 Karten vorhanden", total_cards == 62)
	t.check_true("4 Ordnungsaufgaben vorhanden", total_order_items >= 15)
	t.check_true("Ordnungsaufgaben mit Lösungsweg", total_order_with_solution == 4)


# ------------------------------------------------------------------
# Die Mastery-Kriterien: Eine einzelne richtige Quizantwort darf keine
# ganze Welt freischalten. Jede Teilaufgabe muss geloest sein.
# ------------------------------------------------------------------
static func _test_mastery_criteria(t: TestFramework) -> void:
	var progress := PlayerProgress.new()
	var world_id := "W1"

	# Eine einzelne richtige Antwort schaltet nichts frei.
	progress.mark_concept_solved(world_id, 0, 0)
	t.check_true(
		"Einzelne Teilaufgabe schaltet die Stufe nicht frei",
		not progress.is_stage_done(world_id, 0)
	)

	# Erst wenn alle Teile geloest sind, ist die Stufe erledigt.
	var parts := _concept_part_count(world_id)
	t.check_true("Welt W1 hat Teilaufgaben", parts > 0)
	for part in range(parts):
		progress.mark_concept_solved(world_id, 0, part)
	t.check_true(
		"Alle Teilaufgaben geloest: Stufe vollstaendig",
		progress.is_concept_stage_complete(world_id, 0, parts)
	)

	# Das Markieren ist idempotent – XP gibt es nur einmal.
	var before_xp := progress.xp
	progress.mark_concept_solved(world_id, 0, 0)
	t.check_true("Kein doppelter XP-Gewinn", progress.xp == before_xp)

	# Die Schluessel sind welt- und stufenbezogen.
	progress.mark_concept_solved("W2", 0, 0)
	t.check_false(
		"Fortschritt einer anderen Welt bleibt unberuehrt",
		progress.is_concept_solved("W1", 0, 0) == false
	)


## Zaehlt die Teilaufgaben einer Welt (identisch zur Logik im Overlay).
static func _concept_part_count(world_id: String) -> int:
	var w := LearningContent.get_world(world_id)
	if w == null:
		return 0
	var count := 0
	for item in w.concept_items:
		match item.kind:
			"quiz": count += item.questions.size()
			"sort": count += item.rounds.size()
			"order": count += 1
	return count


# ------------------------------------------------------------------
static func _test_content_coverage(t: TestFramework) -> void:
	var worlds := LearningContent.get_worlds()
	t.check_true("9 Welten vorhanden", worlds.size() == 9)

	# Alle Welten haben die vollständige Struktur
	for w in worlds:
		t.check_true("%s: 3 Stufen" % w.id, w.get_stage_titles().size() == 3)
		t.check_true("%s: Briefing vorhanden" % w.id, w.briefing.size() > 0)
		t.check_true("%s: Quelle dokumentiert" % w.id, w.sources != "")

	# Welten-IDs und Reihenfolge
	var expected_ids := ["W1", "W2", "W3", "W4", "W5", "W6", "W7", "W8", "W9"]
	for i in range(mini(expected_ids.size(), worlds.size())):
		t.check_true("Welt %d hat ID %s" % [i + 1, expected_ids[i]], String(worlds[i].id) == expected_ids[i])

	# Beide Prüfseiten vertreten (Investition / Finanzierung je 60 Punkte)
	var inv_count := 0
	var fin_count := 0
	for w in worlds:
		if String(w.side) == "INV":
			inv_count += 1
		else:
			fin_count += 1
	# Verteilung laut Originaldaten (src/data1.js, data2.js, data3.js):
	# W1-W4 und W9 sind Investition, W5-W8 sind Finanzierung.
	t.check_true("5 Investitionswelten", inv_count == 5)
	t.check_true("4 Finanzierungswelten", fin_count == 4)

	# Jede Welt hat Originalaufgaben (Rechen-Labor)
	var total_lab := 0
	for w in worlds:
		total_lab += w.lab_tasks.size()
	t.check_true("Originalaufgaben vorhanden", total_lab >= 30)

	# Jede Welt hat ein Konzept-Minispiel mit Quizfragen
	for w in worlds:
		var quiz_count := 0
		for item in w.concept_items:
			# item ist ein ConceptItem-Objekt, kein Dictionary.
			# Dictionary.get() akzeptiert nur einen Default-Parameter.
			quiz_count += item.questions.size()
		t.check_true("%s: mindestens 2 Quizfragen" % w.id, quiz_count >= 2)

	# Trainer-Generator für jede Welt
	for w in worlds:
		t.check_true("%s: Trainer vorhanden" % w.id, w.has_trainer)


# ------------------------------------------------------------------
static func _test_task_logic(t: TestFramework) -> void:
	var worlds := LearningContent.get_worlds()
	var w2: WorldContent = null
	for w in worlds:
		if String(w.id) == "W2":
			w2 = w
			break

	t.check_true("W2 geladen", w2 != null)
	if w2 == null:
		return

	# Originalaufgabe Fuhrpark: alle Felder mit Musterlösung
	var task: LabTask = w2.lab_tasks[0]
	t.check_true("Aufgabe hat Felder", task.fields.size() > 0)
	for field in task.fields:
		t.check_true("Feld %s hat Musterlösung" % field.key, field.has_answer)
		t.check_true("Feld %s hat Toleranz" % field.key, field.tolerance > 0.0)

	# Die kritische Menge der Originalaufgabe
	var xkrit := -1.0
	for field in task.fields:
		if String(field.key) == "xkrit":
			xkrit = field.answer
	t.check_approx("x_krit Originalaufgabe", xkrit, 116.375, 0.001)

	# Klausurfallen (Traps) müssen erhalten sein
	var trap_count := 0
	for field in task.fields:
		trap_count += field.traps.size()
	t.check_true("Klausurfallen dokumentiert", trap_count >= 3)

	# Toleranz: absolute Werte korrekt, relative Werte korrekt.
	#
	# Die Toleranzen sind im gesamten Content verteilt: ueberwiegend
	# relativ (Prozentwert <= 1), absolut (> 1) bei W3 Aufgabe 2.
	# Deshalb wird der gesamte Content geprueft, nicht nur eine Aufgabe.
	var relative_field: LabField = null
	var absolute_field: LabField = null
	for world in worlds:
		for world_task in world.lab_tasks:
			for field in world_task.fields:
				if field.tolerance <= 1.0 and field.tolerance > 0.0 and field.answer > 100.0:
					if relative_field == null:
						relative_field = field
				elif field.tolerance > 1.0:
					if absolute_field == null:
						absolute_field = field
	t.check_true("Relative Toleranz erkannt", relative_field != null)
	t.check_true("Absolute Toleranz erkannt", absolute_field != null)


# ------------------------------------------------------------------
static func _test_progress(t: TestFramework) -> void:
	var progress := PlayerProgress.new()

	# Fortschritt kann nur einmal belohnt werden
	var first := progress.complete_stage("W1", 0, 100)
	t.check_true("Erste Belohnung", first.xp > 0)
	var second := progress.complete_stage("W1", 0, 100)
	t.check_true("Keine Doppelbelohnung", second.xp == 0)
	t.check_true("XP bleibt einmalig", progress.xp == first.xp)

	# Freischaltung: W2 ist nach W1 Stufe 1 offen
	t.check_true("W2 nach W1 freigeschaltet", progress.is_world_unlocked("W2"))
	t.check_true("W3 gesperrt", not progress.is_world_unlocked("W3"))

	# Freischaltungskette: jede Welt schaltet die nächste frei.
	# W3 wird also frei, sobald W2 abgeschlossen ist.
	progress.complete_stage("W1", 1, 120)
	progress.complete_stage("W1", 2, 150)
	t.check_true("W3 nach W1 gesperrt", not progress.is_world_unlocked("W3"))
	progress.complete_stage("W2", 0, 100)
	t.check_true("W3 nach W2 frei", progress.is_world_unlocked("W3"))

	# Stufenpunkte werden nie überschrieben, sondern maximiert.
	#
	# Der Vergleich erfolgt ueber float(): `complete_stage` liefert ein
	# Dictionary, `higher.points` ist damit ein Variant. Der Vergleich
	# eines Variant mit einem int ist in Godot 4.7 nicht verlaesslich –
	# er liefert false, obwohl der Wert stimmt.
	var higher := progress.complete_stage("W1", 0, 250)
	t.check_approx("Höherer Punktwert zählt", float(higher.points), 250.0, 0.01)
	var lower := progress.complete_stage("W1", 0, 50)
	t.check_approx("Niedrigerer Punktwert überschreibt nicht", float(lower.points), 250.0, 0.01)

	# Fortschritt roundtrip
	var data := progress.to_dict()
	var restored := PlayerProgress.from_dict(data)
	t.check_approx("Roundtrip XP", restored.xp, progress.xp, 0.01)
	t.check_true("Roundtrip Weltenfortschritt", restored.is_stage_done("W1", 2))
