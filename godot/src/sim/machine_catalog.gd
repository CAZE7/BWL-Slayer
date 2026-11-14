class_name MachineCatalog
extends RefCounted

## Der Maschinenkatalog.
##
## Die beiden Anlagen A und B bilden den Kostenvergleich der Welt 2 ab
## (Fuhrpark der Folien). Ihre Werte stammen exakt aus der geprüften
## Originalaufgabe, damit die Simulation und die Lehrinhalte identisch
## rechnen:
##
##   Auto A: A₀ = 16.000 €, n = 4, i = 10 %, Fixkosten 1.180,20 €,
##           k_var = 26 €/100 km
##   Auto B: A₀ = 17.000 €, n = 4, i = 10 %, Fixkosten 1.345,70 €,
##           k_var = 22 €/100 km
##
##   x_krit = (6.445,70 − 5.980,20) / (26 − 22) = 116,375 (Hundert-km)
##
## Die Maschinen werden für das Spiel als Produktionsanlagen
## interpretiert: statt Kilometer zählen Stück. Die Kostenstruktur
## (Fixkosten, variable Stückkosten, Kapazität) bleibt identisch.

const CAR_A_ID := &"MACHINE_A"
const CAR_B_ID := &"MACHINE_B"
const CONVEYOR_ID := &"MACHINE_C"
const PACKER_ID := &"MACHINE_D"


## Alle verfügbaren Maschinen.
static func all() -> Array[MachineSpec]:
	return [car_a(), car_b(), conveyor(), packer()]


static func car_a() -> MachineSpec:
	var spec := MachineSpec.new()
	spec.id = CAR_A_ID
	spec.display_name = "Anlage A · Fuhrparkmodell"
	spec.description = "Das wirtschaftlichere Modell bei geringer Stückzahl: niedrigere Fixkosten, dafür höhere variable Stückkosten."
	spec.acquisition_cost = 16000.0
	spec.residual_value = 0.0
	spec.useful_life_years = 4
	spec.imputed_interest_rate = 0.10
	spec.fixed_operating_costs = 1180.20
	spec.variable_cost_per_unit = 26.0
	spec.price_per_unit = 62.0
	spec.capacity_units_per_year = 11637.5
	spec.product_name = "Transportleistung"
	spec.material_per_unit = 0.0
	spec.material_price_per_kg = 0.0
	spec.labor_hours_per_year = 2200.0
	spec.labor_rate_per_hour = 24.0
	spec.delivery_days = 7
	spec.installation_days = 2
	spec.footprint_sqm = 140.0
	spec.accent_color = Color(0.42, 0.60, 0.68)
	return spec


static func car_b() -> MachineSpec:
	var spec := MachineSpec.new()
	spec.id = CAR_B_ID
	spec.display_name = "Anlage B · Großgerät"
	spec.description = "Teurer in der Anschaffung, aber geringere variable Stückkosten – ab der kritischen Menge die wirtschaftlichere Alternative."
	spec.acquisition_cost = 17000.0
	spec.residual_value = 0.0
	spec.useful_life_years = 4
	spec.imputed_interest_rate = 0.10
	spec.fixed_operating_costs = 1345.70
	spec.variable_cost_per_unit = 22.0
	spec.price_per_unit = 62.0
	spec.capacity_units_per_year = 11637.5
	spec.product_name = "Transportleistung"
	spec.material_per_unit = 0.0
	spec.material_price_per_kg = 0.0
	spec.labor_hours_per_year = 2200.0
	spec.labor_rate_per_hour = 24.0
	spec.delivery_days = 9
	spec.installation_days = 2
	spec.footprint_sqm = 160.0
	spec.accent_color = Color(0.55, 0.50, 0.42)
	return spec


static func conveyor() -> MachineSpec:
	var spec := MachineSpec.new()
	spec.id = CONVEYOR_ID
	spec.display_name = "Förderbandlinie"
	spec.description = "Materialintensive Linie mit hoher Kapazität – lohnt sich erst bei großer Menge."
	spec.acquisition_cost = 48000.0
	spec.residual_value = 8000.0
	spec.useful_life_years = 8
	spec.imputed_interest_rate = 0.08
	spec.fixed_operating_costs = 9200.0
	spec.variable_cost_per_unit = 4.0
	spec.price_per_unit = 21.0
	spec.capacity_units_per_year = 180000.0
	spec.product_name = "Halbfertigteil"
	spec.material_per_unit = 2.5
	spec.material_price_per_kg = 1.4
	spec.labor_hours_per_year = 1800.0
	spec.labor_rate_per_hour = 28.0
	spec.delivery_days = 14
	spec.installation_days = 5
	spec.footprint_sqm = 320.0
	spec.accent_color = Color(0.38, 0.52, 0.56)
	return spec


static func packer() -> MachineSpec:
	var spec := MachineSpec.new()
	spec.id = PACKER_ID
	spec.display_name = "Verpackungsautomat"
	spec.description = "Geringe Fixkosten, hoher Deckungsbeitrag je Stück – der Klassiker für den Einstieg."
	spec.acquisition_cost = 24000.0
	spec.residual_value = 3000.0
	spec.useful_life_years = 6
	spec.imputed_interest_rate = 0.08
	spec.fixed_operating_costs = 5400.0
	spec.variable_cost_per_unit = 3.0
	spec.price_per_unit = 18.0
	spec.capacity_units_per_year = 90000.0
	spec.product_name = "Verpackte Ware"
	spec.material_per_unit = 0.6
	spec.material_price_per_kg = 1.1
	spec.labor_hours_per_year = 1200.0
	spec.labor_rate_per_hour = 26.0
	spec.delivery_days = 10
	spec.installation_days = 3
	spec.footprint_sqm = 200.0
	spec.accent_color = Color(0.46, 0.58, 0.42)
	return spec


## Die beiden Kernanlagen für den Kostenvergleich.
static func comparison_pair() -> Array[MachineSpec]:
	return [car_a(), car_b()]


## Kritische Menge der beiden Anlagen (in Stück).
static func critical_quantity(a: MachineSpec, b: MachineSpec) -> float:
	var denom := a.variable_cost_per_unit - b.variable_cost_per_unit
	if is_equal_approx(denom, 0.0):
		return NAN
	return (b.total_fixed_costs() - a.total_fixed_costs()) / denom
