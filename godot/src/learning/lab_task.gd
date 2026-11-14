class_name LabTask
extends RefCounted

## Eine Originalaufgabe der Vorlesung (Rechen-Labor einer Welt).

var id: String = ""
var prompt: String = ""
var given: String = ""
var fields: Array[LabField] = []
var solution: String = ""
var world_id: String = ""


## Erzeugt eine Aufgabe aus dem Content-Sidecar.
static func from_dict(data: Dictionary, p_world_id: String = "") -> LabTask:
	var task := LabTask.new()
	task.id = String(data.get("id", ""))
	task.prompt = String(data.get("prompt", ""))
	task.given = String(data.get("given", ""))
	task.solution = String(data.get("solution", ""))
	task.world_id = p_world_id
	for field_data in data.get("fields", []):
		task.fields.append(LabField.from_dict(field_data))
	return task


## Prüft alle Felder einer Aufgabe.
##
## Rückgabe: {correct_fields, total_fields, results: [{key, value, correct, trap}]}
func evaluate(values: Dictionary) -> Dictionary:
	var correct := 0
	var results: Array = []
	for field in fields:
		var raw: Variant = values.get(field.key, null)
		var value := 0.0
		var valid := false
		if raw is float or raw is int:
			value = float(raw)
			valid = true
		elif typeof(raw) == TYPE_STRING:
			value = _parse_german_number(String(raw))
			valid = is_finite(value)
		var ok := valid and field.is_correct(value)
		if ok:
			correct += 1
		var trap := field.trap_at(value) if valid else {}
		results.append({
			"key": field.key,
			"label": field.label,
			"value": value,
			"correct": ok,
			"trap": trap,
			"explanation": String(trap.get("message", "")) if not ok else "",
		})
	return {
		"correct_fields": correct,
		"total_fields": fields.size(),
		"results": results,
		"ratio": (float(correct) / float(fields.size())) if fields.size() > 0 else 0.0,
	}


## Parst eine deutsche Zahl ("1.234,56" -> 1234.56).
static func _parse_german_number(text: String) -> float:
	var cleaned := text.strip_edges().replace("€", "").replace("%", "").replace(" ", "")
	if cleaned.is_empty():
		return NAN
	if cleaned.contains(","):
		cleaned = cleaned.replace(".", "").replace(",", ".")
	return float(cleaned) if cleaned.is_valid_float() else NAN
