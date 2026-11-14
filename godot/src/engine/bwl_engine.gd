class_name BWLEngine
extends RefCounted

## BWL Slayer · Finanzmathematische Engine (GDScript-Port).
##
## 1:1-Port von `src/engine.js` (JavaScript, verifiziert gegen 140 Musterlösungen).
## Diese Klasse ist die FACHLICHE Quelle der Wahrheit für alle Rechnungen.
##
## Regeln:
##   - keine UI-, keine Godot-Szenen-Abhängigkeit (nur Math/String)
##   - deterministisch: gleiche Eingabe => identisches Ergebnis
##   - keine Zufallszahlen
##
## Gegenreferenz: tests/gdscript/test_bwl_engine.gd prüft jeden Wert gegen
## dieselben Musterlösungen wie der JS-Test tests/verify.cjs.

# ==================================================================
# 1. Statische Investitionsrechnung (Kapitel 2)
# ==================================================================

## Kostenfunktion: Gesamtkosten bei Menge x.
static func total_costs_at(
	acquisition_cost: float,
	residual_value: float,
	useful_life: int,
	interest_rate: float,
	fixed_operating_costs: float,
	variable_cost_per_unit: float,
	x: float
) -> float:
	var depreciation := (acquisition_cost - residual_value) / float(useful_life)
	var average_bound := (acquisition_cost + residual_value) / 2.0
	var imputed := average_bound * interest_rate
	var total_fixed := fixed_operating_costs + depreciation + imputed
	return variable_cost_per_unit * x + total_fixed


## Abschreibung (linear).
static func depreciation_of(acquisition_cost: float, residual_value: float, useful_life: int) -> float:
	if useful_life <= 0:
		return 0.0
	return (acquisition_cost - residual_value) / float(useful_life)


## Durchschnittlich gebundenes Kapital.
static func average_bound_capital(acquisition_cost: float, residual_value: float) -> float:
	return (acquisition_cost + residual_value) / 2.0


## Kalkulatorische Zinsen.
static func imputed_interest_of(acquisition_cost: float, residual_value: float, interest_rate: float) -> float:
	return average_bound_capital(acquisition_cost, residual_value) * interest_rate


## Gesamte kalkulatorische Fixkosten (K_fix).
static func total_fixed_costs(
	acquisition_cost: float,
	residual_value: float,
	useful_life: int,
	interest_rate: float,
	fixed_operating_costs: float
) -> float:
	return (
		fixed_operating_costs
		+ depreciation_of(acquisition_cost, residual_value, useful_life)
		+ imputed_interest_of(acquisition_cost, residual_value, interest_rate)
	)


## Deckungsbeitrag je Einheit.
static func contribution_margin(price_per_unit: float, variable_cost_per_unit: float) -> float:
	return price_per_unit - variable_cost_per_unit


## Gewinn bei Menge x.
static func profit_at(
	price_per_unit: float,
	variable_cost_per_unit: float,
	x: float,
	total_fixed: float
) -> float:
	return (price_per_unit - variable_cost_per_unit) * x - total_fixed


## Break-even-Menge (kritische Menge der Einzelanlage).
static func break_even_quantity(price_per_unit: float, variable_cost_per_unit: float, total_fixed: float) -> float:
	var db := contribution_margin(price_per_unit, variable_cost_per_unit)
	if db <= 0.0:
		return -1.0
	return total_fixed / db


## Kritische Menge im Kostenvergleich (COST) zwischen zwei Anlagen.
static func critical_quantity_cost(
	a0_1: float, l_1: float, n_1: int, i_1: float, kfix_1: float, kvar_1: float,
	a0_2: float, l_2: float, n_2: int, i_2: float, kfix_2: float, kvar_2: float
) -> float:
	var denom := kvar_1 - kvar_2
	if is_equal_approx(denom, 0.0):
		return NAN
	var num := (
		total_fixed_costs(a0_2, l_2, n_2, i_2, kfix_2)
		- total_fixed_costs(a0_1, l_1, n_1, i_1, kfix_1)
	)
	return num / denom


## Kritische Menge im Gewinnvergleich (PROFIT) zwischen zwei Anlagen.
static func critical_quantity_profit(
	a0_1: float, l_1: float, n_1: int, i_1: float, kfix_1: float, kvar_1: float, p_1: float,
	a0_2: float, l_2: float, n_2: int, i_2: float, kfix_2: float, kvar_2: float, p_2: float
) -> float:
	var db_1 := contribution_margin(p_1, kvar_1)
	var db_2 := contribution_margin(p_2, kvar_2)
	var denom := db_2 - db_1
	if is_equal_approx(denom, 0.0):
		return NAN
	var num := (
		total_fixed_costs(a0_2, l_2, n_2, i_2, kfix_2)
		- total_fixed_costs(a0_1, l_1, n_1, i_1, kfix_1)
	)
	return num / denom


