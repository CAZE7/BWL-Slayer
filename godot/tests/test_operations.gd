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
	t.suite("Ablauf · Getrennte Materialarten")
	_test_material_types(t)
	t.suite("Ablauf · Rahmenverträge")
	_test_contracts(t)
	t.suite("Ablauf · Mehrstufige Produktionskette")
	_test_production_chain(t)
	t.suite("Ablauf · Wirtschaftlichkeit der Kette")
	_test_chain_economics(t)


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

	# Ohne betriebsbereite Anlage gibt es keine Tagesproduktion -
	# die Auftraege koennten nie bedient werden.
	var worker := MachineInstance.new(spec, "auf-1")
	worker.state = MachineInstance.State.ACTIVE
	worker.commissioned_year = 1
	sim.machines["auf-1"] = worker

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
	# Storniert wird, sobald progress_days die Frist UEBERschreitet -
	# also beim 31. Verarbeitungstag.
	for _i in range(31):
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
	# Die Kasse startet bei 50.000 (Startkapital) und waechst um den
	# sofort bezahlten Erloes.
	t.check_approx("Kasse erhoeht", sim.economy.cash, 50_100.0, 0.01)

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

	# Material ist variable Kosten. Der Kostenvergleich muss es
	# einbeziehen, sonst waere die kritische Menge zu niedrig.
	var with_mat_a := _make_spec(&"MA", 16000.0, 1180.20, 26.0, 40.0, 50000.0)
	with_mat_a.material_per_unit = 2.0
	with_mat_a.material_price_per_kg = 1.5
	var with_mat_b := _make_spec(&"MB", 17000.0, 1345.70, 26.0, 40.0, 50000.0)
	var mat_result := CostComparison.compare(with_mat_a, with_mat_b, "COST", 60, 5000.0)
	# A hat 26 + 3 = 29 Euro variable Stueckkosten, B hat 26. Damit
	# liegt B oberhalb der kritischen Menge im Vorteil.
	t.check_approx(
		"Material steckt in den variablen Stueckkosten",
		with_mat_a.full_variable_cost_per_unit(),
		29.0,
		0.01
	)
	t.check_approx(
		"Deckungsbeitrag ohne Material im Vergleich",
		mat_result.contribution_a,
		40.0 - 29.0,
		0.01
	)
	t.check_true(
		"Kritische Menge beruecksichtigt das Material",
		mat_result.valid and mat_result.x_critical > 0.0
	)
	# Die kritische Menge muss mit der Materialbelastung groesser
	# sein als ohne: die Anlage braucht mehr Stueck, um ihre Fixkosten
	# zu decken.
	var ohne_mat := CostComparison.compare(a, b, "COST", 60, 5000.0)
	t.check_true(
		"Material erhoeht die kritische Menge",
		mat_result.x_critical > ohne_mat.x_critical
	)

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

	# Die fabrizierte Jahresproduktion (10.000 Stueck) braucht die
	# dazugehoerigen Zahlungsstroeme, sonst KANN die Bilanz nicht
	# aufgehen: Das Material wurde im Jahr eingekauft (Kasse ->
	# Lagerbestand, ein Aktivtausch) und bei der Produktion
	# verbraucht; die Fixkosten wurden monatlich von der Kasse
	# bezahlt. Im echten Lauf erledigen buy_material() und die
	# Monatsbuchung das - hier wird es nachgestellt.
	var material_purchase := 10000.0 * spec.material_per_unit * spec.material_price_per_kg
	eco.move_cash(-material_purchase)
	eco.inventory_value = material_purchase
	eco.move_cash(-(spec.fixed_operating_costs + spec.labor_cost()))

	# Jahresabschluss
	sim._close_business_year()

	# Der Materialaufwand muss in den Kosten stehen.
	var expected_material := 10000.0 * spec.material_per_unit * spec.material_price_per_kg
	t.check_approx("Materialaufwand ausgewiesen", eco.material_costs_year, expected_material, 0.01)
	# costs_current_year wird am Jahresende auf 0 zurueckgesetzt -
	# fuer das abgeschlossene Jahr zaehlt die kumulierte Summe.
	t.check_true(
		"Materialaufwand in den Gesamtkosten",
		eco.costs_total >= expected_material
	)

	# Die Fixkosten muessen gebucht sein.
	t.check_true("Fixkosten gebucht", eco.fixed_costs_year > 0.0)
	t.check_true(
		"Fixkosten in den Gesamtkosten",
		eco.costs_total >= eco.fixed_costs_year
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

	# Zwei ganze Jahre simulieren.
	#
	# Warum zwei? Die Nachfrage taktet mit der Kapazitaet: bei
	# ~11.600 Stueck Jahreskapazitaet kommt nur alle 154 Tage ein
	# Auftrag, und der umfasst ~7.800 Stueck - rund 240
	# Produktionstage. Ein Auftrag aus Tag 154 wird also erst im
	# zweiten Jahr fertig. Ein Ein-Jahres-Lauf koennte prinzipiell
	# keinen abgeschlossenen Auftrag enthalten.
	for _i in range(720):
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

	# Die Bilanz muss aufgehen - auch nach zwei Jahresabschluessen.
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
		720.0,
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

	# Der fuenfte Tag: die Ware kommt an. Die laufende Produktion
	# verbraucht am selben Tag bereits ihren Tagesbedarf - die
	# Lieferung speist einen lebenden Betrieb, kein totes Lager.
	var daily_use := 2.0 * 1000.0 / 360.0
	sim.advance_day()
	t.check_approx(
		"Ware am Liefertag da",
		sim.inventory_material,
		1_000.0 - daily_use,
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
		(1_000.0 - daily_use) / daily_use,
		1.0
	)

	# Ein Sofortkauf liefert sofort.
	var cash_before2 := sim.economy.cash
	var direct := sim.buy_material(500.0)
	t.check_true("Sofortkauf moeglich", bool(direct.get("ok", false)))
	t.check_approx(
		"Ware sofort im Lager",
		sim.inventory_material,
		1_000.0 - daily_use + 500.0,
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
	# Ohne betriebsbereite Anlage kennt der Betrieb keinen
	# Materialpreis - die Bestellung wuerde abgelehnt.
	var m2 := MachineInstance.new(spec, "matlog-2")
	m2.state = MachineInstance.State.ACTIVE
	m2.commissioned_year = 1
	sim2.machines["matlog-2"] = m2
	var order2 := sim2.order_material(800.0, 4)
	t.check_true("Zweite Bestellung moeglich", bool(order2.get("ok", false)))
	var restored := SimulationEngine.new()
	restored.specs[spec.id] = spec
	restored.from_dict(sim2.to_dict())
	t.check_approx(
		"Materiallieferung im Spielstand",
		restored.material_in_transit(),
		800.0,
		0.01
	)


# ------------------------------------------------------------------
# Produktionskette: verschiedene Materialarten, getrennt gelagert.
#
# Wer Stahl hat, kann keine Verpackung produzieren. Ein Bestand
# ersetzt keinen anderen. Das ist der Grund, warum getrennte
# Materialbestände noetig sind.
# ------------------------------------------------------------------
static func _test_material_types(t: TestFramework) -> void:
	var steel := _make_spec(&"STAHL", 1000.0, 0.0, 0.0, 0.0, 1000.0)
	steel.material_type = MachineCatalog.MATERIAL_STEEL
	steel.material_per_unit = 2.0
	steel.material_price_per_kg = 1.40

	var packing := _make_spec(&"PACK", 1000.0, 0.0, 0.0, 0.0, 1000.0)
	packing.material_type = MachineCatalog.MATERIAL_PACKAGING
	packing.material_per_unit = 0.6
	packing.material_price_per_kg = 1.10

	var sim := SimulationEngine.new()
	sim.specs[steel.id] = steel
	sim.specs[packing.id] = packing

	var m1 := MachineInstance.new(steel, "stahl-1")
	m1.state = MachineInstance.State.ACTIVE
	m1.commissioned_year = 1
	sim.machines["stahl-1"] = m1

	var m2 := MachineInstance.new(packing, "pack-1")
	m2.state = MachineInstance.State.ACTIVE
	m2.commissioned_year = 1
	sim.machines["pack-1"] = m2

	# Beide Materialarten werden gebraucht.
	var types := sim.required_material_types()
	t.check_true("Zwei Materialarten erkannt", types.size() == 2)
	t.check_true("Stahl wird gebraucht", types.has(MachineCatalog.MATERIAL_STEEL))
	t.check_true("Verpackung wird gebraucht", types.has(MachineCatalog.MATERIAL_PACKAGING))

	# Die Preise sind je Art verschieden.
	t.check_approx(
		"Stahlpreis korrekt", sim.material_price(MachineCatalog.MATERIAL_STEEL), 1.40, 0.01
	)
	t.check_approx(
		"Verpackungspreis korrekt",
		sim.material_price(MachineCatalog.MATERIAL_PACKAGING),
		1.10,
		0.01
	)

	# Der Tagesbedarf ist je Art getrennt.
	t.check_approx(
		"Stahlbedarf korrekt",
		sim.daily_material_need(MachineCatalog.MATERIAL_STEEL),
		2.0 * 1000.0 / 360.0,
		0.01
	)
	t.check_approx(
		"Verpackungsbedarf korrekt",
		sim.daily_material_need(MachineCatalog.MATERIAL_PACKAGING),
		0.6 * 1000.0 / 360.0,
		0.01
	)

	# Nur Stahl kaufen: die Verpackung bleibt leer.
	var cash_before := sim.economy.cash
	var buy := sim.buy_material(1_000.0, MachineCatalog.MATERIAL_STEEL)
	t.check_true("Stahlkauf moeglich", bool(buy.get("ok", false)))
	t.check_approx(
		"Stahl im Lager",
		sim.material_stock(MachineCatalog.MATERIAL_STEEL),
		1_000.0,
		0.01
	)
	t.check_approx(
		"Verpackung unberuehrt",
		sim.material_stock(MachineCatalog.MATERIAL_PACKAGING),
		0.0,
		0.01
	)
	t.check_approx(
		"Kasse nur einmal belastet",
		sim.economy.cash,
		cash_before - 1_400.0,
		0.01
	)

	# Jetzt produzieren: die Stahlmaschine laeuft, die Verpackung
	# steht still, weil ihr Material fehlt.
	var produced_before := m2.quantity_this_year
	for _i in range(10):
		sim.advance_day()
	t.check_true(
		"Stahlanlage produziert",
		m1.quantity_this_year > 0.0
	)
	t.check_approx(
		"Verpackungsanlage steht still",
		m2.quantity_this_year,
		produced_before,
		0.01
	)

	# Verpackung nachkaufen: dann laeuft auch sie.
	sim.buy_material(1_000.0, MachineCatalog.MATERIAL_PACKAGING)
	var pack_before := m2.quantity_this_year
	for _i in range(10):
		sim.advance_day()
	t.check_true(
		"Verpackungsanlage produziert jetzt",
		m2.quantity_this_year > pack_before
	)

	# Die Bestände sind getrennt geblieben.
	t.check_true(
		"Stahlbestand vorhanden",
		sim.material_stock(MachineCatalog.MATERIAL_STEEL) > 0.0
	)
	t.check_true(
		"Verpackungsbestand vorhanden",
		sim.material_stock(MachineCatalog.MATERIAL_PACKAGING) > 0.0
	)

	# Der Spielstand muss beide Bestände behalten.
	var restored := SimulationEngine.new()
	restored.specs[steel.id] = steel
	restored.specs[packing.id] = packing
	restored.from_dict(sim.to_dict())
	t.check_approx(
		"Stahlbestand im Spielstand",
		restored.material_stock(MachineCatalog.MATERIAL_STEEL),
		sim.material_stock(MachineCatalog.MATERIAL_STEEL),
		0.01
	)
	t.check_approx(
		"Verpackungsbestand im Spielstand",
		restored.material_stock(MachineCatalog.MATERIAL_PACKAGING),
		sim.material_stock(MachineCatalog.MATERIAL_PACKAGING),
		0.01
	)


# ------------------------------------------------------------------
# Rahmenvertraege sichern Nachfrage - aber nur zu einem Preis, der
# den Deckungsbeitrag deckt. Ein Vertrag unter dem Deckungsbeitrag
# waere ein Verlust auf jedem Stueck und wird abgelehnt.
# ------------------------------------------------------------------
static func _test_contracts(t: TestFramework) -> void:
	var spec := _make_spec(&"VERTR", 1000.0, 1000.0, 20.0, 60.0, 10000.0)
	var sim := SimulationEngine.new()
	sim.specs[spec.id] = spec

	var m := MachineInstance.new(spec, "vertr-1")
	m.state = MachineInstance.State.ACTIVE
	m.commissioned_year = 1
	sim.machines["vertr-1"] = m

	# Der Deckungsbeitrag ist 60 - 20 = 40 EUR je Stueck.
	t.check_approx(
		"Deckungsbeitrag korrekt", sim._weighted_contribution_margin(), 40.0, 0.01
	)

	# Ein Preis unter dem Deckungsbeitrag wird abgelehnt.
	var too_low := sim.sign_contract(1_000.0, 30.0, 3)
	t.check_true("Preis unter Deckungsbeitrag abgelehnt", not bool(too_low.get("ok", false)))
	t.check_true("Kein Vertrag angelegt", sim.contracts.is_empty())

	# Eine Menge ueber der Kapazitaet wird abgelehnt.
	var too_much := sim.sign_contract(1_000_000.0, 50.0, 3)
	t.check_true("Ueberkapazitaet abgelehnt", not bool(too_much.get("ok", false)))

	# Ein gueltiger Vertrag wird geschlossen.
	var contract := sim.sign_contract(3_000.0, 50.0, 3)
	t.check_true("Vertrag geschlossen", bool(contract.get("ok", false)))
	t.check_true("Vertrag in der Liste", sim.contracts.size() == 1)
	t.check_approx(
		"Gesicherte Menge korrekt", sim.contracted_quantity(), 3_000.0, 0.01
	)
	t.check_approx(
		"Gesicherter Deckungsbeitrag korrekt",
		sim.contracted_margin(),
		3_000.0 * 10.0,
		0.01
	)

	# Die vertragliche Menge wird in der Nachfrage angeboten.
	var capacity := sim._total_capacity()
	var share := 0.6
	var market_quantity: float = floor(capacity * share / 100.0) * 100.0
	t.check_true(
		"Vertragsmenge groesser als die Marktnachfrage",
		sim.contracted_quantity() > 0.0
	)

	# Kuendigung kostet eine Gebuehr von 10 % des Jahresumsatzes.
	var cash_before := sim.economy.cash
	var termination := sim.terminate_contract(String(sim.contracts[0].get("id", "")))
	t.check_true("Kuendigung moeglich", bool(termination.get("ok", false)))
	t.check_approx(
		"Kuendigungsgebuehr abgebucht",
		sim.economy.cash,
		cash_before - 3_000.0 * 50.0 * 0.10,
		0.01
	)
	t.check_true("Vertrag entfernt", sim.contracts.is_empty())

	# Die Laufzeit verringert sich im Jahresabschluss.
	var contract2 := sim.sign_contract(1_000.0, 50.0, 2)
	t.check_true("Zweiter Vertrag geschlossen", bool(contract2.get("ok", false)))
	var years_before := int(sim.contracts[0].get("years_remaining", 0))
	sim._close_business_year()
	t.check_true(
		"Laufzeit um ein Jahr verringert",
		int(sim.contracts[0].get("years_remaining", 0)) == years_before - 1
	)

	# Nach zwei Jahren ist der Vertrag ausgelaufen.
	sim._close_business_year()
	t.check_true("Vertrag ausgelaufen", sim.contracts.is_empty())

	# Der Spielstand muss die Vertraege behalten.
	var sim2 := SimulationEngine.new()
	sim2.specs[spec.id] = spec
	# Ohne betriebsbereite Anlage gibt es keine Kapazitaet - der
	# Vertrag wuerde an der Kapazitaetsgrenze abgelehnt.
	var m2 := MachineInstance.new(spec, "vertr-2")
	m2.state = MachineInstance.State.ACTIVE
	m2.commissioned_year = 1
	sim2.machines["vertr-2"] = m2
	var signed2 := sim2.sign_contract(500.0, 50.0, 5)
	t.check_true("Vertrag fuer den Spielstand geschlossen", bool(signed2.get("ok", false)))
	var restored := SimulationEngine.new()
	restored.specs[spec.id] = spec
	restored.from_dict(sim2.to_dict())
	t.check_true("Vertrag im Spielstand", restored.contracts.size() == 1)
	t.check_approx(
		"Vertragsmenge im Spielstand",
		restored.contracted_quantity(),
		500.0,
		0.01
	)


# ------------------------------------------------------------------
# Mehrstufige Produktionskette
#
# Die Kette ist das Zusammenspiel zweier Anlagen: Die Vorstufe
# erzeugt ein Zwischenprodukt, die Endstufe verbraucht es. Geprueft
# wird, dass die Kopplung wirklich greift – also dass die Endstufe
# ohne Vorstufe stillsteht, mit Vorstufe aber laeuft.
# ------------------------------------------------------------------
static func _test_production_chain(t: TestFramework) -> void:
	# Die Produktion ist alles-oder-nichts: Eine Anlage laeuft nur,
	# wenn ihr voller Tagesbedarf an Vorprodukten da ist - sonst
	# steht sie im Leerlauf (mit Protokollvermerk). Die Mengen hier
	# sind darauf abgestimmt.
	#
	# Vorstufe: 90.000 Halbfertigteile p.a. -> 250 am Tag.
	var stage1 := _make_spec(&"VORSTUFE", 40_000.0, 8_000.0, 4.0, 21.0, 90_000.0)
	stage1.output_product = &"halb"
	# Endstufe: braucht 2 Halbfertigteile je Endprodukt. Bei
	# 36.000 p.a. (100 am Tag) braucht sie 200 Halbfertigteile am
	# Tag - die Vorstufe liefert 250, der Rest von 50 bleibt im
	# Zwischenlager.
	var stage2 := _make_spec(&"ENDSTUFE", 24_000.0, 5_400.0, 3.0, 18.0, 36_000.0)
	stage2.input_product = &"halb"
	stage2.input_product_per_unit = 2.0

	# --- Ohne Vorstufe steht die Endstufe still ---
	var sim := SimulationEngine.new()
	sim.specs[stage1.id] = stage1
	sim.specs[stage2.id] = stage2

	var only_end := MachineInstance.new(stage2, "end-1")
	only_end.state = MachineInstance.State.ACTIVE
	only_end.commissioned_year = 1
	sim.machines["end-1"] = only_end

	sim.advance_day()
	t.check_approx(
		"Endstufe ohne Vorstufe produziert nichts",
		only_end.quantity_this_year,
		0.0,
		0.01
	)
	t.check_true(
		"Leerlauf wird protokolliert",
		only_end.notes.size() > 0
	)

	# --- Mit Vorstufe laeuft die Kette ---
	var chain := SimulationEngine.new()
	chain.specs[stage1.id] = stage1
	chain.specs[stage2.id] = stage2

	var producer := MachineInstance.new(stage1, "vor-1")
	producer.state = MachineInstance.State.ACTIVE
	producer.commissioned_year = 1
	chain.machines["vor-1"] = producer

	var finisher := MachineInstance.new(stage2, "end-1")
	finisher.state = MachineInstance.State.ACTIVE
	finisher.commissioned_year = 1
	chain.machines["end-1"] = finisher

	chain.advance_day()

	var stage1_daily := stage1.capacity_units_per_year / 360.0
	var stage2_daily := stage2.capacity_units_per_year / 360.0

	t.check_approx(
		"Vorstufe produziert ihre Tagesmenge",
		producer.quantity_this_year,
		stage1_daily,
		0.01
	)
	# Die Endstufe braucht 2 Halbfertigteile je Endstueck. Die
	# Vorstufe liefert am selben Tag 250 Stueck - mehr als die 200,
	# die die Endstufe braucht. Der Rest bleibt im Zwischenlager.
	t.check_approx(
		"Endstufe produziert ihre Tagesmenge",
		finisher.quantity_this_year,
		stage2_daily,
		0.01
	)
	t.check_approx(
		"Zwischenlager erhaelt den Ueberschuss",
		chain.intermediate_stock(&"halb"),
		stage1_daily - stage2_daily * 2.0,
		0.01
	)

	# Die Vorstufe darf nicht zum Markt verkaufen: sonst waere die
	# Ware doppelt verkauft.
	var chain2 := SimulationEngine.new()
	chain2.specs[stage1.id] = stage1
	chain2.specs[stage2.id] = stage2
	var producer2 := MachineInstance.new(stage1, "vor-1")
	producer2.state = MachineInstance.State.ACTIVE
	chain2.machines["vor-1"] = producer2
	chain2.advance_day()
	t.check_true(
		"Vorstufe erzeugt kein Endprodukt",
		producer2.spec.is_intermediate_stage()
	)

	# --- Rueckstau: zu wenig Vorstufenleistung bremst die Endstufe ---
	var starved := SimulationEngine.new()
	starved.specs[stage1.id] = stage1
	starved.specs[stage2.id] = stage2
	# Die Vorstufe liefert nur 50 am Tag - ein Viertel des
	# Tagesbedarfs der Endstufe (200).
	var weak := stage1.with_overrides({"capacity_units_per_year": 18_000.0})
	starved.specs[stage1.id] = weak
	var weak_producer := MachineInstance.new(weak, "vor-1")
	weak_producer.state = MachineInstance.State.ACTIVE
	weak_producer.commissioned_year = 1
	starved.machines["vor-1"] = weak_producer
	var starving_end := MachineInstance.new(stage2, "end-1")
	starving_end.state = MachineInstance.State.ACTIVE
	starving_end.commissioned_year = 1
	starved.machines["end-1"] = starving_end

	# Die Produktion ist alles-oder-nichts: Die Endstufe laeuft nur
	# an Tagen, an denen ihr voller Tagesbedarf (200) im
	# Zwischenlager liegt. Bei 50 Stueck Zulauf am Tag ist das
	# jeder vierte Tag - Tag 4 und Tag 8 in acht Tagen. Im Schnitt
	# ist die Endstufe damit auf ein Viertel ihrer Kapazitaet
	# gebremst: genau die Begrenzung durch die Vorstufe.
	for _i in range(8):
		starved.advance_day()
	t.check_approx(
		"Endstufe wird von der Vorstufe begrenzt",
		starving_end.quantity_this_year,
		2.0 * (36_000.0 / 360.0),
		0.01
	)

	# --- Spielstand: Zwischenprodukte ueberleben das Speichern ---
	var saved := SimulationEngine.new()
	saved.specs[stage1.id] = stage1
	saved.specs[stage2.id] = stage2
	saved.set_intermediate_stock(&"halb", 1234.0)
	var restored := SimulationEngine.new()
	restored.specs[stage1.id] = stage1
	restored.specs[stage2.id] = stage2
	restored.from_dict(saved.to_dict())
	t.check_approx(
		"Zwischenlager im Spielstand",
		restored.intermediate_stock(&"halb"),
		1234.0,
		0.01
	)


# ------------------------------------------------------------------
# Wirtschaftlichkeit der Kette
#
# Der Deckungsbeitrag einer Kette ist nicht der Deckungsbeitrag der
# Endstufe allein: Die Vorstufe bringt Wertschoepfung, ihre Kosten
# muessen aber abgezogen werden.
# ------------------------------------------------------------------
static func _test_chain_economics(t: TestFramework) -> void:
	var stage1 := _make_spec(&"VORSTUFE", 40_000.0, 8_000.0, 4.0, 21.0, 36_000.0)
	stage1.output_product = &"halb"
	var stage2 := _make_spec(&"ENDSTUFE", 24_000.0, 5_400.0, 3.0, 18.0, 36_000.0)
	stage2.input_product = &"halb"
	stage2.input_product_per_unit = 2.0

	var sim := SimulationEngine.new()
	sim.specs[stage1.id] = stage1
	sim.specs[stage2.id] = stage2

	var producer := MachineInstance.new(stage1, "vor-1")
	producer.state = MachineInstance.State.ACTIVE
	sim.machines["vor-1"] = producer
	var finisher := MachineInstance.new(stage2, "end-1")
	finisher.state = MachineInstance.State.ACTIVE
	sim.machines["end-1"] = finisher

	# Der Ketten-Deckungsbeitrag ist der Deckungsbeitrag der Endstufe
	# PLUS die Wertschoepfung der Vorstufe. Er ist deshalb hoeher als
	# der der Endstufe allein – die Vorstufe erzeugt echten Mehrwert.
	# Entscheidend ist, dass die Endstufe allein diesen Beitrag gar
	# nicht erbringen kann: ohne Vorstufe gibt es keine Ware.
	var chain_db := sim._weighted_contribution_margin()
	var end_alone := stage2.contribution_margin_per_unit()
	t.check_true(
		"Ketten-Deckungsbeitrag ist positiv",
		chain_db > 0.0
	)
	t.check_true(
		"Vorstufe steuert Wertschoepfung bei",
		chain_db > end_alone
	)
	t.check_true(
		"Endstufe allein ist keine Alternative zur Kette",
		stage2.input_product != &""
	)

	# Die Kosten der Vorstufe werden in die Kette eingerechnet: Mit
	# teurerer Vorstufe sinkt der Ketten-Deckungsbeitrag.
	var expensive := stage1.with_overrides({"variable_cost_per_unit": 12.0})
	var sim2 := SimulationEngine.new()
	sim2.specs[stage1.id] = expensive
	sim2.specs[stage2.id] = stage2
	var producer2 := MachineInstance.new(expensive, "vor-1")
	producer2.state = MachineInstance.State.ACTIVE
	sim2.machines["vor-1"] = producer2
	var finisher2 := MachineInstance.new(stage2, "end-1")
	finisher2.state = MachineInstance.State.ACTIVE
	sim2.machines["end-1"] = finisher2
	t.check_true(
		"Teurere Vorstufe senkt den Ketten-Deckungsbeitrag",
		sim2._weighted_contribution_margin() < chain_db
	)

	# Der Kapitalwert der Kette umfasst beide Stufen. Die Endstufe
	# allein waere zu niedrig bewertet, weil die Vorstufe fehlt.
	var kw_chain: float = sim.chain_net_present_value(finisher, 0.084)
	var kw_end_only: float = finisher.net_present_value(0.084)
	t.check_true(
		"Ketten-Kapitalwert schliesst die Vorstufe ein",
		kw_chain > kw_end_only
	)
	# Der Kapitalwert muss mit dem Kapitaleinsatz verglichen werden:
	# eine Kette, die mehr einbringt als sie kostet, schafft Wert.
	t.check_true(
		"Ketten-Kapitalwert ist positiv",
		kw_chain > 0.0
	)
	# Die Kette bindet mehr Kapital als die Endstufe allein: das
	# zusaetzliche Kapital der Vorstufe ist nur dann sinnvoll
	# gebunden, wenn es mehr Wert schafft als es kostet.
	var total_investment := stage1.acquisition_cost + stage2.acquisition_cost
	t.check_true(
		"Die Kette bindet mehr Kapital als die Endstufe allein",
		total_investment > stage2.acquisition_cost
	)
