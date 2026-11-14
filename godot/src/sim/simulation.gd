extends Node
class_name SimulationEngine

## Die Wirtschaftssimulation.
##
## Deterministisch: der gleiche Startzustand + die gleiche Folge von
## Aktionen erzeugt immer exakt denselben Ablauf. Kein Zufall in der
## Wirtschaftsrechnung; Nachfrage folgt definierten Regeln.
##
## Der Klassenname `SimulationEngine` weicht bewusst vom Autoload-Namen
## `Simulation` ab: Godot verbietet es, dass eine `class_name` einen
## Autoload-Singleton verdeckt. Mit dem abweichenden Namen bleibt die
## Klasse trotzdem direkt instanziierbar – so koennen Tests mit einer
## isolierten Simulation arbeiten, ohne den laufenden Spielzustand
## zu veraendern.
##
## Zeitsteuerung: TAGE_PRO_JAHR simulierte Tage pro Echtzeit-Sekunde
## (abhängig von der Geschwindigkeit), Ticks sind ganzzahlig.

const DAYS_PER_YEAR := 360
const DAYS_PER_MONTH := 30
const MONTH_DAYS := 30

## Geschwindigkeitsstufen (Tage pro Sekunde)
const SPEEDS := [0.0, 1.0, 3.0, 8.0, 20.0]

var running: bool = false
var speed_index: int = 1
var day: int = 0
var year: int = 1
var tick: int = 0
var days_per_second: float = 1.0

## --- Zustand ---
var economy := EconomyState.new()
var grid := FactoryGrid.new()
var machines: Dictionary = {}       ## instance_id -> MachineInstance
var specs: Dictionary = {}          ## spec_id -> MachineSpec
var orders: Array = []              ## Kundenaufträge (offen)
var completed_orders: Array = []    ## abgeschlossene Kundenaufträge
var deliveries: Array = []          ## laufende Lieferungen
var inventory_material: float = 0.0 ## kg Material im Lager
var day_accumulator: float = 0.0

## Produktionseinstellungen (vom Spieler steuerbar)
var production_enabled: bool = true
## Auftragsannahme aktiv?
var accepting_orders: bool = true

## --- Statistiken ---
var stats := {
	"days_simulated": 0,
	"machines_installed": 0,
	"machines_ordered": 0,
	"orders_completed": 0,
	"orders_rejected": 0,
	"peak_utilization": 0.0,
	"total_revenue": 0.0,
	"total_costs": 0.0,
}


func _ready() -> void:
	# Maschinenkatalog einlesen
	for spec in MachineCatalog.all():
		specs[spec.id] = spec
	# Startbestand: ein Grundstock Material, damit die Produktion nach
	# der ersten Investition anlaufen kann.
	inventory_material = 0.0
	# Die Simulation startet pausiert. Der Spieler startet sie bewusst –
	# und headless-Testläufe sollen nicht endlos ticken.
	running = false
	speed_index = 0
	EventBus.simulation_speed_changed.emit(speed_index)
	EventBus.economy_changed.emit(economy.to_dict())
	# Der Startbetrieb: eine Anlage, die bereits steht und arbeitet.
	#
	# Ohne Startanlage waere das Spiel eine Sackgasse: Es gibt keine
	# Produktion, damit keine Auftraege, damit keine Einnahmen und
	# damit keine Investition. Der Spieler bekommt einen laufenden
	# Betrieb, den er ausbauen oder durch eine bessere Anlage ersetzen
	# kann.
	_start_initial_machine()


## Richtet den Startbetrieb ein: eine Anlage A steht bereits im Betrieb.
func _start_initial_machine() -> void:
	var spec: MachineSpec = specs.get(MachineCatalog.CAR_A_ID)
	if spec == null:
		return
	var instance := MachineInstance.new(spec, "anlage-start")
	instance.state = MachineInstance.State.ACTIVE
	instance.commissioned_year = year
	instance.book_value = spec.acquisition_cost
	var spot: Vector2i = grid.find_free_spot(FactoryGrid.Zone.PRODUCTION, 3, 3)
	if spot.x >= 0:
		instance.position = grid.cell_to_world(spot.x + 1, spot.y + 1)
	machines[instance.instance_id] = instance
	stats["machines_installed"] = 1
	# Die Startanlage steht bereits im Anlagevermoegen. Sie wurde
	# vorher gekauft und bezahlt – das Kapital ist gebunden.
	economy.book_investment(spec.acquisition_cost)


