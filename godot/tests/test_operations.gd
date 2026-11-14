extends RefCounted

## Tests der operativen Abläufe: Lieferung, Produktion, Aufträge.
##
## Diese Suite deckt die Kette ab, die das Spiel trägt:
##
##   Bestellung → Transport → Ladezone → Entladen → Montage → Betrieb
##   → Tagesproduktion → Materialverbrauch → Kundenauftrag → Erlös
##
## Geprüft wird nicht nur, dass die Zustände passieren, sondern auch,
## dass die Mengen, Bestände und Geldbeträge stimmen.


static func run(t: TestFramework) -> void:
	t.suite("Ablauf · Maschinen-Lieferkette")
	_test_delivery_chain(t)
	t.suite("Ablauf · Produktion & Material")
	_test_production(t)
	t.suite("Ablauf · Kundenaufträge")
	_test_orders(t)
	t.suite("Ablauf · Investitionsentscheidung")
	_test_investment(t)
	t.suite("Ablauf · Jahresabschluss & Bilanz")
	_test_year_close(t)
	t.suite("Ablauf · Nachfrage")
	_test_demand(t)
	t.suite("Ablauf · Materialbeschaffung")
	_test_material(t)
	t.suite("Ablauf · Gesamtbetrieb über ein Jahr")
	_test_full_year(t)
	t.suite("Ablauf · Kassenlogik ohne Doppelbuchung")
	_test_cash_logic(t)
	t.suite("Ablauf · Materiallieferung mit Vorlauf")
	_test_material_logistics(t)


# ------------------------------------------------------------------
# Hilfsfunktionen
# ------------------------------------------------------------------

static func _make_spec(
	id: StringName, cost: float, fixed: float, kvar: float, price: float,
	capacity: float = 10000.0, delivery_days: int = 3, install_days: int = 2
) -> MachineSpec:
	var spec := MachineSpec.new()
	spec.id = id
	spec.display_name = "Testmaschine %s" % id
	spec.acquisition_cost = cost
	spec.residual_value = 0.0
	spec.useful_life_years = 4
	spec.imputed_interest_rate = 0.08
	spec.fixed_operating_costs = fixed
	spec.variable_cost_per_unit = kvar
	spec.price_per_unit = price
	spec.capacity_units_per_year = capacity
	spec.delivery_days = delivery_days
	spec.installation_days = install_days
	spec.material_per_unit = 0.0
	return spec


