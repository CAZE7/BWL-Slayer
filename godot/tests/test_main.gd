extends Node

## Test-Einstiegspunkt für headless CI.
##
## Aufruf:  godot --headless --path godot res://tests/test_scene.tscn
##
## Wichtig: Die Tests laufen als ECHTER Projektlauf (Szene), nicht
## mit --script. Der Unterschied ist entscheidend: Im --script-Modus
## instanziiert Godot KEINE Autoloads. Jedes Skript, das EventBus,
## GameState, Simulation, SaveService oder Advisor referenziert,
## kompiliert dann nicht ("Identifier not found") - und jede
## Testfunktion, die eine Klasse aus so einem Skript benutzt, bricht
## mit "Nonexistent function 'new' in base 'GDScript'" STILL ab.
## Die abgebrochenen Pruefungen fehlen einfach im Ergebnis, ohne als
## Fehlschlag zu zaehlen. Genau das hat lange Zeit Dutzende
## Testfunktionen unsichtbar uebersprungen.
##
## Weitere Details zu Godot 4:
##
##  * `get_tree().quit(code)` setzt den Exit-Code des Prozesses.
##
##  * Ein Parse-Fehler im Skript fuehrt zu Exit-Code 0. Der CI-Schritt
##    prueft deshalb zusaetzlich, ob der Testbericht ueberhaupt
##    geschrieben wurde.
##
##  * stdout ist gepuffert. Bricht der Prozess ab, geht die Ausgabe
##    verloren. Der Testlauf schreibt seinen Verlauf deshalb direkt
##    in eine Datei nach user://.
##
##  * NICHT nach res://test-output.log schreiben! In diese Datei
##    leitet der CI-Schritt die Prozessausgabe um (tee). Ein
##    Schreiben von hier ueberschreibt sie von innen - Banner,
##    RUN-TESTS-Zeilen und alle SCRIPT-ERROR-Zeilen gehen verloren.

const LOG_PATH := "user://test-output.log"

# --- Testsuiten ---
#
# Wichtig: Die Suiten werden zur Laufzeit geladen, nicht per preload.
# Ein preload im Kopf dieses Skripts wuerde die Datei beim Laden
# einbinden – ein Fehler darin wuerde den gesamten Lauf still
# abbrechen.
const SUITE_PATHS := [
	"res://tests/test_bwl_engine.gd",
	"res://tests/test_engine_parity.gd",
	"res://tests/test_simulation.gd",
	"res://tests/test_factory_grid.gd",
	"res://tests/test_operations.gd",
	"res://tests/test_persistence.gd",
	"res://tests/test_learning.gd",
	"res://tests/test_advisor.gd",
	"res://tests/test_longrun.gd",
]


func _ready() -> void:
	# Erste Ausgabe: zeigt, ob die Szene ueberhaupt laeuft.
	print("RUN-TESTS: _ready() erreicht (Szenenlauf mit Autoloads)")
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
		if suite == null or not suite.can_instantiate():
			t.check_true("Suite ladbar: %s" % suite_path, false)
			continue
		suite.run(t)
		print("RUN-TESTS: Suite fertig: ", suite_path)

	# Frei erzeugte Nodes (Simulationen, Berater) aufraeumen - sonst
	# meldet der Prozess sie beim Beenden als geleakte Instanzen.
	t.free_tracked()

	# Der Bericht schliesst die Protokolldatei.
	var code := t.report("res://test-report")

	# Aus dem user://-Verzeichnis in den Projektordner kopieren, damit
	# der CI-Schritt die Datei direkt findet. Siehe Kopfkommentar:
	# ausdruecklich NICHT nach res://test-output.log.
	if log_file != null:
		var source := FileAccess.get_file_as_string(LOG_PATH)
		var target := FileAccess.open("res://test-framework.log", FileAccess.WRITE)
		if target != null:
			target.store_string(source)
			target.flush()
			target.close()

	if code == 0:
		print("\nAlle Tests bestanden.")
	else:
		print("\n%d Pruefungen fehlgeschlagen." % t.failed)

	# Beendet den Prozess mit dem Exit-Code.
	get_tree().quit(code)
