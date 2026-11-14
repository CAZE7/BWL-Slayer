class_name TestFramework
extends RefCounted

## Minimaler, abhängigkeitsfreier Test-Runner für GDScript.
##
## Läuft headless in der CI ohne externe Plugins. Sammelt Ergebnisse,
## schreibt einen JSON-Bericht und setzt den Exit-Code.

var passed: int = 0
var failed: int = 0
var failures: Array[String] = []
var current_suite: String = ""
var _started_at: int = 0

## Protokolldatei. stdout ist bei Godot gepuffert; bricht der Prozess
## ab, geht die Ausgabe verloren. Deshalb wird zusaetzlich in eine Datei
## geschrieben, die der CI-Schritt auswertet.
var _log: FileAccess = null


## Ein bestehendes Protokollhandle uebernehmen (optional – ohne Datei
## laeuft alles ueber stdout).
func attach_log(file: FileAccess) -> void:
	_log = file


## Protokolldatei oeffnen (optional – ohne Datei laeuft alles ueber stdout).
##
## Wichtig: Das Verzeichnis muss vorher existieren. Ein Schreiben in ein
## nicht vorhandenes Verzeichnis schlaegt still fehl, ohne dass Godot
## einen Fehler meldet.
func open_log(path: String) -> void:
	var dir_path := path.get_base_dir()
	if dir_path != "":
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		_log = file
	else:
		push_warning("Protokolldatei nicht anlegbar: %s" % path)


## Zeile in die Protokolldatei schreiben und stdout bedienen.
func _log_line(text: String) -> void:
	if _log != null:
		_log.store_string(text + "\n")
	print(text)


func suite(name: String) -> void:
	current_suite = name
	_log_line("\n--- %s ---" % name)


## Prüft, dass zwei Werte (mit Toleranz) übereinstimmen.
func check(label: String, actual: Variant, expected: Variant, tolerance: float = 0.0001) -> bool:
	var ok := false
	if actual is float or expected is float:
		var a := float(actual) if actual is float else NAN
		var e := float(expected) if expected is float else NAN
		ok = is_finite(a) and is_finite(e) and absf(a - e) <= tolerance
	else:
		ok = actual == expected

	if ok:
		passed += 1
		_log_line("  OK   %s" % label)
	else:
		failed += 1
		var msg := "  FAIL %s – ist %s | erwartet %s" % [label, str(actual), str(expected)]
		failures.append("%s :: %s" % [current_suite, msg])
		_log_line(msg)
	return ok


## Prüft, dass ein Wert ungefähr gleich ist (für Prozent-/Rundungswerte).
func check_approx(label: String, actual: float, expected: float, tolerance: float = 0.01) -> bool:
	return check(label, actual, expected, tolerance)


## Prüft, dass eine Bedingung wahr ist.
func check_true(label: String, condition: bool) -> bool:
	return check(label, condition, true)


## Prueft, dass eine Bedingung NICHT zutrifft.
func check_false(label: String, condition: bool) -> bool:
	return check(label, condition, false)


## Prüft, dass ein Wert nicht null ist (für Variant-Rückgaben).
func check_not_null(label: String, value: Variant) -> bool:
	return check(label, value != null, true)


## Prüft, dass ein Wert null ist.
func check_null(label: String, value: Variant) -> bool:
	return check(label, value == null, true)


## Prüft, dass zwei Dictionaries dieselben Schlüssel enthalten.
func check_has_keys(label: String, dict: Dictionary, keys: Array) -> bool:
	var ok := true
	for key in keys:
		if not dict.has(key):
			ok = false
			break
	return check(label, ok, true)


## Schreibt den JSON-Bericht und gibt den Exit-Code zurück.
func report(output_dir: String = "res://test-report") -> int:
	var data := {
		"passed": passed,
		"failed": failed,
		"total": passed + failed,
		"failures": failures,
		"timestamp": Time.get_datetime_string_from_system(),
	}
	var payload := JSON.stringify(data, "  ")

	# Der Bericht geht nach user://. Dieses Verzeichnis ist immer
	# beschreibbar, auch im exportierten Spiel.
	#
	# Wichtig: Die Unterverzeichnisse werden mit der statischen
	# Variante make_dir_recursive_absolute() angelegt. Die
	# Instanzmethode make_dir_recursive() blockiert im Headless-Betrieb.
	var report_dir := ProjectSettings.globalize_path("user://test-report")
	DirAccess.make_dir_recursive_absolute(report_dir)
	var safe_file := FileAccess.open("user://test-report/report.json", FileAccess.WRITE)
	if safe_file != null:
		safe_file.store_string(payload)
		safe_file.flush()
		safe_file.close()

	# Zusaetzlich ins Projektverzeichnis, damit der CI-Schritt die Datei
	# direkt findet. Das Schreiben nach res:// ist zur Laufzeit nicht
	# zuverlaessig (im exportierten Spiel gar nicht moeglich) – deshalb
	# bleibt der Umweg ueber user:// der verlaessliche Weg, und der
	# Schritt hier ist nur ein Bonus fuer lokale Laeufe.
	if output_dir != "":
		# Auch hier die statische Variante verwenden.
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
		var file := FileAccess.open(output_dir.path_join("report.json"), FileAccess.WRITE)
		if file != null:
			file.store_string(payload)
			file.flush()
			file.close()

	_log_line("\n========================================")
	_log_line("ERGEBNIS: %d bestanden, %d fehlgeschlagen" % [passed, failed])
	_log_line("========================================")
	if failed > 0:
		_log_line("\nFehlgeschlagene Prüfungen:")
		for f in failures:
			_log_line("  " + f)
	# stdout explizit leeren, damit die Ausgabe nicht im Ausgabepuffer
	# verloren geht, wenn der Prozess direkt nach dem Testlauf endet.
	print("")
	if _log != null:
		_log.flush()
		_log.close()
		_log = null
	return 0 if failed == 0 else 1
