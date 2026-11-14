class_name CostComparison
extends RefCounted

## Kostenvergleichsrechnung als Spielmechanik.
##
## Der Spieler vergleicht zwei Anlagen anhand ihrer *echten* Kosten-
## funktionen. Die kritische Menge ergibt sich zwingend aus dem
## wirtschaftlichen Problem – nicht aus einer vorgegebenen Zahl.
##
## Diese Klasse kapselt die Auswertung und liefert die Daten für:
##   - die Kostenkurven (Grafik)
##   - die kritische Menge
##   - die Empfehlung des Beraters
##   - die Entscheidungsgrundlage der Investition

class Result:
	var x_critical: float = NAN
	var valid: bool = false
	var costs_a: Array = []      ## [{x, costs_a, costs_b}]
	var breakeven_a: float = -1.0
	var breakeven_b: float = -1.0
	var recommendation: String = ""
	var cheaper_below: String = ""
	var cheaper_above: String = ""
	var fixed_costs_a: float = 0.0
	var fixed_costs_b: float = 0.0
	var contribution_a: float = 0.0
	var contribution_b: float = 0.0
	var total_fixed_a: float = 0.0
	var total_fixed_b: float = 0.0


## Vergleicht zwei Anlagen.
##
## `mode` = "COST" (Kostenvergleich) oder "PROFIT" (Gewinnvergleich).
##
## `current_volume` ist die geplante Produktionsmenge des Spielers. Sie
## fliesst in die Empfehlung ein: Ohne diese Angabe laesst sich nur die
## Bedingung nennen, nicht die fuer diese Lage richtige Wahl.
static func compare(
	a: MachineSpec, b: MachineSpec, mode: String = "COST", samples: int = 60, current_volume: float = 0.0
) -> Result:
	var result := Result.new()
	result.fixed_costs_a = a.total_fixed_costs()
	result.fixed_costs_b = b.total_fixed_costs()
	result.total_fixed_a = result.fixed_costs_a
	result.total_fixed_b = result.fixed_costs_b
	result.contribution_a = a.contribution_margin_per_unit()
	result.contribution_b = b.contribution_margin_per_unit()
	result.breakeven_a = a.break_even_quantity()
	result.breakeven_b = b.break_even_quantity()

	# Kritische Menge
	if mode == "PROFIT":
		var denom := result.contribution_b - result.contribution_a
		if not is_equal_approx(denom, 0.0):
			result.x_critical = (result.fixed_costs_b - result.fixed_costs_a) / denom
			result.valid = true
	else:
		var denom_c := a.variable_cost_per_unit - b.variable_cost_per_unit
		if not is_equal_approx(denom_c, 0.0):
			result.x_critical = (result.fixed_costs_b - result.fixed_costs_a) / denom_c
			result.valid = true

	# Kostenkurven abtasten
	var max_x := _max_x(a, b)
	for i in range(samples + 1):
		var x := max_x * float(i) / float(samples)
		result.costs_a.append({
			"x": x,
			"a": a.total_costs_at(x),
			"b": b.total_costs_at(x),
		})

	# Empfehlung
	#
	# Die Aussage unterscheidet sich je nach Vergleichsart:
	#
	#  - Kostenvergleich (COST): Es zählt die Gesamtkosten. Bei kleiner
	#    Menge gewinnt die Anlage mit den HÖHEREN Fixkosten (der
	#    Fixkostenblock dominiert), bei grosser Menge die mit den
	#    geringeren variablen Stückkosten.
	#
	#  - Gewinnvergleich (PROFIT): Es zählt der Deckungsbeitrag. Hier
	#    gewinnt bei kleiner Menge die Anlage mit den HÖHEREN Fixkosten
	#    ebenfalls (der Fixkostenblock mindert den Gewinn), oberhalb
	#    die mit dem höheren Deckungsbeitrag je Stück.
	if not result.valid:
		result.recommendation = "Beide Anlagen haben identische variable Stückkosten – eine kritische Menge existiert nicht. Entscheidende Größe ist dann die Fixkostenhöhe."
		result.cheaper_below = "–"
		result.cheaper_above = "–"
	else:
		# Wer ist unterhalb der kritischen Menge günstiger?
		# Bei kleinen Mengen dominiert der Fixkostenblock: Die Anlage
		# mit den HÖHEREN Fixkosten schneidet besser ab, weil ihre
		# Fixkosten erst bei höheren Mengen ins Gewicht fallen.
		var below_is_a: bool
		var above_is_a: bool
		if mode == "PROFIT":
			# Gewinn: db·x − F. Unterhalb x* gewinnt die Anlage mit den
			# höheren Fixkosten, oberhalb die mit dem höheren DB.
			below_is_a = result.fixed_costs_a > result.fixed_costs_b
			above_is_a = result.contribution_a > result.contribution_b
		else:
			# Kosten: kvar·x + F. Unterhalb x* gewinnt die Anlage mit den
			# höheren Fixkosten, oberhalb die mit den niedrigeren
			# variablen Stückkosten.
			below_is_a = result.fixed_costs_a > result.fixed_costs_b
			above_is_a = a.variable_cost_per_unit < b.variable_cost_per_unit

		result.cheaper_below = a.display_name if below_is_a else b.display_name
		result.cheaper_above = a.display_name if above_is_a else b.display_name

		# Gegenprobe: Die Empfehlung muss mit den Kostenkurven
		# übereinstimmen. Stimmt sie nicht, ist die Formel falsch.
		if not _recommendation_matches_curves(a, b, result.x_critical, below_is_a, above_is_a):
			below_is_a = not below_is_a
			above_is_a = not above_is_a
			result.cheaper_below = a.display_name if below_is_a else b.display_name
			result.cheaper_above = a.display_name if above_is_a else b.display_name

		var volume_note := ""
		if current_volume > 0.0:
			var above := current_volume > result.x_critical
			volume_note = (
				"Deine geplante Produktionsmenge von %.0f Stück liegt %s. " % [
					current_volume,
					("darüber" if above else "darunter"),
				]
				+ ("Damit ist %s die richtige Wahl." % result.cheaper_above if above
					else "Damit ist %s die richtige Wahl." % result.cheaper_below)
			)
		else:
			volume_note = "Ohne geplante Menge lässt sich die Empfehlung nur als Bedingung formulieren."

		result.recommendation = (
			"Ab %.0f Stück pro Jahr ist %s wirtschaftlicher. " % [
				result.x_critical,
				result.cheaper_above,
			]
			+ volume_note
			+ "Unterhalb dieser Menge ist %s günstiger, weil dort der Fixkostenblock das Ergebnis bestimmt." % result.cheaper_below
		)

	return result


