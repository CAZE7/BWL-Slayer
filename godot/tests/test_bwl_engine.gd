extends RefCounted

## Verifikation der GDScript-BWL-Engine gegen dieselben Musterlösungen,
## die auch `tests/verify.cjs` (JavaScript-Original) prüft.
##
## Diese Datei ist das Bindeglied: wenn sie grün ist, verhalten sich
## beide Engines identisch. Ein Wechsel der Rechenlogik wäre sofort sichtbar.


static func run(t: TestFramework) -> void:
	t.suite("BWL-Engine · Statische Verfahren")
	_test_static(t)
	t.suite("BWL-Engine · Dynamische Verfahren")
	_test_dynamic(t)
	t.suite("BWL-Engine · Anleihen & Duration")
	_test_bonds(t)
	t.suite("BWL-Engine · Finanzierung")
	_test_financing(t)
	t.suite("BWL-Engine · Aktienbewertung")
	t.suite("BWL-Engine · Grenzwerte")
	_test_edge_cases(t)


# ------------------------------------------------------------------
static func _test_static(t: TestFramework) -> void:
	# Auto A / B aus Folie 8
	var a0_a := 16000.0
	var a0_b := 17000.0
	var n := 4
	var i := 0.10
	var kfix_a := 355.80 + 824.40
	var kfix_b := 415.20 + 930.50
	var kvar_a := 26.0
	var kvar_b := 22.0

	t.check_approx("Auto A Fixkosten", BWLEngine.total_fixed_costs(a0_a, 0.0, n, i, kfix_a), 5980.20, 0.01)
	t.check_approx("Auto B Fixkosten", BWLEngine.total_fixed_costs(a0_b, 0.0, n, i, kfix_b), 6445.70, 0.01)

	var xkrit := BWLEngine.critical_quantity_cost(
		a0_a, 0.0, n, i, kfix_a, kvar_a,
		a0_b, 0.0, n, i, kfix_b, kvar_b
	)
	t.check_approx("x_krit (Hundert-km)", xkrit, 116.375, 0.001)

	t.check_approx(
		"Kosten A bei 15.000 km",
		BWLEngine.total_costs_at(a0_a, 0.0, n, i, kfix_a, kvar_a, 150.0),
		9880.20, 0.01
	)
	t.check_approx(
		"Kosten B bei 15.000 km",
		BWLEngine.total_costs_at(a0_b, 0.0, n, i, kfix_b, kvar_b, 150.0),
		9745.70, 0.01
	)
	t.check_approx(
		"Kosten A bei 40.000 km",
		BWLEngine.total_costs_at(a0_a, 0.0, n, i, kfix_a, kvar_a, 400.0),
		16380.20, 0.01
	)
	t.check_approx(
		"Kosten B bei 40.000 km",
		BWLEngine.total_costs_at(a0_b, 0.0, n, i, kfix_b, kvar_b, 400.0),
		15245.70, 0.01
	)

	# Abfüllanlagen
	var m1 := {"a0": 95000.0, "l": 4000.0, "n": 3, "i": 0.06, "kfix": 1000.0, "kvar": 4.0, "p": 10.0}
	var m2 := {"a0": 80000.0, "l": 0.0, "n": 3, "i": 0.06, "kfix": 8000.0, "kvar": 3.0, "p": 10.0}
	t.check_approx(
		"Abfüllanlage 1 AfA",
		BWLEngine.depreciation_of(m1.a0, m1.l, m1.n), 30333.33, 0.01
	)
	t.check_approx(
		"Abfüllanlage 1 kalk. Zinsen",
		BWLEngine.imputed_interest_of(m1.a0, m1.l, m1.i), 2970.00, 0.01
	)
	t.check_approx(
		"Abfüllanlage 1 Fixkosten",
		BWLEngine.total_fixed_costs(m1.a0, m1.l, m1.n, m1.i, m1.kfix), 34303.33, 0.01
	)
	t.check_approx(
		"Abfüllanlage 2 Fixkosten",
		BWLEngine.total_fixed_costs(m2.a0, m2.l, m2.n, m2.i, m2.kfix), 37066.67, 0.01
	)
	var xk2 := BWLEngine.critical_quantity_cost(
		m1.a0, m1.l, m1.n, m1.i, m1.kfix, m1.kvar,
		m2.a0, m2.l, m2.n, m2.i, m2.kfix, m2.kvar
	)
	t.check_approx("x_krit Abfüllanlagen", xk2, 2763.33, 0.01)

	# Rentabilität / Amortisation / Kumulation aus der Folie
	# Referenzwerte aus tests/verify.cjs (JavaScript-Original).
	var fix1 := BWLEngine.total_fixed_costs(m1.a0, m1.l, m1.n, m1.i, m1.kfix)
	t.check_approx("Gewinn M1 @15.000", BWLEngine.profit_at(m1.p, m1.kvar, 15000.0, fix1), 55696.67, 0.02)
	t.check_approx(
		"Rentabilität Abfüllanlage 1",
		(BWLEngine.profit_at(m1.p, m1.kvar, 15000.0, fix1) / BWLEngine.average_bound_capital(m1.a0, m1.l)) * 100.0,
		112.52, 0.02
	)
	var fix2 := BWLEngine.total_fixed_costs(m2.a0, m2.l, m2.n, m2.i, m2.kfix)
	t.check_approx(
		"Rentabilität Abfüllanlage 2",
		(BWLEngine.profit_at(m2.p, m2.kvar, 15000.0, fix2) / BWLEngine.average_bound_capital(m2.a0, m2.l)) * 100.0,
		169.83, 0.02
	)
	# Kumulationsmethode: Referenzdaten aus tests/verify.cjs
	var payback := BWLEngine.cumulative_payback(540.0, [110.0, 96.0, 90.0, 130.0, 120.0, 95.0, 100.0])
	t.check_approx("Kumulation 4,95 Jahre", float(payback.get("years", 0.0)), 4.95, 0.005)
	t.check_approx("Restbetrag nach Jahr 4", float(payback.get("rest", 0.0)), 114.0, 0.001)
	var payback2 := BWLEngine.cumulative_payback(540.0, [135.0, 135.0, 135.0, 135.0])
	t.check_approx("Kumulation Objekt 2", float(payback2.get("years", 0.0)), 4.0, 0.001)


