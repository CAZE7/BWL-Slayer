class_name LearningOverlay
extends Control

## Der BWL-Labor-Bereich.
##
## Hier laufen die drei Stufen einer Welt:
##   1. Konzept-Minispiel (Quiz / Sortieren / Ordnen)
##   2. Rechen-Labor mit den Originalaufgaben
##   3. Endlos-Trainer
##
## Der Bereich überlagert die Fabrikszene, weil Lernen hier ein
## *Arbeitsvorgang* ist – die Verbindung zur laufenden Simulation bleibt
## sichtbar (Tageszähler, Kapital).

## Die Farbpalette des Lernbereichs.
##
## Dieselbe Palette wie in der Hauptoberflaeche: Anthrazit,
## Graphit, Stahlgrau, Off-White. Blau markiert Auswahl und aktive
## Elemente, Gruen positive Zustaende, Orange und Rot Warnungen.
const UI := {
	"background": Color(0.055, 0.063, 0.075),
	"surface": Color(0.086, 0.098, 0.114),
	"border": Color(0.180, 0.200, 0.225),
	"text": Color(0.880, 0.900, 0.920),
	"text_muted": Color(0.520, 0.560, 0.610),
	"text_faint": Color(0.380, 0.420, 0.465),
	"accent": Color(0.290, 0.530, 0.640),
	"positive": Color(0.280, 0.580, 0.400),
	"warning": Color(0.760, 0.480, 0.180),
	"danger": Color(0.720, 0.330, 0.310),
}


var world_id: String = ""
var world: WorldContent
var stage_index: int = 0
var trainer: EndlessTrainer
var trainer_task: Dictionary = {}
var trainer_streak: int = 0

var _panel: PanelContainer
var _title: Label
var _subtitle: Label
var _content: VBoxContainer
var _status: Label
var _answer_inputs: Array[LineEdit] = []


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = UI["background"]
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(820, 560)
	_panel.add_theme_stylebox_override("panel", _style(UI["surface"], 6))
	add_child(_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	_panel.add_child(root)

	var header := HBoxContainer.new()
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 20)
	header.add_child(_title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var close := Button.new()
	close.text = "✕ Schließen"
	close.pressed.connect(func(): queue_free())
	header.add_child(close)
	root.add_child(header)

	_subtitle = Label.new()
	_subtitle.add_theme_font_size_override("font_size", 12)
	_subtitle.add_theme_color_override("font_color", UI["text_muted"])
	root.add_child(_subtitle)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 12)
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_content)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size", 13)
	root.add_child(_status)


## Öffnet eine Welt.
func open_world(p_world_id: String, p_stage: int = 0) -> void:
	world_id = p_world_id
	world = LearningContent.get_world(p_world_id)
	stage_index = p_stage
	if world == null:
		_status.text = "Welt nicht gefunden."
		return
	trainer = EndlessTrainer.new(world)
	_render()


# ==================================================================
# Darstellung
# ==================================================================

func _render() -> void:
	for child in _content.get_children():
		child.queue_free()
	_answer_inputs.clear()
	_status.text = ""

	var titles := world.get_stage_titles()
	_title.text = "%s %s" % [world.icon, world.title]
	_subtitle.text = "%s · %s" % [world.side_label(), world.sources]

	# Stufenwahl
	var stage_row := HBoxContainer.new()
	stage_row.name = "StageRow"
	stage_row.add_theme_constant_override("separation", 8)
	for i in range(3):
		var button := Button.new()
		button.name = "Stage_%d" % i
		var done := GameState.progress.is_stage_done(world.id, i)
		button.text = "%s %s" % ["✓" if done else str(i + 1), titles[i]]
		button.custom_minimum_size = Vector2(0, 30)
		button.disabled = i > 0 and not GameState.progress.is_stage_done(world.id, i - 1)
		button.pressed.connect(func(): _set_stage(i))
		stage_row.add_child(button)
	_content.add_child(stage_row)

	match stage_index:
		0: _render_concept()
		1: _render_lab()
		2: _render_trainer()