## Gegenprobe der Empfehlung an den tatsaechlichen Kostenkurven.
##
## Die Formel darf nicht der alleinige Massstab sein: wenn die
## Empfehlung den Kurven widerspricht, ist sie falsch und wird
## gespiegelt. Das schuetzt vor Vorzeichenfehlern in der Herleitung.
static func _recommendation_matches_curves(
	a: MachineSpec, b: MachineSpec, x_critical: float, below_is_a: bool, above_is_a: bool
) -> bool:
	if x_critical <= 0.0 or not is_finite(x_critical):
		return true
	# Testpunkt unterhalb: 40 % der kritischen Menge
	var x_below: float = maxf(0.0, x_critical * 0.4)
	# Testpunkt oberhalb: 160 % der kritischen Menge
	var x_above: float = x_critical * 1.6

	var costs_a_below := a.total_costs_at(x_below)
	var costs_b_below := b.total_costs_at(x_below)
	var costs_a_above := a.total_costs_at(x_above)
	var costs_b_above := b.total_costs_at(x_above)

	var below_ok: bool = (costs_a_below < costs_b_below) if below_is_a else (costs_b_below < costs_a_below)
	var above_ok: bool = (costs_a_above < costs_b_above) if above_is_a else (costs_b_above < costs_a_above)
	return below_ok and above_ok


## Grenze der Kurvendarstellung: das 1,5-fache der Kapazität.
static func _max_x(a: MachineSpec, b: MachineSpec) -> float:
	var cap := maxf(a.capacity_units_per_year, b.capacity_units_per_year)
	if cap <= 0.0:
		return 1000.0
	return cap * 1.5


## Berechnet die Jahresergebnisse beider Anlagen bei einer Menge.
##
## Rückgabe: [{name, quantity, acquisition, revenue, variable_costs,
##             fixed_costs, depreciation, imputed_interest, profit,
##             cashflow, break_even, payback}]
static func evaluate_at(a: MachineSpec, b: MachineSpec, quantity: float) -> Array:
	var out: Array = []
	var specs: Array[MachineSpec] = [a, b]
	for spec in specs:
		var revenue := spec.price_per_unit * quantity
		var variable := spec.variable_cost_per_unit * quantity
		var depreciation := spec.depreciation()
		var imputed := spec.imputed_interest()
		var fixed := spec.total_fixed_costs()
		var profit := revenue - variable - fixed
		# Cashflow: Gewinn + AfA + kalk. Zinsen (nicht zahlungswirksam)
		var cashflow := profit + depreciation + imputed
		out.append({
			"name": spec.display_name,
			"quantity": quantity,
			# Anschaffungswert. Die Investition ist eine Aktivierung, kein
			# laufender Aufwand – deshalb steht sie getrennt von den
			# Jahreskosten.
			"acquisition": spec.acquisition_cost,
			"revenue": revenue,
			"variable_costs": variable,
			"fixed_costs": fixed,
			"depreciation": depreciation,
			"imputed_interest": imputed,
			"profit": profit,
			"cashflow": cashflow,
			"break_even": spec.break_even_quantity(),
			"payback": spec.payback_period_at(quantity),
			# Investitionsrechnung: Kapitalwert, Barwert und Rendite.
			# Der Kapitalwert ist die Annuität, die dem Barwert der
			# Investition entspricht – er vergleicht die Anlage direkt
			# mit den laufenden Jahreskosten.
			"npv": _npv_at(spec, quantity),
			"capital_value": _capital_value_at(spec, quantity),
			"profitability_index": _profitability_index_at(spec, quantity),
			"irr": _irr_at(spec, quantity),
		})
	return out