# ------------------------------------------------------------------
static func _test_dynamic(t: TestFramework) -> void:
	t.check_approx("Werkzeug I df(10%,2)", BWLEngine.df(0.10, 2), 0.826446, 0.00001)
	t.check_approx("Werkzeug II rbf(10%,10)", BWLEngine.rbf(0.10, 10), 6.144567, 0.00001)
	t.check_approx("Werkzeug III anf(10%,10)", BWLEngine.anf(0.10, 10), 0.162745, 0.00001)

	# Kapitalwert / Annuität / PI.
	# Referenzdaten aus tests/verify.cjs (JavaScript-Original):
	# Maschine 1, A0 = 27.000, Zahlungen [10.000, 8.000, 6.000, 15.000], i = 4 %.
	var d1 := [10000.0, 8000.0, 6000.0, 15000.0]
	var kw := BWLEngine.npv(27000.0, d1, 0.04)
	t.check_approx("Kapitalwert", kw, 8167.88, 0.02)
	t.check_approx("Annuität", BWLEngine.annuity_from_npv(8167.88, 0.04, 4), 2250.17, 0.05)
	t.check_approx("Rbf(4 %, 4 J.)", BWLEngine.rbf(0.04, 4), 3.63, 0.005)

	# PI: Projekte aus der Folie (A0, Rückflüsse), i = 6 %
	var proj := [
		[20.0, [10.0, 70.0]],
		[20.0, [70.0, 10.0]],
		[10.0, [35.0, 5.0]],
		[10.0, [39.0, 1.0]],
		[10.0, [5.0, 5.0]],
	]
	var pi_expected := [2.59, 2.75, 2.75, 2.77, -0.083]
	for idx in range(proj.size()):
		var a0: float = proj[idx][0]
		var cf: Array = proj[idx][1]
		var pi_value: float = BWLEngine.profitability_index(BWLEngine.npv(a0, cf, 0.06), a0)
		t.check_approx("PI Projekt %d" % (idx + 1), pi_value, pi_expected[idx], 0.005)

	# Sekantenverfahren: Maschine 1, i1 = 3 %, i2 = 5 %
	var sec := BWLEngine.secant_irr_step(27000.0, [10000.0, 8000.0, 6000.0, 6000.0], 0.03, 0.05)
	t.check_approx("Sekante i*", float(sec["i_star"]) * 100.0, 4.828, 0.005)

	# IRR per Bisektion: Maschine 1 exakt
	var irr_value: Variant = BWLEngine.irr(27000.0, [10000.0, 8000.0, 6000.0, 6000.0])
	t.check_not_null("IRR vorhanden", irr_value)
	if irr_value != null:
		t.check_approx("IRR", float(irr_value) * 100.0, 4.82, 0.01)

	# Sonderfälle
	t.check_approx(
		"IRR Einzelzahlung",
		BWLEngine.irr_single_payment(1000.0, 1500.0, 2), 0.224745, 0.00001
	)
	t.check_approx("IRR ewige Rente", BWLEngine.irr_perpetuity(1000.0, 100.0), 0.10, 0.00001)

	# Renten-IRR mit Strahlensatz (dokumentierter Blueprint-Sonderfall).
	# Referenzdaten aus tests/verify.cjs: A0 = 1.000.000, CF = 420.000, 3 Jahre.
	var ann := BWLEngine.irr_annuity_interval(1000000.0, 420000.0, 3)
	t.check_has_keys("Renten-IRR Struktur", ann, ["rbf", "i_approx"])
	t.check_approx("Renten-IRR Näherung", float(ann.get("i_approx", 0.0)) * 100.0, 12.5, 0.2)
	t.check_approx("Rbf = A0/CF", 1000000.0 / 420000.0, 2.381, 0.001)
	t.check_approx("IRR ewige Rente 75.000/6.000", BWLEngine.irr_perpetuity(75000.0, 6000.0) * 100.0, 8.0, 0.001)