## Setzt die Simulation auf den Ausgangszustand zurueck.
##
## Wird fuer ein neues Spiel benoetigt. Die Startanlage wird neu
## angelegt, die Wirtschaft auf 50.000 € zurueckgesetzt.
func reset() -> void:
	day = 0
	year = 1
	tick = 0
	day_accumulator = 0.0
	machines.clear()
	orders.clear()
	completed_orders.clear()
	deliveries.clear()
	inventory_material = 0.0
	economy = EconomyState.new()
	stats = {
		"days_simulated": 0,
		"machines_installed": 0,
		"machines_ordered": 0,
		"orders_completed": 0,
		"orders_cancelled": 0,
		"peak_utilization": 0.0,
		"total_revenue": 0.0,
		"total_costs": 0.0,
	}
	production_enabled = true
	accepting_orders = true
	running = false
	speed_index = 0
	_start_initial_machine()
	EventBus.simulation_speed_changed.emit(speed_index)
	EventBus.economy_changed.emit(economy.to_dict())


## Kauft Material auf dem Markt.
##
## Ohne diese Funktion koennte die Produktion nie anlaufen: Das Lager
## waere leer, die Anlage stuende still und es gaebe keinen Weg, an
## Material zu kommen.
##
## Der Preis ist der gewichtete Durchschnitt der Materialpreise aller
## Anlagen mit Materialverbrauch – derselbe Preis, mit dem der
## Lagerbestand bewertet wird. Es gibt keine Marge: der Rohstoffmarkt
## ist ein perfekter Wettbewerb.
##
## Rückgabe: {ok, quantity, price, cost}
func buy_material(quantity_kg: float) -> Dictionary:
	if quantity_kg <= 0.0:
		return {"ok": false, "error": "Menge muss positiv sein."}

	var price := _average_material_price()
	if price <= 0.0:
		return {
			"ok": false,
			"error": "Materialpreis unbekannt – im Maschinenkatalog nachsehen.",
		}

	var cost := price * quantity_kg
	if economy.cash < cost:
		return {
			"ok": false,
			"error": "Nicht genug Kapital: %s € benötigt, %s € verfügbar." % [
				_format_int(cost), _format_int(economy.cash)
			],
		}

	economy.move_cash(-cost)
	inventory_material += quantity_kg
	economy.inventory_value = inventory_material * price
	stats["material_bought_kg"] = float(stats.get("material_bought_kg", 0.0)) + quantity_kg
	stats["material_spend"] = float(stats.get("material_spend", 0.0)) + cost

	EventBus.economy_changed.emit(economy.to_dict())
	EventBus.notify(
		"Material eingekauft",
		"%s kg Material für %s € ins Lager aufgenommen." % [
			_format(quantity_kg), _format_int(cost)
		],
		"success"
	)
	return {"ok": true, "quantity": quantity_kg, "price": price, "cost": cost}


# ==================================================================
# Zeitsteuerung
# ==================================================================

func _process(delta: float) -> void:
	if not running or speed_index <= 0:
		return
	days_per_second = SPEEDS[speed_index]
	day_accumulator += delta * days_per_second
	while day_accumulator >= 1.0:
		day_accumulator -= 1.0
		advance_day()


func set_speed(index: int) -> void:
	speed_index = clampi(index, 0, SPEEDS.size() - 1)
	running = speed_index > 0
	EventBus.simulation_speed_changed.emit(speed_index)
	EventBus.simulation_paused_changed.emit(not running)


func toggle_pause() -> void:
	if speed_index == 0:
		set_speed(1)
	else:
		set_speed(0)


# ==================================================================
# Tagesablauf
# ==================================================================

## Führt einen Simulationstag aus. Öffentlich, damit Tests deterministisch
## einen ganzen Tag Schritt für Schritt simulieren können.
func advance_day() -> void:
	day += 1
	tick += 1
	stats["days_simulated"] = int(stats["days_simulated"]) + 1

	_progress_deliveries()
	_progress_production()
	_process_customer_orders()
	_generate_demand()
	_book_monthly_fixed_costs()

	if day % DAYS_PER_YEAR == 0:
		_close_business_year()
		year += 1
		day = 0

	EventBus.simulation_ticked.emit(day, tick)
	EventBus.economy_changed.emit(economy.to_dict())


## Die laufenden Fixkosten monatlich abbuchen.
##
## Die Fixkosten (Personal, Wartung, Verwaltung) fallen laufend an –
## nicht erst am Jahresende. Fuer die Liquiditaetsanzeige wird deshalb
## jeden Monat ein Zwölftel der Jahresfixkosten von der Kasse
## abgezogen.
##
## Der Aufwand selbst wird im Jahresabschluss erfasst, damit die
## Jahresrechnung vollstaendig ist. Diese Funktion ist reine
## Zahlungswirkung und darf den Aufwand nicht doppelt buchen.
func _book_monthly_fixed_costs() -> void:
	if day == 0 or day % DAYS_PER_MONTH != 0:
		return
	var monthly: float = monthly_fixed_costs()
	if monthly <= 0.0:
		return
	economy.move_cash(-monthly)