## Aktualisiert die Beschriftung und Sperrung der Stufenbuttons.
func _update_stage_buttons() -> void:
	var titles := world.get_stage_titles()
	for i in range(3):
		var button := _content.find_child("Stage_%d" % i, true, false) as Button
		if button == null:
			continue
		var done := GameState.progress.is_stage_done(world.id, i)
		button.text = "%s %s" % ["✓" if done else str(i + 1), titles[i]]
		button.disabled = i > 0 and not GameState.progress.is_stage_done(world.id, i - 1)


func _set_stage(index: int) -> void:
	stage_index = index
	trainer_streak = 0
	_render()


# ------------------------------------------------------------------
# Konzeptstufe
#
# Wichtig: Es werden ALLE Konzept-Elemente der Welt gezeigt, nicht nur
# das erste. Vorher blieb der Rest der Welt unsichtbar – es galt als
# erledigt, obwohl die Inhalte nie bearbeitet wurden. Die Freischaltung
# der nächsten Stufe setzt voraus, dass jede Aufgabe bearbeitet wurde.
# ------------------------------------------------------------------
func _render_concept() -> void:
	var items := world.concept_items
	if items.is_empty():
		_content.add_child(_muted("Kein Konzept-Minispiel vorhanden."))
		return

	var progress_label := Label.new()
	progress_label.name = "ConceptProgress"
	progress_label.add_theme_font_size_override("font_size", 12)
	progress_label.add_theme_color_override("font_color", UI["text_muted"])
	_content.add_child(progress_label)
	_update_concept_progress()

	var index := 0
	for item in items:
		index += 1
		# Trennlinie zwischen den Aufgaben, damit die Abschnitte
		# sichtbar getrennt bleiben.
		if index > 1:
			var sep := HSeparator.new()
			sep.custom_minimum_size = Vector2(0, 12)
			_content.add_child(sep)

		match item.kind:
			"quiz": _render_quiz(item)
			"sort": _render_sort(item)
			"order": _render_order(item)
			_:
				_content.add_child(_muted("Konzeptaufgabe nicht verfügbar."))


## Fortschritt der Konzeptstufe: erledigte Aufgaben / Gesamtzahl.
func _update_concept_progress() -> void:
	var label := _content.find_child("ConceptProgress", true, false) as Label
	if label == null:
		return
	var parts := _concept_parts()
	var done := 0
	for part in parts:
		if GameState.progress.is_concept_solved(world.id, stage_index, part["index"]):
			done += 1
	label.text = "Teilaufgabe %d von %d gelöst" % [done, parts.size()]


## Die flache Liste aller Teilaufgaben der Konzeptstufe.
##
## Jede Teilaufgabe bekommt einen fortlaufenden Index. Der Index ist
## stabil, solange sich der Inhalt der Welt nicht aendert – er ist
## der Schluessel im Spielstand.
##
## Rückgabe: [{index, kind, item_index, part_index, title}]
func _concept_parts() -> Array:
	var parts: Array = []
	var index := 0
	for item in world.concept_items:
		match item.kind:
			"quiz":
				for q_index in range(item.questions.size()):
					parts.append({
						"index": index,
						"kind": "quiz",
						"item_index": item_index_of(item),
						"part_index": q_index,
						"title": item.title,
					})
					index += 1
			"sort":
				for r_index in range(item.rounds.size()):
					parts.append({
						"index": index,
						"kind": "sort",
						"item_index": item_index_of(item),
						"part_index": r_index,
						"title": item.title,
					})
					index += 1
			"order":
				parts.append({
					"index": index,
					"kind": "order",
					"item_index": item_index_of(item),
					"part_index": 0,
					"title": item.title,
				})
				index += 1
	return parts


## Index eines Konzept-Elements innerhalb der Welt (fuer Ruecksprünge).
func item_index_of(item: ConceptItem) -> int:
	var items := world.concept_items
	for i in range(items.size()):
		if items[i] == item:
			return i
	return -1