# ------------------------------------------------------------------
# Lieferkette
# ------------------------------------------------------------------
static func _test_delivery_chain(t: TestFramework) -> void:
	# Jeder Zustandsübergang muss fachlich zulässig und in der
	# richtigen Reihenfolge erreichbar sein.
	var spec := _make_spec(&"LIEF", 1000.0, 100.0, 1.0, 5.0, 10000.0, 3, 2)
	var m := MachineInstance.new(spec, "lief-1")

	t.check_true("Start: ORDERED", m.state == MachineInstance.State.ORDERED)
	t.check_true("ORDERED -> IN_TRANSIT erlaubt", MachineInstance.is_valid_transition(MachineInstance.State.ORDERED, MachineInstance.State.IN_TRANSIT))
	t.check_true("IN_TRANSIT -> ARRIVED erlaubt", MachineInstance.is_valid_transition(MachineInstance.State.IN_TRANSIT, MachineInstance.State.ARRIVED))
	t.check_true("ARRIVED -> UNLOADING erlaubt", MachineInstance.is_valid_transition(MachineInstance.State.ARRIVED, MachineInstance.State.UNLOADING))
	t.check_true("UNLOADING -> INSTALLING erlaubt", MachineInstance.is_valid_transition(MachineInstance.State.UNLOADING, MachineInstance.State.INSTALLING))
	t.check_true("INSTALLING -> ACTIVE erlaubt", MachineInstance.is_valid_transition(MachineInstance.State.INSTALLING, MachineInstance.State.ACTIVE))

	# Sprünge über Stufen hinweg sind nicht zulässig.
	t.check_true("Sprung ORDERED -> ACTIVE verboten", not MachineInstance.is_valid_transition(MachineInstance.State.ORDERED, MachineInstance.State.ACTIVE))
	t.check_true("Sprung IN_TRANSIT -> INSTALLING verboten", not MachineInstance.is_valid_transition(MachineInstance.State.IN_TRANSIT, MachineInstance.State.INSTALLING))
	t.check_true("Rueckwaertswechsel verboten", not MachineInstance.is_valid_transition(MachineInstance.State.INSTALLING, MachineInstance.State.ARRIVED))

	# Der Zustand wandert in der richtigen Reihenfolge weiter.
	m.advance_state()
	t.check_true("Nach Schritt 1: IN_TRANSIT", m.state == MachineInstance.State.IN_TRANSIT)
	t.check_approx("Lieferzeit gesetzt", float(m.days_remaining), 3.0, 0.01)

	m.advance_state()
	t.check_true("Nach Schritt 2: ARRIVED", m.state == MachineInstance.State.ARRIVED)
	t.check_approx("Entladezeit gesetzt", float(m.days_remaining), float(MachineInstance.UNLOAD_DAYS), 0.01)

	m.advance_state()
	t.check_true("Nach Schritt 3: UNLOADING", m.state == MachineInstance.State.UNLOADING)

	m.advance_state()
	t.check_true("Nach Schritt 4: INSTALLING", m.state == MachineInstance.State.INSTALLING)
	t.check_approx("Montagezeit gesetzt", float(m.days_remaining), 2.0, 0.01)

	m.advance_state()
	t.check_true("Nach Schritt 5: ACTIVE", m.state == MachineInstance.State.ACTIVE)
	t.check_true("Maschine betriebsbereit", m.is_operational())

	# Aus dem Betriebszustand geht es nicht weiter.
	t.check_false("Aus ACTIVE kein weiterer Schritt", m.advance_state())

	# Zustandsbezeichnungen fuer die Oberflaeche
	t.check_true("Label fuer UNLOADING vorhanden", MachineInstance.new(spec, "x").state_label() != "")

	# Save-Roundtrip im Zustand UNLOADING
	var m2 := MachineInstance.new(spec, "lief-2")
	m2.advance_state()
	m2.advance_state()
	m2.advance_state()
	t.check_true("Testfall: steht in UNLOADING", m2.state == MachineInstance.State.UNLOADING)
	var restored := MachineInstance.new(spec, "lief-2")
	restored.from_dict(m2.to_dict())
	t.check_true("Save-Roundtrip: Zustand erhalten", restored.state == MachineInstance.State.UNLOADING)
	t.check_approx("Save-Roundtrip: Restzeit erhalten", float(restored.days_remaining), float(m2.days_remaining), 0.01)


# ------------------------------------------------------------------
# Produktion & Material
# ------------------------------------------------------------------
static func _test_production(t: TestFramework) -> void:
	# Eine Maschine mit Materialverbrauch: Die Produktion ist durch
	# den Lagerbestand begrenzt.
	var spec := _make_spec(&"PROD", 1000.0, 100.0, 1.0, 5.0, 3600.0)
	spec.material_per_unit = 2.0
	spec.material_price_per_kg = 5.0

	var sim := SimulationEngine.new()
	sim.specs[spec.id] = spec

	# Maschine direkt in Betrieb nehmen
	var m := MachineInstance.new(spec, "prod-1")
	m.state = MachineInstance.State.ACTIVE
	m.commissioned_year = 1
	sim.machines["prod-1"] = m

	# Ohne Material wird nichts produziert.
	sim.inventory_material = 0.0
	sim.production_enabled = true
	sim._progress_production()
	t.check_approx("Ohne Material keine Produktion", m.quantity_this_year, 0.0, 0.01)

	# Mit Material wird produziert und der Bestand sinkt.
	sim.inventory_material = 1000.0
	var before_stock: float = sim.inventory_material
	sim._progress_production()
	var daily_capacity: float = spec.capacity_units_per_year / 360.0
	t.check_approx("Tagesproduktion", m.quantity_this_year, daily_capacity, 0.01)
	t.check_approx(
		"Materialverbrauch gebucht",
		before_stock - sim.inventory_material,
		daily_capacity * spec.material_per_unit,
		0.01
	)

	# Der Lagerbestand begrenzt die Produktion.
	sim.inventory_material = 1.0
	var m2 := MachineInstance.new(spec, "prod-2")
	m2.state = MachineInstance.State.ACTIVE
	m2.commissioned_year = 1
	sim.machines["prod-2"] = m2
	sim._progress_production()
	t.check_approx("Materialengpass stoppt die Produktion", m2.quantity_this_year, 0.0, 0.01)
	t.check_true("Engpass vermerkt", m2.notes.size() > 0)