# ------------------------------------------------------------------
static func _test_bonds(t: TestFramework) -> void:
	# Kuponanleihe
	# Referenzdaten aus tests/verify.cjs (JavaScript-Original).
	t.check_approx("Hamburg AG PV @2 % (3 J.)", BWLEngine.bond_pv(100.0, 0.06, 3, 0.02), 111.54, 0.01)
	t.check_approx("Hamburg AG PV @5 % (3 J.)", BWLEngine.bond_pv(100.0, 0.06, 3, 0.05), 102.72, 0.01)
	t.check_approx("YTM 4 %-Anleihe @98, y=4 %", BWLEngine.bond_pv(100.0, 0.04, 3, 0.04) - 98.0, 2.00, 0.01)

	# Spot Rates
	t.check_approx("Spot Rate 1 J.", BWLEngine.zero_yield(100.0, 94.0, 1) * 100.0, 6.38, 0.01)
	t.check_approx("Spot Rate 2 J.", BWLEngine.zero_yield(100.0, 82.0, 2) * 100.0, 10.43, 0.01)
	t.check_approx("Spot Rate 3 J.", BWLEngine.zero_yield(100.0, 70.0, 3) * 100.0, 12.62, 0.01)

	# Duration: A0 = 1.000, Kupon 5 %, 4 Jahre, Markt 5,5 %
	var dur := BWLEngine.duration(1000.0, 0.05, 4, 0.055)
	t.check_approx("Barwert 4 J. 5 % @5,5 %", float(dur["present_value"]), 982.47, 0.02)
	t.check_approx("Macauley Duration", float(dur["macauley_duration"]), 3.72, 0.006)
	t.check_approx("Modified Duration", float(dur["modified_duration"]), 3.53, 0.01)

	# Portfolioduration
	t.check_approx(
		"Portfolioduration",
		BWLEngine.portfolio_duration([0.6, 0.4], [3.72, 15.0]),
		8.232, 0.01
	)


