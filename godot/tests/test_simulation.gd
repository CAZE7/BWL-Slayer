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
	t.suite("Simulation · Finanzierung")
	_test_financing(t)
	t.suite("Simulation · Tilgungspläne")
	_test_structured_loans(t)
	t.suite("Simulation · Dividendenpolitik")
	_test_dividend_policy(t)
	t.suite("Simulation · Finanzplan & Aktienbewertung")
	_test_financial_tools(t)
	t.suite("Simulation · Kapitalerhöhung & Bezugsrecht")
	_test_capital_increase(t)


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

	# Der zahlungswirksame Jahres-Cashflow muss den Legacy-Werten
	# entsprechen: Gewinn + Abschreibung + kalkulatorische Zinsen.
	# Die kalkulatorischen Zinsen werden dabei herausgerechnet, die
	# Abschreibung hinzugefuegt.
	var quantity := 2_000.0
	var cashflow := spec.annual_cashflow_at(quantity)
	var expected_cashflow := (
		spec.contribution_margin_per_unit() * quantity
		- spec.fixed_operating_costs
	)
	t.check_approx(
		"Cashflow entspricht der Legacy-Definition",
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

	# Der Cashflow der Investitionsrechnung folgt der Legacy-Definition:
	# Gewinn + AfA + kalk. Zinsen. Im letzten Jahr kommt der Restwert
	# dazu. Die Reihe enthaelt NUR die Zahlungen ab t = 1 – die
	# Investition zieht BWLEngine.npv() ueber a0 selbst ab.
	var expected_flows: Array = []
	for year_index in spec.useful_life_years:
		var flow := spec.annual_cashflow_at(quantity)
		if year_index == spec.useful_life_years - 1:
			flow += spec.residual_value
		expected_flows.append(flow)

	t.check_approx(
		"Barwert stimmt mit der Engine ueberein",
		float(row.get("npv", 0.0)),
		BWLEngine.npv(spec.acquisition_cost, expected_flows, spec.effective_interest_rate()),
		1.0
	)

	# Der Barwert muss auch gegen eine unabhaengige Rechnung stimmen:
	# Investition bei t = 0, dann die Discounted Cashflows.
	var manual_npv := -spec.acquisition_cost
	for year_index in expected_flows.size():
		manual_npv += float(expected_flows[year_index]) / pow(
			1.0 + spec.effective_interest_rate(), float(year_index + 1)
		)
	t.check_approx(
		"Barwert stimmt mit der Handrechnung ueberein",
		float(row.get("npv", 0.0)),
		manual_npv,
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

	# Die interne Rendite liegt UEBER dem Diskontsatz, wenn der
	# Barwert positiv ist – das ist die Aussage des Barwertkriteriums.
	var irr := float(row.get("irr", -1.0))
	if npv_value > 0.0:
		t.check_true(
			"Interne Rendite positiv",
			irr > 0.0
		)
		t.check_true(
			"Interne Rendite ueber dem Diskontsatz",
			irr > spec.effective_interest_rate()
		)
	else:
		t.check_true(
			"Interne Rendite unter dem Diskontsatz",
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


# ------------------------------------------------------------------
# Die Finanzierung muss echte Konsequenzen haben.
#
# Kreditaufnahme erhoeht die Liquiditaet, belastet aber die Bilanz.
# Der Zinssatz richtet sich nach der Bonitaet. Die Tilgung ist eine
# Entscheidung des Spielers – und liquiditaetsbegrenzt.
# ------------------------------------------------------------------
static func _test_financing(t: TestFramework) -> void:
	var sim := SimulationEngine.new()
	t.track(sim)

	# Ausgangslage: 50.000 € Eigenkapital, kein Fremdkapital.
	t.check_approx("EK-Quote startet bei 100 %", sim.equity_ratio(), 1.0, 0.0001)
	t.check_approx("FK-Quote startet bei 0 %", sim.debt_ratio(), 0.0, 0.0001)

	# Der Kreditrahmen richtet sich nach dem Eigenkapital.
	var limit := sim.credit_limit()
	t.check_true("Kreditrahmen vorhanden", limit > 0.0)
	t.check_approx(
		"Kreditrahmen entspricht dem Eigenkapital",
		limit,
		50_000.0,
		1.0
	)

	# Kreditaufnahme: Kasse steigt, Fremdkapital steigt.
	var cash_before := sim.economy.cash
	var loan := sim.take_loan(20_000.0)
	t.check_true("Kredit aufgenommen", bool(loan.get("ok", false)))
	t.check_approx(
		"Kasse steigt um den Kreditbetrag",
		sim.economy.cash,
		cash_before + 20_000.0,
		0.01
	)
	t.check_approx(
		"Fremdkapital steigt",
		sim.economy.debt,
		20_000.0,
		0.01
	)

	# Die Bilanz muss weiterhin aufgehen: Kapital kommt von der Bank.
	t.check_approx("Bilanz stimmt nach Kredit", sim.economy.balance_check(), 0.0, 1.0)

	# Die FK-Quote ist jetzt 20.000 / 70.000 = 28,57 %.
	t.check_approx(
		"FK-Quote korrekt",
		sim.debt_ratio(),
		20_000.0 / 70_000.0,
		0.0001
	)

	# Der Zinssatz richtet sich nach der Bonitaet: bei 28,57 % FK
	# sind es 4 % + 0,2857 * 5 % = 5,43 %.
	t.check_approx(
		"Zinssatz richtet sich nach der Bonitaet",
		float(loan.get("rate", 0.0)),
		0.04 + (20_000.0 / 70_000.0) * 0.05,
		0.0001
	)

	# Ueberziehung des Kreditrahmens wird abgelehnt.
	var too_much := sim.take_loan(500_000.0)
	t.check_true("Ueberziehung wird abgelehnt", not bool(too_much.get("ok", false)))
	t.check_approx(
		"Abgelehnter Kredit veraendert die Kasse nicht",
		sim.economy.cash,
		cash_before + 20_000.0,
		0.01
	)

	# Tilgung: liquiditaetsbegrenzt und konfigurierbar.
	sim.set_repayment_share(0.5)
	var cash_before2 := sim.economy.cash
	var repay := sim.repay_loan(5_000.0)
	t.check_true("Tilgung moeglich", bool(repay.get("ok", false)))
	t.check_approx(
		"Kasse sinkt um den Tilgungsbetrag",
		sim.economy.cash,
		cash_before2 - 5_000.0,
		0.01
	)
	t.check_approx(
		"Fremdkapital sinkt um den Tilgungsbetrag",
		sim.economy.debt,
		15_000.0,
		0.01
	)
	t.check_approx(
		"Bilanz stimmt nach Tilgung",
		sim.economy.balance_check(),
		0.0,
		1.0
	)

	# Ein ungueltiger Tilgungsanteil wird abgelehnt.
	var bad_share := sim.set_repayment_share(1.5)
	t.check_true("Ungueltiger Tilgungsanteil abgelehnt", not bool(bad_share.get("ok", false)))
	t.check_approx(
		"Tilgungsanteil unveraendert",
		sim.economy.repayment_share,
		0.5,
		0.0001
	)

	# Die Automatik laesst sich abschalten: dann wird im
	# Jahresabschluss nicht getilgt.
	sim.economy.auto_repayment = false
	sim.economy.repayment_share = 1.0
	var debt_before := sim.economy.debt
	sim._close_business_year()
	t.check_approx(
		"Ohne Automatik wird nicht getilgt",
		sim.economy.debt,
		debt_before,
		0.01
	)

	# Die Zinsbelastung ist eine Kennzahl fuer den Berater.
	sim.economy.interest_paid_year = 900.0
	t.check_true(
		"Zinsbelastung berechenbar",
		sim.interest_burden() > 0.0
	)
	t.check_approx(
		"Finanzierungskosten = Zinsen + Tilgung",
		sim.financing_costs_year(),
		900.0 + sim.economy.repayment_year,
		0.01
	)


# ------------------------------------------------------------------
# Strukturierte Darlehen: Der Schuldendienst folgt exakt dem
# Tilgungsplan aus der BWL-Engine. Damit treibt derselbe Stoff, den
# das Lernsystem lehrt, die Simulation an - und jede Abweichung
# zwischen Lehre und Spiel waere ein Testfehler.
# ------------------------------------------------------------------
static func _test_structured_loans(t: TestFramework) -> void:
	# --- Annuitaetendarlehen ---------------------------------------
	var sim := SimulationEngine.new()
	t.track(sim)
	var result := sim.take_structured_loan(20_000.0, 4, "ANNUITY", 0.08)
	t.check_true("Annuitaetendarlehen aufgenommen", bool(result.get("ok", false)))
	t.check_approx("Fremdkapital = Darlehenssumme", sim.economy.debt, 20_000.0, 0.01)
	t.check_approx("Restschuld der Darlehen", sim.structured_debt(), 20_000.0, 0.01)

	var plan: Dictionary = BWLEngine.amortization_plan(20_000.0, 0.08, 4, "ANNUITY")
	var rows: Array = plan["rows"]

	# Jahr 1: Zins auf die volle Restschuld, Tilgung = Annuitaet - Zins.
	sim._close_business_year()
	var row1: Dictionary = rows[0]
	t.check_approx(
		"Jahr 1: Zins nach Plan",
		sim.economy.interest_paid_year,
		float(row1["interest"]),
		0.01
	)
	t.check_approx(
		"Jahr 1: Tilgung nach Plan",
		sim.economy.repayment_year,
		float(row1["redemption"]),
		0.01
	)
	t.check_approx(
		"Jahr 1: Restschuld nach Plan",
		sim.economy.debt,
		float(row1["rest_end"]),
		0.01
	)
	t.check_approx("Bilanz stimmt nach Schuldendienst", sim.economy.balance_check(), 0.0, 1.0)

	# Jahr 2: Der Zinsanteil sinkt, der Tilgungsanteil steigt.
	sim._close_business_year()
	var row2: Dictionary = rows[1]
	t.check_approx(
		"Jahr 2: Zins sinkt nach Plan",
		sim.economy.interest_paid_year,
		float(row2["interest"]),
		0.01
	)
	t.check_approx(
		"Jahr 2: Restschuld nach Plan",
		sim.economy.debt,
		float(row2["rest_end"]),
		0.01
	)
	t.check_true(
		"Tilgungsanteil steigt von Jahr zu Jahr",
		float(row2["redemption"]) > float(row1["redemption"])
	)

	# Nach der vollen Laufzeit ist das Darlehen getilgt und verschwindet.
	sim._close_business_year()
	sim._close_business_year()
	t.check_approx("Nach Laufzeitende schuldenfrei", sim.economy.debt, 0.0, 0.05)
	t.check_true("Darlehen aus der Liste entfernt", sim.loans.is_empty())

	# --- Ratendarlehen: konstante Tilgung --------------------------
	var sim2 := SimulationEngine.new()
	t.track(sim2)
	sim2.take_structured_loan(12_000.0, 3, "REDEMPTION", 0.05)
	sim2._close_business_year()
	t.check_approx("Ratendarlehen: Tilgung Jahr 1", sim2.economy.repayment_year, 4_000.0, 0.01)
	t.check_approx("Ratendarlehen: Zins Jahr 1", sim2.economy.interest_paid_year, 600.0, 0.01)
	sim2._close_business_year()
	t.check_approx("Ratendarlehen: Tilgung Jahr 2 konstant", sim2.economy.repayment_year, 4_000.0, 0.01)
	t.check_approx("Ratendarlehen: Zins Jahr 2 sinkt", sim2.economy.interest_paid_year, 400.0, 0.01)

	# --- Endfaelliges Darlehen: Tilgung erst am Ende ----------------
	var sim3 := SimulationEngine.new()
	t.track(sim3)
	sim3.take_structured_loan(10_000.0, 2, "FEST", 0.06)
	sim3._close_business_year()
	t.check_approx("Endfaellig: keine Tilgung im Jahr 1", sim3.economy.repayment_year, 0.0, 0.01)
	t.check_approx("Endfaellig: Zins Jahr 1", sim3.economy.interest_paid_year, 600.0, 0.01)
	t.check_approx("Endfaellig: Restschuld unveraendert", sim3.economy.debt, 10_000.0, 0.01)
	sim3._close_business_year()
	t.check_approx("Endfaellig: volle Tilgung am Ende", sim3.economy.repayment_year, 10_000.0, 0.01)
	t.check_true("Endfaellig: Darlehen abgeschlossen", sim3.loans.is_empty())

	# --- Validierung und Persistenz --------------------------------
	var invalid_kind := sim3.take_structured_loan(5_000.0, 3, "BALLON")
	t.check_true("Unbekannte Darlehensform abgelehnt", not bool(invalid_kind.get("ok", false)))
	var invalid_years := sim3.take_structured_loan(5_000.0, 0, "ANNUITY")
	t.check_true("Laufzeit unter 1 Jahr abgelehnt", not bool(invalid_years.get("ok", false)))

	var sim4 := SimulationEngine.new()
	t.track(sim4)
	sim4.take_structured_loan(8_000.0, 5, "REDEMPTION", 0.07)
	var loaded_sim := SimulationEngine.new()
	t.track(loaded_sim)
	loaded_sim.from_dict(sim4.to_dict())
	t.check_approx(
		"Darlehen ueberlebt den Spielstand",
		loaded_sim.structured_debt(),
		8_000.0,
		0.01
	)
	t.check_true("Darlehensliste wiederhergestellt", loaded_sim.loans.size() == 1)


# ------------------------------------------------------------------
# Dividendenpolitik: Die Ausschuettungsquote bestimmt, welcher Teil
# des Jahresueberschusses an die Eigentuemer fliesst. Der Rest bleibt
# als Selbstfinanzierung im Unternehmen. Verlustjahre schuetten
# nichts aus.
# ------------------------------------------------------------------
static func _test_dividend_policy(t: TestFramework) -> void:
	var sim := SimulationEngine.new()
	t.track(sim)

	# Quote setzen und validieren.
	var ok := sim.set_dividend_policy(0.4)
	t.check_true("Ausschuettungsquote gesetzt", bool(ok.get("ok", false)))
	var rejected_ratio := sim.set_dividend_policy(1.5)
	t.check_true("Quote ueber 100 % abgelehnt", not bool(rejected_ratio.get("ok", false)))
	t.check_approx("Quote unveraendert nach Ablehnung", sim.economy.dividend_policy_ratio, 0.4, 0.0001)

	# Ein Gewinnjahr: 10.000 Ueberschuss -> 4.000 Dividende.
	sim.economy.cash += 10_000.0
	sim.economy.revenue_current_year += 10_000.0
	sim.economy.revenue_total += 10_000.0
	var equity_before := sim.economy.equity
	sim._close_business_year()
	t.check_approx("Dividende = Quote x Ueberschuss", sim.economy.dividends_paid, 4_000.0, 0.01)
	t.check_approx(
		"Eigenkapital: Gewinn minus Ausschuettung",
		sim.economy.equity,
		equity_before + 10_000.0 - 4_000.0,
		0.01
	)
	t.check_approx("Bilanz stimmt nach Dividende", sim.economy.balance_check(), 0.0, 1.0)

	# Ein Verlustjahr schuettet nichts aus.
	var sim2 := SimulationEngine.new()
	t.track(sim2)
	sim2.set_dividend_policy(0.5)
	sim2.economy.costs_current_year += 2_000.0
	sim2.economy.costs_total += 2_000.0
	sim2._close_business_year()
	t.check_approx("Verlustjahr: keine Dividende", sim2.economy.dividends_paid, 0.0, 0.01)

	# Die Politik ueberlebt den Spielstand.
	var restored_eco := EconomyState.new()
	restored_eco.from_dict(sim.economy.to_dict())
	t.check_approx("Quote im Spielstand", restored_eco.dividend_policy_ratio, 0.4, 0.0001)


# ------------------------------------------------------------------
# Finanzplan, Aktienbewertung und Lohmann-Ruchti-Ausblick: Die
# Werkzeuge rechnen mit denselben Engine-Funktionen, die das
# Lernsystem lehrt.
# ------------------------------------------------------------------
static func _test_financial_tools(t: TestFramework) -> void:
	# --- Finanzplan -------------------------------------------------
	var spec := _make_spec(&"FINPLAN", 16_000.0, 1_200.0, 2.0, 10.0)
	var sim := SimulationEngine.new()
	t.track(sim)
	sim.specs[spec.id] = spec
	var m := MachineInstance.new(spec, "finplan-1")
	m.state = MachineInstance.State.ACTIVE
	m.commissioned_year = 1
	sim.machines["finplan-1"] = m

	var plan := sim.financial_plan()
	# Tageskosten: Fixkosten 1.200/360 + variable 2 EUR x Tageskapazitaet.
	var expected_daily := 1_200.0 / 360.0 + 2.0 * spec.capacity_units_per_year / 360.0
	t.check_approx("Finanzplan: Tageskosten", float(plan["daily_cost"]), expected_daily, 0.01)
	# Kapitalbindung: 5 Tage Lager + 1 Tag Produktion + 30 Tage Ziel.
	var wc: Dictionary = plan["working_capital"]
	t.check_approx("Finanzplan: Kapitalbindungsdauer", float(wc["days"]), 36.0, 0.01)
	t.check_approx(
		"Finanzplan: Kapitalbedarf = Dauer x Tageskosten",
		float(wc["need"]),
		36.0 * expected_daily,
		0.5
	)
	t.check_true(
		"Finanzplan: Fixkosten als Auszahlung",
		float(plan["expected_outflow"]) >= 1_200.0
	)

	# Mit Darlehen erscheint der Schuldendienst im Plan.
	sim.take_structured_loan(9_000.0, 3, "REDEMPTION", 0.06)
	var plan2 := sim.financial_plan()
	t.check_approx("Finanzplan: Darlehenszins", float(plan2["loan_interest"]), 540.0, 0.01)
	t.check_approx("Finanzplan: Darlehenstilgung", float(plan2["loan_principal"]), 3_000.0, 0.01)

	# --- Aktienbewertung ---------------------------------------------
	var sim2 := SimulationEngine.new()
	t.track(sim2)
	sim2.set_dividend_policy(0.5)
	# Zuletzt festgestelltes Ergebnis: 5.000 EUR (extern, keine kalk. Zinsen).
	sim2.economy.profit_current_year = 5_000.0
	sim2.economy.imputed_interest_year = 0.0
	var value := sim2.share_valuation(0.025, 1.1, 0.08)
	t.check_approx("Bewertung: Ergebnis je Aktie", float(value["eps"]), 5.0, 0.0001)
	t.check_approx("Bewertung: Buchwert je Aktie", float(value["book_value_per_share"]), 50.0, 0.0001)
	t.check_approx("Bewertung: Dividende je Aktie", float(value["dividend_per_share"]), 2.5, 0.0001)
	# g = Thesaurierung 0,5 x EK-Rendite 10 % = 5 %.
	t.check_approx("Bewertung: nachhaltiges Wachstum", float(value["growth"]), 0.05, 0.0001)
	# r = 2,5 % + 1,1 x 5,5 % = 8,55 %.
	t.check_approx("Bewertung: CAPM-Kapitalkosten", float(value["cost_of_equity"]), 0.0855, 0.0001)
	# Gordon: D1 / (r - g) = 2,625 / 0,0355.
	t.check_approx(
		"Bewertung: Gordon-Wert",
		float(value["gordon_value"]),
		2.625 / 0.0355,
		0.01
	)

	# --- Lohmann-Ruchti-Ausblick -------------------------------------
	var sim3 := SimulationEngine.new()
	t.track(sim3)
	sim3.specs[spec.id] = spec
	for i in range(3):
		var lm := MachineInstance.new(spec, "lr-%d" % i)
		lm.state = MachineInstance.State.ACTIVE
		lm.commissioned_year = 1
		sim3.machines["lr-%d" % i] = lm
	var outlook := sim3.lohmann_ruchti_outlook(7)
	t.check_true("Lohmann-Ruchti: Ausblick vorhanden", bool(outlook.get("ok", false)))
	t.check_true("Lohmann-Ruchti: Anlagenzahl erkannt", int(outlook.get("machines", 0)) == 3)
	var engine_rows: Array = BWLEngine.lohmann_ruchti(
		3, spec.acquisition_cost, spec.useful_life_years, 7
	)
	var outlook_rows: Array = outlook["rows"]
	t.check_true("Lohmann-Ruchti: 7 Jahreszeilen", outlook_rows.size() == 7)
	t.check_approx(
		"Lohmann-Ruchti: AfA-Parität mit der Engine",
		float(outlook_rows[0]["depreciation"]),
		float(engine_rows[0]["depreciation"]),
		0.01
	)

	# Ohne aktive Anlage gibt es keinen Ausblick.
	var empty := SimulationEngine.new()
	t.track(empty)
	var none := empty.lohmann_ruchti_outlook(5)
	t.check_true("Lohmann-Ruchti: ohne Anlagen abgelehnt", not bool(none.get("ok", false)))


# ------------------------------------------------------------------
# Kapitalerhoehung mit Bezugsrecht: Aussenfinanzierung ueber junge
# Aktien. Der Bezugsrechtswert gleicht den Altaktionaeren den
# Kursverlust zum Mischkurs aus - gerechnet mit demselben Verfahren,
# das das Lernsystem lehrt (BWLEngine.subscription_right).
# ------------------------------------------------------------------
static func _test_capital_increase(t: TestFramework) -> void:
	var sim := SimulationEngine.new()
	t.track(sim)

	# Frischer Betrieb: kein festgestellter Gewinn, keine Dividende.
	# Der Kurs ist der Buchwert je Aktie: 50.000 / 1.000 = 50 EUR.
	t.check_approx("Startkurs = Buchwert je Aktie", sim.current_share_price(), 50.0, 0.0001)
	t.check_approx("1.000 Aktien zu Beginn", sim.shares_outstanding, 1_000.0, 0.01)

	# Bezugsverhaeltnis 4:1 zum Ausgabekurs 40 EUR:
	# 250 junge Aktien x 40 EUR = 10.000 EUR Zufluss.
	var cash_before := sim.economy.cash
	var equity_before := sim.economy.equity
	var result := sim.capital_increase(4.0, 40.0)
	t.check_true("Kapitalerhoehung durchgefuehrt", bool(result.get("ok", false)))
	t.check_approx("250 junge Aktien", float(result.get("new_shares", 0.0)), 250.0, 0.01)
	t.check_approx("Zufluss 10.000", float(result.get("inflow", 0.0)), 10_000.0, 0.01)
	t.check_approx("Kasse steigt um den Zufluss", sim.economy.cash, cash_before + 10_000.0, 0.01)
	t.check_approx("Eigenkapital steigt um den Zufluss", sim.economy.equity, equity_before + 10_000.0, 0.01)
	t.check_approx("1.250 Aktien danach", sim.shares_outstanding, 1_250.0, 0.01)
	t.check_approx("Bilanz stimmt nach Kapitalerhoehung", sim.economy.balance_check(), 0.0, 1.0)

	# Mischkurs: (1.000 x 50 + 250 x 40) / 1.250 = 48 EUR.
	t.check_approx("Mischkurs 48", float(result.get("mixed_price", 0.0)), 48.0, 0.01)
	# Bezugsrecht: (50 - 40) / (4 + 1) = 2 EUR.
	t.check_approx("Bezugsrecht 2", float(result.get("subscription_right_value", 0.0)), 2.0, 0.01)

	# Paritaet mit der Engine-Funktion des Lernsystems.
	var reference: Dictionary = BWLEngine.subscription_right({
		"old_shares": 1_000.0,
		"new_shares": 250.0,
		"old_share_price": 50.0,
		"issue_price_new": 40.0,
		"nominal_value": 1.0,
	})
	t.check_approx(
		"Paritaet: Bezugsrechtswert",
		float(result.get("subscription_right_value", 0.0)),
		float(reference["subscription_right_value"]),
		0.0001
	)
	t.check_approx(
		"Paritaet: Mischkurs",
		float(result.get("mixed_price", 0.0)),
		float(reference["mixed_price"]),
		0.0001
	)

	# Nach der Erhoehung sinkt der rechnerische Kurs auf den
	# Buchwert je Aktie der groesseren Aktienzahl: 60.000 / 1.250 = 48.
	t.check_approx("Kurs nach Erhoehung = Mischkurs", sim.current_share_price(), 48.0, 0.01)

	# Ein Ausgabekurs ueber dem aktuellen Kurs wird abgelehnt:
	# niemand zeichnet junge Aktien teurer als die alten.
	var overpriced := sim.capital_increase(4.0, 60.0)
	t.check_true("Ausgabekurs ueber Kurs abgelehnt", not bool(overpriced.get("ok", false)))
	# Ein Bezugsverhaeltnis unter 1:1 ist unzulaessig.
	var tiny_ratio := sim.capital_increase(0.5, 10.0)
	t.check_true("Bezugsverhaeltnis unter 1:1 abgelehnt", not bool(tiny_ratio.get("ok", false)))
	t.check_approx("Abgelehnte Erhoehung veraendert nichts", sim.shares_outstanding, 1_250.0, 0.01)

	# Die Aktienzahl ueberlebt den Spielstand.
	var loaded := SimulationEngine.new()
	t.track(loaded)
	loaded.from_dict(sim.to_dict())
	t.check_approx("Aktienzahl im Spielstand", loaded.shares_outstanding, 1_250.0, 0.01)
