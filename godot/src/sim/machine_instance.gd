class_name MachineInstance
extends RefCounted

## Ein konkretes Exemplar einer Maschine im Betrieb.
##
## Lebenszyklus:
##   ORDERED → IN_TRANSIT → ARRIVED → UNLOADING → INSTALLING → ACTIVE
##   → DECOMMISSIONED
##
## Jeder Übergang hat eine fachliche und eine spielmechanische Bedeutung:
##
##  - ORDERED:      Bestellung ist erfasst, das Kapital ist gebunden.
##                  Der LKW ist noch nicht unterwegs.
##  - IN_TRANSIT:   Der LKW hat das Werk verlassen und ist auf dem Weg.
##                  Die Lieferzeit läuft.
##  - ARRIVED:      Der LKW steht auf dem Werksgelände an der Ladezone.
##                  Die Ware ist angekommen, wird aber noch nicht bewegt.
##  - UNLOADING:    Die Ware wird entladen (Kran, Hubwagen, Abladung).
##  - INSTALLING:   Die Maschine wird am Zielplatz montiert und
##                  angeschlossen. Erst danach startet die Abschreibung.
##  - ACTIVE:       Die Maschine produziert.
##  - DECOMMISSIONED: Nutzungsdauer beendet.
##
## Jede Maschine hat ihre *eigene* Abschreibung (Beginn ab Installationsjahr),
## eigenen Auslastungsverlauf und eigene Rückflüsse. Nur so ist eine
## nachvollziehbare Investitionsrechnung pro Anlage möglich.

enum State {
	ORDERED,       ## bestellt, Kapital gebunden
	IN_TRANSIT,    ## LKW unterwegs
	ARRIVED,       ## angekommen an der Ladezone, wartet auf Entladung
	UNLOADING,     ## wird entladen
	INSTALLING,    ## wird montiert
	ACTIVE,        ## in Betrieb
	DECOMMISSIONED ## außer Betrieb
}

## Anzahl der Tage, die das Entladen vom Eintreffen beansprucht.
const UNLOAD_DAYS := 2

var spec: MachineSpec
var instance_id: String
var state: int = State.ORDERED
var position: Vector3 = Vector3.ZERO
var rotation_y: float = 0.0

## Jahr der Inbetriebnahme (Basis für Abschreibung und Rückflüsse)
var commissioned_year: int = 0
## Aktuelles Betriebsjahr seit Inbetriebnahme
var age_years: int = 0
## Restbuchwert (wird über die Zeit abgeschrieben)
var book_value: float = 0.0
## kumulierte Abschreibung
var accumulated_depreciation: float = 0.0

## Produktion im laufenden Jahr
var quantity_this_year: float = 0.0
## Historie der Jahresproduktion
var production_history: Array[Dictionary] = []

## Wartungskosten im laufenden Jahr (kumuliert)
var maintenance_cost: float = 0.0
## Installationskosten (einmalig, zahlungswirksam)
var installation_cost: float = 0.0
## Bestand in Tagen bis zur Fertigstellung
var days_remaining: int = 0

## Notizen zum Betriebszustand
var notes: PackedStringArray = []


func _init(p_spec: MachineSpec, p_instance_id: String = "") -> void:
	spec = p_spec
	instance_id = p_instance_id if p_instance_id != "" else spec.id
	book_value = spec.acquisition_cost
	accumulated_depreciation = 0.0
	days_remaining = spec.delivery_days


func is_operational() -> bool:
	return state == State.ACTIVE


## Aktuelle Jahres-Abschreibung dieses Exemplars.
func current_depreciation() -> float:
	if commissioned_year <= 0:
		return 0.0
	var remaining_years := maxi(0, spec.useful_life_years - age_years)
	if remaining_years <= 0:
		return 0.0
	# Letztes Jahr: auf den Restwert herabschreiben, nicht auf null.
	# Der Restwert ist der kalkulierte Wert am Ende der Nutzungsdauer
	# und darf nicht wegfallen.
	if remaining_years == 1:
		return maxf(0.0, book_value - spec.residual_value)
	return (spec.acquisition_cost - spec.residual_value) / float(spec.useful_life_years)