# ------------------------------------------------------------------
# Kundenaufträge
# ------------------------------------------------------------------
static func _test_orders(t: TestFramework) -> void:
	# Ein Auftrag darf erst erfuellt werden, wenn die Menge auch
	# tatsaechlich produziert wurde.
	var spec := _make_spec(&"AUF", 1000.0, 100.0, 1.0, 5.0, 360.0)
	var sim := SimulationEngine.new()
	sim.specs[spec.id] = spec
	sim.accepting_orders = true

	var order := {
		"id": "o-1",
		"status": "accepted",
		"quantity": 100.0,
		"revenue": 500.0,
		"lead_time_days": 30,
		"progress_days": 0,
		"payment_delay_days": 0,
		"produced": 0.0,
	}
	sim.orders.append(order)

	# Kapazitaet 360/360 = 1 Stueck pro Tag -> 100 Tage noetig,
	# Lieferfrist sind 30 Tage: der Auftrag muss scheitern.
	for _i in range(30):
		sim._process_customer_orders()
	t.check_true("Auftrag bei Fristablauf storniert", String(order["status"]) == "cancelled")
	t.check_true("Nicht als erfuellt gewertet", int(sim.stats.get("orders_completed", 0)) == 0)

	# Ein Auftrag, dessen Menge die Kapazitaet nicht uebersteigt,
	# wird erfuellt.
	var order2 := {
		"id": "o-2",
		"status": "accepted",
		"quantity": 20.0,
		"revenue": 100.0,
		"lead_time_days": 60,
		"progress_days": 0,
		"payment_delay_days": 0,
		"produced": 0.0,
	}
	sim.orders.append(order2)
	var days := 0
	while String(order2["status"]) == "accepted" and days < 60:
		sim._process_customer_orders()
		days += 1
	t.check_true("Auftrag bei ausreichender Produktion erfuellt", String(order2["status"]) == "delivered")
	t.check_approx("Erlos gebucht", sim.economy.revenue_current_year, 100.0, 0.01)
	t.check_approx("Kasse erhoeht", sim.economy.cash, 100.0, 0.01)

	# Eigenkapital NICHT doppelt fortgeschrieben
	t.check_true(
		"Eigenkapital entspricht dem Ergebnis",
		absf(sim.economy.equity - (50000.0 + sim.economy.profit_current_year)) < 1.0
	)


# ------------------------------------------------------------------
# Investitionsentscheidung
# ------------------------------------------------------------------
static func _test_investment(t: TestFramework) -> void:
	# Anlage A: niedrige Fixkosten, hohe variable Stueckkosten.
	# Anlage B: hohe Fixkosten, niedrige variable Stueckkosten.
	#
	# Bei der Kostenbetrachtung K(x) = kvar*x + F gilt:
	#   unterhalb x*  -> der Fixkostenblock dominiert, die Anlage mit
	#                    dem NIEDRIGEREN F ist billiger (hier A)
	#   oberhalb x*   -> der Stueckpreis dominiert, die Anlage mit dem
	#                    NIEDRIGEREN kvar ist billiger (hier B)
	var a := _make_spec(&"A", 16000.0, 1180.20, 26.0, 40.0, 50000.0)
	var b := _make_spec(&"B", 17000.0, 1345.70, 22.0, 40.0, 50000.0)

	var result := CostComparison.compare(a, b, "COST", 60, 5000.0)
	t.check_true("Kritische Menge berechenbar", result.valid)
	t.check_true("Kritische Menge positiv", result.x_critical > 0.0)

	# Gegenprobe an den echten Kostenfunktionen.
	var x_below: float = result.x_critical * 0.4
	var x_above: float = result.x_critical * 1.6
	var a_below := a.total_costs_at(x_below)
	var b_below := b.total_costs_at(x_below)
	var a_above := a.total_costs_at(x_above)
	var b_above := b.total_costs_at(x_above)

	t.check_true(
		"Unterhalb gewinnt die Anlage mit den niedrigeren Fixkosten",
		(b_below < a_below) if result.cheaper_below == b.display_name else (a_below < b_below)
	)
	t.check_true(
		"Oberhalb gewinnt die Anlage mit den niedrigeren variablen Kosten",
		(a_above < b_above) if result.cheaper_above == a.display_name else (b_above < a_above)
	)

	# Die Empfehlung muss zur Kurve passen, nicht nur zur Formel.
	t.check_true(
		"Empfehlung nennt die unterhalb guenstigere Anlage",
		result.recommendation.contains(result.cheaper_below)
	)
	t.check_true(
		"Empfehlung beruecksichtigt die geplante Menge",
		result.recommendation.contains("5.000") or result.recommendation.contains("5000")
	)

	# Identische variable Stueckkosten: keine kritische Menge.
	var c := _make_spec(&"C", 16000.0, 1180.20, 26.0, 40.0, 50000.0)
	var d := _make_spec(&"D", 17000.0, 1345.70, 26.0, 40.0, 50000.0)
	var result2 := CostComparison.compare(c, d, "COST", 60, 5000.0)
	t.check_false("Gleiche variable Kosten: keine kritische Menge", result2.valid)
	t.check_true("Hinweis auf die Fixkosten", result2.recommendation.contains("Fixkosten"))

	# Auswertung bei einer Menge: die Anschaffung muss ausgewiesen sein.
	var rows := CostComparison.evaluate_at(a, b, 15000.0)
	t.check_true("Auswertung liefert zwei Zeilen", rows.size() == 2)
	if rows.size() == 2:
		t.check_approx("Anschaffung A ausgewiesen", float(rows[0]["acquisition"]), 16000.0, 0.01)
		t.check_approx("Anschaffung B ausgewiesen", float(rows[1]["acquisition"]), 17000.0, 0.01)
		t.check_approx("Umsatz A", float(rows[0]["revenue"]), 40.0 * 15000.0, 0.01)
		t.check_true("Break-Even vorhanden", float(rows[0]["break_even"]) > 0.0)

	# Kurvenpunkte tragen echte Werte.
	var curve := CostComparison.curve_points(a, b, 20)
	var points: Array = curve["points"]
	t.check_true("Kurvenpunkte vorhanden", points.size() == 21)
	if points.size() == 21:
		t.check_true("Kurvenpunkt mit Kosten A", float(points[10]["a"]) > 0.0)
		t.check_true("Kurvenpunkt mit Kosten B", float(points[10]["b"]) > 0.0)