## Der Index der Teilaufgabe, die zu einem Element gehoert.
##
## Innerhalb eines Elements werden die Teilaufgaben fortlaufend
## nummeriert; die Nummerierung startet bei 0 und gilt pro Element.
func _part_index_for(item: ConceptItem, kind: String, part_index: int) -> int:
	var parts := _concept_parts()
	for part in parts:
		if int(part["item_index"]) == item_index_of(item) \
				and String(part["kind"]) == kind \
				and int(part["part_index"]) == part_index:
			return int(part["index"])
	return -1


## Ist dieses Konzept-Element bereits erfolgreich bearbeitet?
##
## Der Fortschritt liegt in GameState.progress. Damit eine Aufgabe
## zaehlt, MUSS die zugehoerige Teilaufgabe als geloest markiert sein –
## eine einzige richtige Quizantwort reicht nicht mehr, um eine ganze
## Welt freizuschalten.
func _is_concept_item_done(item: ConceptItem) -> bool:
	match item.kind:
		"quiz":
			for q_index in range(item.questions.size()):
				var idx := _part_index_for(item, "quiz", q_index)
				if idx < 0 or not GameState.progress.is_concept_solved(world.id, stage_index, idx):
					return false
			return item.questions.size() > 0
		"sort":
			for round_index in range(item.rounds.size()):
				var idx := _part_index_for(item, "sort", round_index)
				if idx < 0 or not GameState.progress.is_concept_solved(world.id, stage_index, idx):
					return false
			return item.rounds.size() > 0
		"order":
			var idx := _part_index_for(item, "order", 0)
			return idx >= 0 and GameState.progress.is_concept_solved(world.id, stage_index, idx)
	return false


func _render_quiz(item: ConceptItem) -> void:
	_content.add_child(_heading(item.title))
	if item.intro != "":
		_content.add_child(_muted(item.intro))

	for q_index in range(item.questions.size()):
		var q: Dictionary = item.questions[q_index]
		var question := Label.new()
		question.text = String(q.get("q", ""))
		question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		question.add_theme_font_size_override("font_size", 14)
		_content.add_child(question)

		var options: Array = q.get("options", [])
		for o_index in range(options.size()):
			var option := Button.new()
			option.text = "  %s" % String(options[o_index])
			option.alignment = HORIZONTAL_ALIGNMENT_LEFT
			option.custom_minimum_size = Vector2(0, 30)
			option.pressed.connect(_on_quiz_answer.bind(item, q_index, o_index))
			_content.add_child(option)

		var feedback := Label.new()
		feedback.name = "Feedback_%d" % q_index
		feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		feedback.add_theme_font_size_override("font_size", 12)
		_content.add_child(feedback)


func _on_quiz_answer(item: ConceptItem, q_index: int, o_index: int) -> void:
	var result := item.check_quiz(q_index, o_index)
	var feedback := _content.find_child("Feedback_%d" % q_index, true, false) as Label
	if feedback != null:
		feedback.text = String(result.get("feedback", ""))
		feedback.add_theme_color_override("font_color",
			UI["positive"] if bool(result.get("correct", false)) else UI["danger"])
	if bool(result.get("correct", false)):
		_mark_concept_part_done(item, "quiz", q_index)


## Prueft, ob alle Teilaufgaben der Stufe geloest sind und schaltet
## die Stufe dann frei.
##
## Vorher genuegte eine einzige richtige Quizantwort. Jetzt zaehlt
## jede Teilaufgabe: jede Quizfrage, jede Zuordnungsrunde und jede
## Ordnungsaufgabe. Erst wenn wirklich alles bearbeitet wurde, gilt
## die Stufe als abgeschlossen.
func _check_stage_complete() -> void:
	var parts := _concept_parts()
	if parts.is_empty():
		return
	for part in parts:
		if not GameState.progress.is_concept_solved(world.id, stage_index, int(part["index"])):
			return

	# Alles geloest: die Stufe freischalten.
	var reward := GameState.complete_stage(world.id, stage_index, 20)
	if bool(reward.get("first_time", false)):
		_status.text = "Alle Teilaufgaben gelöst – Stufe abgeschlossen."
	# Der Status wird im Kopf der Stufenleiste angezeigt.
	_update_stage_buttons()