## Lieferungen: Bestellung → Transport → Ladezone → Entladen → Montage → Betrieb.
##
## Die Logik folgt ausschliesslich dem Zustand der Maschine. Jeder
## Uebergang wird von `MachineInstance.advance_state()` ausgefuehrt und
## ist dort fachlich begruendet. Dadurch kann kein Zustand uebersprungen
## werden – insbesondere beginnt der Transport nicht erst dann, wenn
## die Maschine schon da ist.
func _progress_deliveries() -> void:
	var still_open: Array = []
	for delivery in deliveries:
		var instance: MachineInstance = machines.get(delivery["instance_id"])
		if instance == null:
			continue

		# ORDERED: Das LKW startet am Folgetag. Die Bestellung selbst
		# ist bereits am Vortag erfasst worden.
		if instance.state == MachineInstance.State.ORDERED:
			instance.advance_state()
			delivery["phase"] = "transport"
			delivery["days_remaining"] = instance.days_remaining
			EventBus.delivery_ordered.emit(delivery)
			EventBus.notify(
				"Lieferung unterwegs",
				"%s verlässt das Werk. Ankunft in %d Tagen." % [
					instance.spec.display_name, instance.days_remaining
				],
				"info"
			)
			still_open.append(delivery)
			continue

		instance.days_remaining -= 1
		delivery["days_remaining"] = instance.days_remaining

		if instance.days_remaining > 0:
			still_open.append(delivery)
			continue

		# Der aktuelle Zustand ist abgeschlossen: einen Schritt weiter.
		match instance.state:
			MachineInstance.State.IN_TRANSIT:
				instance.advance_state()
				delivery["phase"] = "arrived"
				EventBus.delivery_arrived.emit(delivery)
				EventBus.notify(
					"Anlieferung eingetroffen",
					"%s steht an der Ladezone und wird entladen." % instance.spec.display_name,
					"info"
				)
			MachineInstance.State.ARRIVED:
				instance.advance_state()
				delivery["phase"] = "unloading"
			MachineInstance.State.UNLOADING:
				instance.advance_state()
				delivery["phase"] = "installing"
			MachineInstance.State.INSTALLING:
				instance.advance_state()
				instance.commissioned_year = year
				instance.age_years = 0
				instance.book_value = instance.spec.acquisition_cost
				instance.accumulated_depreciation = 0.0
				instance.days_remaining = 0
				delivery["phase"] = "installed"
				stats["machines_installed"] = int(stats["machines_installed"]) + 1
				EventBus.delivery_installed.emit(delivery)
				EventBus.notify(
					"Maschine in Betrieb",
					"%s ist installiert. Die Kapazität steht bereit." % instance.spec.display_name,
					"success"
				)
			_:
				pass

		if instance.state != MachineInstance.State.ACTIVE:
			still_open.append(delivery)

	deliveries = still_open


## Durchschnittlicher Materialpreis je Kilogramm.
##
## Der Materialpreis ist an die jeweilige Maschine gebunden. Fuer die
## Lagerbewertung (Bestandsvermögen) wird der gewichtete Durchschnitt
## ueber alle Maschinen mit Materialverbrauch gebildet. Maschinen ohne
## Materialverbrauch gehen nicht in die Mittelung ein – sonst wuerde
## der Preis gegen Null sinken.
func _average_material_price() -> float:
	var weighted := 0.0
	var weight := 0.0
	for instance_id in machines:
		var instance: MachineInstance = machines[instance_id]
		var per_unit := instance.spec.material_per_unit
		if per_unit <= 0.0:
			continue
		weighted += instance.spec.material_price_per_kg * per_unit
		weight += per_unit
	if weight <= 0.0:
		return 0.0
	return weighted / weight


## Der aktuelle Materialpreis je Kilogramm.
func material_price() -> float:
	return _average_material_price()


## Produktion: Auslastung, Materialverbrauch, Kosten.
func _progress_production() -> void:
	if not production_enabled:
		return
	for instance_id in machines:
		var instance: MachineInstance = machines[instance_id]
		if not instance.is_operational():
			continue

		# Tagesproduktion = Kapazität/360, gedeckelt durch Material
		var daily_capacity := instance.spec.capacity_units_per_year / float(DAYS_PER_YEAR)
		var daily_material_needed := daily_capacity * instance.spec.material_per_unit
		var material_available := true
		if daily_material_needed > 0.0:
			material_available = inventory_material >= daily_material_needed
			if material_available:
				inventory_material -= daily_material_needed

		if not material_available:
			# Materialengpass -> Maschine läuft im Leerlauf
			instance.notes.append("Tag %d: Materialengpass – Anlage im Leerlauf." % day)
			continue

		instance.quantity_this_year += daily_capacity
		instance.maintenance_cost += instance.spec.fixed_operating_costs / float(DAYS_PER_YEAR)

		var utilization := instance.spec.utilization_at(instance.quantity_this_year)
		stats["peak_utilization"] = maxf(float(stats["peak_utilization"]), utilization)