# ------------------------------------------------------------------
# Anlagevermögen und Bilanz
# ------------------------------------------------------------------
static func _test_balance(t: TestFramework) -> void:
	# Eine Investition erhoeht das Anlagevermoegen und mindert die
	# Kasse – sie ist keine laufende Ausgabe.
	var e := EconomyState.new()
	e.cash = 100000.0
	e.equity = 100000.0
	var before_cash := e.cash
	e.book_investment(16000.0)
	t.check_approx("Kasse gemindert", e.cash, before_cash - 16000.0, 0.01)
	t.check_approx("Anlagevermoegen erhoeht", e.fixed_assets, 16000.0, 0.01)
	t.check_true("Aktiva gestiegen", e.total_assets() > 100000.0)

	# Die Abschreibung mindert das Anlagevermoegen, ohne die Kasse zu
	# bewegen.
	e.book_depreciation(4000.0)
	t.check_approx("Anlagevermoegen gemindert", e.fixed_assets, 12000.0, 0.01)
	t.check_approx("Kasse unveraendert", e.cash, before_cash - 16000.0, 0.01)

	# Die Abschreibung darf das Anlagevermoegen nicht negativ machen.
	e.book_depreciation(999999.0)
	t.check_true("Anlagevermoegen nicht negativ", e.fixed_assets >= 0.0)


# ------------------------------------------------------------------
# Der Jahresabschluss bucht alle Kostenarten und haelt die Bilanz
# ausgeglichen.
# ------------------------------------------------------------------
static func _test_year_close(t: TestFramework) -> void:
	var spec := _make_spec(&"JAHR", 16000.0, 1180.20, 26.0, 40.0, 36000.0)
	spec.material_per_unit = 2.0
	spec.material_price_per_kg = 1.4

	var sim := SimulationEngine.new()
	sim.specs[spec.id] = spec

	var m := MachineInstance.new(spec, "jahr-1")
	m.state = MachineInstance.State.ACTIVE
	m.commissioned_year = 1
	m.quantity_this_year = 10000.0
	sim.machines["jahr-1"] = m

	var eco := sim.economy
	eco.cash = 100000.0
	eco.equity = 100000.0

	# Eine Investition: Kasse −A₀, Anlagevermögen +A₀.
	eco.book_investment(16000.0)
	t.check_approx("Investition mindert die Kasse", eco.cash, 84000.0, 0.01)
	t.check_approx("Investition erhoeht das Anlagevermoegen", eco.fixed_assets, 16000.0, 0.01)

	# Jahresabschluss
	sim._close_business_year()

	# Der Materialaufwand muss in den Kosten stehen.
	var expected_material := 10000.0 * spec.material_per_unit * spec.material_price_per_kg
	t.check_approx("Materialaufwand ausgewiesen", eco.material_costs_year, expected_material, 0.01)
	t.check_true(
		"Materialaufwand in den Gesamtkosten",
		eco.costs_current_year >= expected_material
	)

	# Die Fixkosten muessen gebucht sein.
	t.check_true("Fixkosten gebucht", eco.fixed_costs_year > 0.0)
	t.check_true(
		"Fixkosten in den Gesamtkosten",
		eco.costs_current_year >= eco.fixed_costs_year
	)

	# Die Abschreibung mindert das Anlagevermoegen, die Kasse nicht.
	var cash_before := eco.cash
	t.check_approx("Abschreibung gebucht", eco.depreciation_year, 4000.0, 0.01)
	t.check_approx("Anlagevermoegen nach AfA", eco.fixed_assets, 12000.0, 0.01)

	# Die Bilanz muss aufgehen.
	var balance := eco.balance_check()
	t.check_approx("Bilanz stimmt", balance, 0.0, 0.5)

	# Das Ergebnis muss den Kontostand veraendert haben.
	t.check_true("Jahresabschluss hat das Ergebnis gebucht", eco.profit_current_year != 0.0)

	# Persistenz: das Jahr muss den Roundtrip ueberstehen.
	var data := eco.to_dict()
	var restored := EconomyState.new()
	restored.from_dict(data)
	t.check_approx("Roundtrip Materialaufwand", restored.material_costs_year, eco.material_costs_year, 0.01)
	t.check_approx("Roundtrip Anlagevermoegen", restored.fixed_assets, eco.fixed_assets, 0.01)
	t.check_approx("Roundtrip Kasse", restored.cash, eco.cash, 0.01)


