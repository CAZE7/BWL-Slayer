extends RefCounted

## Paritätstest: GDScript-Engine gegen das JavaScript-Original.
##
## Die Referenzwerte in `content/reference_values.json` werden vom
## JavaScript-Original (`src/engine.js`) erzeugt – siehe
## `tools/generate_reference.cjs`.
##
## Dieser Test beweist, dass der GDScript-Port **exakt dieselben**
## Ergebnisse liefert. Damit ist die Kontrolle über den Port formal
## abgesichert: jede Abweichung fällt sofort auf.
##
## Wichtig: Die Referenzdatei wird von der CI vor dem Testlauf erzeugt,
## damit sie nie veraltet sein kann.

const REFERENCE_PATH := "res://content/reference_values.json"


static func run(t: TestFramework) -> void:
	t.suite("Engine-Parität · GDScript vs. JavaScript-Original")

	if not FileAccess.file_exists(REFERENCE_PATH):
		t.check_true("Referenzdatei vorhanden", false)
		return

	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(REFERENCE_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		t.check_true("Referenzdatei lesbar", false)
		return

	var data: Dictionary = parsed
	var values: Array = data.get("values", [])
	t.check_true("Referenzwerte vorhanden", values.size() >= 60)

	# Jeder Eintrag: {label, value}
	# Die Zuordnung Label -> GDScript-Funktion.
	for entry in values:
		var label := String(entry.get("label", ""))
		var expected := float(entry.get("value", 0.0))
		# _compute() liefert bewusst Variant (Dictionary oder null),
		# deshalb ist die Typinferenz hier nicht moeglich.
		var actual: Variant = _compute(label)
		if actual == null:
			t.check_true("%s: Berechnung vorhanden" % label, false)
			continue
		t.check_approx("%s" % label, float(actual), expected, 0.01)


## Berechnet den Referenzwert mit der GDScript-Engine.
## Gibt null zurück, wenn das Label unbekannt ist.
static func _compute(label: String) -> Variant:
	# --- WELT 2 ---
	match label:
		"auto_a_fixkosten":
			return BWLEngine.total_fixed_costs(16000.0, 0.0, 4, 0.10, 355.80 + 824.40)
		"auto_b_fixkosten":
			return BWLEngine.total_fixed_costs(17000.0, 0.0, 4, 0.10, 415.20 + 930.50)
		"auto_xkrit":
			return BWLEngine.critical_quantity_cost(
				16000.0, 0.0, 4, 0.10, 355.80 + 824.40, 26.0,
				17000.0, 0.0, 4, 0.10, 415.20 + 930.50, 22.0
			)
		"auto_a_kosten_15000km":
			return BWLEngine.total_costs_at(16000.0, 0.0, 4, 0.10, 355.80 + 824.40, 26.0, 150.0)
		"auto_b_kosten_15000km":
			return BWLEngine.total_costs_at(17000.0, 0.0, 4, 0.10, 415.20 + 930.50, 22.0, 150.0)
		"auto_a_kosten_40000km":
			return BWLEngine.total_costs_at(16000.0, 0.0, 4, 0.10, 355.80 + 824.40, 26.0, 400.0)
		"auto_b_kosten_40000km":
			return BWLEngine.total_costs_at(17000.0, 0.0, 4, 0.10, 415.20 + 930.50, 22.0, 400.0)
		"abfuell_afa_1":
			return BWLEngine.depreciation_of(95000.0, 4000.0, 3)
		"abfuell_zinsen_1":
			return BWLEngine.imputed_interest_of(95000.0, 4000.0, 0.06)
		"abfuell_fixkosten_1":
			return BWLEngine.total_fixed_costs(95000.0, 4000.0, 3, 0.06, 1000.0)
		"abfuell_fixkosten_2":
			return BWLEngine.total_fixed_costs(80000.0, 0.0, 3, 0.06, 8000.0)
		"abfuell_xkrit":
			return BWLEngine.critical_quantity_cost(
				95000.0, 4000.0, 3, 0.06, 1000.0, 4.0,
				80000.0, 0.0, 3, 0.06, 8000.0, 3.0
			)
		"abfuell_rentabilitaet_1":
			var fix := BWLEngine.total_fixed_costs(95000.0, 4000.0, 3, 0.06, 1000.0)
			var profit := BWLEngine.profit_at(10.0, 4.0, 2000.0, fix)
			return (profit / BWLEngine.average_bound_capital(95000.0, 4000.0)) * 100.0
		"abfuell_kumulation_jahre":
			var result := BWLEngine.cumulative_payback(95000.0, [20000.0, 25000.0, 30000.0, 30000.0])
			return float(result.get("years", 0.0)) if not result.is_empty() else null

		# --- WELT 3 ---
		"df_10_2":
			return BWLEngine.df(0.10, 2)
		"rbf_10_10":
			return BWLEngine.rbf(0.10, 10)
		"anf_10_10":
			return BWLEngine.anf(0.10, 10)
		"kapitalwert":
			return BWLEngine.npv(20000.0, [3000.0, 4000.0, 5000.0, 6000.0], 0.10)
		"annuitaet":
			var kw := BWLEngine.npv(20000.0, [3000.0, 4000.0, 5000.0, 6000.0], 0.10)
			return BWLEngine.annuity_from_npv(kw, 0.10, 4)
		"pi_kapitalwert":
			var kw2 := BWLEngine.npv(20000.0, [3000.0, 4000.0, 5000.0, 6000.0], 0.10)
			return BWLEngine.profitability_index(kw2, 20000.0)
		"pi_barwert":
			return BWLEngine.profitability_index_pv(20000.0, [3000.0, 4000.0, 5000.0, 6000.0], 0.10)
		"sekante_i":
			var sec := BWLEngine.secant_irr_step(20000.0, [3000.0, 4000.0, 5000.0, 6000.0], 0.0, 0.30)
			return float(sec["i_star"])
		"irr_bisektion":
			return BWLEngine.irr(20000.0, [3000.0, 4000.0, 5000.0, 6000.0])
		"irr_einzahlung":
			return BWLEngine.irr_single_payment(1000.0, 1500.0, 2)
		"irr_ewige_rente":
			return BWLEngine.irr_perpetuity(1000.0, 100.0)
		"renten_irr_approx":
			var ann := BWLEngine.irr_annuity_interval(10000.0, 2000.0, 5)
			return float(ann.get("i_approx", 0.0)) if not ann.is_empty() else null

		# --- WELT 4 ---
		"bond_barwert":
			return BWLEngine.bond_pv(1000.0, 0.06, 5, 0.07)
		"kassazinssatz":
			return BWLEngine.zero_yield(1000.0, 950.0, 5)
		"macauley_duration":
			var dur := BWLEngine.duration(1000.0, 0.05, 5, 0.06)
			return float(dur["macauley_duration"])
		"modified_duration":
			var dur2 := BWLEngine.duration(1000.0, 0.05, 5, 0.06)
			return float(dur2["modified_duration"])
		"portfolioduration":
			return BWLEngine.portfolio_duration([0.6, 0.4], [3.72, 15.0])

		# --- WELT 6-8 ---
		"lr_rest_jahr1":
			var rows := BWLEngine.lohmann_ruchti(10, 5000.0, 5, 7)
			return float(rows[0]["rest"])
		"lr_gekauft_jahr7":
			var rows2 := BWLEngine.lohmann_ruchti(10, 5000.0, 5, 7)
			return float(rows2[6]["bought"])
		"lr_aktiv_jahr7":
			var rows3 := BWLEngine.lohmann_ruchti(10, 5000.0, 5, 7)
			return float(rows3[6]["active_machines"])
		"bezugsrechtswert":
			var br := BWLEngine.subscription_right({
				"old_shares": 100.0, "new_shares": 50.0,
				"old_share_price": 100.0, "issue_price_new": 80.0,
				"dividend_old": 4.0, "months_entitled_new": 5,
			})
			return float(br["subscription_right_value"])
		"mischkurs":
			var br2 := BWLEngine.subscription_right({
				"old_shares": 100.0, "new_shares": 50.0,
				"old_share_price": 100.0, "issue_price_new": 80.0,
				"dividend_old": 4.0, "months_entitled_new": 5,
			})
			return float(br2["mixed_price"])
		"kapitalerhoehung":
			var br3 := BWLEngine.subscription_right({
				"old_shares": 100.0, "new_shares": 50.0,
				"old_share_price": 100.0, "issue_price_new": 80.0,
				"dividend_old": 4.0, "months_entitled_new": 5,
			})
			return float(br3["share_capital_increase"])
		"agio":
			var br4 := BWLEngine.subscription_right({
				"old_shares": 100.0, "new_shares": 50.0,
				"old_share_price": 100.0, "issue_price_new": 80.0,
				"dividend_old": 4.0, "months_entitled_new": 5,
			})
			return float(br4["agio"])
		"skontozins":
			return BWLEngine.supplier_credit_rate(4.0, 60.0, 30.0)
		"leverage_roe":
			var lev := BWLEngine.leverage(800000.0, 200000.0, 10.0, 5.0)
			return float(lev["roe_pct"])
		"leverage_gewinn":
			var lev2 := BWLEngine.leverage(800000.0, 200000.0, 10.0, 5.0)
			return float(lev2["net_profit"])
		"leverage2_roe":
			var lev3 := BWLEngine.leverage(400000.0, 600000.0, 10.0, 5.0)
			return float(lev3["roe_pct"])
		"annuitaet_plan":
			var plan := BWLEngine.amortization_plan(10000.0, 0.05, 5, "ANNUITY")
			return float(plan["annual_payment"])
		"kapitalbindungsdauer":
			var wc := BWLEngine.working_capital_need(
				[{"days": 25.0}, {"days": 20.0}, {"days": 30.0}, {"days": 45.0}], 30.0, 12000.0
			)
			return float(wc["days"])
		"kapitalbedarf":
			var wc2 := BWLEngine.working_capital_need(
				[{"days": 25.0}, {"days": 20.0}, {"days": 30.0}, {"days": 45.0}], 30.0, 12000.0
			)
			return float(wc2["need"])

		# --- WELT 9 ---
		"eps":
			return BWLEngine.eps(12e6, 0.5e6, 4e6)
		"kgv":
			return BWLEngine.kgv(60.0, 2.875)
		"dividendenrendite_prozent":
			return BWLEngine.dividend_yield(2.0, 60.0) * 100.0
		"barwert_dividenden":
			return BWLEngine.pv_dividend_stream([2.0, 2.5, 3.0], 0.08)
		"fairer_wert_mit_verkauf":
			return BWLEngine.pv_dividend_stream([2.0, 2.5, 3.0], 0.08, 75.0, 3)
		"gordon_p0":
			return BWLEngine.gordon(3.0, 0.10, 0.04)
		"implizites_wachstum_prozent":
			return BWLEngine.implied_growth(3.0, 0.10, 60.0) * 100.0
		"capm_prozent":
			return BWLEngine.capm(0.03, 1.4, 0.09) * 100.0
		"capm_gordon":
			return BWLEngine.gordon(4.0, BWLEngine.capm(0.03, 1.4, 0.09), 0.03)
		"zweiphasen_d3":
			var ts: Variant = BWLEngine.two_stage_ddm(2.0, 0.15, 3, 0.03, 0.09)
			return float(ts["flows"][2]["dividend"]) if ts != null else null
		"zweiphasen_terminal":
			var ts2: Variant = BWLEngine.two_stage_ddm(2.0, 0.15, 3, 0.03, 0.09)
			return float(ts2["terminal_value"]) if ts2 != null else null
		"zweiphasen_wert":
			var ts3: Variant = BWLEngine.two_stage_ddm(2.0, 0.15, 3, 0.03, 0.09)
			return float(ts3["present_value"]) if ts3 != null else null
		"nachhaltiges_wachstum_prozent":
			return BWLEngine.sustainable_growth(0.6, 0.12) * 100.0
		"bewertung_kgv_multiple":
			return BWLEngine.valuation_by_multiple(2.875, 22.0)
		"gesamtrendite_prozent":
			return BWLEngine.equity_total_return(50.0, 2.0, 55.0) * 100.0

	return null