## Kumulationsmethode: exakte Amortisationsdauer bei ungleichen Rückflüssen.
static func cumulative_payback(a0: float, cashflows: Array) -> Dictionary:
	var cumulative := 0.0
	var target := absf(a0)
	for t in range(cashflows.size()):
		var next := cumulative + float(cashflows[t])
		if next >= target:
			var rest := target - cumulative
			return {
				"years": float(t) + rest / float(cashflows[t]),
				"full_years": t,
				"rest": rest,
				"inflow": float(cashflows[t]),
				"cumulative_before": cumulative,
			}
		cumulative = next
	return {}


# ==================================================================
# 2. Dynamische Investitionsrechnung (Kapitel 3)
# ==================================================================

## Werkzeug I: Abzinsungsfaktor (1 + i)^-t.
static func df(i: float, t: int) -> float:
	return pow(1.0 + i, -float(t))


## Werkzeug II: Rentenbarwertfaktor.
static func rbf(i: float, n: int) -> float:
	if is_zero_approx(i):
		return float(n)
	return (1.0 - pow(1.0 + i, -float(n))) / i


## Werkzeug III: Annuitätenfaktor.
static func anf(i: float, n: int) -> float:
	if is_zero_approx(i):
		return 1.0 / float(n)
	return i / (1.0 - pow(1.0 + i, -float(n)))


## Kapitalwert: KW = -|A0| + Σ CF_t · (1+i)^-t  (CF in t = 1..n)
static func npv(a0: float, flows: Array, i: float) -> float:
	return -absf(a0) + pv_flows(flows, i)


## Barwert einer Zahlungsreihe ab t = start.
static func pv_flows(flows: Array, i: float, start: int = 1) -> float:
	var s := 0.0
	for k in range(flows.size()):
		s += float(flows[k]) * df(i, start + k)
	return s


## Kapitalwert mit vorzeichenbehafteten Zahlungen inkl. t = 0.
static func npv_signed(flows: Array, i: float) -> float:
	var s := 0.0
	for k in range(flows.size()):
		s += float(flows[k]) * df(i, k)
	return s


## Annuität aus einem Kapitalwert.
static func annuity_from_npv(npv_value: float, i: float, n: int) -> float:
	return npv_value * anf(i, n)


## Kapitalwertindex (PI) über Kapitalwert.
static func profitability_index(npv_value: float, a0: float) -> float:
	return npv_value / absf(a0)


## PI über Barwert (Kriterium > 1).
static func profitability_index_pv(a0: float, flows: Array, i: float) -> float:
	return pv_flows(flows, i) / absf(a0)


## Dynamische Amortisationsdauer über diskontierte Rückflüsse.
static func dynamic_payback(a0: float, flows: Array, i: float) -> Dictionary:
	var discounted: Array = []
	for k in range(flows.size()):
		discounted.append(float(flows[k]) * df(i, k + 1))
	return cumulative_payback(a0, discounted)


## Sekanten-/Strahlensatz-Iteration.
static func secant_irr_step(a0: float, flows: Array, i1: float, i2: float) -> Dictionary:
	var kw1 := npv(a0, flows, i1)
	var kw2 := npv(a0, flows, i2)
	var i_star := i1
	if not is_equal_approx(kw1, kw2):
		i_star = i1 + kw1 * ((i2 - i1) / (kw1 - kw2))
	return {
		"i_star": i_star,
		"kw1": kw1,
		"kw2": kw2,
		"kw_star": npv(a0, flows, i_star),
	}


## Exakter IRR per Bisektion (nur bei Vorzeichenwechsel).
static func irr(a0: float, flows: Array) -> Variant:
	var f := func(i: float) -> float: return npv(a0, flows, i)
	var lo := -0.9999
	var hi := 10.0
	if f.call(lo) * f.call(hi) > 0.0:
		return null
	for _k in range(200):
		var mid := (lo + hi) / 2.0
		if f.call(lo) * f.call(mid) <= 0.0:
			hi = mid
		else:
			lo = mid
	return (lo + hi) / 2.0


## Sonderfall 1: eine Aus- und eine Einzahlung.
static func irr_single_payment(a0: float, cf: float, t: int) -> float:
	return pow(cf / absf(a0), 1.0 / float(t)) - 1.0