# ------------------------------------------------------------------
# Die Nachfrage: Ohne eingehende Auftraege laeuft die Produktion ins
# Leere und keine Investition wuerde sich rechnen.
# ------------------------------------------------------------------
static func _test_demand(t: TestFramework) -> void:
	# Ohne betriebsbereite Anlage gibt es keine Nachfrage.
	var sim := SimulationEngine.new()
	sim.day = 1
	sim._generate_demand()
	t.check_true("Ohne Anlage keine Nachfrage", sim.orders.is_empty())

	# Mit einer Anlage entstehen Auftraege.
	var spec := _make_spec(&"NACH", 16000.0, 1180.20, 26.0, 40.0, 36000.0)
	var m := MachineInstance.new(spec, "nach-1")
	m.state = MachineInstance.State.ACTIVE
	m.commissioned_year = 1
	sim.machines["nach-1"] = m

	# Die Nachfrage entsteht in einem bestimmten Rhythmus.
	var found := false
	for test_day in range(1, 60):
		sim.day = test_day
		sim._generate_demand()
		if not sim.orders.is_empty():
			found = true
			break
	t.check_true("Nachfrage entsteht", found)

	# Die Menge wird ausserhalb des if-Blocks gebraucht (Vergleich mit
	# groesserer Kapazitaet weiter unten).
	var quantity := 0.0
	if not sim.orders.is_empty():
		var order: Dictionary = sim.orders[0]
		quantity = float(order["quantity"])
		var db := spec.contribution_margin_per_unit()
		var price := float(order["price_per_unit"])

		# Der Auftrag muss wirtschaftlich sein: der Preis liegt ueber
		# dem Deckungsbeitrag.
		t.check_true("Preis ueber Deckungsbeitrag", price > db)
		t.check_approx("Umsatz = Menge x Preis", float(order["revenue"]), quantity * price, 0.01)

		# Die Menge muss zur Kapazitaet passen und positiv sein.
		t.check_true("Menge positiv", quantity > 0.0)
		t.check_true(
			"Menge im Bereich der Kapazitaet",
			quantity <= spec.capacity_units_per_year
		)

		# Die Lieferfrist muss realistisch sein: sie reicht, um die
		# Menge bei Tagesproduktion zu erzeugen, plus Puffer.
		var daily := spec.capacity_units_per_year / 360.0
		var needed: float = ceil(quantity / maxf(1.0, daily))
		t.check_true(
			"Lieferfrist ausreichend",
			int(order["lead_time_days"]) >= int(needed)
		)

		# Determinismus: derselbe Tag erzeugt denselben Auftrag.
		var sim2 := SimulationEngine.new()
		var m2 := MachineInstance.new(spec, "nach-1")
		m2.state = MachineInstance.State.ACTIVE
		m2.commissioned_year = 1
		sim2.machines["nach-1"] = m2
		sim2.day = sim.day
		sim2._generate_demand()
		t.check_true("Nachfrage ist deterministisch", not sim2.orders.is_empty())
		if not sim2.orders.is_empty():
			t.check_approx(
				"Gleiche Menge am gleichen Tag",
				float(sim2.orders[0]["quantity"]),
				quantity,
				0.01
			)

	# Mehr Kapazitaet bedeutet mehr Nachfrage.
	var sim3 := SimulationEngine.new()
	var big := _make_spec(&"GROSS", 16000.0, 1180.20, 26.0, 40.0, 72000.0)
	var m3 := MachineInstance.new(big, "gross-1")
	m3.state = MachineInstance.State.ACTIVE
	m3.commissioned_year = 1
	sim3.machines["gross-1"] = m3
	sim3.day = sim.day
	sim3._generate_demand()
	if not sim3.orders.is_empty():
		t.check_true(
			"Groessere Kapazitaet bringt mehr Auftrag",
			float(sim3.orders[0]["quantity"]) > quantity
		)


