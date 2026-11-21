class_name EndlessTrainer
extends RefCounted

## Der prozedurale Endlos-Trainer.
##
## Anforderung: „Keine zufälligen Zahlen ohne definierte fachliche
## Gültigkeitsbereiche." Der Trainer erzeugt daher Aufgaben aus *fachlich
## validierten Bereichen* (z. B. Zinssatz 0–20 %, Nutzungsdauer 1–15 Jahre,
## positive Investitionssummen) und ist deterministisch seedbar.
##
## Die Grundparameter kommen aus dem Content-Sidecar, damit der
## GDScript-Trainer dieselben Aufgabentypen erzeugt wie der JS-Original.

var world: WorldContent
var rng := RandomNumberGenerator.new()
var _counter: int = 0
var _seed_base: int = 0


func _init(p_world: WorldContent = null) -> void:
	world = p_world
	_seed_base = hash(world.id if world != null else "W")
	rng.seed = _seed_base


## Setzt einen deterministischen Startzustand (für Tests und Saves).
func set_seed(seed_value: int) -> void:
	_seed_base = seed_value
	rng.seed = seed_value
	_counter = 0


## Erzeugt die nächste Aufgabe.
##
## Rückgabe: {prompt, given, fields: [{key,label,ans,unit,tol}], solution}
func next_task() -> Dictionary:
	_counter += 1
	var params: Dictionary = world.trainer_params if world != null else {}
	if params.is_empty():
		return _fallback_task()

	var constant: Dictionary = params.get("constant", {})
	var field_defs: Array = params.get("fields", [])

	# Werte erzeugen: konstante Felder übernehmen, variable neu ziehen
	var values := {}
	for field_def in field_defs:
		var key := String(field_def.get("key", ""))
		if bool(field_def.get("constant", false)):
			values[key] = float(field_def.get("ans", 0.0))
		else:
			values[key] = _generate_value(field_def, key)

	var fields: Array = []
	for field_def in field_defs:
		var key := String(field_def.get("key", ""))
		fields.append({
			"key": key,
			"label": String(field_def.get("label", key)),
			"ans": values.get(key, 0.0),
			"unit": String(field_def.get("unit", "")),
			"tol": float(field_def.get("tol", 0.02)),
		})

	return {
		"prompt": _fill_prompt(constant.get("prompt"), values),
		"given": String(constant.get("given", "")),
		"fields": fields,
		"solution": _build_solution(fields),
	}


## Erzeugt einen fachlich gültigen Wert für ein Feld.
##
## Die Wertebereiche sind bewusst eng gefasst, damit jede erzeugte
## Aufgabe wirtschaftlich sinnvoll ist (keine negativen Anschaffungskosten,
## keine unrealistischen Zinssätze, positive Kapazitäten).
func _generate_value(field_def: Dictionary, key: String) -> float:
	match key:
		"fa", "fb", "fixa", "fixb":
			# Fixkosten: zusammengesetzt aus Basis + AfA + kalk. Zinsen
			var a0 := _round_to(rng.randf_range(8000.0, 22000.0), 0.0)
			var n := rng.randi_range(2, 8)
			var i := _round_to(rng.randf_range(0.04, 0.12), 0.001)
			var kfix := _round_to(rng.randf_range(500.0, 4000.0), 0.01)
			return a0 / float(n) + a0 / 2.0 * i + kfix
		"xk", "xkrit":
			# Kritische Menge: aus zwei Fixkostenblöcken und variablem Kostensprung
			var k1 := rng.randf_range(800.0, 5000.0)
			var k2 := rng.randf_range(800.0, 5000.0)
			var dv := rng.randf_range(1.0, 4.0)
			return _round_to((k2 - k1) / dv, 0.01)
		_:
			# Standard: fachlich plausibler Betrag
			return _round_to(rng.randf_range(100.0, 9000.0), 0.01)


## Rundet auf eine definierte Genauigkeit.
func _round_to(value: float, decimals: float) -> float:
	if decimals <= 0.0:
		return round(value)
	var factor: float = pow(10.0, decimals)
	return round(value * factor) / factor


## Füllt Platzhalter im Prompt mit den erzeugten Werten.
func _fill_prompt(template: Variant, values: Dictionary) -> String:
	if template == null:
		return "Berechne die Kennzahlen der Anlage."
	var text := String(template)
	# Platzhalter der Form {key} ersetzen
	for key in values:
		text = text.replace("{%s}" % key, _format_value(float(values[key])))
	return text


## Erzeugt den Lösungs-Text.
func _build_solution(fields: Array) -> String:
	var parts: Array[String] = []
	for field in fields:
		parts.append("%s = %s" % [field["label"], _format_value(float(field["ans"]))])
	return "; ".join(parts)


## Fallback-Aufgabe, falls der Welt keine Trainer-Parameter hinterlegt sind.
func _fallback_task() -> Dictionary:
	var a0 := _round_to(rng.randf_range(9000.0, 18000.0), 0.0)
	var n := rng.randi_range(3, 6)
	var i := _round_to(rng.randf_range(0.05, 0.10), 0.001)
	var kfix := _round_to(rng.randf_range(600.0, 3000.0), 0.01)
	var kvar := _round_to(rng.randf_range(1.0, 5.0), 0.0)
	var fix_a := a0 / float(n) + a0 / 2.0 * i + kfix
	var fix_b := fix_a + rng.randf_range(500.0, 3000.0)
	var xk := (fix_b - fix_a) / kvar
	return {
		"prompt": "Maschine A: A₀ = %s €, n = %d J., i = %s %%, K_Bfix = %s €, k_var = %s €. Maschine B: abweichende Fixkosten." % [
			_format_value(a0), n, _format_value(i * 100.0), _format_value(kfix), _format_value(kvar)
		],
		"given": "Fixkosten = K_Bfix + A₀/n + A₀/2 · i",
		"fields": [
			{"key": "fa", "label": "Fixkosten A", "ans": fix_a, "unit": "€", "tol": 0.02},
			{"key": "fb", "label": "Fixkosten B", "ans": fix_b, "unit": "€", "tol": 0.02},
			{"key": "xk", "label": "Kritische Menge x_krit", "ans": xk, "unit": "Stück", "tol": 0.02},
		],
		"solution": "K_fix,A = %s €, K_fix,B = %s €, x_krit = %s Stück." % [
			_format_value(fix_a), _format_value(fix_b), _format_value(xk)
		],
	}


## Zahlenformat (deutsch).
func _format_value(value: float) -> String:
	return String.num(value, 2).replace(".", ",")
