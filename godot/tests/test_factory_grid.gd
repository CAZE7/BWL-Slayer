extends RefCounted

## Tests des Betriebsgelaendes.
##
## Das Gelaende ist eine echte Ressource: Flaeche ist begrenzt, Zonen
## haben Regeln und Gebaeude belegen Rasterzellen. Ein Fehler in der
## Belegung fuehrt zu ueberlappenden Gebaeuden oder zu einer FLAECHE,
## die als belegt gemeldet wird, obwohl sie frei ist.

static func run(t: TestFramework) -> void:
	t.suite("Gelaende · Belegung")
	_test_occupy(t)
	t.suite("Gelaende · Zonen und Suche")
	_test_zones(t)


# ------------------------------------------------------------------
static func _test_occupy(t: TestFramework) -> void:
	var grid := FactoryGrid.new(24, 18)

	# Ein Gebaeude, das NICHT quadratisch ist und nicht bei (0,0)
	# beginnt. Genau hier ist der alte Fehler aufgefallen: die
	# innere Schleife lief bis origin_z + w statt bis origin_x + w.
	var ok := grid.occupy(5, 9, 3, 2, "halle-a")
	t.check_true("Gebaeude belegt", ok)

	# Alle belegten Zellen muessen zur Flaeche gehoeren.
	for z in range(9, 11):
		for x in range(5, 8):
			t.check_true(
				"Zelle (%d,%d) belegt" % [x, z],
				grid.occupied.has(Vector2i(x, z))
			)
			t.check_true(
				"Zelle (%d,%d) gehoert zum Gebaeude" % [x, z],
				grid.occupied[Vector2i(x, z)] == "halle-a"
			)

	# Und keine Zelle ausserhalb.
	t.check_true(
		"Keine Zelle links vom Gebaeude belegt",
		not grid.occupied.has(Vector2i(4, 9))
	)
	t.check_true(
		"Keine Zelle unter dem Gebaeude belegt",
		not grid.occupied.has(Vector2i(5, 11))
	)
	t.check_true(
		"Keine Zelle rechts daneben belegt",
		not grid.occupied.has(Vector2i(8, 9))
	)

	# Das Gebaeude muss jetzt blockieren.
	t.check_true(
		"Ueberlappung wird erkannt",
		not grid.is_area_free(5, 9, 3, 2)
	)
	t.check_true(
		"Ueberlappung wird abgelehnt",
		not grid.occupy(6, 9, 3, 2, "halle-b")
	)

	# Direkt daneben (ohne Ueberlappung) muss frei sein.
	t.check_true(
		"Direkt angrenzende Flaeche ist frei",
		grid.is_area_free(8, 9, 3, 2)
	)
	t.check_true(
		"Angrenzendes Gebaeude passt",
		grid.occupy(8, 9, 3, 2, "halle-b")
	)

	# Freigeben macht die Flaeche wieder benutzbar.
	grid.release("halle-a")
	t.check_true(
		"Nach Freigabe wieder frei",
		grid.is_area_free(5, 9, 3, 2)
	)
	t.check_true(
		"Freigabe loescht genau die eigenen Zellen",
		not grid.occupied.has(Vector2i(5, 9))
	)
	t.check_true(
		"Freigabe laesst fremde Zellen unberuehrt",
		grid.occupied.has(Vector2i(8, 9))
	)

	# Ausserhalb des Grundstuecks: nicht belegbar.
	t.check_true(
		"Rand links wird abgelehnt",
		not grid.occupy(-1, 0, 2, 2, "rand")
	)
	t.check_true(
		"Rand rechts wird abgelehnt",
		not grid.occupy(23, 0, 3, 2, "rand")
	)
	t.check_true(
		"Rand unten wird abgelehnt",
		not grid.occupy(0, 17, 2, 3, "rand")
	)


# ------------------------------------------------------------------
static func _test_zones(t: TestFramework) -> void:
	var grid := FactoryGrid.new(24, 18)
	# Ein Produktionsbereich, der gross genug fuer mehrere
	# 3x3-Gebaeude ist. find_free_spot verlangt, dass die GESAMTE
	# Flaeche in derselben Zone liegt.
	for z in range(2, 8):
		for x in range(2, 14):
			grid.set_zone(x, z, FactoryGrid.Zone.PRODUCTION)

	t.check_true(
		"Zone gesetzt",
		grid.zone_at(3, 2) == FactoryGrid.Zone.PRODUCTION
	)
	t.check_true(
		"Ausserhalb der Zone bleibt Gruen",
		grid.zone_at(10, 10) == FactoryGrid.Zone.GREEN
	)

	# Die Suche muss eine freie Stelle in der Zone finden.
	var spot := grid.find_free_spot(FactoryGrid.Zone.PRODUCTION, 3, 3)
	t.check_true("Freie Stelle gefunden", spot.x >= 0)
	t.check_true(
		"Gefundene Stelle liegt in der Zone",
		grid.zone_at(spot.x, spot.y) == FactoryGrid.Zone.PRODUCTION
	)
	t.check_true(
		"Gefundene Stelle ist frei",
		grid.is_area_free(spot.x, spot.y, 3, 3)
	)

	# Nach der Belegung muss die Suche weitergehen.
	t.check_true(
		"Belegung mit der gefundenen Stelle",
		grid.occupy(spot.x, spot.y, 3, 3, "maschine-1")
	)
	var spot2 := grid.find_free_spot(FactoryGrid.Zone.PRODUCTION, 3, 3)
	t.check_true(
		"Zweite Stelle weicht aus",
		spot2.x >= 0 and (spot2.x != spot.x or spot2.y != spot.y)
	)

	# Koordinaten-Umrechnung muss verlustfrei hin und her gehen.
	var world := grid.cell_to_world(7, 11)
	var back := grid.world_to_cell(world)
	t.check_true(
		"Koordinaten-Umrechnung stimmt",
		back == Vector2i(7, 11)
	)
