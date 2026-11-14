extends RefCounted

## Tests des Save-Systems: Versionierung, Migration, Sanitisierung,
## atomare Schreibvorgänge, Backups und Wiederherstellung.


static func run(t: TestFramework) -> void:
	t.suite("Persistenz · Versionierung & Migration")
	_test_migration(t)
	t.suite("Persistenz · Sanitisierung")
	_test_sanitize(t)
	t.suite("Persistenz · Dateioperationen")
	_test_files(t)
	t.suite("Persistenz · Spielstand-Roundtrip")
	_test_game_state_roundtrip(t)


# ------------------------------------------------------------------
# Der Spielstand muss die Simulation UND den Lernfortschritt
# unveraendert ueberstehen. Sonst waere der Fortschritt verloren.
# ------------------------------------------------------------------
static func _test_game_state_roundtrip(t: TestFramework) -> void:
	var progress := PlayerProgress.new()
	progress.mark_concept_solved("W1", 0, 0)
	progress.complete_stage("W1", 0, 120)
	progress.xp = 480

	var state := GameStateStore.new()
	state.player_name = "Test CFO"
	state.progress = progress
	state.settings["reduced_motion"] = true

	var data := state.to_dict()
	var restored := GameStateStore.new()
	restored.from_dict(data)

	t.check_true("Spielername erhalten", restored.player_name == "Test CFO")
	t.check_approx("XP erhalten", float(restored.progress.xp), 480.0, 0.01)
	t.check_true(
		"Stufenfortschritt erhalten",
		restored.progress.is_stage_done("W1", 0)
	)
	t.check_true(
		"Teilaufgabe erhalten",
		restored.progress.is_concept_solved("W1", 0, 0)
	)
	t.check_true(
		"Einstellung erhalten",
		bool(restored.settings.get("reduced_motion", false))
	)

	# Die Simulation muss ihren Zustand ebenfalls behalten.
	var sim := SimulationEngine.new()
	sim.day = 137
	sim.year = 2
	sim.economy.cash = 43210.0
	sim.economy.fixed_assets = 12000.0
	sim.inventory_material = 750.0

	var sim_data := sim.to_dict()
	var sim2 := SimulationEngine.new()
	sim2.from_dict(sim_data)

	t.check_approx("Tag erhalten", float(sim2.day), 137.0, 0.01)
	t.check_approx("Jahr erhalten", float(sim2.year), 2.0, 0.01)
	t.check_approx("Kasse erhalten", sim2.economy.cash, 43210.0, 0.01)
	t.check_approx("Anlagevermoegen erhalten", sim2.economy.fixed_assets, 12000.0, 0.01)
	t.check_approx("Materialbestand erhalten", sim2.inventory_material, 750.0, 0.01)

	# Ein Reset setzt alles auf den Ausgangszustand zurueck.
	sim2.reset()
	t.check_true("Reset setzt den Tag zurueck", sim2.day == 0)
	t.check_approx("Reset setzt die Kasse zurueck", sim2.economy.cash, 50000.0, 0.01)
	t.check_true("Reset legt die Startanlage an", not sim2.machines.is_empty())


# ------------------------------------------------------------------
static func _test_migration(t: TestFramework) -> void:
	# v1: alter Spielstand ohne Karrierefelder
	var legacy_v1 := {
		"id": "legacy-1",
		"playerName": "Alt-Spieler",
		"cash": 12345.0,
		"worlds": {"W1": {"stages": [true, false, false], "points": [10, 0, 0]}},
	}
	var migrated := SaveSystem.migrate_save(legacy_v1, 1)
	t.check_approx("Migration: Kapital übernommen", migrated.economy.cash, 12345.0, 0.01)
	t.check_true("Migration: XP initialisiert", migrated.xp == 0)
	t.check_true("Migration: Welten erhalten", migrated.worlds.has("W1"))
	t.check_true("Migration: Stufe 1 erhalten", bool(migrated.worlds["W1"]["stages"][0]))
	t.check_true("Migration: Version gesetzt", migrated.version == SaveSystem.CURRENT_VERSION)

	# v2 → v3: Statistiken, Skills, Unternehmen
	var legacy_v2 := {
		"id": "legacy-2",
		"xp": 500,
		"reputation": 30,
		"economy": {"cash": 80000.0},
		"worlds": {},
	}
	var migrated2 := SaveSystem.migrate_save(legacy_v2, 2)
	t.check_approx("Migration v2: XP", migrated2.xp, 500.0, 0.01)
	t.check_approx("Migration v2: Reputation", migrated2.reputation, 30.0, 0.01)
	t.check_approx("Migration v2: Kapital", migrated2.economy.cash, 80000.0, 0.01)

	# Bereits aktuelle Version: unverändert durchreichen
	var current := {
		"id": "cur-1", "xp": 1234, "reputation": 55,
		"economy": {"cash": 60000.0}, "worlds": {},
	}
	var migrated3 := SaveSystem.migrate_save(current, SaveSystem.CURRENT_VERSION)
	t.check_approx("Aktuelle Version: XP", migrated3.xp, 1234.0, 0.01)
	t.check_approx("Aktuelle Version: Reputation", migrated3.reputation, 55.0, 0.01)