## Kundenaufträge: Annahme, Produktion, Lieferung, Zahlung.
##
## Ein Auftrag wird ausschliesslich erfuellt, wenn die geforderte Menge
## tatsaechlich produziert wurde. Die Produktion wird aus den Maschinen
## heraus an die Auftraege verteilt: jede Einheit wird nur einmal
## vergeben. Ohne diese Kopplung wuerde ein Auftrag allein an der
## vorhandenen Kapazitaet erfuellt, ohne dass etwas hergestellt wurde.
func _process_customer_orders() -> void:
	if not accepting_orders:
		return

	# Tagesproduktion aller betriebsbereiten Maschinen. Sie ist die
	# Menge, die an die offenen Auftraege verteilt werden kann.
	var daily_production := 0.0
	for instance_id in machines:
		var instance: MachineInstance = machines[instance_id]
		if instance.is_operational():
			daily_production += instance.spec.capacity_units_per_year / float(DAYS_PER_YEAR)

	# Forderungen einziehen, deren Zahlungsziel erreicht ist.
	_collect_receivables()

	# Nachfrage folgt einer deterministischen Kurve (Saisonalitaet + Wachstum)
	# Kein Zufall: der Spielstand bleibt reproduzierbar.
	for order in orders:
		if order["status"] != "accepted":
			continue
		# Fortschritt in Tagen
		order["progress_days"] = int(order["progress_days"]) + 1

		var required := float(order["quantity"])
		var produced_for_order := float(order.get("produced", 0.0))

		# Nur solange die Lieferfrist nicht abgelaufen ist, wird
		# produziert. Danach kann der Auftrag nicht mehr erfuellt
		# werden und wird storniert.
		if order["progress_days"] > int(order["lead_time_days"]):
			order["status"] = "cancelled"
			order["cancelled_day"] = day
			stats["orders_cancelled"] = int(stats.get("orders_cancelled", 0)) + 1
			EventBus.notify(
				"Auftrag nicht erfüllbar",
				"Die Lieferfrist für %s Stück ist verstrichen. Der Auftrag wurde storniert." % _format(required),
				"warning"
			)
			continue

		# Produktion auf den Auftrag anrechnen.
		var still_needed := required - produced_for_order
		if still_needed > 0.0 and daily_production > 0.0:
			var allocatable: float = minf(still_needed, daily_production)
			produced_for_order += allocatable
			daily_production -= allocatable
			order["produced"] = produced_for_order
			order["production_progress"] = produced_for_order / required if required > 0.0 else 0.0

		# Auslieferung: Menge vollstaendig UND Lieferfrist eingehalten.
		if produced_for_order >= required and order["progress_days"] <= int(order["lead_time_days"]):
			order["status"] = "delivered"
			order["delivered_day"] = day
			order["produced"] = required
			# Erloes: ggf. mit Zahlungsziel (Forderung)
			#
			# Wichtig: Das Eigenkapital wird NICHT hier fortgeschrieben.
			# Das geschieht einmal im Jahresabschluss ueber das
			# Jahresergebnis. Andernfalls waere der Umsatz doppelt
			# erfasst.
			var revenue := float(order["revenue"])
			economy.revenue_current_year += revenue
			economy.revenue_total += revenue
			if int(order.get("payment_delay_days", 0)) <= 0:
				economy.move_cash(revenue)
			else:
				economy.receivables += revenue
			stats["orders_completed"] = int(stats["orders_completed"]) + 1
			completed_orders.append(order)
			EventBus.order_completed.emit(order)
			EventBus.notify(
				"Auftrag abgeschlossen",
				"%s Stück wurden geliefert. Umsatz: %s €" % [
					_format(order["quantity"]), _format_int(revenue)
				],
				"success"
			)

	orders = orders.filter(func(o): return o["status"] == "accepted")