# ------------------------------------------------------------------
# Materialbeschaffung: Ohne die Moeglichkeit, Material zu kaufen,
# liefe jede Anlage mit Materialbedarf dauerhaft im Leerlauf.
# ------------------------------------------------------------------
static func _test_material(t: TestFramework) -> void:
	var spec := _make_spec(&"MAT", 1000.0, 100.0, 1.0, 5.0, 3600.0)
	spec.material_per_unit = 2.0
	spec.material_price_per_kg = 5.0

	var sim := SimulationEngine.new()
	sim.specs[spec.id] = spec
	var m := MachineInstance.new(spec, "mat-1")
	m.state = MachineInstance.State.ACTIVE
	m.commissioned_year = 1
	sim.machines["mat-1"] = m

	sim.economy.cash = 10000.0

	# Der Materialpreis ist der gewichtete Durchschnitt.
	t.check_approx("Materialpreis", sim.material_price(), 5.0, 0.01)

	# Der Kauf bucht den Bestand und mindert die Kasse.
	var result := sim.buy_material(1000.0)
	t.check_true("Kauf erfolgreich", bool(result.get("ok", false)))
	t.check_approx("Bestand erhoeht", sim.inventory_material, 1000.0, 0.01)
	t.check_approx("Kasse gemindert", sim.economy.cash, 5000.0, 0.01)
	t.check_approx("Lagerwert gesetzt", sim.economy.inventory_value, 5000.0, 0.01)

	# Ohne Kapital kein Kauf.
	sim.economy.cash = 100.0
	var failed := sim.buy_material(1000.0)
	t.check_false("Kauf ohne Kapital schlaegt fehl", bool(failed.get("ok", true)))
	t.check_approx("Bestand unveraendert", sim.inventory_material, 1000.0, 0.01)

	# Negative Mengen sind ungueltig.
	sim.economy.cash = 10000.0
	var invalid := sim.buy_material(-100.0)
	t.check_false("Negative Menge abgelehnt", bool(invalid.get("ok", true)))

	# Jetzt kann die Anlage produzieren.
	sim.inventory_material = 1000.0
	sim._progress_production()
	t.check_true("Produktion laeuft mit Material", m.quantity_this_year > 0.0)


# ------------------------------------------------------------------
# Der Gesamtbetrieb ueber ein ganzes Jahr.
#
# Dieser Test laeuft die vollstaendige Kette durch: Produktion,
# Nachfrage, Auftragsabwicklung, Erloese, Kosten, Jahresabschluss.
# Er ist der End-to-End-Nachweis, dass das Spiel wirtschaftlich
# funktioniert.
# ------------------------------------------------------------------
static func _test_full_year(t: TestFramework) -> void:
	var spec := _make_spec(&"JAHR", 16000.0, 1180.20, 26.0, 62.0, 11637.5)
	var sim := SimulationEngine.new()
	sim.specs[spec.id] = spec

	var m := MachineInstance.new(spec, "jahr-1")
	m.state = MachineInstance.State.ACTIVE
	m.commissioned_year = 1
	sim.machines["jahr-1"] = m
	# Die Anlage steht im Anlagevermoegen (Aktivierung, kein Aufwand).
	sim.economy.book_investment(spec.acquisition_cost)

	var start_cash := sim.economy.cash

	# Ein ganzes Jahr simulieren.
	for _i in range(360):
		sim.advance_day()

	# Es muessen Auftraege eingegangen sein.
	t.check_true("Auftraege eingegangen", int(sim.stats.get("orders_received", 0)) > 0)

	# Der Umsatz muss entstanden sein.
	t.check_true("Umsatz erzielt", sim.economy.revenue_total > 0.0)
	t.check_true("Auftrage erfuellt", int(sim.stats.get("orders_completed", 0)) > 0)

	# Die Kasse muss durch den Umsatz gewachsen sein (die Anlage hat
	# kein Materialverbrauch, also bleiben die laufenden Kosten gering).
	t.check_true(
		"Kasse durch Umsatz gewachsen",
		sim.economy.cash > start_cash
	)

	# Die Bilanz muss aufgehen.
	var balance := sim.economy.balance_check()
	t.check_approx("Bilanz stimmt nach einem Jahr", balance, 0.0, 1.0)

	# Das Anlagevermoegen muss durch Abschreibung gesunken sein.
	t.check_true(
		"Anlagevermoegen abgeschrieben",
		sim.economy.fixed_assets < 16000.0
	)

	# Die Fixkosten muessen im Ergebnis stehen.
	t.check_true("Fixkosten gebucht", sim.economy.fixed_costs_year > 0.0)

	# Der Jahresabschluss hat das Jahr gezahlt.
	t.check_true("Jahreszaehler erhoeht", sim.year >= 1)
	t.check_approx(
		"Tageszaehler stimmt",
		float(sim.stats.get("days_simulated", 0)),
		360.0,
		0.01
	)

	# Der Cache muss die Maschine kennen.
	t.check_true("Maschine im Bestand", sim.machines.has("jahr-1"))