# ------------------------------------------------------------------
# Zuordnungsaufgabe (sort)
#
# Jede Runde hat eigene Kategorien und eigene Karten. Der Spieler weist
# jeder Karte eine Kategorie zu und gibt die Zuordnung ab. Die
# Auswertung nennt fuer jede falsche Karte die Begruendung – die
# fachliche Erklaerung, nicht nur "falsch".
# ------------------------------------------------------------------
func _render_sort(item: ConceptItem) -> void:
	_content.add_child(_heading(item.title))
	if item.intro != "":
		_content.add_child(_muted(item.intro))

	if item.rounds.is_empty():
		_content.add_child(_muted("Für diese Aufgabe liegen keine Runden vor."))
		return

	for round_index in range(item.rounds.size()):
		var round_data: Dictionary = item.rounds[round_index]
		_render_sort_round(item, round_data, round_index)


func _render_sort_round(item: ConceptItem, round_data: Dictionary, round_index: int) -> void:
	var categories: Array = round_data.get("categories", [])
	var cards: Array = round_data.get("cards", [])

	if round_data.get("title", "") != "":
		var round_title := Label.new()
		round_title.text = "Runde %d · %s" % [round_index + 1, String(round_data.get("title", ""))]
		round_title.add_theme_font_size_override("font_size", 13)
		round_title.add_theme_color_override("font_color", UI["text"])
		_content.add_child(round_title)

	if categories.is_empty() or cards.is_empty():
		_content.add_child(_muted("Diese Runde enthält keine Karten."))
		return

	# Die Kategorien als Auswahlliste je Karte.
	var selects: Array[OptionButton] = []
	for card in cards:
		var card_id := String(card.get("id", ""))
		if card_id == "":
			card_id = "c%d" % cards.find(card)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)

		var label := Label.new()
		label.text = String(card.get("text", card_id))
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(320, 0)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 13)
		row.add_child(label)

		var option := OptionButton.new()
		option.name = "Sort_%d_%s" % [round_index, card_id]
		option.custom_minimum_size = Vector2(190, 28)
		option.add_item("– bitte wählen –")
		for cat in categories:
			option.add_item(String(cat.get("label", "")))
		row.add_child(option)
		selects.append(option)

		_content.add_child(row)

	var check := Button.new()
	check.text = "Zuordnung prüfen"
	check.pressed.connect(_on_check_sort.bind(item, round_data, round_index, selects))
	_content.add_child(check)

	var feedback := Label.new()
	feedback.name = "SortFeedback_%d" % round_index
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.add_theme_font_size_override("font_size", 12)
	_content.add_child(feedback)


func _on_check_sort(
	item: ConceptItem, round_data: Dictionary, round_index: int, selects: Array[OptionButton]
) -> void:
	var categories: Array = round_data.get("categories", [])
	var cards: Array = round_data.get("cards", [])

	# Die Zuordnung zusammenstellen: Karte -> Kategorie-ID.
	var assignment := {}
	for i in range(mini(cards.size(), selects.size())):
		var option: OptionButton = selects[i]
		if option.selected <= 0:
			continue
		var card_id := String(cards[i].get("id", ""))
		if card_id == "":
			card_id = "c%d" % i
		assignment[card_id] = String(categories[option.selected - 1].get("id", ""))

	var result := item.check_sort(assignment)
	var feedback := _content.find_child("SortFeedback_%d" % round_index, true, false) as Label
	var correct := int(result.get("correct_count", 0))
	var total := int(result.get("total", 0))

	if feedback != null:
		feedback.text = "%d von %d Zuordnungen richtig. %s" % [
			correct, total, String(result.get("feedback", ""))
		]
		feedback.add_theme_color_override("font_color",
			UI["positive"] if bool(result.get("correct", false)) else UI["danger"])

	# Bei Erfolg: die Begruendungen der Karten anzeigen. Sie erklaeren,
	# warum die Zuordnung so und nicht anders lautet.
	if bool(result.get("correct", false)):
		for card in cards:
			var why := String(card.get("why", ""))
			if why == "":
				continue
			var explanation := Label.new()
			explanation.text = "• %s – %s" % [String(card.get("text", "")), why]
			explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			explanation.add_theme_font_size_override("font_size", 12)
			explanation.add_theme_color_override("font_color", UI["positive"])
			_content.add_child(explanation)
		_mark_concept_part_done(item, "sort", round_index)
	else:
		# Bei Fehlern: die richtige Zuordnung mit Begruendung nennen.
		for card in cards:
			var card_id := String(card.get("id", ""))
			if card_id == "":
				card_id = "c%d" % cards.find(card)
			var expected := String(card.get("cat", ""))
			var given := String(assignment.get(card_id, ""))
			if given == expected or expected == "":
				continue
			var label := ""
			for cat in categories:
				if String(cat.get("id", "")) == expected:
					label = String(cat.get("label", expected))
			var hint := Label.new()
			hint.text = "• %s gehört zu „%s“: %s" % [
				String(card.get("text", "")), label, String(card.get("why", ""))
			]
			hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			hint.add_theme_font_size_override("font_size", 12)
			hint.add_theme_color_override("font_color", UI["warning"])
			_content.add_child(hint)