## Kalkulatorische Zinsen auf den aktuellen Restbuchwert.
func current_imputed_interest() -> float:
	return book_value * spec.imputed_interest_rate


## Zahlungswirksame Fixkosten dieses Exemplars.
func current_cash_fixed_costs() -> float:
	return spec.fixed_operating_costs


## Gesamt-Fixkosten (kalkulatorisch) dieses Exemplars.
func current_total_fixed_costs() -> float:
	return current_cash_fixed_costs() + current_depreciation() + current_imputed_interest()


## Deckungsbeitrag bei gegebener Menge.
func contribution_at(quantity: float) -> float:
	return spec.contribution_margin_per_unit() * quantity


## Gewinn bei gegebener Menge (kalkulatorisch, inkl. AfA und kalk. Zinsen).
func profit_at(quantity: float) -> float:
	return contribution_at(quantity) - current_total_fixed_costs()


## Jahres-Cashflow bei gegebener Menge (zahlungswirksam).
##
## Der Gewinn enthaelt die kalkulatorischen Zinsen, die nicht
## zahlungswirksam sind – sie werden herausgerechnet. Die
## Abschreibung ist ebenfalls nicht zahlungswirksam und wird
## hinzugefuegt.
func annual_cashflow_at(quantity: float) -> float:
	return profit_at(quantity) + current_depreciation() - current_imputed_interest()


## Kapitalwert der Maschine über die Nutzungsdauer.
## Nutzt die BWL-Engine: KW = -|A0| + Σ CF_t · (1+i)^-t
func net_present_value(discount_rate: float) -> float:
	var flows: Array[float] = []
	for year in range(spec.useful_life_years):
		var cf := annual_cashflow_at(spec.capacity_units_per_year)
		# in den letzten Jahren Restwert berücksichtigen
		if year == spec.useful_life_years - 1:
			cf += spec.residual_value
		flows.append(cf)
	# abs() liefert in GDScript einen Variant, daher explizit float.
	var kw: float = -absf(spec.acquisition_cost)
	for t in range(flows.size()):
		kw += flows[t] / pow(1.0 + discount_rate, float(t + 1))
	return kw


## Buchwert nach n Jahren (linear).
func book_value_after(years: int) -> float:
	var remaining := maxi(0, spec.useful_life_years - years)
	return spec.residual_value + (spec.acquisition_cost - spec.residual_value) * (float(remaining) / float(spec.useful_life_years))


## Aktualisiert den Abschreibungszustand für ein neues Jahr.
func advance_year(year: int) -> void:
	if state == State.ACTIVE:
		production_history.append({
			"year": year,
			"quantity": quantity_this_year,
			"utilization": spec.utilization_at(quantity_this_year),
		})
		quantity_this_year = 0.0
		maintenance_cost = 0.0
		# Die Abschreibung gehoert zum gerade abgeschlossenen
		# Betriebsjahr, also vor der Alterung berechnen. Andernfalls
		# wuerde im letzten Jahr zu viel abgeschrieben.
		var depreciation := current_depreciation()
		accumulated_depreciation += depreciation
		book_value = maxf(spec.residual_value, book_value - depreciation)
		age_years += 1
		if age_years >= spec.useful_life_years:
			state = State.DECOMMISSIONED
			notes.append("Nutzungsdauer von %d Jahren erreicht – Maschine außer Betrieb." % spec.useful_life_years)


## Zustandsbezeichnung für die UI.
func state_label() -> String:
	match state:
		State.ORDERED: return "Bestellt"
		State.IN_TRANSIT: return "Im Transport"
		State.ARRIVED: return "An der Ladezone"
		State.UNLOADING: return "Wird entladen"
		State.INSTALLING: return "In Montage"
		State.ACTIVE: return "In Betrieb"
		State.DECOMMISSIONED: return "Außer Betrieb"
	return "Unbekannt"