# ------------------------------------------------------------------
static func _test_sanitize(t: TestFramework) -> void:
	# Defekte Werte müssen repariert werden, nicht crashen
	var broken := {
		"id": "broken",
		"xp": "nicht-eine-zahl",
		"reputation": 5000.0,
		"economy": {"cash": "kaputt", "debt": -100.0},
		"worlds": {"W1": {"stages": [true, "yes", false], "points": [1, 2, 3]}},
	}
	var fixed := SaveSystem.sanitize_save(broken)
	t.check_true("Sanitize: XP numerisch", fixed.xp >= 0.0)
	t.check_approx("Sanitize: Reputation begrenzt", fixed.reputation, 100.0, 0.01)
	t.check_true("Sanitize: Kapital numerisch", fixed.economy.cash >= 0.0)
	t.check_approx("Sanitize: Schulden nicht negativ", fixed.economy.debt, 0.0, 0.01)
	t.check_true("Sanitize: Stufen boolesch", typeof(fixed.worlds["W1"]["stages"][1]) == TYPE_BOOL)

	# Komplett leerer Spielstand
	var empty := SaveSystem.sanitize_save({})
	t.check_true("Sanitize: leerer Stand spielbar", empty.economy.cash >= 0.0)
	t.check_true("Sanitize: Statistik vorhanden", empty.statistics.has("questions_solved"))


# ------------------------------------------------------------------
static func _test_files(t: TestFramework) -> void:
	# Test in einem temporären Verzeichnis unter user://
	var dir := "user://bwl_test_saves"
	var store := SaveStore.new(dir)

	# Ordner anlegen
	store.ensure_root()

	var save := SaveSystem.create_default_save("slot-test", "Testprofil")
	save.xp = 250.0
	save.economy.cash = 77777.0

	# Schreiben und Laden
	var ok := store.write_slot(save)
	t.check_true("Spielstand geschrieben", ok)

	var loaded: Variant = store.load_slot("slot-test")
	t.check_not_null("Spielstand geladen", loaded)
	if loaded != null:
		t.check_approx("Roundtrip: Kapital", float(loaded["economy"]["cash"]), 77777.0, 0.01)
		t.check_approx("Roundtrip: XP", float(loaded["xp"]), 250.0, 0.01)
		t.check_true("Roundtrip: Name", String(loaded["player_name"]) == "Testprofil")

	# Versionierung: nach erneutem Schreiben existiert ein Backup
	var save2 := save.duplicate(true)
	save2.xp = 500.0
	store.write_slot(save2)
	var backups := store.list_backups("slot-test")
	t.check_true("Backup angelegt", backups.size() >= 1)

	# Wiederherstellung aus Backup
	var restored: Variant = store.restore_backup("slot-test", backups[0])
	t.check_not_null("Backup wiederhergestellt", restored)

	# Pfad-Traversal muss abgewiesen werden
	var traversal: Variant = store.restore_backup("slot-test", "../../etc/passwd")
	t.check_null("Traversal abgewiesen", traversal)

	# Nicht vorhandener Spielstand
	var missing: Variant = store.load_slot("gibt-es-nicht")
	t.check_null("Fehlender Spielstand = null", missing)

	# Liste der Spielstände
	var slots := store.list_slots()
	t.check_true("Spielstände gelistet", slots.size() >= 1)

	# Aufräumen
	store.delete_slot("slot-test")
	var after_delete: Variant = store.load_slot("slot-test")
	t.check_null("Spielstand gelöscht", after_delete)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir))