## Markiert eine Teilaufgabe als geloest und aktualisiert den Fortschritt.
func _mark_concept_part_done(item: ConceptItem, kind: String, part_index: int) -> void:
	var idx := _part_index_for(item, kind, part_index)
	if idx < 0:
		return
	GameState.progress.mark_concept_solved(world.id, stage_index, idx)
	_update_concept_progress()
	_check_stage_complete()


# ------------------------------------------------------------------
# Ordnungsaufgabe (order)
#
# Die Elemente liegen in der richtigen Reihenfolge vor, sind aber
# durcheinander gemischt. Der Spieler baut die Reihenfolge selbst auf:
# ein Klick auf ein Element haengt es an, ein Klick auf ein bereits
# platziertes Element nimmt es wieder heraus.
# ------------------------------------------------------------------
func _render_order(item: ConceptItem) -> void:
	_content.add_child(_heading(item.title))
	if item.intro != "":
		_content.add_child(_muted(item.intro))
	if item.prompt != "":
		_content.add_child(_muted(item.prompt))

	if item.items.is_empty():
		_content.add_child(_muted("Für diese Aufgabe liegen keine Elemente vor."))
		return

	# Die Elemente werden in einer festen, aber gemischten Reihenfolge
	# angezeigt. Die Mischung ist deterministisch (fester Seed), damit
	# die Aufgabe bei jedem Aufruf gleich beginnt.
	var shuffled := _shuffled_order(item.items)

	_content.add_child(_muted("Klicke die Elemente in der richtigen Reihenfolge an. Ein Klick auf ein platziertes Element nimmt es wieder heraus."))

	var sequence: Array = []
	var buttons: Array[Button] = []

	var placed_row := HBoxContainer.new()
	placed_row.name = "OrderPlaced"
	placed_row.add_theme_constant_override("separation", 6)
	_content.add_child(placed_row)

	var placed_label := Label.new()
	placed_label.name = "OrderSequence"
	placed_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	placed_label.add_theme_font_size_override("font_size", 13)
	placed_label.add_theme_color_override("font_color", UI["text"])
	_content.add_child(placed_label)

	var pool := HBoxContainer.new()
	pool.name = "OrderPool"
	pool.add_theme_constant_override("separation", 6)
	_content.add_child(pool)

	for entry in shuffled:
		var entry_id := String(entry.get("id", ""))
		var button := Button.new()
		button.text = String(entry.get("text", entry_id))
		button.custom_minimum_size = Vector2(0, 32)
		button.set_meta("entry_id", entry_id)
		button.pressed.connect(_on_order_click.bind(item, entry_id, sequence, buttons, placed_label))
		pool.add_child(button)
		buttons.append(button)

	var check := Button.new()
	check.text = "Reihenfolge prüfen"
	check.pressed.connect(_on_check_order.bind(item, sequence))
	_content.add_child(check)

	var feedback := Label.new()
	feedback.name = "OrderFeedback"
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.add_theme_font_size_override("font_size", 12)
	_content.add_child(feedback)

	# Die aktuelle Reihenfolge anfangs anzeigen.
	_update_order_label(sequence, placed_label)