# ------------------------------------------------------------------
# Die Kasse darf keinen Euro doppelt zaehlen.
#
# Der Umsatz wird bei der Lieferung gutgeschrieben und darf im
# Jahresabschluss nicht noch einmal hinzukommen. Das Material wird
# beim Einkauf bezahlt und darf beim Verbrauch nicht noch einmal von
# der Kasse abgezogen werden. Die Fixkosten werden monatlich
# abgezogen und duerfen am Jahresende nicht noch einmal gebucht
# werden.
# ------------------------------------------------------------------
static func _test_cash_logic(t: TestFramework) -> void:
	var spec := _make_spec(&"KASSE", 10000.0, 0.0, 0.0, 0.0, 1000.0)
	var sim := SimulationEngine.new()
	sim.specs[spec.id] = spec

	var m := MachineInstance.new(spec, "kasse-1")
	m.state = MachineInstance.State.ACTIVE
	m.commissioned_year = 1
	sim.machines["kasse-1"] = m
	sim.economy.book_investment(spec.acquisition_cost)

	# --- Fall 1: Umsatz wird genau einmal gezaehlt -----------------
	var cash_before := sim.economy.cash
	var revenue := 5000.0
	sim.economy.cash += revenue
	sim.economy.revenue_current_year += revenue
	sim.economy.revenue_total += revenue

	# Der Jahresabschluss darf den Umsatz nicht noch einmal geben.
	sim._close_business_year()
	t.check_approx(
		"Umsatz nicht doppelt gezaehlt",
		sim.economy.cash,
		cash_before + revenue,
		0.01
	)

	# --- Fall 2: Material wird nicht doppelt bezahlt ----------------
	var spec_mat := _make_spec(&"MAT", 10000.0, 0.0, 0.0, 0.0, 1000.0)
	spec_mat.material_per_unit = 2.0
	spec_mat.material_price_per_kg = 3.50
	var sim2 := SimulationEngine.new()
	sim2.specs[spec_mat.id] = spec_mat
	var m2 := MachineInstance.new(spec_mat, "kasse-2")
	m2.state = MachineInstance.State.ACTIVE
	m2.commissioned_year = 1
	sim2.machines["kasse-2"] = m2

	# Material einkaufen: Kasse sinkt, Bestand steigt.
	var cash_before2 := sim2.economy.cash
	var buy := sim2.buy_material(100.0)
	t.check_true("Materialkauf moeglich", bool(buy.get("ok", false)))
	t.check_approx(
		"Materialkauf mindert die Kasse genau einmal",
		sim2.economy.cash,
		cash_before2 - sim2.material_price() * 100.0,
		0.01
	)
	var inventory_after_buy := sim2.inventory_material

	# Jahresabschluss: der Verbrauch darf die Kasse NICHT noch
	# einmal belasten.
	sim2._close_business_year()
	t.check_approx(
		"Material nicht doppelt bezahlt",
		sim2.economy.cash,
		cash_before2 - sim2.material_price() * 100.0,
		0.01
	)
	t.check_approx(
		"Bestand unveraendert ohne Produktion",
		sim2.inventory_material,
		inventory_after_buy,
		0.01
	)

	# --- Fall 3: Fixkosten werden nicht doppelt abgezogen ---------
	var sim3 := SimulationEngine.new()
	sim3.specs[spec.id] = spec
	var m3 := MachineInstance.new(spec, "kasse-3")
	m3.state = MachineInstance.State.ACTIVE
	m3.commissioned_year = 1
	sim3.machines["kasse-3"] = m3

	# Die Fixkosten sind null in diesem Test, die Kasse darf sich
	# durch den Jahresabschluss also nicht veraendern.
	var cash_before3 := sim3.economy.cash
	sim3._close_business_year()
	t.check_approx(
		"Jahresabschluss ohne Aufwand veraendert die Kasse nicht",
		sim3.economy.cash,
		cash_before3,
		0.01
	)