## Zieht den Zustand eine Stufe weiter.
##
## Jeder Übergang ist fachlich bedingt und wird nur ausgeführt, wenn
## der aktuelle Zustand ihn zulässt. Rückgaben:
##   true  – der Übergang hat stattgefunden
##   false – der Übergang war nicht zulässig
func advance_state() -> bool:
	match state:
		State.ORDERED:
			# Die Bestellung ist aufgenommen, das LKW rollt an.
			state = State.IN_TRANSIT
			days_remaining = spec.delivery_days
			notes.append("Transport zur Lieferzone gestartet.")
			return true
		State.IN_TRANSIT:
			# Das LKW steht auf dem Werksgelände.
			state = State.ARRIVED
			days_remaining = UNLOAD_DAYS
			notes.append("Anlieferung eingetroffen, Ladezone erreicht.")
			return true
		State.ARRIVED:
			# Entladung beginnt.
			state = State.UNLOADING
			notes.append("Entladung läuft.")
			return true
		State.UNLOADING:
			# Ware ist abgeladen, jetzt wird montiert.
			state = State.INSTALLING
			days_remaining = spec.installation_days
			notes.append("Maschine wird montiert.")
			return true
		State.INSTALLING:
			# Montage abgeschlossen, die Maschine geht in Betrieb.
			state = State.ACTIVE
			commissioned_year = maxf(0.0, float(commissioned_year))
			notes.append("Inbetriebnahme erfolgt – Produktion startet.")
			return true
		_:
			return false


## Zustandswechsel, der von außen erzwungen wird (z. B. beim Laden
## eines Spielstands). Ungültige Übergänge werden abgelehnt.
func set_state(new_state: int) -> bool:
	if new_state == state:
		return true
	if not is_valid_transition(state, new_state):
		return false
	state = new_state
	return true


## Prüft, ob ein Übergang fachlich zulässig ist.
static func is_valid_transition(from_state: int, to_state: int) -> bool:
	match from_state:
		State.ORDERED:
			return to_state == State.IN_TRANSIT
		State.IN_TRANSIT:
			return to_state == State.ARRIVED
		State.ARRIVED:
			return to_state == State.UNLOADING
		State.UNLOADING:
			return to_state == State.INSTALLING
		State.INSTALLING:
			return to_state == State.ACTIVE
		State.ACTIVE:
			return to_state == State.DECOMMISSIONED
		_:
			return false


## Wie viele Tage der aktuelle Zustand noch beansprucht.
func days_in_current_state() -> int:
	match state:
		State.ORDERED: return 1
		State.IN_TRANSIT: return spec.delivery_days
		State.ARRIVED: return UNLOAD_DAYS
		State.UNLOADING: return 1
		State.INSTALLING: return spec.installation_days
		_: return 0


## Serialisierbarer Zustand für das Save-System.
func to_dict() -> Dictionary:
	return {
		"instance_id": instance_id,
		"spec_id": spec.id,
		"state": state,
		"position": [position.x, position.y, position.z],
		"rotation_y": rotation_y,
		"commissioned_year": commissioned_year,
		"age_years": age_years,
		"book_value": book_value,
		"accumulated_depreciation": accumulated_depreciation,
		"quantity_this_year": quantity_this_year,
		"production_history": production_history,
		"maintenance_cost": maintenance_cost,
		"installation_cost": installation_cost,
		"days_remaining": days_remaining,
		"notes": notes,
	}


## Stellt den Zustand aus einem Save wieder her.
func from_dict(data: Dictionary) -> void:
	state = int(data.get("state", State.ORDERED))
	var pos: Array = data.get("position", [0.0, 0.0, 0.0])
	position = Vector3(pos[0], pos[1], pos[2])
	rotation_y = float(data.get("rotation_y", 0.0))
	commissioned_year = int(data.get("commissioned_year", 0))
	age_years = int(data.get("age_years", 0))
	book_value = float(data.get("book_value", spec.acquisition_cost))
	accumulated_depreciation = float(data.get("accumulated_depreciation", 0.0))
	quantity_this_year = float(data.get("quantity_this_year", 0.0))
	production_history = data.get("production_history", [])
	maintenance_cost = float(data.get("maintenance_cost", 0.0))
	installation_cost = float(data.get("installation_cost", 0.0))
	days_remaining = int(data.get("days_remaining", 0))
	notes = PackedStringArray(data.get("notes", []))
