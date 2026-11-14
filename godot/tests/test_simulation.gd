extends RefCounted

## Tests der Wirtschaftssimulation.
##
## Prüft die Kernanforderung: Investitionsauszahlung, Abschreibung und
## kalkulatorische Zinsen müssen sauber getrennt sein. Eine Maschine darf
## NICHT mit dem vollen Anschaffungspreis UND zusätzlich mit Abschreibung
## belastet werden.


static func run(t: TestFramework) -> void:
	t.suite("Simulation · Kostenarten-Trennung")
	_test_cost_separation(t)
	t.suite("Simulation · Maschinen-Lebenszyklus")
	_test_lifecycle(t)
	t.suite("Simulation · Wirtschaftliche Kennzahlen")
	_test_metrics(t)
	t.suite("Simulation · Liquidität & Krisen")
	_test_liquidity(t)
	t.suite("Simulation · Investitionsrechnung")
	_test_investment_evaluation(t)


# ------------------------------------------------------------------
static func _make_spec(id: StringName, cost: float, fixed: float, kvar: float, price: float) -> MachineSpec:
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
	spec.capacity_units_per_year = 10000.0
	spec.delivery_days = 0
	spec.installation_days = 0
	spec.material_per_unit = 0.0
	return spec


# ------------------------------------------------------------------
static func _test_cost_separation(t: TestFramework) -> void:
	# Abschreibung: (A0 - L) / n
	var spec := _make_spec(&"TEST", 10000.0, 500.0, 5.0, 20.0)
	t.check_approx("AfA linear", spec.depreciation(), 2500.0, 0.01)
	t.check_approx("Durchschnittlich gebundenes Kapital", spec.average_bound_capital(), 5000.0, 0.01)
	t.check_approx("Kalkulatorische Zinsen", spec.imputed_interest(), 400.0, 0.01)
	t.check_approx("K_fix gesamt", spec.total_fixed_costs(), 3400.0, 0.01)

	# Zahlungswirksame Fixkosten enthalten KEINE AfA und KEINE kalk. Zinsen
	t.check_approx("Zahlungswirksam nur Fixkosten", spec.cash_fixed_costs(), 500.0, 0.01)

	# Cashflow-Rechnung: Gewinn + AfA + kalk. Zinsen
	# Bei x = 1000: DB = 15, Gewinn = 15*1000 - 3400 = 11600
	var profit := spec.profit_at(1000.0)
	t.check_approx("Gewinn bei x=1000", profit, 11600.0, 0.01)
	var cashflow := spec.annual_cashflow_at(1000.0)
	t.check_approx("Cashflow = Gewinn + AfA + kalk.Z", cashflow, 14500.0, 0.01)

	# KRITISCH: Die Investitionsauszahlung darf NICHT als laufender Aufwand
	# erscheinen. Nur die Abschreibung wirkt auf das Ergebnis.
	t.check_true("Anschaffungspreis nicht in Fixkosten", not is_equal_approx(spec.total_fixed_costs(), 10000.0 + 500.0))

	# Break-even: K_fix / DB = 3400 / 15
	t.check_approx("Break-even Menge", spec.break_even_quantity(), 226.667, 0.01)


# ------------------------------------------------------------------
static func _test_lifecycle(t: TestFramework) -> void:
	var spec := _make_spec(&"LIFE", 8000.0, 400.0, 4.0, 15.0)
	spec.useful_life_years = 3
	spec.residual_value = 2000.0

	var m := MachineInstance.new(spec, "inst-1")
	t.check_true("Neu: ORDERED", m.state == MachineInstance.State.ORDERED)
	t.check_approx("Restbuchwert = Anschaffung", m.book_value, 8000.0, 0.01)

	# In Betrieb nehmen
	m.state = MachineInstance.State.ACTIVE
	m.commissioned_year = 1
	m.age_years = 0
	t.check_approx("AfA im Betriebsjahr 1", m.current_depreciation(), 2000.0, 0.01)
	t.check_approx("Kalk. Zinsen auf Restbuchwert", m.current_imputed_interest(), 640.0, 0.01)

	# Ein Jahr verstreichen lassen
	m.quantity_this_year = 3000.0
	m.advance_year(1)
	t.check_true("Alterung: Jahr 1 -> 2", m.age_years == 1)
	t.check_approx("Restbuchwert nach Jahr 1", m.book_value, 6000.0, 0.01)
	t.check_true("Produktionshistorie geführt", m.production_history.size() == 1)

	# Letztes Jahr: auf Restwert herabschreiben
	m.age_years = 2
	t.check_approx("Abschreibung im letzten Jahr", m.current_depreciation(), 4000.0, 0.01)
	m.advance_year(2)
	t.check_true("Nach Nutzungsdauer außer Betrieb", m.state == MachineInstance.State.DECOMMISSIONED)

	# Roundtrip: Zustand serialisieren und wiederherstellen
	var m2 := MachineInstance.new(spec, "inst-2")
	m2.state = MachineInstance.State.ACTIVE
	m2.commissioned_year = 3
	m2.age_years = 1
	m2.book_value = 6000.0
	m2.quantity_this_year = 1234.0
	var data := m2.to_dict()
	var m3 := MachineInstance.new(spec, "inst-3")
	m3.from_dict(data)
	t.check_approx("Roundtrip Restbuchwert", m3.book_value, 6000.0, 0.01)
	t.check_approx("Roundtrip Produktion", m3.quantity_this_year, 1234.0, 0.01)
	t.check_true("Roundtrip Zustand", m3.state == MachineInstance.State.ACTIVE)