## Sonderfall 2: Rente – Bracketing + lineare Interpolation.
## ACHTUNG: der Strahlensatz wird auf KW(i) = Rbf(i,n) − Zielwert angewendet.
static func irr_annuity_interval(a0: float, cf: float, n: int) -> Dictionary:
	var target := absf(a0) / cf
	var prev_i := -1.0
	var prev_v := 0.0
	var i := 0.0
	while i <= 1.0:
		var v := rbf(i, n)
		if v <= target:
			if prev_i < 0.0:
				return {"rbf": target, "lower": null, "upper": null, "i_approx": i}
			var kw1 := prev_v - target
			var kw2 := v - target
			var i_star := prev_i
			if not is_equal_approx(kw1, kw2):
				i_star = prev_i + kw1 * ((i - prev_i) / (kw1 - kw2))
			return {
				"rbf": target,
				"lower": {"i": prev_i, "v": prev_v},
				"upper": {"i": i, "v": v},
				"i_approx": i_star,
			}
		prev_i = i
		prev_v = v
		i += 0.0001
	return {}


## Sonderfall 3: ewige Rente.
static func irr_perpetuity(a0: float, cf: float) -> float:
	return cf / absf(a0)


# ==================================================================
# 3. Anleihen, Zinsstruktur & Duration (Kapitel 4)
# ==================================================================

## Barwert Kuponanleihe. `y` = Zahl oder Vektor der Spot Rates.
static func bond_pv(face_value: float, coupon_rate: float, maturity: int, y: Variant) -> float:
	var coupon := face_value * coupon_rate
	var pv := 0.0
	for t in range(1, maturity + 1):
		var cf := coupon + face_value if t == maturity else coupon
		var r: float
		if y is Array:
			r = float((y as Array)[t - 1])
		else:
			r = float(y)
		pv += cf / pow(1.0 + r, float(t))
	return pv


## Zerobond-Rendite (Kassazinssatz).
static func zero_yield(face_value: float, price: float, maturity: int) -> float:
	return pow(face_value / price, 1.0 / float(maturity)) - 1.0


## Macauley- & Modified Duration inkl. Kursänderung.
static func duration(face_value: float, coupon_rate: float, maturity: int, y: float) -> Dictionary:
	var coupon := face_value * coupon_rate
	var pv_sum := 0.0
	var weighted := 0.0
	var legs: Array = []
	for t in range(1, maturity + 1):
		var cf := coupon + face_value if t == maturity else coupon
		var pv_cf: float = cf / pow(1.0 + y, float(t))
		pv_sum += pv_cf
		weighted += float(t) * pv_cf
		legs.append({"t": t, "cf": cf, "pv_cf": pv_cf, "weight": 0.0})
	for leg in legs:
		leg["weight"] = float(leg["pv_cf"]) / pv_sum
	var macauley := weighted / pv_sum
	var modified := macauley / (1.0 + y)
	return {
		"present_value": pv_sum,
		"legs": legs,
		"macauley_duration": macauley,
		"modified_duration": modified,
	}


## Portfolioduration = Σ w_i · D_i
static func portfolio_duration(weights: Array, durations: Array) -> float:
	var s := 0.0
	for k in range(mini(weights.size(), durations.size())):
		s += float(weights[k]) * float(durations[k])
	return s


# ==================================================================
# 4. Finanzierung
# ==================================================================

## Lohmann-Ruchti-Simulator (Kohortenmodell).
static func lohmann_ruchti(
	initial_machines: int = 10,
	cost_per_machine: float = 5000.0,
	useful_life: int = 5,
	years: int = 7
) -> Array:
	var cohorts: Array = [initial_machines]
	var rows: Array = []
	var carried := 0.0
	for y in range(1, years + 1):
		var active := 0
		for c in cohorts:
			active += int(c)
		var afa := float(active) * (cost_per_machine / float(useful_life))
		var available := afa + carried
		var bought := int(floor(available / cost_per_machine + 1e-9))
		var invested := float(bought) * cost_per_machine
		var rest := available - invested
		var retire_idx := y - useful_life
		var retired := 0
		if retire_idx >= 0:
			retired = int(cohorts[retire_idx]) if retire_idx < cohorts.size() else 0
		rows.append({
			"year": y,
			"active_machines": active,
			"depreciation": afa,
			"available": available,
			"bought": bought,
			"invested": invested,
			"retired": retired,
			"rest": rest,
			"available_before": available,
		})
		if retire_idx >= 0 and retire_idx < cohorts.size():
			cohorts[retire_idx] = 0
		cohorts.append(bought)
		carried = rest
	return rows


