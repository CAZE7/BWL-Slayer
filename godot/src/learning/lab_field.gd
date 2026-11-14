class_name LabField
extends RefCounted

## Ein Eingabefeld einer Rechenaufgabe.
##
## `tolerance` ist die zulässige Abweichung (absolut oder relativ
## aufgelöst). `traps` sind dokumentierte Klausurfallen mit Erklärung –
## sie stammen direkt aus dem geprüften Lerncontent.

var key: String = ""
var label: String = ""
var answer: float = 0.0
var has_answer: bool = false
var unit: String = ""
var tolerance: float = 0.01
var hint: String = ""
var traps: Array = []  ## [{value, tolerance, message}]


## Erzeugt ein Feld aus dem Content-Sidecar.
static func from_dict(data: Dictionary) -> LabField:
	var f := LabField.new()
	f.key = String(data.get("key", ""))
	f.label = String(data.get("label", ""))
	f.unit = String(data.get("unit", ""))
	f.hint = String(data.get("hint", ""))
	if data.has("ans"):
		f.answer = float(data["ans"])
		f.has_answer = true
	# Toleranz auflösen: Werte <= 1 werden als relative Toleranz interpretiert
	var raw_tol := float(data.get("tol", 0.0))
	if raw_tol > 0.0:
		f.tolerance = raw_tol if raw_tol > 1.0 else absf(f.answer) * raw_tol + 1e-9
	else:
		f.tolerance = maxf(0.01, absf(f.answer) * 1e-4 + 1e-9)
	for trap in data.get("traps", []):
		f.traps.append({
			"value": float(trap.get("v", 0.0)),
			"tolerance": float(trap.get("tol", 0.1)),
			"message": String(trap.get("msg", "")),
		})
	return f


## Prüft, ob ein Wert korrekt ist.
func is_correct(value: float) -> bool:
	if not has_answer or not is_finite(value):
		return false
	return absf(value - answer) <= tolerance


## Erkennt eine dokumentierte Klausurfalle und gibt deren Erklärung zurück.
func detect_trap(value: float) -> String:
	var trap := trap_at(value)
	if trap.is_empty():
		return ""
	return String(trap["message"])


## Die erkannte Falle als Struktur.
func trap_at(value: float) -> Dictionary:
	for trap in traps:
		if absf(value - float(trap["value"])) <= float(trap["tolerance"]):
			return trap
	return {}