## Die Nachfrage: Kundenaufträge, die von selbst entstehen.
##
## Ohne Nachfrage haette die Produktion keine Abnehmer – die Anlage
## liefe ins Leere und keine Investition wuerde sich rechnen. Die
## Nachfrage folgt definierten Regeln und ist deterministisch:
##
##  1. Grundmenge: ein fester Anteil der installierten Kapazitaet
##     wird bestellt. Wer mehr Kapazitaet baut, bekommt auch mehr
##     Auftrage – sonst waere eine Investition sinnlos.
##  2. Der Preis richtet sich nach dem Deckungsbeitrag der Anlage
##     plus einem festen Aufschlag. Uebersteigt der Preis den
##     Deckungsbeitrag, ist der Auftrag unrentabel und wird gar
##     nicht erst angeboten.
##  3. Die Menge schwankt in einem definierten Band. Die Schwankung
##     folgt einer deterministischen Funktion aus Tag und Jahr – kein
##     Zufall, aber auch keine konstante Nachfrage.
##  4. Jeder Auftrag hat eine Lieferfrist. Wer die Frist reisst,
##     verliert den Auftrag.
##
## Der Auftrag wird sofort angenommen: Im Spiel gibt es keinen
## Vertrieb – die Firma ist ein etablierter Lieferant.
func _generate_demand() -> void:
	# Kapazitaet und Deckungsbeitrag der betriebsbereiten Anlagen
	var capacity := 0.0
	var db := 0.0
	var price_hint := 0.0
	for instance_id in machines:
		var instance: MachineInstance = machines[instance_id]
		if not instance.is_operational():
			continue
		capacity += instance.spec.capacity_units_per_year
		db = instance.spec.contribution_margin_per_unit()
		price_hint = instance.spec.price_per_unit
	if capacity <= 0.0:
		return

	# Ein Auftrag alle X Tage. Je groesser die Kapazitaet, desto
	# oefter kommt ein Auftrag.
	var interval := maxi(15, int(180.0 / maxf(1.0, capacity / 10000.0)))
	if day % interval != 0:
		return
	# Am ersten Tag eines Jahres kein neuer Auftrag: das Jahr soll
	# zusammenfassbar bleiben.
	if day % DAYS_PER_YEAR == 0:
		return

	# Die bestellte Menge: ein Anteil der Kapazitaet.
	#
	# Der Anteil schwankt deterministisch zwischen 40 % und 80 % der
	# Kapazitaet. Die Schwankung folgt einer Sinusfunktion ueber die
	# Jahrestage – glatt, nachvollziehbar, ohne Zufall.
	var phase := float(day % DAYS_PER_YEAR) / float(DAYS_PER_YEAR) * TAU
	var swing := 0.6 + 0.2 * sin(phase)
	var share := 0.40 + 0.40 * swing
	# floor() liefert in Godot 4 einen Variant – der Typ wird explizit
	# angegeben, sonst schlaegt die Typinferenz fehl.
	var quantity: float = floor(capacity * share / 100.0) * 100.0
	if quantity <= 0.0:
		quantity = 100.0

	# Der Preis: Deckungsbeitrag plus Marge. Uebersteigt er den
	# Deckungsbeitrag deutlich, ist der Auftrag nicht mehr sinnvoll.
	var margin := 0.15
	var price := db * (1.0 + margin)
	if price_hint > 0.0:
		# Der Preis orientiert sich am Marktpreis der Anlage, bleibt
		# aber so, dass eine Marge ueber den Fixkosten moeglich ist.
		price = maxf(price, db * 1.05)
		price = minf(price, price_hint)
	if price <= db:
		# Unrentabel: der Auftrag wird gar nicht erst angeboten.
		return

	# Lieferfrist: so viele Tage, wie die Menge bei Tagesproduktion
	# braucht, plus 40 % Puffer.
	var daily := capacity / float(DAYS_PER_YEAR)
	var needed := int(ceil(quantity / maxf(1.0, daily)))
	var lead_time := maxi(10, int(needed * 1.4))

	# Zahlungsziel: 30 Tage, gelegentlich 60. Das erzeugt
	# Forderungen und macht die Liquiditaetsplanung spannend.
	var payment_delay := 30
	if day % 97 == 0:
		payment_delay = 60

	var order := {
		"id": "auftrag-%d" % day,
		"status": "accepted",
		"customer": "Großhandel %d" % (1 + day % 7),
		"quantity": quantity,
		"price_per_unit": price,
		"revenue": price * quantity,
		"lead_time_days": lead_time,
		"progress_days": 0,
		"payment_delay_days": payment_delay,
		"produced": 0.0,
		"accepted_day": day,
	}
	orders.append(order)
	stats["orders_received"] = int(stats.get("orders_received", 0)) + 1
	EventBus.order_received.emit(order)
	EventBus.notify(
		"Neuer Kundenauftrag",
		"%s bestellt %s Stück zu %s € je Stück. Lieferung in %d Tagen." % [
			order["customer"], _format(quantity), _format_int(price), lead_time
		],
		"info"
	)


## Zieht fällige Forderungen ein.
##
## Kundenaufträge mit Zahlungsziel werden zunächst als Forderung
## gebucht. Erreicht das Ziel, fliesst der Betrag in die Kasse. Ohne
## diese Logik bliebe das Geld dauerhaft gebunden und die Liquidität
## sinkf über die Zeit ohne sichtbaren Grund.
func _collect_receivables() -> void:
	var still_open: Array = []
	for order in completed_orders:
		if int(order.get("payment_delay_days", 0)) <= 0:
			continue
		if int(order.get("payment_received", 0)) == 1:
			continue
		var due_day := int(order.get("delivered_day", day)) + int(order.get("payment_delay_days", 0))
		if day >= due_day:
			var revenue := float(order["revenue"])
			economy.move_cash(revenue)
			economy.receivables = maxf(0.0, economy.receivables - revenue)
			order["payment_received"] = 1
			order["payment_received_day"] = day
		else:
			still_open.append(order)
	# Abgeloeste Auftraege ohne Zahlungsziel bleiben fuer die Statistik.
	for order in completed_orders:
		if int(order.get("payment_delay_days", 0)) <= 0:
			still_open.append(order)
	completed_orders = still_open