## Bezugsrecht & Kapitalerhöhung.
static func subscription_right(p: Dictionary) -> Dictionary:
	var old_shares := float(p.get("old_shares", 0.0))
	var new_shares := float(p.get("new_shares", 1.0))
	var old_price := float(p.get("old_share_price", 0.0))
	var issue_price := float(p.get("issue_price_new", 0.0))
	var ratio := old_shares / new_shares
	var disadvantage := 0.0
	if p.has("dividend_old") and p.has("months_entitled_new"):
		disadvantage = float(p["dividend_old"]) * (1.0 - float(p["months_entitled_new"]) / 12.0)
	var br := (old_price - (issue_price + disadvantage)) / (ratio + 1.0)
	var mixed := (old_shares * old_price + new_shares * issue_price) / (old_shares + new_shares)
	var nominal := float(p.get("nominal_value", 1.0))
	var capital_increase := new_shares * nominal
	var agio := new_shares * (issue_price - nominal)
	return {
		"ratio": ratio,
		"disadvantage": disadvantage,
		"subscription_right_value": br,
		"mixed_price": mixed,
		"share_capital_increase": capital_increase,
		"agio": agio,
		"total_inflow": capital_increase + agio,
	}


## Lieferantenkredit: Jahreszins nach 360-Tage-Überschlagsformel.
static func supplier_credit_rate(sconto_pct: float, target_days: float, skonto_days: float) -> float:
	if is_equal_approx(target_days, skonto_days):
		return NAN
	return (sconto_pct / (target_days - skonto_days)) * 360.0


## Leasing-Bilanzierung: Leasingnehmer oder Leasinggeber?
static func leasing_owner(input: Dictionary) -> Dictionary:
	if bool(input.get("is_special_leasing", false)):
		return {"owner": "LEASING_NEHMER", "reason": "Spezial-Leasing → immer Leasingnehmer"}
	var ratio := float(input.get("basic_lease_term_months", 0.0)) / float(input.get("useful_life_months", 1.0))
	if ratio < 0.4:
		return {"owner": "LEASING_NEHMER", "reason": "GMZ < 40 % der BGND → Zurechnung Leasingnehmer"}
	if ratio > 0.9:
		return {"owner": "LEASING_NEHMER", "reason": "GMZ > 90 % der BGND → Zurechnung Leasingnehmer"}
	var option_type := String(input.get("option_type", "NONE"))
	if option_type == "NONE":
		return {"owner": "LEASING_GEBER", "reason": "40–90 % und keine Option → Leasinggeber"}
	if option_type == "PURCHASE":
		if bool(input.get("purchase_price_below_book_value", false)):
			return {"owner": "LEASING_NEHMER", "reason": "Kaufoption unter Restbuchwert → Leasingnehmer"}
		return {"owner": "LEASING_GEBER", "reason": "Kaufoption ≥ Restbuchwert → Leasinggeber"}
	if bool(input.get("extension_rent_below_depreciation", false)):
		return {"owner": "LEASING_NEHMER", "reason": "Anschlussmiete < lin. Wertverzehr → Leasingnehmer"}
	return {"owner": "LEASING_GEBER", "reason": "Anschlussmiete ≥ lin. Wertverzehr → Leasinggeber"}


## Leverage-Effekt: r_e = r_g + FK/EK · (r_g − r_f)
static func leverage(equity: float, debt: float, rg_pct: float, rf_pct: float) -> Dictionary:
	var ratio := debt / equity
	var roe := rg_pct + ratio * (rg_pct - rf_pct)
	var total_capital := equity + debt
	var ebit := total_capital * (rg_pct / 100.0)
	var interest := debt * (rf_pct / 100.0)
	return {
		"leverage_ratio": ratio,
		"roe_pct": roe,
		"ebit": ebit,
		"interest": interest,
		"net_profit": ebit - interest,
		"positive": rg_pct > rf_pct,
		"roe_direct": ((ebit - interest) / equity) * 100.0,
	}