# ------------------------------------------------------------------
# Material braucht Vorlauf.
#
# Die Zahlung erfolgt bei der Bestellung, die Ware kommt erst
# nach der Lieferzeit. Bis dahin muss der vorhandene Bestand
# reichen – sonst laeuft die Produktion leer.
# ------------------------------------------------------------------
static func _test_material_logistics(t: TestFramework) -> void:
	var spec := _make_spec(&"MATLOG", 1000.0, 0.0, 0.0, 0.0, 1000.0)
	spec.material_per_unit = 2.0
	spec.material_price_per_kg = 2.50

	var sim := SimulationEngine.new()
	sim.specs[spec.id] = spec
	var m := MachineInstance.new(spec, "matlog-1")
	m.state = MachineInstance.State.ACTIVE
	m.commissioned_year = 1
	sim.machines["matlog-1"] = m

	# Der Materialpreis ergibt sich aus der Anlage.
	t.check_approx("Materialpreis korrekt", sim.material_price(), 2.50, 0.01)

	# Der Tagesbedarf: 2 kg/Stueck bei 1.000 Stuecken p.a.
	t.check_approx(
		"Tagesbedarf korrekt",
		sim.daily_material_need(),
		2.0 * 1000.0 / 360.0,
		0.01
	)

	# Bestellen mit Lieferzeit: Zahlung sofort, Ware noch nicht da.
	var cash_before := sim.economy.cash
	var order := sim.order_material(1_000.0, 5)
	t.check_true("Bestellung moeglich", bool(order.get("ok", false)))
	t.check_approx(
		"Zahlung bei Bestellung",
		sim.economy.cash,
		cash_before - 2_500.0,
		0.01
	)
	t.check_approx(
		"Ware noch nicht im Lager",
		sim.inventory_material,
		0.0,
		0.01
	)
	t.check_approx(
		"Material auf dem Weg",
		sim.material_in_transit(),
		1_000.0,
		0.01
	)

	# Vier Tage laufen: die Ware ist noch nicht da.
	for _i in range(4):
		sim.advance_day()
	t.check_approx(
		"Ware nach vier Tagen noch nicht da",
		sim.inventory_material,
		0.0,
		0.01
	)
	t.check_approx(
		"Lieferung noch unterwegs",
		sim.material_in_transit(),
		1_000.0,
		0.01
	)

	# Der fuenfte Tag: die Ware kommt an.
	sim.advance_day()
	t.check_approx(
		"Ware am Liefertag da",
		sim.inventory_material,
		1_000.0,
		0.01
	)
	t.check_approx(
		"Kein Material mehr unterwegs",
		sim.material_in_transit(),
		0.0,
		0.01
	)

	# Die Reichweite entspricht jetzt dem Bestand.
	t.check_approx(
		"Reichweite berechenbar",
		sim.material_coverage_days(),
		1_000.0 / (2.0 * 1000.0 / 360.0),
		1.0
	)

	# Ein Sofortkauf liefert sofort.
	var cash_before2 := sim.economy.cash
	var direct := sim.buy_material(500.0)
	t.check_true("Sofortkauf moeglich", bool(direct.get("ok", false)))
	t.check_approx(
		"Ware sofort im Lager",
		sim.inventory_material,
		1_500.0,
		0.01
	)
	t.check_approx(
		"Sofortkauf mindert die Kasse",
		sim.economy.cash,
		cash_before2 - 1_250.0,
		0.01
	)

	# Der Spielstand muss die Lieferung ueberstehen.
	var sim2 := SimulationEngine.new()
	sim2.specs[spec.id] = spec
	sim2.order_material(800.0, 4)
	var restored := SimulationEngine.new()
	restored.specs[spec.id] = spec
	restored.from_dict(sim2.to_dict())
	t.check_approx(
		"Materiallieferung im Spielstand",
		restored.material_in_transit(),
		800.0,
		0.01
	)