# ==================================================================
# Geschäftsjahresabschluss
# ==================================================================

func _close_business_year() -> void:
	# Abschreibungen und kalkulatorische Zinsen neu berechnen
	var new_depreciation := 0.0
	var new_imputed := 0.0
	for instance_id in machines:
		var instance: MachineInstance = machines[instance_id]
		if instance.is_operational():
			new_depreciation += instance.current_depreciation()
			new_imputed += instance.current_imputed_interest()
	economy.depreciation_year = new_depreciation
	economy.imputed_interest_year = new_imputed
	economy.interest_paid_year = economy.debt * economy.debt_rate

	# Zahlungswirksame Fixkosten: Personal, Wartung, Verwaltung
	var fixed := 0.0
	for instance_id in machines:
		var instance: MachineInstance = machines[instance_id]
		if instance.is_operational():
			fixed += instance.spec.fixed_operating_costs
			fixed += instance.spec.labor_cost()
	economy.fixed_costs_year = fixed

	# Materialverbrauch buchen.
	#
	# Wichtig: Das verbrauchte Material wird gegen den Lagerbestand
	# gebucht und geht als Aufwand in die laufenden Kosten ein. Ohne
	# diese Verbuchung wäre die Produktion kostenlos.
	var material_cost := 0.0
	for instance_id in machines:
		var instance: MachineInstance = machines[instance_id]
		if instance.is_operational():
			material_cost += instance.spec.material_per_unit * instance.spec.material_price_per_kg * instance.quantity_this_year
	economy.material_costs_year = material_cost
	economy.costs_current_year += material_cost
	economy.costs_total += material_cost
	economy.inventory_value = inventory_material * _average_material_price()

	# Fixkosten als laufenden Aufwand verbuchen.
	#
	# Die Fixkosten sind zahlungswirksam und gehen in die Gewinnrechnung
	# ein. Abschreibung und kalkulatorische Zinsen sind es nicht – sie
	# wirken ueber die Ergebnisrechnung, ohne die Kasse zu bewegen.
	economy.costs_current_year += economy.fixed_costs_year
	economy.costs_total += economy.fixed_costs_year

	# Abschreibung: mindert das Anlagevermögen und mindert den Gewinn.
	economy.costs_current_year += economy.depreciation_year
	economy.costs_total += economy.depreciation_year
	economy.book_depreciation(economy.depreciation_year)

	# Kalkulatorische Zinsen: mindern den Gewinn, sind aber nicht
	# zahlungswirksam. Der eigentliche Zinsaufwand auf Fremdkapital
	# wird weiter unten separat verbucht.
	economy.costs_current_year += economy.imputed_interest_year
	economy.costs_total += economy.imputed_interest_year

	# Zinsaufwand auf Fremdkapital: zahlungswirksam.
	economy.costs_current_year += economy.interest_paid_year
	economy.costs_total += economy.interest_paid_year

	# Tilgung auf das Fremdkapital.
	#
	# Die Tilgung ist zahlungswirksam, mindert aber das Eigenkapital
	# nicht – sie reduziert das Fremdkapital. Sie ist daher KEIN Aufwand
	# und gehoert nicht in die Gewinnrechnung, sondern in den
	# Finanzierungsbereich.
	var repayment: float = 0.0
	if economy.debt > 0.0:
		# Standardmaessig werden 10 % des Fremdkapitals getilgt, sofern
		# die Kasse das hergibt.
		repayment = minf(economy.debt * 0.10, maxf(0.0, economy.cash))
		if repayment > 0.0:
			economy.move_cash(-repayment)
			economy.debt = maxf(0.0, economy.debt - repayment)
	economy.repayment_year = repayment

	# Jahr abschließen: Gewinn und Kasse.
	#
	# Wichtig: Der Umsatz ist der Kasse BEREITS bei der Lieferung
	# gutgeschrieben worden. Hier darf er nicht ein zweites Mal
	# hinzugefuegt werden – sonst waere der Umsatz doppelt erfasst.
	#
	# Was die Kasse im Jahr mindert, sind die ZAHLUNGSWIRKSAMEN
	# Kosten:
	#   Zinsaufwand auf Fremdkapital
	#
	# Fixkosten wurden bereits monatlich von der Kasse abgezogen
	# (_book_monthly_fixed_costs); hier kommen sie nur noch in die
	# Jahresrechnung als Aufwand. Doppelbuchung auf der Kasse wuerde
	# die Liquiditaet zu stark schrumpfen lassen.
	#
	# Das Material wird hier NICHT noch einmal abgezogen: Die Zahlung
	# erfolgte bereits beim Einkauf (buy_material mindert die Kasse),
	# der Bestand wurde beim Verbrauch abgebaut. Der Materialaufwand
	# gehoert in die Gewinnrechnung, nicht in eine zweite Barabbuchung.
	#
	# Abschreibung und kalkulatorische Zinsen sind nicht zahlungswirksam
	# und bleiben deshalb ohne Wirkung auf die Kasse.
	#
	# Die Tilgung wurde oben bereits direkt gebucht (Fremdkapital
	# sinkt, Kasse sinkt) und darf nicht noch einmal erfasst werden.
	economy.profit_current_year = economy.operating_result()
	economy.move_cash(-economy.interest_paid_year)
	economy.move_cash(-economy.dividend_current_year)
	economy.equity += economy.profit_current_year - economy.dividend_current_year
	if economy.dividend_current_year > 0.0:
		economy.dividends_paid += economy.dividend_current_year

	# Jahreswerte zurücksetzen
	economy.revenue_current_year = 0.0
	economy.costs_current_year = 0.0
	economy.dividend_current_year = 0.0

	# Maschinen altern
	for instance_id in machines:
		machines[instance_id].advance_year(year)

	stats["total_revenue"] = economy.revenue_total
	stats["total_costs"] = economy.costs_total
	stats["fixed_assets"] = economy.fixed_assets
	stats["balance_check"] = economy.balance_check()

	EventBus.day_passed.emit(year, _year_report())
	EventBus.economy_changed.emit(economy.to_dict())


