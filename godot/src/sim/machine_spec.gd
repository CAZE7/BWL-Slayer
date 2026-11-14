class_name MachineSpec
extends Resource

## Fachliche Spezifikation einer Produktionsmaschine.
##
## WICHTIG – Trennung der Kostenarten:
##   acquisition_cost   → Investitionsauszahlung (einmalig, aktiviert Anlage)
##   depreciation       → Abschreibung (periodisch, auf den Wertverzehr)
##   imputed_interest    → kalkulatorische Zinsen (nicht zahlungswirksam!)
##   fixed_operating_costs → zahlungswirksame Fixkosten (Personal, Wartung, ...)
##   variable_cost_per_unit  → zahlungswirksame variable Stückkosten
##
## Maschinen dürfen NIEMALS gleichzeitig mit dem vollen Anschaffungspreis
## UND mit Abschreibungen belastet werden. Der Anschaffungspreis ist eine
## Investitionsauszahlung, kein laufender Aufwand.

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""

# --- Investitionsdaten ---
@export var acquisition_cost: float = 0.0
@export var residual_value: float = 0.0
@export var useful_life_years: int = 5
## kalkulatorischer Zinssatz für die Restwertberechnung (Dezimal, 0.08 = 8 %)
@export var imputed_interest_rate: float = 0.08

# --- Betriebsdaten ---
## zahlungswirksame Fixkosten pro Jahr
@export var fixed_operating_costs: float = 0.0
## zahlungswirksame variable Stückkosten je Einheit
@export var variable_cost_per_unit: float = 0.0
## Verkaufspreis je Einheit
@export var price_per_unit: float = 0.0
## maximale Jahreskapazität in Stück
@export var capacity_units_per_year: float = 0.0

# --- Produkt & Betrieb ---
@export var product_name: String = ""
## Materialverbrauch je Einheit (kg)
@export var material_per_unit: float = 0.0
@export var material_price_per_kg: float = 0.0
## Personalbedarf (Arbeitsstunden pro Jahr)
@export var labor_hours_per_year: float = 0.0
@export var labor_rate_per_hour: float = 0.0

# --- Logistik ---
## Lieferzeit in Tagen
@export var delivery_days: int = 7
## Installationsdauer in Tagen nach Ankunft
@export var installation_days: int = 2
## benötigte Grundfläche in Quadratmetern
@export var footprint_sqm: float = 120.0

# --- Finanzierung der Investition ---
## Anteil des Fremdkapitals an der Investition (Dezimal, 0.4 = 40 %).
##
## Der Anteil bestimmt den Zinssatz der Investitionsrechnung: Der
## Fremdkapitalanteil kostet den Effektivzins des Kredits, der
## Eigenkapitalanteil kostet den Eigenkapitalzins. Zusammen ergeben
## sie den kalkulatorischen Zinssatz, mit dem der Kapitalwert gerechnet
## wird.
@export var debt_share: float = 0.4
## Effektivzins des Fremdkapitals (Dezimal, 0.06 = 6 %)
@export var debt_interest_rate: float = 0.06
## Eigenkapitalzins (Dezimal, 0.10 = 10 %)
@export var equity_interest_rate: float = 0.10

# --- Darstellung ---
@export var mesh_config: Dictionary = {}
@export var accent_color: Color = Color(0.42, 0.71, 0.78)


## Der kalkulatorische Zinssatz der Investitionsrechnung.
##
## Gewichteter Mittelwert aus Eigen- und Fremdkapitalzins. Das ist der
## Satz, mit dem Barwert und Kapitalwert gerechnet werden.
func effective_interest_rate() -> float:
	var share := clampf(debt_share, 0.0, 1.0)
	return equity_interest_rate * (1.0 - share) + debt_interest_rate * share


## Jahrliche Abschreibung (linear, Restwert berücksichtigt).
func depreciation() -> float:
	if useful_life_years <= 0:
		return 0.0
	return (acquisition_cost - residual_value) / float(useful_life_years)


## Durchschnittlich gebundenes Kapital.
func average_bound_capital() -> float:
	return (acquisition_cost + residual_value) / 2.0


## Kalkulatorische Zinsen auf das durchschnittlich gebundene Kapital.
## NICHT zahlungswirksam – beeinflusst aber Rentabilität und Kapitalwert.
func imputed_interest() -> float:
	return average_bound_capital() * imputed_interest_rate


## Gesamte kalkulatorische Fixkosten (Fixkosten + AfA + kalk. Zinsen).
## Entspricht K_fix der statischen Investitionsrechnung.
func total_fixed_costs() -> float:
	return fixed_operating_costs + depreciation() + imputed_interest()


## Zahlungswirksame Fixkosten (ohne AfA und kalk. Zinsen).
## Maßgeblich für die Cashflow-Rechnung.
func cash_fixed_costs() -> float:
	return fixed_operating_costs


## Deckungsbeitrag je Einheit.
func contribution_margin_per_unit() -> float:
	return price_per_unit - variable_cost_per_unit


## Variable Stückkosten inkl. Materialverbrauch.
func full_variable_cost_per_unit() -> float:
	return variable_cost_per_unit + material_per_unit * material_price_per_kg


## Deckungsbeitrag je Einheit unter Berücksichtigung des Materials.
func full_contribution_margin_per_unit() -> float:
	return price_per_unit - full_variable_cost_per_unit()


## Kritische Menge (Break-even) in Stück.
func break_even_quantity() -> float:
	var db := contribution_margin_per_unit()
	if db <= 0.0:
		return -1.0
	return total_fixed_costs() / db


## Kostenfunktion: Gesamtkosten bei Menge x.
func total_costs_at(x: float) -> float:
	return variable_cost_per_unit * x + total_fixed_costs()


## Gewinnfunktion bei Menge x.
func profit_at(x: float) -> float:
	return contribution_margin_per_unit() * x - total_fixed_costs()


## Jahres-Cashflow bei Menge x (zahlungswirksam).
##
## Der Gewinn enthaelt bereits die kalkulatorischen Zinsen, die nicht
## zahlungswirksam sind – sie werden deshalb herausgerechnet. Die
## Abschreibung ist ebenfalls nicht zahlungswirksam und wird
## hinzugefuegt. So entsteht der zahlungswirksame Jahres-Cashflow:
##
##   Cashflow = Gewinn + Abschreibung − kalkulatorische Zinsen
func annual_cashflow_at(x: float) -> float:
	return profit_at(x) + depreciation() - imputed_interest()


## Amortisationsdauer in Jahren bei konstantem Jahres-Cashflow.
func payback_period_at(x: float) -> float:
	var cf := annual_cashflow_at(x)
	if cf <= 0.0:
		return INF
	return acquisition_cost / cf


## Auslastung in Prozent (0..100+).
func utilization_at(quantity: float) -> float:
	if capacity_units_per_year <= 0.0:
		return 0.0
	return (quantity / capacity_units_per_year) * 100.0


## Jahres-Personalkosten.
func labor_cost() -> float:
	return labor_hours_per_year * labor_rate_per_hour


## Erzeugt eine Kopie mit überschriebenen Werten.
func with_overrides(overrides: Dictionary) -> MachineSpec:
	var copy := duplicate(true) as MachineSpec
	for key in overrides:
		copy.set(key, overrides[key])
	return copy