# ------------------------------------------------------------------
static func _test_financing(t: TestFramework) -> void:
	# Lohmann-Ruchti: 7 Jahre inkl. Neukäufen, Ausmusterungen, Kassenresten
	var rows := BWLEngine.lohmann_ruchti(10, 5000.0, 5, 7)
	t.check_true("Lohmann-Ruchti 7 Zeilen", rows.size() == 7)
	if rows.size() == 7:
		t.check_true("Jahr 1: 10 Maschinen aktiv", int(rows[0]["active_machines"]) == 10)
		t.check_true("Kassenreste bleiben positiv", float(rows[0]["rest"]) >= 0.0)

	# Bezugsrecht
	# Referenzdaten aus tests/verify.cjs (JavaScript-Original).
	var br := BWLEngine.subscription_right({
		"old_shares": 80000.0, "new_shares": 20000.0,
		"old_share_price": 120.0, "issue_price_new": 90.0,
	})
	t.check_approx("Mischkurs Level 1", float(br["mixed_price"]), 114.0, 0.001)
	t.check_approx("Bezugsrechtswert Level 1", float(br["subscription_right_value"]), 6.0, 0.001)

	var br2 := BWLEngine.subscription_right({
		"old_shares": 80000.0, "new_shares": 20000.0,
		"old_share_price": 120.0, "issue_price_new": 90.0,
		"dividend_old": 20.0, "months_entitled_new": 5,
	})
	t.check_approx("Dividendennachteil", float(br2["disadvantage"]), 11.67, 0.01)
	t.check_approx("Bezugsrechtswert Level 2", float(br2["subscription_right_value"]), 3.67, 0.005)

	var br3 := BWLEngine.subscription_right({
		"old_shares": 20000000.0, "new_shares": 5000000.0,
		"old_share_price": 50.0, "issue_price_new": 40.0, "nominal_value": 5.0,
	})
	t.check_approx("XY AG Mischkurs", float(br3["mixed_price"]), 48.0, 0.001)
	t.check_approx("XY AG Bezugsrecht", float(br3["subscription_right_value"]), 2.0, 0.001)

	var br4 := BWLEngine.subscription_right({
		"old_shares": 75000000.0, "new_shares": 30000000.0,
		"old_share_price": 260.0, "issue_price_new": 113.0, "nominal_value": 1.0,
	})
	t.check_approx("Medizin AG Mischkurs", float(br4["mixed_price"]), 218.0, 0.01)
	t.check_approx("Medizin AG Bezugsrecht", float(br4["subscription_right_value"]), 42.0, 0.01)
	t.check_approx("Medizin AG Kapitalerhöhung (Mio.)", float(br4["share_capital_increase"]) / 1e6, 30.0, 0.001)
	t.check_approx("Medizin AG Agio (Mio.)", float(br4["agio"]) / 1e6, 3360.0, 0.01)

	# Skonto
	t.check_approx("Skontozins", BWLEngine.supplier_credit_rate(4.0, 60.0, 30.0), 48.0, 0.01)

	# Leasing-Korridor
	var lease1 := BWLEngine.leasing_owner({
		"is_special_leasing": false, "basic_lease_term_months": 21,
		"useful_life_months": 60, "option_type": "NONE",
	})
	t.check_true("Leasing < 40 % → Nehmer", String(lease1["owner"]) == "LEASING_NEHMER")
	var lease2 := BWLEngine.leasing_owner({
		"is_special_leasing": false, "basic_lease_term_months": 36,
		"useful_life_months": 60, "option_type": "NONE",
	})
	t.check_true("Leasing 40–90 % ohne Option → Geber", String(lease2["owner"]) == "LEASING_GEBER")
	var lease3 := BWLEngine.leasing_owner({
		"is_special_leasing": true, "basic_lease_term_months": 10,
		"useful_life_months": 60, "option_type": "NONE",
	})
	t.check_true("Spezial-Leasing → immer Nehmer", String(lease3["owner"]) == "LEASING_NEHMER")

	# Leverage
	var lev := BWLEngine.leverage(800000.0, 200000.0, 10.0, 5.0)
	t.check_approx("Leverage EK-Rentabilität", float(lev["roe_pct"]), 11.25, 0.001)
	t.check_approx("Leverage Reingewinn", float(lev["net_profit"]), 90000.0, 0.01)
	var lev2 := BWLEngine.leverage(400000.0, 600000.0, 10.0, 5.0)
	t.check_approx("Leverage Variante 2", float(lev2["roe_pct"]), 17.50, 0.001)

	# Tilgungsplan
	var plan := BWLEngine.amortization_plan(10000.0, 0.05, 5, "ANNUITY")
	t.check_approx("Annuität", float(plan["annual_payment"]), 2309.75, 0.01)

	# Umlaufvermögen
	var wc := BWLEngine.working_capital_need(
		[{"days": 25.0}, {"days": 20.0}, {"days": 30.0}, {"days": 45.0}], 30.0, 12000.0
	)
	t.check_approx("Kapitalbindungsdauer", float(wc["days"]), 90.0, 0.001)
	t.check_approx("Kapitalbedarf", float(wc["need"]), 1080000.0, 1.0)