## Tilgungspläne. `type` = ANNUITY / REDEMPTION / FEST
static func amortization_plan(principal: float, rate: float, years: int, type: String) -> Dictionary:
	var rows: Array = []
	var rest := principal
	if type == "ANNUITY":
		var ann := principal * anf(rate, years)
		for t in range(1, years + 1):
			var interest := rest * rate
			var redemption := ann - interest
			rest -= redemption
			rows.append({
				"t": t,
				"rest_start": rest + redemption,
				"interest": interest,
				"redemption": redemption,
				"rate": ann,
				"rest_end": rest,
			})
		return {"rows": rows, "annual_payment": ann, "total": ann * float(years)}

	var linear := principal / float(years)
	for t in range(1, years + 1):
		var interest := rest * rate
		if type == "REDEMPTION":
			rest -= linear
			rows.append({
				"t": t,
				"rest_start": rest + linear,
				"interest": interest,
				"redemption": linear,
				"rate": interest + linear,
				"rest_end": rest,
			})
		else:
			var redemption := principal if t == years else 0.0
			rest -= redemption
			rows.append({
				"t": t,
				"rest_start": rest + redemption,
				"interest": interest,
				"redemption": redemption,
				"rate": interest + redemption,
				"rest_end": rest,
			})
	var total := 0.0
	for r in rows:
		total += float(r["rate"])
	return {"rows": rows, "total": total}


## Kapitalbedarf Umlaufvermögen: Kapitalbindungsdauer × Tageskosten.
static func working_capital_need(phases: Array, payable_days: float, cost_per_day: float) -> Dictionary:
	var days := 0.0
	for p in phases:
		days += float(p["days"])
	days -= payable_days
	return {"days": days, "need": days * cost_per_day}


# ==================================================================
# 5. Aktien & Aktienbewertung (Kapitel 5)
# ==================================================================

## Ergebnis je Aktie.
static func eps(net_income: float, preferred_dividend_total: float, common_shares: float) -> float:
	return (net_income - preferred_dividend_total) / common_shares


## Kurs-Gewinn-Verhältnis.
static func kgv(price: float, eps_value: float) -> Variant:
	if is_zero_approx(eps_value):
		return null
	return price / eps_value


## Dividendenrendite.
static func dividend_yield(dividend: float, price: float) -> Variant:
	if is_zero_approx(price):
		return null
	return dividend / price


## Gesamtrendite einer Aktie.
static func equity_total_return(p0: float, d1: float, p1: float) -> float:
	return (d1 + p1 - p0) / p0


## CAPM.
static func capm(rf: float, beta: float, rm: float) -> float:
	return rf + beta * (rm - rf)


## Gordon-Growth: P0 = D1 / (r − g), nur für r > g.
static func gordon(d1: float, r: float, g: float) -> Variant:
	if r <= g:
		return null
	return d1 / (r - g)


## Implizite Wachstumsrate.
static func implied_growth(d1: float, r: float, p0: float) -> float:
	return r - d1 / p0


## Nachhaltige Wachstumsrate: g = Thesaurierungsquote · EK-Rendite.
static func sustainable_growth(retention_ratio: float, roe: float) -> float:
	return retention_ratio * roe


## Barwert expliziter Dividenden + optionaler Verkaufserlös.
static func pv_dividend_stream(dividends: Array, r: float, sale_price: float = 0.0, sale_at: int = 0) -> float:
	var pv := 0.0
	for k in range(dividends.size()):
		pv += float(dividends[k]) * df(r, k + 1)
	if sale_price > 0.0 and sale_at > 0:
		pv += sale_price * df(r, sale_at)
	return pv


## Zweiphasiges Dividendendiskontierungsmodell.
static func two_stage_ddm(d1: float, g1: float, n: int, g2: float, r: float) -> Variant:
	if r <= g2:
		return null
	var flows: Array = []
	var d := d1
	for t in range(1, n + 1):
		flows.append({"t": t, "dividend": d})
		d = d * (1.0 + g1)
	var d_next: float = float(flows[n - 1]["dividend"]) * (1.0 + g2)
	var terminal := d_next / (r - g2)
	var pv := 0.0
	for f in flows:
		pv += float(f["dividend"]) / pow(1.0 + r, float(f["t"]))
	pv += terminal / pow(1.0 + r, float(n))
	return {
		"flows": flows,
		"terminal_value": terminal,
		"present_value": pv,
		"pv_explicit": pv - terminal / pow(1.0 + r, float(n)),
	}


## Bewertung über konstantes KGV.
static func valuation_by_multiple(eps_value: float, multiple: float) -> float:
	return eps_value * multiple


# ==================================================================
# Formatierung (deutsch)
# ==================================================================

static func format_eur(value: float, decimals: int = 2) -> String:
	return String.num(value, decimals).replace(".", ",") + " €"


static func format_pct(value: float, decimals: int = 2) -> String:
	return String.num(value, decimals).replace(".", ",") + " %"