## Elemente in einer deterministischen, von der Loesung abweichenden
## Reihenfolge. Kein Zufall: der Seed ist aus dem Inhalt abgeleitet,
## damit die Aufgabe bei jedem Aufruf gleich beginnt und der Spieler
## sie nicht durch Neuladen "neu würfelt".
func _shuffled_order(items: Array) -> Array:
	var result: Array = []
	for entry in items:
		result.append(entry)
	# Fester, inhaltsabhängiger Seed: gleicher Inhalt -> gleiche
	# Mischung, aber eine andere als die korrekte Reihenfolge.
	var seed_value := 0
	for entry in items:
		seed_value = seed_value * 31 + String(entry.get("id", "")).hash()
	seed_value = absi(seed_value) % 2147483647
	if seed_value == 0:
		seed_value = 7

	# Fisher-Yates mit deterministischem Zufall.
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in range(result.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Variant = result[i]
		result[i] = result[j]
		result[j] = tmp

	# Ist die Mischung zufällig schon die Loesung, wird sie einmal
	# gedreht – sonst waere die Aufgabe ohne Zutun loesbar.
	var is_solution := true
	for i in range(result.size()):
		if String(result[i].get("id", "")) != String(items[i].get("id", "")):
			is_solution = false
			break
	if is_solution and result.size() > 1:
		var first: Variant = result[0]
		result[0] = result[result.size() - 1]
		result[result.size() - 1] = first
	return result


func _on_order_click(
	item: ConceptItem, entry_id: String, sequence: Array, buttons: Array[Button], placed_label: Label
) -> void:
	# Bereits platziert? Dann wieder entfernen.
	if sequence.has(entry_id):
		sequence.erase(entry_id)
	else:
		sequence.append(entry_id)

	# Die Buttons deaktivieren, die bereits in der Reihenfolge stehen.
	for button in buttons:
		button.disabled = sequence.has(_button_entry_id(button))

	_update_order_label(sequence, placed_label)


## Die Element-ID zu einem Button gehoert.
func _button_entry_id(button: Button) -> String:
	return String(button.get_meta("entry_id", ""))


func _update_order_label(sequence: Array, placed_label: Label) -> void:
	if sequence.is_empty():
		placed_label.text = "Reihenfolge: (noch nichts platziert)"
		return
	var parts: Array[String] = []
	for i in range(sequence.size()):
		parts.append("%d. %s" % [i + 1, _entry_text(sequence[i])])
	placed_label.text = "Reihenfolge: " + "  →  ".join(parts)


## Der Text eines Element-IDs.
func _entry_text(entry_id: String) -> String:
	for entry in world.concept_items:
		for sub in entry.items:
			if String(sub.get("id", "")) == entry_id:
				return String(sub.get("text", entry_id))
	return entry_id


func _on_check_order(item: ConceptItem, sequence: Array) -> void:
	var result := item.check_order(sequence)
	var feedback := _content.find_child("OrderFeedback", true, false) as Label
	var correct := int(result.get("correct_count", 0))
	var total := int(result.get("total", 0))

	if feedback != null:
		feedback.text = "%d von %d Positionen richtig. %s" % [
			correct, total, String(result.get("feedback", ""))
		]
		feedback.add_theme_color_override("font_color",
			UI["positive"] if bool(result.get("correct", false)) else UI["danger"])

	if bool(result.get("correct", false)):
		if item.solution != "":
			var solution := Label.new()
			solution.text = "Lösungsweg: %s" % item.solution
			solution.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			solution.add_theme_font_size_override("font_size", 12)
			solution.add_theme_color_override("font_color", UI["positive"])
			_content.add_child(solution)
		_mark_concept_part_done(item, "order", 0)


# ------------------------------------------------------------------
# Rechen-Labor
#
# Es werden ALLE Originalaufgaben der Welt gezeigt. Vorher war nur die
# erste Aufgabe sichtbar – der Rest der Originalaufgaben (der
# geschuetzte Lerninhalt) war damit unerreichbar.
# ------------------------------------------------------------------
func _render_lab() -> void:
	var tasks := world.lab_tasks
	if tasks.is_empty():
		_content.add_child(_muted("Keine Originalaufgaben vorhanden."))
		return

	_content.add_child(_heading("Originalaufgaben"))

	var index := 0
	for task in tasks:
		index += 1
		if index > 1:
			var sep := HSeparator.new()
			sep.custom_minimum_size = Vector2(0, 12)
			_content.add_child(sep)
		_render_lab_task(task, index)


func _render_lab_task(task: LabTask, index: int) -> void:
	var heading := Label.new()
	heading.text = "Aufgabe %d" % index
	heading.add_theme_font_size_override("font_size", 13)
	heading.add_theme_color_override("font_color", UI["text"])
	_content.add_child(heading)

	var prompt := Label.new()
	prompt.text = task.prompt
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt.add_theme_font_size_override("font_size", 13)
	_content.add_child(prompt)

	if task.given != "":
		var given := Label.new()
		given.text = "Formel: %s" % task.given
		given.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		given.add_theme_font_size_override("font_size", 11)
		given.add_theme_color_override("font_color", UI["text_muted"])
		_content.add_child(given)

	for field in task.fields:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = field.label
		label.custom_minimum_size = Vector2(240, 0)
		label.add_theme_font_size_override("font_size", 13)
		row.add_child(label)

		var input := LineEdit.new()
		input.custom_minimum_size = Vector2(160, 0)
		input.placeholder_text = "Wert"
		# Eindeutiger Name je Aufgabe: sonst wuerden die Felder
		# mehrerer Aufgaben uebereinanderliegen.
		input.name = "Field_%s_%s" % [task.id, field.key]
		row.add_child(input)
		_answer_inputs.append(input)

		if field.hint != "":
			var hint := Label.new()
			hint.text = "Hinweis: %s" % field.hint
			hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			hint.add_theme_font_size_override("font_size", 11)
			hint.add_theme_color_override("font_color", UI["text_faint"])
			row.add_child(hint)

		_content.add_child(row)

	var check := Button.new()
	check.text = "Lösung prüfen"
	check.pressed.connect(_on_check_lab.bind(task))
	_content.add_child(check)

	var solution := Label.new()
	solution.name = "Solution_%s" % task.id
	solution.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	solution.add_theme_font_size_override("font_size", 12)
	_content.add_child(solution)


func _on_check_lab(task: LabTask) -> void:
	var values := {}
	for field in task.fields:
		var input := _content.find_child("Field_%s_%s" % [task.id, field.key], true, false) as LineEdit
		if input == null:
			continue
		var text := input.text.strip_edges().replace("€", "").replace(" ", "")
		if text.contains(","):
			text = text.replace(".", "").replace(",", ".")
		values[field.key] = text.to_float() if text.is_valid_float() else NAN

	var result := task.evaluate(values)
	var ratio := float(result.get("ratio", 0.0))
	var correct := int(result.get("correct_fields", 0))
	var total := int(result.get("total_fields", 0))

	# Die Rueckmeldung steht an der Aufgabe, nicht global – sonst
	# ueberschrieben sich die Meldungen mehrerer Aufgaben.
	var solution := _content.find_child("Solution_%s" % task.id, true, false) as Label
	var message := "%d von %d Feldern richtig (%.0f %%)." % [correct, total, ratio * 100.0]

	# Klausurfallen erklaeren
	for entry in result.get("results", []):
		if bool(entry.get("correct", false)):
			continue
		var explanation := String(entry.get("explanation", ""))
		if explanation != "":
			message += "\n• %s: %s" % [entry.get("label", ""), explanation]

	if solution != null:
		solution.text = message

	# Punkte: der Mittelwert aller Aufgaben ergibt die Stufenpunkte.
	# Eine einzelne Aufgabe schaltet die Stufe NICHT mehr frei – erst
	# wenn alle Aufgaben bearbeitet sind.
	var task_points := int(round(30.0 * ratio))
	GameState.progress.mark_task_solved("lab:%s" % task.id, ratio >= 0.999)
	_accumulate_lab_points(task, task_points)
	_status.text = message


## Sammelt die Punkte aller Laboraufgaben einer Welt.
##
## Die Stufenpunkte sind der Mittelwert ueber die Aufgaben. Die Stufe
## wird erst freigeschaltet, wenn jede Aufgabe bearbeitet wurde – nicht
## schon bei der ersten.
func _accumulate_lab_points(task: LabTask, task_points: int) -> void:
	var tasks := world.lab_tasks
	if tasks.is_empty():
		return

	# Punkte je Aufgabe merken.
	var key := "lab_points:%s" % world.id
	var per_task: Dictionary = GameState.progress.worlds.get(world.id, {}).get("lab_points", {})
	if per_task is Dictionary:
		per_task[task.id] = maxi(int(per_task.get(task.id, 0)), task_points)
	else:
		per_task = {task.id: task_points}

	# Mittelwert ueber alle Aufgaben.
	var total := 0
	for t in tasks:
		total += int(per_task.get(t.id, 0))
	var stage_points := int(round(float(total) / float(tasks.size())))

	# Fortschritt speichern.
	GameState.progress._ensure_world(world.id)
	var entry: Dictionary = GameState.progress.worlds[world.id]
	entry["lab_points"] = per_task

	# Sind alle Aufgaben bearbeitet?
	var all_done := true
	for t in tasks:
		if not GameState.progress.solved_tasks.get("lab:%s" % t.id, false):
			all_done = false
			break

	if all_done:
		var reward := GameState.complete_stage(world.id, stage_index, stage_points)
		if bool(reward.get("first_time", false)):
			_status.text += "\n\nAlle Originalaufgaben bearbeitet – Stufe abgeschlossen."


# ------------------------------------------------------------------
func _render_trainer() -> void:
	_content.add_child(_heading("Endlos-Trainer"))
	if trainer_task.is_empty():
		trainer_task = trainer.next_task()

	var prompt := Label.new()
	prompt.text = String(trainer_task.get("prompt", ""))
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt.add_theme_font_size_override("font_size", 13)
	_content.add_child(prompt)

	for field in trainer_task.get("fields", []):
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = String(field.get("label", ""))
		label.custom_minimum_size = Vector2(240, 0)
		label.add_theme_font_size_override("font_size", 13)
		row.add_child(label)
		var input := LineEdit.new()
		input.custom_minimum_size = Vector2(160, 0)
		input.name = "Trainer_" + String(field.get("key", ""))
		row.add_child(input)
		_content.add_child(row)

	var check := Button.new()
	check.text = "Prüfen"
	check.pressed.connect(_on_check_trainer)
	_content.add_child(check)

	var next := Button.new()
	next.text = "Nächste Aufgabe"
	next.pressed.connect(func():
		trainer_task = trainer.next_task()
		_render()
	)
	_content.add_child(next)


func _on_check_trainer() -> void:
	var values := {}
	var correct := 0
	var total := 0
	for field in trainer_task.get("fields", []):
		total += 1
		var input := _content.find_child("Trainer_" + String(field.get("key", "")), true, false) as LineEdit
		if input == null:
			continue
		var text := input.text.strip_edges().replace("€", "").replace(" ", "")
		if text.contains(","):
			text = text.replace(".", "").replace(",", ".")
		var value := text.to_float() if text.is_valid_float() else NAN
		var tolerance := float(field.get("tol", 0.02))
		var expected := float(field.get("ans", 0.0))
		if absf(value - expected) <= maxf(0.01, absf(expected) * tolerance):
			correct += 1
	_status.text = "%d von %d richtig." % [correct, total]

	if correct == total and total > 0:
		trainer_streak += 1
		_status.text += "  Serie: %d" % trainer_streak
		var points := int(round(20.0 + trainer_streak * 2.0))
		GameState.complete_stage(world.id, stage_index, mini(points, 60))
	else:
		trainer_streak = 0


# ==================================================================
# Hilfsfunktionen
# ==================================================================

func _heading(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", UI["accent"])
	return label


func _muted(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.55, 0.60, 0.68))
	return label


func _style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	return style
