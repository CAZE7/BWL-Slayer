extends SceneTree

## Test-Einstiegspunkt für headless CI.
##
## Aufruf:  godot --headless --path godot --script res://tests/run_tests.gd
##
## Schreibt einen JSON-Bericht nach godot/test-report/report.json und
## beendet den Prozess mit Exit-Code 0 (alles grün) bzw. 1 (Fehler).
##
## Wichtige Details zu Godot 4:
##
##  * `quit(code)` beendet den Prozess mit dem angegebenen Exit-Code.
##    Aufrufe, die per `call_deferred` danach geplant werden, laufen
##    NICHT mehr – deshalb wird direkt gequittet.
##
##  * Ein Parse-Fehler im Skript fuehrt zu Exit-Code 0. Der CI-Schritt
##    prueft deshalb zusaetzlich, ob der Testbericht ueberhaupt
##    geschrieben wurde.
##
##  * stdout ist gepuffert. Bricht der Prozess ab, geht die Ausgabe
##    verloren. Der Testlauf schreibt seinen Verlauf deshalb direkt
##    in eine Datei nach user://.

const LOG_PATH := "user://test-output.log"

# --- Testsuiten ---
#
# Wichtig: Die Suiten werden zur Laufzeit geladen, nicht per preload.
# Ein preload im Kopf eines SceneTree-Skripts wuerde die Datei beim
# Laden des Skripts einbinden – ein Fehler darin wuerde den gesamten
# Lauf still abbrechen.
const SUITE_PATHS := [
	"res://tests/test_bwl_engine.gd",
	"res://tests/test_engine_parity.gd",
	"res://tests/test_simulation.gd",
	"res://tests/test_factory_grid.gd",
	"res://tests/test_operations.gd",
	"res://tests/test_persistence.gd",
	"res://tests/test_learning.gd",
]


func _init() -> void:
	# Erste Ausgabe: zeigt, ob das Skript ueberhaupt laeuft.
	print("RUN-TESTS: _init() erreicht")
	# Das Verzeichnis muss existieren, bevor geschrieben werden kann.
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(LOG_PATH.get_base_dir()))
	# Protokolldatei anlegen. stdout allein ist nicht verlaesslich.
	var log_file := FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if log_file == null:
		print("WARNUNG: Protokolldatei nicht anlegbar – Ausgabe nur ueber stdout.")

	print("RUN-TESTS: Logdatei: ", log_file != null)

	var t := TestFramework.new()
	if log_file != null:
		t.attach_log(log_file)
	print("RUN-TESTS: Framework bereit")

	# Alle Suiten nacheinander ausfuehren. Jede Suite meldet ihren
	# Namen, damit bei einem Abbruch klar ist, wo es passiert ist.
	for suite_path in SUITE_PATHS:
		print("RUN-TESTS: Suite startet: ", suite_path)
		var suite: GDScript = load(suite_path)
		if suite == null:
			t.check_true("Suite ladbar: %s" % suite_path, false)
			continue
		suite.run(t)
		print("RUN-TESTS: Suite fertig: ", suite_path)

	# Der Bericht schliesst die Protokolldatei.
	var code := t.report("res://test-report")

	# Aus dem user://-Verzeichnis in den Projektordner kopieren, damit
	# der CI-Schritt die Datei direkt findet.
	if log_file != null:
		var source := FileAccess.get_file_as_string(LOG_PATH)
		var target := FileAccess.open("res://test-output.log", FileAccess.WRITE)
		if target != null:
			target.store_string(source)
			target.flush()
			target.close()

	if code == 0:
		print("\nAlle Tests bestanden.")
	else:
		print("\n%d Pruefungen fehlgeschlagen." % t.failed)

	# Beendet den Prozess mit dem Exit-Code. Deferred aufrufe wuerden
	# danach nicht mehr ausgefuehrt.
	quit(code)
