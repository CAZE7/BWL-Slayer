extends RefCounted

## Oekonometrie-Test ueber zehn simulierte Geschaeftsjahre.
##
## Der Risikoabschnitt des Fahrplans fordert genau diesen Nachweis:
## Die Wirtschaftssimulation darf ueber lange Zeitraeume weder
## explodieren (Zahlen laufen gegen unendlich) noch kollabieren
## (ein solide gefuehrter Betrieb geht pleite). Geprueft wird ein
## kompletter Spielverlauf mit Produktion, Nachfrage, Fremdkapital
## und Dividendenpolitik - 3.600 Tage am Stueck.


static func run(t: TestFramework) -> void:
	t.suite("Langzeit · 10 Jahre Grundbetrieb")
	_test_ten_years_base(t)
	t.suite("Langzeit · 10 Jahre mit Finanzierung")
	_test_ten_years_financed(t)


static func _make_spec() -> MachineSpec:
	# Die Startanlage des Spiels: 62 EUR Preis, 26 EUR variable
	# Kosten, ~11.600 Stueck Jahreskapazitaet.
	var spec := MachineSpec.new()
	spec.id = &"LANGLAUF"
	spec.display_name = "Langlauf-Anlage"
	spec.acquisition_cost = 16_000.0
	spec.residual_value = 0.0
	spec.useful_life_years = 4
	spec.imputed_interest_rate = 0.08
	spec.fixed_operating_costs = 1_180.20
	spec.variable_cost_per_unit = 26.0
	spec.price_per_unit = 62.0
	spec.capacity_units_per_year = 11_637.5
	spec.delivery_days = 0
	spec.installation_days = 0
	return spec


static func _build_sim() -> SimulationEngine:
	var spec := _make_spec()
	var sim := SimulationEngine.new()
	sim.specs[spec.id] = spec
	var m := MachineInstance.new(spec, "lang-1")
	m.state = MachineInstance.State.ACTIVE
	m.commissioned_year = 1
	sim.machines["lang-1"] = m
	sim.economy.book_investment(spec.acquisition_cost)
	return sim


## Prueft, dass alle zentralen Groessen endliche Zahlen sind.
## NaN oder Unendlich an einer Stelle wuerde sich sonst still durch
## alle Folgejahre ziehen.
static func _check_finite(t: TestFramework, label: String, sim: SimulationEngine) -> void:
	var values := [
		sim.economy.cash, sim.economy.equity, sim.economy.debt,
		sim.economy.fixed_assets, sim.economy.receivables,
		sim.economy.inventory_value, sim.economy.revenue_total,
		sim.economy.costs_total, sim.finished_goods,
	]
	var all_finite := true
	for v in values:
		if not is_finite(float(v)):
			all_finite = false
	t.check_true(label, all_finite)


static func _test_ten_years_base(t: TestFramework) -> void:
	var sim := _build_sim()
	t.track(sim)
	var start_cash := sim.economy.cash
	var start_equity := sim.economy.equity

	for _day in range(3_600):
		sim.advance_day()

	# Der Betrieb hat zehn Jahre durchlaufen.
	t.check_approx(
		"3.600 Tage simuliert",
		float(sim.stats.get("days_simulated", 0)),
		3_600.0,
		0.01
	)
	t.check_true("Zehn Jahresabschluesse", sim.year >= 10)

	# Keine Explosion, kein Kollaps.
	_check_finite(t, "Alle Groessen endlich (Grundbetrieb)", sim)
	t.check_true("Betrieb bleibt liquide", sim.economy.cash > 0.0)
	t.check_true("Eigenkapital bleibt positiv", sim.economy.equity > 0.0)

	# Ein profitables Produkt (DB 36 EUR am Marktpreis, Auftraege
	# zu auskoemmlichen Preisen) muss ueber zehn Jahre Vermoegen
	# aufbauen - sonst ist das Spiel unbalanciert.
	t.check_true("Kasse waechst ueber zehn Jahre", sim.economy.cash > start_cash)
	t.check_true("Eigenkapital waechst ueber zehn Jahre", sim.economy.equity > start_equity)

	# Aber nicht beliebig: Der Umsatz ist durch die Kapazitaet
	# gedeckelt. Mehr als Kapazitaet x Marktpreis x 10 Jahre kann
	# nicht entstanden sein.
	var revenue_ceiling := 11_637.5 * 62.0 * 10.0
	t.check_true("Umsatz bleibt unter der Kapazitaetsgrenze", sim.economy.revenue_total < revenue_ceiling)
	t.check_true("Umsatz entstanden", sim.economy.revenue_total > 0.0)
	t.check_true(
		"Auftraege wurden erfuellt",
		int(sim.stats.get("orders_completed", 0)) > 0
	)

	# Die Bilanz geht nach zehn Jahresabschluessen weiterhin auf.
	t.check_approx("Bilanz stimmt nach zehn Jahren", sim.economy.balance_check(), 0.0, 1.0)

	# Der Spielstand eines langen Spiels uebersteht den Roundtrip.
	var loaded := SimulationEngine.new()
	t.track(loaded)
	loaded.specs[sim.specs.keys()[0]] = sim.specs.values()[0]
	loaded.from_dict(sim.to_dict())
	t.check_approx("Roundtrip: Kasse", loaded.economy.cash, sim.economy.cash, 0.01)
	t.check_approx("Roundtrip: Eigenkapital", loaded.economy.equity, sim.economy.equity, 0.01)
	t.check_approx("Roundtrip: Tag", float(loaded.day), float(sim.day), 0.01)


static func _test_ten_years_financed(t: TestFramework) -> void:
	# Derselbe Betrieb, aber mit echter Finanzierungspolitik:
	# Annuitaetendarlehen ueber fuenf Jahre und 30 % Ausschuettung.
	# Das Zusammenspiel aus Schuldendienst, Dividende und laufendem
	# Geschaeft darf den Betrieb ueber zehn Jahre nicht kippen.
	var sim := _build_sim()
	t.track(sim)
	var loan := sim.take_structured_loan(20_000.0, 5, "ANNUITY", 0.07)
	var policy := sim.set_dividend_policy(0.30)

	t.check_true("Darlehen zum Start aufgenommen", bool(loan.get("ok", false)))
	t.check_true("Ausschuettungsquote gesetzt", bool(policy.get("ok", false)))

	for _day in range(3_600):
		sim.advance_day()

	_check_finite(t, "Alle Groessen endlich (finanziert)", sim)
	t.check_true("Finanzierter Betrieb bleibt liquide", sim.economy.cash > 0.0)
	t.check_true("Eigenkapital uebersteht Schuldendienst und Dividende", sim.economy.equity > 0.0)

	# Das Fuenf-Jahres-Darlehen ist nach zehn Jahren vollstaendig
	# getilgt und aus der Liste verschwunden.
	t.check_true("Darlehen nach Laufzeit getilgt", sim.loans.is_empty())
	t.check_approx("Keine Restschuld aus dem Darlehen", sim.structured_debt(), 0.0, 0.01)

	# Zehn profitable Jahre mit 30 % Ausschuettung muessen
	# Dividenden gezahlt haben.
	t.check_true("Dividenden sind geflossen", sim.economy.dividends_paid > 0.0)

	# Bilanz und Kennzahlen bleiben konsistent.
	t.check_approx("Bilanz stimmt (finanziert)", sim.economy.balance_check(), 0.0, 1.0)
	t.check_true(
		"FK-Quote im gueltigen Bereich",
		sim.debt_ratio() >= 0.0 and sim.debt_ratio() <= 1.0
	)