# ------------------------------------------------------------------
static func _test_metrics(t: TestFramework) -> void:
	var e := EconomyState.new()
	e.cash = 84500.0
	e.equity = 120000.0
	e.debt = 30000.0
	e.debt_rate = 0.06
	e.revenue_current_year = 12400.0
	e.costs_current_year = 8250.0
	e.fixed_costs_year = 24000.0
	e.depreciation_year = 6000.0
	e.imputed_interest_year = 3000.0
	e.interest_paid_year = 1800.0

	t.check_approx("Betriebsergebnis", e.operating_result(), 4150.0, 0.01)
	# Cashflow = Betriebsergebnis + AfA + kalk. Zinsen.
	#
	# Der Zinsaufwand auf Fremdkapital wird NICHT noch einmal abgezogen:
	# Er steckt bereits in `costs_current_year` und damit im
	# Betriebsergebnis. Ein zweiter Abzug waere eine doppelte Belastung.
	# Dieselbe Formel verwendet die Legacy-Engine:
	#   annualCashflowAtX = profitAtX + depreciation + imputedInterest
	t.check_approx("Cashflow", e.cash_flow(), 4150.0 + 6000.0 + 3000.0, 0.01)
	t.check_approx("Operativer Cashflow", e.operating_cash_flow(), e.cash_flow(), 0.01)
	# Der Zinsaufwand ist im Ergebnis bereits enthalten.
	t.check_true(
		"Zinsaufwand nicht doppelt belastet",
		e.cash_flow() > e.operating_result() + e.depreciation_year + e.imputed_interest_year - 0.01
	)
	t.check_approx("Fremdkapitalquote", e.debt_ratio(), 0.2, 0.001)
	t.check_true("Liquidität gesund", e.health_status() == "healthy")

	# EK-Quote: FK / (FK + EK) = 30000 / 150000 = 20 %
	t.check_approx("FK-Quote korrekt", e.debt_ratio() * 100.0, 20.0, 0.01)

	# Leverage-Effekt auf die EK-Rentabilität
	var e2 := EconomyState.new()
	e2.equity = 800000.0
	e2.debt = 200000.0
	e2.revenue_current_year = 100000.0
	e2.costs_current_year = 10000.0
	t.check_approx("EK-Rentabilität %", e2.roe_percent(), 11.25, 0.01)


# ------------------------------------------------------------------
static func _test_liquidity(t: TestFramework) -> void:
	var e := EconomyState.new()
	e.cash = 1000.0
	e.equity = 50000.0
	e.debt = 0.0
	e.fixed_costs_year = 24000.0
	t.check_true("Tense bei niedriger Liquidität", e.health_status() == "tense")
	t.check_true("Begründung vorhanden", e.health_reasons().size() > 0)

	var e2 := EconomyState.new()
	e2.cash = -5000.0
	e2.equity = 20000.0
	e2.debt = 19000.0
	e2.fixed_costs_year = 24000.0
	t.check_true("Critical bei überzogener Kasse", e2.health_status() == "critical")
	t.check_true("Krisenbegründung", e2.health_reasons().size() >= 2)

	# Liquiditätsgrad II
	var e3 := EconomyState.new()
	e3.cash = 12000.0
	e3.fixed_costs_year = 24000.0
	t.check_approx("Liquiditätsgrad II", e3.liquidity_ratio(), 6.0, 0.01)