## Jahresabschlussbericht.
func _year_report() -> Dictionary:
	return {
		"year": year,
		"revenue": economy.revenue_total,
		"result": economy.profit_current_year,
		"cash": economy.cash,
		"roe": economy.roe_percent(),
		"liquidity": economy.liquidity_ratio(),
		"health": economy.health_status(),
	}


# ==================================================================
# Spielaktionen
# ==================================================================

## Bestellt eine Maschine. Kapital wird gebunden, Lieferung wird angelegt.
func order_machine(spec_id: StringName) -> Dictionary:
	var spec: MachineSpec = specs.get(spec_id)
	if spec == null:
		return {"ok": false, "error": "Unbekannter Maschinentyp: %s" % spec_id}
	if economy.cash < spec.acquisition_cost:
		return {
			"ok": false,
			"error": "Nicht genügend Kapital: %s € benötigt, %s € verfügbar." % [
				_format_int(spec.acquisition_cost), _format_int(economy.cash)
			],
		}

	# Investitionsauszahlung: Kapital binden, Anlagevermögen erhöhen.
	# Das ist KEIN laufender Aufwand – die Abschreibung wirkt später.
	economy.book_investment(spec.acquisition_cost)
	stats["machines_ordered"] = int(stats["machines_ordered"]) + 1

	var instance_id := "%s_%d" % [spec.id, machines.size()]
	var instance := MachineInstance.new(spec, instance_id)
	instance.state = MachineInstance.State.ORDERED

	# Position auf dem Gelände bestimmen
	var spot: Vector2i = grid.find_free_spot(FactoryGrid.Zone.PRODUCTION, 3, 3)
	if spot.x >= 0:
		instance.position = grid.cell_to_world(spot.x + 1, spot.y + 1)

	machines[instance_id] = instance

	var delivery := {
		"instance_id": instance_id,
		"spec_id": spec_id,
		"phase": "ordered",
		"days_remaining": spec.delivery_days,
		"ordered_day": day,
	}
	deliveries.append(delivery)

	EventBus.investment_committed.emit({
		"instance_id": instance_id,
		"spec_id": spec_id,
		"cost": spec.acquisition_cost,
		"delivery_days": spec.delivery_days,
	})
	EventBus.delivery_ordered.emit(delivery)
	EventBus.notify(
		"Maschine bestellt",
		"%s für %s € bestellt. Lieferung in %d Tagen." % [
			spec.display_name, _format_int(spec.acquisition_cost), spec.delivery_days
		],
		"info"
	)

	return {"ok": true, "instance_id": instance_id, "delivery": delivery}


## Nimmt einen Kundenauftrag an.
func accept_order(order: Dictionary) -> bool:
	if order.get("status", "") == "accepted":
		return true
	order["status"] = "accepted"
	order["accepted_day"] = day
	orders.append(order)
	EventBus.order_received.emit(order)
	return true


