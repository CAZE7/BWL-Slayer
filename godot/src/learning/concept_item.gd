class_name ConceptItem
extends RefCounted

## Ein Element des Konzept-Minispiels.
##
## Drei Varianten:
##   sort   – Zuordnung zu Kategorien (Cashflow-Tinder, Kosten-Baukasten …)
##   order  – Reihenfolge herstellen (Prozessphasen)
##   quiz   – Multiple Choice

var kind: String = ""
var title: String = ""
var intro: String = ""
var prompt: String = ""      ## Aufgabenstellung (order-Items)
var solution: String = ""    ## Lösungsweg (order-Items)
var categories: Array = []   ## [{id, label}]
var items: Array = []        ## [{id, text}]
var questions: Array = []    ## [{q, options, a, why}]
var rounds: Array = []       ## [{title, categories, cards}] – Zuordnungsrunden


static func from_dict(data: Dictionary) -> ConceptItem:
	var item := ConceptItem.new()
	item.kind = String(data.get("kind", ""))
	item.title = String(data.get("title", ""))
	item.intro = String(data.get("intro", ""))
	item.prompt = String(data.get("prompt", ""))
	item.solution = String(data.get("solution", ""))
	item.categories = data.get("categories", [])
	item.items = data.get("items", [])
	item.questions = data.get("questions", [])
	item.rounds = data.get("rounds", [])
	return item


## Prüft eine Multiple-Choice-Antwort.
## Rückgabe: {correct, feedback}
func check_quiz(question_index: int, answer_index: int) -> Dictionary:
	if question_index < 0 or question_index >= questions.size():
		return {"correct": false, "feedback": "Ungültige Frage."}
	var q: Dictionary = questions[question_index]
	var correct_index := int(q.get("a", -1))
	var options: Array = q.get("options", [])
	var why := String(q.get("why", ""))
	if answer_index == correct_index:
		return {"correct": true, "feedback": why}
	var feedback := "Richtig wäre: %s – %s" % [
		String(options[correct_index]) if correct_index < options.size() else "?",
		why,
	]
	return {"correct": false, "feedback": feedback}


## Prüft eine Zuordnungsaufgabe (sort).
##
## Erwartet: {item_id: category_id}
## Rückgabe: {correct, total, feedback}
func check_sort(assignment: Dictionary) -> Dictionary:
	if items.is_empty():
		return {"correct": false, "total": 0, "feedback": "Keine Zuordnungsaufgabe."}
	var correct := 0
	var wrong_text: Array[String] = []
	for entry in items:
		var item_id := String(entry.get("id", ""))
		var expected := String(entry.get("cat", entry.get("target", "")))
		var given := String(assignment.get(item_id, ""))
		if not expected.is_empty() and given == expected:
			correct += 1
		else:
			var label := ""
			for cat in categories:
				if String(cat.get("id", "")) == expected:
					label = String(cat.get("label", expected))
			wrong_text.append("%s → %s" % [String(entry.get("text", item_id)), label])
	var total := items.size()
	var ok := correct == total
	var feedback := "Alle Zuordnungen korrekt." if ok else "Diese Zuordnungen sind falsch: %s." % ", ".join(wrong_text)
	return {"correct": ok, "total": total, "correct_count": correct, "feedback": feedback}


## Prüft eine Ordnungsaufgabe (order).
##
## Erwartet: eine Liste von item-IDs in der gewünschten Reihenfolge.
func check_order(sequence: Array) -> Dictionary:
	if items.is_empty():
		return {"correct": false, "total": 0, "feedback": "Keine Ordnungsaufgabe."}
	var correct := 0
	for i in range(mini(sequence.size(), items.size())):
		if String(sequence[i]) == String(items[i].get("id", "")):
			correct += 1
	var total := items.size()
	var ok := correct == total
	return {
		"correct": ok,
		"total": total,
		"correct_count": correct,
		"feedback": "Reihenfolge korrekt." if ok else "Die Reihenfolge stimmt noch nicht (offen: %d von %d)." % [correct, total],
	}