# ------------------------------------------------------------------
# Die Investitionsrechnung muss mit der BWL-Engine uebereinstimmen.
#
# Geprueft werden: Barwert (NPV), Kapitalwert (Annuität),
# Rentabilitaetsindex und die interne Rendite. Die Werte werden
# unabhaengig mit BWLEngine berechnet und verglichen.
# ------------------------------------------------------------------
static func _test_investment_evaluation(t: TestFramework) -> void:
	var spec := MachineSpec.new()
	spec.id = &"INV"
	spec.display_name = "Investitionsanlage"
	spec.acquisition_cost = 50_000.0
	spec.residual_value = 5_000.0
	spec.useful_life_years = 5
	spec.imputed_interest_rate = 0.08
	spec.fixed_operating_costs = 12_000.0
	spec.variable_cost_per_unit = 20.0
	spec.price_per_unit = 60.0
	spec.capacity_units_per_year = 2_000.0
	spec.debt_share = 0.4
	spec.debt_interest_rate = 0.06
	spec.equity_interest_rate = 0.10

	# Der Zinssatz ist der gewichtete Mittelwert aus Eigen- und
	# Fremdkapitalzins: 0.6 * 10 % + 0.4 * 6 % = 8.4 %
	t.check_approx(
		"Effektivzins korrekt gewichtet",
		spec.effective_interest_rate(),
		0.084,
		0.0001
	)

	# Der zahlungswirksame Jahres-Cashflow darf die kalkulatorischen
	# Zinsen NICHT enthalten.
	var quantity := 2_000.0
	var cashflow := spec.annual_cashflow_at(quantity)
	var expected_cashflow := (
		spec.contribution_margin_per_unit() * quantity
		- spec.fixed_operating_costs
		+ spec.depreciation()
	)
	t.check_approx(
		"Cashflow ohne kalkulatorische Zinsen",
		cashflow,
		expected_cashflow,
		0.01
	)

	# Gegenrechnung mit der Engine.
	var other := MachineSpec.new()
	other.id = &"INV-B"
	other.display_name = "Vergleichsanlage"
	other.acquisition_cost = 60_000.0
	other.residual_value = 0.0
	other.useful_life_years = 5
	other.imputed_interest_rate = 0.08
	other.fixed_operating_costs = 15_000.0
	other.variable_cost_per_unit = 18.0
	other.price_per_unit = 58.0
	other.capacity_units_per_year = 2_000.0

	var rows := CostComparison.evaluate_at(spec, other, quantity)
	t.check_true("Zwei Anlagen ausgewertet", rows.size() == 2)

	var row: Dictionary = rows[0]
	t.check_approx(
		"Barwert stimmt mit der Engine ueberein",
		float(row.get("npv", 0.0)),
		BWLEngine.npv(
			spec.acquisition_cost,
			[5_000.0, 5_000.0, 5_000.0, 5_000.0, 5_000.0],
			spec.effective_interest_rate()
		),
		1.0
	)

	# Der Kapitalwert ist die Annuität zum Barwert.
	t.check_approx(
		"Kapitalwert ist die Annuität zum Barwert",
		float(row.get("capital_value", 0.0)),
		BWLEngine.annuity_from_npv(
			float(row.get("npv", 0.0)),
			spec.effective_interest_rate(),
			spec.useful_life_years
		),
		0.01
	)

	# Der Rentabilitaetsindex muss ueber 1 liegen, wenn der Barwert
	# positiv ist.
	var npv_value := float(row.get("npv", 0.0))
	if npv_value > 0.0:
		t.check_true(
			"Rentabilitaetsindex ueber 1 bei positivem Barwert",
			float(row.get("profitability_index", 0.0)) > 1.0
		)

	# Die interne Rendite liegt zwischen 0 % und dem Effektivzins,
	# wenn der Barwert positiv ist.
	var irr := float(row.get("irr", -1.0))
	if npv_value > 0.0:
		t.check_true(
			"Interne Rendite positiv",
			irr > 0.0
		)
		t.check_true(
			"Interne Rendite unter dem Effektivzins",
			irr < spec.effective_interest_rate()
		)

	# Eine unrentable Anlage muss einen negativen Barwert haben.
	var bad := MachineSpec.new()
	bad.id = &"INV-SCHLECHT"
	bad.display_name = "Verlustanlage"
	bad.acquisition_cost = 80_000.0
	bad.residual_value = 0.0
	bad.useful_life_years = 5
	bad.imputed_interest_rate = 0.08
	bad.fixed_operating_costs = 30_000.0
	bad.variable_cost_per_unit = 50.0
	bad.price_per_unit = 55.0
	bad.capacity_units_per_year = 2_000.0

	var bad_rows := CostComparison.evaluate_at(bad, other, quantity)
	t.check_true(
		"Verlustanlage hat negativen Barwert",
		float(bad_rows[0].get("npv", 0.0)) < 0.0
	)
	t.check_true(
		"Verlustanlage hat negativen Kapitalwert",
		float(bad_rows[0].get("capital_value", 0.0)) < 0.0
	)
	t.check_true(
		"Verlustanlage hat Index unter 1",
		float(bad_rows[0].get("profitability_index", 0.0)) < 1.0
	)