## Verkauft / liquidiert eine Maschine.
func divest_machine(instance_id: String, sale_price: float) -> Dictionary:
	var instance: MachineInstance = machines.get(instance_id)
	if instance == null:
		return {"ok": false, "error": "Maschine nicht gefunden."}
	var book := instance.book_value
	var gain := sale_price - book
	economy.move_cash(sale_price)
	economy.equity += gain
	# Restbuchwert wird ausgebucht
	economy.depreciation_year = maxf(0.0, economy.depreciation_year - instance.current_depreciation())
	machines.erase(instance_id)
	deliveries = deliveries.filter(func(d): return d["instance_id"] != instance_id)
	EventBus.notify(
		"Maschine verkauft",
		"%s für %s € veräußert. Buchwert %s €." % [
			instance.spec.display_name, _format_int(sale_price), _format_int(book)
		],
		"info"
	)
	return {"ok": true, "gain": gain, "book_value": book}


## Nimmt einen Kredit auf.
func take_loan(amount: float, rate: float = -1.0) -> Dictionary:
	if amount <= 0.0:
		return {"ok": false, "error": "Kreditbetrag muss positiv sein."}
	economy.move_cash(amount)
	economy.debt += amount
	if rate >= 0.0:
		economy.debt_rate = rate
	EventBus.economy_changed.emit(economy.to_dict())
	return {"ok": true, "amount": amount, "rate": economy.debt_rate}


## Tilgt einen Kredit.
func repay_loan(amount: float) -> Dictionary:
	if amount <= 0.0:
		return {"ok": false, "error": "Tilgungsbetrag muss positiv sein."}
	var actual := minf(amount, economy.debt)
	economy.move_cash(-actual)
	economy.debt = maxf(0.0, economy.debt - actual)
	EventBus.economy_changed.emit(economy.to_dict())
	return {"ok": true, "amount": actual}


# ==================================================================
# Abfragen
# ==================================================================

## Alle Maschinen im aktiven Betrieb.
func active_machines() -> Array[MachineInstance]:
	var out: Array[MachineInstance] = []
	for id in machines:
		var m: MachineInstance = machines[id]
		if m.is_operational():
			out.append(m)
	return out


## Aktuelle Gesamtauslastung aller Anlagen in Prozent.
func current_utilization() -> float:
	var active := active_machines()
	if active.is_empty():
		return 0.0
	var total_capacity := 0.0
	var total_produced := 0.0
	for m in active:
		total_capacity += m.spec.capacity_units_per_year
		total_produced += m.quantity_this_year
	if total_capacity <= 0.0:
		return 0.0
	return (total_produced / total_capacity) * 100.0


## Monatliche Fixkosten (für die Liquiditätsanzeige).
func monthly_fixed_costs() -> float:
	# Die Jahresfixkosten werden direkt aus den betriebsbereiten
	# Anlagen berechnet. `economy.fixed_costs_year` wird erst beim
	# Jahresabschluss gesetzt und taege fuer die laufende
	# Zahlungswirkung zu spaet.
	var total := 0.0
	for instance_id in machines:
		var instance: MachineInstance = machines[instance_id]
		if instance.is_operational():
			total += instance.spec.fixed_operating_costs
			total += instance.spec.labor_cost()
	return total / 12.0


## Serialisierbarer Zustand der Simulation.
func to_dict() -> Dictionary:
	var machine_data := {}
	for id in machines:
		machine_data[id] = machines[id].to_dict()
	return {
		"day": day,
		"year": year,
		"tick": tick,
		"economy": economy.to_dict(),
		"grid": grid.to_dict(),
		"machines": machine_data,
		"orders": orders,
		"completed_orders": completed_orders,
		"deliveries": deliveries,
		"inventory_material": inventory_material,
		"stats": stats,
	}


## Stellt den Simulationszustand aus einem Save wieder her.
func from_dict(data: Dictionary) -> void:
	day = int(data.get("day", 0))
	year = int(data.get("year", 1))
	tick = int(data.get("tick", 0))
	economy.from_dict(data.get("economy", {}))
	grid.from_dict(data.get("grid", {}))
	machines.clear()
	var machine_data: Dictionary = data.get("machines", {})
	for id in machine_data:
		var entry: Dictionary = machine_data[id]
		var spec_id: StringName = StringName(entry.get("spec_id", ""))
		var spec: MachineSpec = specs.get(spec_id)
		if spec == null:
			continue
		var instance := MachineInstance.new(spec, String(id))
		instance.from_dict(entry)
		machines[id] = instance
	orders = data.get("orders", [])
	completed_orders = data.get("completed_orders", [])
	deliveries = data.get("deliveries", [])
	inventory_material = float(data.get("inventory_material", 0.0))
	stats = data.get("stats", stats)


# ==================================================================
# Formatierung
# ==================================================================

func _format(value: float) -> String:
	return String.num(value, 2)


func _format_int(value: float) -> String:
	return String.num(round(value), 0)