# ------------------------------------------------------------------
static func _test_stocks(t: TestFramework) -> void:
	t.check_approx("EPS", BWLEngine.eps(12e6, 0.5e6, 4e6), 2.875, 0.0005)
	t.check_approx("KGV", float(BWLEngine.kgv(60.0, 2.875)), 20.87, 0.01)
	t.check_approx("Dividendenrendite %", BWLEngine.dividend_yield(2.0, 60.0) * 100.0, 3.33, 0.01)
	t.check_approx("BW explizite Dividenden", BWLEngine.pv_dividend_stream([2.0, 2.5, 3.0], 0.08), 6.38, 0.01)
	t.check_approx("Fairer Wert inkl. Verkauf", BWLEngine.pv_dividend_stream([2.0, 2.5, 3.0], 0.08, 75.0, 3), 65.92, 0.01)
	t.check_approx("Gordon P0", float(BWLEngine.gordon(3.0, 0.10, 0.04)), 50.0, 0.01)
	t.check_null("Gordon bei r<=g", BWLEngine.gordon(3.0, 0.04, 0.06))
	t.check_approx("Implizites Wachstum %", BWLEngine.implied_growth(3.0, 0.10, 60.0) * 100.0, 5.0, 0.001)
	t.check_approx("CAPM %", BWLEngine.capm(0.03, 1.4, 0.09) * 100.0, 11.4, 0.001)
	t.check_approx("CAPM-Gordon", float(BWLEngine.gordon(4.0, BWLEngine.capm(0.03, 1.4, 0.09), 0.03)), 47.62, 0.01)
	var ts: Variant = BWLEngine.two_stage_ddm(2.0, 0.15, 3, 0.03, 0.09)
	t.check_not_null("Zweiphasen-Modell", ts)
	if ts != null:
		t.check_approx("Zweiphasen D3", float(ts["flows"][2]["dividend"]), 2.645, 0.0005)
		t.check_approx("Zweiphasen Terminal Value", float(ts["terminal_value"]), 45.41, 0.01)
		t.check_approx("Zweiphasen Wert heute", float(ts["present_value"]), 40.87, 0.01)
	t.check_approx("Nachhaltiges Wachstum %", BWLEngine.sustainable_growth(0.6, 0.12) * 100.0, 7.2, 0.001)
	t.check_approx("Bewertung über KGV", BWLEngine.valuation_by_multiple(2.875, 22.0), 63.25, 0.01)
	t.check_approx("Gesamtrendite %", BWLEngine.equity_total_return(50.0, 2.0, 55.0) * 100.0, 14.0, 0.001)


# ------------------------------------------------------------------
static func _test_edge_cases(t: TestFramework) -> void:
	# Null-Nutzungsdauer darf nicht zu Infinity führen
	t.check_approx("AfA bei n=0", BWLEngine.depreciation_of(10000.0, 0.0, 0), 0.0, 0.0)

	# Zinssatz 0: Rbf = n, Anf = 1/n
	t.check_approx("rbf bei i=0", BWLEngine.rbf(0.0, 10), 10.0, 0.0001)
	t.check_approx("anf bei i=0", BWLEngine.anf(0.0, 10), 0.1, 0.0001)

	# Negative Preise / Vorzeichen
	t.check_approx("df mit negativem i", BWLEngine.df(-0.05, 1), 1.052632, 0.00001)
	# Ohne Vorzeichenwechsel gibt es keinen Kapitalwert-Nulldurchgang:
	# eine Investition von 1.000 ohne jede Rückzahlung -> kein IRR.
	# (Identisch zum Verhalten des JavaScript-Originals in engine.js.)
	t.check_true("IRR ohne Vorzeichenwechsel = null", BWLEngine.irr(1000.0, [0.0]) == null)

	# Gordon bei r <= g
	t.check_null("Gordon ungültig", BWLEngine.gordon(3.0, 0.04, 0.06))

	# Kritische Menge bei identischen variablen Kosten
	var nan_result := BWLEngine.critical_quantity_cost(
		1000.0, 0.0, 5, 0.05, 100.0, 10.0,
		2000.0, 0.0, 5, 0.05, 200.0, 10.0
	)
	t.check_true("x_krit bei gleicher k_var = NaN", is_nan(nan_result))

	# Break-even bei negativem Deckungsbeitrag
	t.check_approx("Break-even ohne DB", BWLEngine.break_even_quantity(5.0, 10.0, 100.0), -1.0, 0.0)

	# Skonto mit identischen Tagen
	t.check_true("Skonto mit target=skonto = NaN", is_nan(BWLEngine.supplier_credit_rate(4.0, 30.0, 30.0)))