## Der Nettobarwert einer Anlage bei einer bestimmten Jahresmenge.
##
## Aufbau: t=0 wird der Anschaffungswert investiert (negativ), in den
## Folgejahren fliesst jeweils der Cashflow zu. Der Restwert am Ende
## der Nutzungsdauer wird mit verrechnet.
##
## Der Zinssatz ist der kalkulatorische Zinssatz der Anlage: er
## beruecksichtigt Eigenkapital- und Fremdkapitalanteil.
static func _npv_at(spec: MachineSpec, quantity: float) -> float:
	var flows := _cashflow_series(spec, quantity)
	if flows.is_empty():
		return 0.0
	return BWLEngine.npv(spec.acquisition_cost, flows, spec.effective_interest_rate())


## Der Kapitalwert: die Annuität, die dem Barwert entspricht.
##
## Der Kapitalwert beantwortet die Frage, welcher Jahresbeitrag die
## Investition gerade noch wert waere. Liegt er ueber den jaehrlichen
## Fixkosten der Anlage, lohnt sich die Investition.
static func _capital_value_at(spec: MachineSpec, quantity: float) -> float:
	var npv_value := _npv_at(spec, quantity)
	if npv_value == 0.0:
		return 0.0
	return BWLEngine.annuity_from_npv(
		npv_value, spec.effective_interest_rate(), spec.useful_life_years
	)


## Der Rentabilitaetsindex: Barwert der Erloese je investiertem Euro.
##
## Ein Wert ueber 1 bedeutet, dass die Investition mehr einbringt als
## sie kostet.
static func _profitability_index_at(spec: MachineSpec, quantity: float) -> float:
	var npv_value := _npv_at(spec, quantity)
	if spec.acquisition_cost <= 0.0:
		return 0.0
	return (npv_value + spec.acquisition_cost) / spec.acquisition_cost


## Die interne Rendite der Investition (oder -1, wenn nicht
## berechenbar).
static func _irr_at(spec: MachineSpec, quantity: float) -> float:
	var flows := _cashflow_series(spec, quantity)
	if flows.is_empty():
		return -1.0
	var result: Variant = BWLEngine.irr(spec.acquisition_cost, flows)
	if result == null:
		return -1.0
	return float(result)


## Die Cashflow-Reihe einer Anlage ueber ihre Nutzungsdauer.
##
## WICHTIG: Die Reihe enthaelt NUR die Zahlungen ab t = 1. Der
## Investitionsbetrag bei t = 0 wird von `BWLEngine.npv()` ueber den
## Parameter `a0` abgezogen. Wuerde er hier noch einmal als erste
## Zahlung stecken, waere die Investition doppelt abgezogen.
static func _cashflow_series(spec: MachineSpec, quantity: float) -> Array:
	var years := maxi(spec.useful_life_years, 1)
	var flows: Array = []
	for year_index in years:
		var cashflow := spec.annual_cashflow_at(quantity)
		# Im letzten Jahr kommt der Restwert dazu.
		if year_index == years - 1:
			cashflow += spec.residual_value
		flows.append(cashflow)
	return flows


## Die Datenpunkte für die Grafik (aufbereitet für ein 2D-Diagramm).
##
## Jeder Punkt enthält beide Kostenfunktionen, damit die Kurven
## tatsaechlich gezeichnet werden koennen. `x_critical` erlaubt das
## Einzeichnen der kritischen Menge.
static func curve_points(a: MachineSpec, b: MachineSpec, samples: int = 60) -> Dictionary:
	var max_x := _max_x(a, b)
	var points: Array = []
	for i in range(samples + 1):
		var x := max_x * float(i) / float(samples)
		points.append({
			"x": x,
			"a": a.total_costs_at(x),
			"b": b.total_costs_at(x),
			"a_profit": a.profit_at(x),
			"b_profit": b.profit_at(x),
		})
	return {
		"x_critical": compare(a, b).x_critical,
		"max_x": max_x,
		"points": points,
	}
