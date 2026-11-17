extends Node

## Der Unternehmensberater.
##
## Wichtig: dieses Skript darf KEIN `class_name` tragen. Ein
## `class_name` mit demselben Namen wie ein Autoload-Singleton fuehrt
## beim Import zum Fehler. Dasselbe gilt fuer eine andere
## Klassennamen auf derselben Datei: Godon registriert die Datei
## dann zweimal, und die Instanz laesst sich nicht erzeugen.
##
## Er analysiert den tatsächlichen Zustand des Unternehmens und gibt
## kontextbezogene Hinweise. Grundsatz aus der Spieldefinition:
## „Der Berater darf nicht immer die fertige Lösung verraten." Er benennt
## das Problem, zeigt den Analyseweg und verweist auf die Konsequenz –
## die Entscheidung trifft der Spieler.

const ANALYSIS_INTERVAL := 5  ## Analyse alle 5 Simulationstage

var _last_analysis_day: int = -1
var _messages: Array = []       ## Historie der Hinweise
var _seen: Dictionary = {}      ## Anti-Wiederholung: gleiche Empfehlung nur einmal
var _cash_event_counter: int = 0  ## Zaehlt Kassenereignisse (eindeutige IDs)
var current_analysis: Dictionary = {}


func _ready() -> void:
	EventBus.simulation_ticked.connect(_on_tick)
	EventBus.order_received.connect(_on_order_received)
	EventBus.delivery_installed.connect(_on_delivery_installed)
	EventBus.order_completed.connect(_on_order_completed)
	EventBus.cash_changed.connect(_on_cash_changed)


## Ein neuer Kundenauftrag: was bedeutet er fuer das Unternehmen?
func _on_order_received(order: Dictionary) -> void:
	var sim: SimulationEngine = Simulation
	if sim == null:
		return
	var quantity := float(order.get("quantity", 0.0))
	var revenue := float(order.get("revenue", 0.0))
	var margin := 0.0
	var machines: Array[MachineInstance] = sim.active_machines()
	for m in machines:
		# Nur Endstufen: eine Vorstufe verkauft nichts an den Markt.
		# Ihr Beitrag steckt im Ketten-Deckungsbeitrag der Endstufe.
		if m.spec.is_intermediate_stage():
			continue
		margin += sim._chain_contribution_margin(m.spec) * minf(
			quantity, m.spec.capacity_units_per_year
		)
	if margin <= 0.0:
		return

	var share := revenue * (margin / maxf(revenue, 1.0))
	var title := "Auftrag über %s €" % _format_eur(revenue)
	var body := (
		"Der Auftrag bindet Produktionskapazität über %d Tage. "
		+ "Erwarteter Deckungsbeitrag: %s €. Prüfe, ob die Fixkosten "
		+ "dieser Kapazität die Rendite nicht auffrisst."
	) % [
		int(order.get("lead_time_days", 0)), _format_eur(share)
	]
	EventBus.notify(title, body, "info")
	_emit_event_finding(
		"event-order-%d" % int(order.get("accepted_day", 0)),
		title,
		body,
		"Welche Kosten entstehen dadurch, dass die Anlage für %d Tage "
		% int(order.get("lead_time_days", 0))
		+ "belegt ist – und ist das mehr als der Deckungsbeitrag?",
		"Der Deckungsbeitrag deckt nur die variablen Kosten. Die Fixkosten "
		+ "der Anlage laufen weiter, auch wenn sie weniger auslastet.",
		"Nimm die Auslastung im Produktionsbereich unter der Woche 1–4 in den Blick.",
	)


## Eine Maschine wurde installiert: was aendert sich jetzt?
func _on_delivery_installed(order: Dictionary) -> void:
	var sim: SimulationEngine = Simulation
	if sim == null:
		return
	var spec: MachineSpec = sim.specs.get(String(order.get("spec_id", "")))
	if spec == null:
		return
	var machines: Array[MachineInstance] = sim.active_machines()
	var capacity := 0.0
	for m in machines:
		capacity += m.spec.capacity_units_per_year

	var body := (
		"Die Anlage ist betriebsbereit. Die Kapazität des Werks steigt auf "
		+ "%s Stück p.a. Fixed Costs: %s € p.a., Abschreibung: %s € p.a. "
		+ "Damit steigt die Break-even-Menge – die Anlage muss erst ausgelastet "
		+ "werden, bevor sie Gewinn bringt."
	) % [
		_format_int(capacity),
		_format_eur(spec.total_fixed_costs()),
		_format_eur(spec.depreciation()),
	]
	EventBus.notify("Anlage in Betrieb: %s" % spec.display_name, body, "success")
	_emit_event_finding(
		"event-install-%s" % String(order.get("instance_id", "")),
		"Anlage installiert: %s" % spec.display_name,
		body,
		"Ab welcher Absatzmenge deckt die neue Kapazität ihre Fixkosten?",
		"Neue Kapazität bringt Nutzen, aber auch Fixkosten. Der Gewinn "
		+ "entsteht erst oberhalb der Break-even-Menge.",
		"Öffne die Produktionsansicht und vergleiche Auslastung und Break-even.",
	)


## Ein Auftrag wurde abgeschlossen: wie wirkt er sich auf die Liquidität aus?
func _on_order_completed(order: Dictionary) -> void:
	var sim: SimulationEngine = Simulation
	if sim == null:
		return
	var revenue := float(order.get("revenue", 0.0))
	var delay := int(order.get("payment_delay_days", 0))
	if delay <= 0:
		return
	var body := (
		"Die Ware ist geliefert. Die %s € fließen erst in %d Tagen auf das "
		+ "Konto. Bis dahin ist das Geld gebunden – prüfe, ob die Liquidität "
		+ "diese Wartezeit trägt."
	) % [_format_eur(revenue), delay]
	EventBus.notify("Auftrag abgeschlossen", body, "info")
	_emit_event_finding(
		"event-complete-%s" % String(order.get("id", "")),
		"Zahlungsziel: %d Tage" % delay,
		body,
		"Wie viel Kapital bindet dieser Auftrag, während du wartest?",
		"Zahlungsziele verschieben Erlöse in die Zukunft. Bei knapper "
		+ "Liquidität können sie den Betrieb gefährden.",
		"Öffne den Finanzbereich und prüfe Forderungen und Kasse.",
	)


## Eine relevante Kassenbewegung: muss der Spieler handeln?
func _on_cash_changed(cash: float, delta: float) -> void:
	if delta >= 0.0:
		return
	var sim: SimulationEngine = Simulation
	if sim == null:
		return

	# Eine Zahlung ist relevant, wenn sie einen spuerbaren Teil der
	# Liquiditaet bindet. Die Schwelle richtet sich nach der Kasse –
	# 10.000 Euro sind bei 80.000 Euro Kasse ein Geringes, bei
	# 15.000 Euro Kasse ein ernstes Zeichen.
	var threshold: float = maxf(5_000.0, absf(sim.economy.cash) * 0.15)
	if absf(delta) < threshold:
		return

	var body := (
		"Es sind %s € aus dem Betrieb abgeflossen. Der Kontostand liegt "
		+ "jetzt bei %s €."
	) % [_format_eur(absf(delta)), _format_eur(cash)]
	EventBus.notify("Zahlung von %s €" % _format_eur(absf(delta)), body, "warning")
	_cash_event_counter += 1
	_emit_event_finding(
		"event-cash-%d-%d" % [Simulation.day, _cash_event_counter],
		"Kasse um %s € gesunken" % _format_eur(absf(delta)),
		body,
		"Reicht die verbleibende Liquidität für Fixkosten und Zinsen?",
		"Jeder Euro, der das Betriebskonto verlässt, muss später "
		+ "wieder hereinkommen. Das ist der Liquiditätsengpass.",
		"Öffne den Finanzbereich und vergleiche Kasse und Fixkosten.",
	)


## Ein ereignisbezogener Hinweis mit Frage, Lektion und Handlung.
func _emit_event_finding(
	id: String, title: String, analysis: String,
	question: String, lesson: String, action: String
) -> void:
	if _seen.has(id):
		return
	_seen[id] = true
	var message := {
		"id": id,
		"severity": "info",
		"title": title,
		"analysis": analysis,
		"questions": [question],
		"lesson": lesson,
		"action": action,
		"day": Simulation.day if Simulation != null else 0,
	}
	_messages.append(message)
	EventBus.advisor_message_added.emit(message)


## Kilogramm-Menge formatieren (mit Tausenderpunkt).
func _format_kg(value: float) -> String:
	return "%s kg" % _format_int(value)


## Ganzzahl formatieren (mit Tausenderpunkt).
func _format_int(value: float) -> String:
	var negative := value < 0.0
	var amount := absf(value)
	var text := "%.0f" % amount
	var grouped := ""
	var count := 0
	for i in range(text.length() - 1, -1, -1):
		grouped = text[i] + grouped
		count += 1
		if count % 3 == 0 and i > 0:
			grouped = "." + grouped
	return ("-" if negative else "") + grouped


## Geldbetrag formatieren.
func _format_eur(value: float) -> String:
	var negative := value < 0.0
	var amount := absf(value)
	var text := "%.0f €" % amount
	# Tausenderpunkt einfuegen.
	var digits := text.split(".")[0]
	var grouped := ""
	var count := 0
	for i in range(digits.length() - 1, -1, -1):
		grouped = digits[i] + grouped
		count += 1
		if count % 3 == 0 and i > 0:
			grouped = "." + grouped
	text = text.replace(digits, grouped)
	return ("-" if negative else "") + text


func _on_tick(_day: int, _tick: int) -> void:
	analyze()


## Führt die Analyse durch und erzeugt Hinweise.
func analyze() -> Dictionary:
	var sim: SimulationEngine = Simulation
	if sim == null:
		return {}

	var economy: EconomyState = sim.economy
	var machines: Array[MachineInstance] = sim.active_machines()
	var findings := _analyze_utilization(machines)
	findings.append_array(_analyze_liquidity(economy))
	findings.append_array(_analyze_capacity(machines))
	findings.append_array(_analyze_investments(machines))
	findings.append_array(_analyze_orders(sim))
	findings.append_array(_analyze_efficiency(machines))
	findings.append_array(_analyze_deliveries(sim))
	findings.append_array(_analyze_capital_binding(sim, machines))
	findings.append_array(_analyze_lost_orders(sim))
	findings.append_array(_analyze_financing(sim))
	findings.append_array(_analyze_material_supply(sim))
	findings.append_array(_analyze_contracts(sim))
	findings.append_array(_analyze_production_chain(sim, machines))
	findings.append_array(_analyze_demand_vs_capacity(sim, machines))
	findings.append_array(_analyze_next_steps(sim, machines))

	current_analysis = {
		"day": sim.day,
		"year": sim.year,
		"findings": findings,
		"utilization": sim.current_utilization(),
		"health": economy.health_status(),
	}
	EventBus.advisor_analysis_changed.emit(current_analysis)
	_publish(findings)
	return current_analysis


# ==================================================================
# Analysemodule
# ==================================================================

## Auslastung: zu geringe Auslastung ist das häufigste Problem.
func _analyze_utilization(machines: Array[MachineInstance]) -> Array:
	var out: Array = []
	if machines.is_empty():
		return out
	# Die Auslastung wird aus den uebergebenen Anlagen berechnet,
	# nicht aus dem globalen Zustand. Sonst waere die Analyse nicht
	# pruefbar und koennte Anzeige und Wirklichkeit auseinanderlaufen.
	var total_capacity := 0.0
	var total_produced := 0.0
	for m in machines:
		total_capacity += m.spec.capacity_units_per_year
		total_produced += m.quantity_this_year
	var utilization := 0.0
	if total_capacity > 0.0:
		utilization = (total_produced / total_capacity) * 100.0

	if utilization < 40.0:
		out.append({
			"id": "low_utilization",
			"severity": "warning",
			"title": "Auslastung zu gering",
			"analysis": "Die Anlagen laufen aktuell zu %d %% Auslastung. Fixkosten werden unabhängig von der Auslastung bezahlt – je niedriger sie ist, desto höher ist der Stückkostenanteil je Einheit." % int(utilization),
			"questions": [
				"Ab welcher Menge deckt der Deckungsbeitrag deine Fixkosten?",
				"Kannst du zusätzliche Kundenaufträge annehmen?",
			],
			"lesson": "Die kritische Menge ist die Produktionsmenge, bei der die Deckungsbeitrage genau die Fixkosten decken.",
			"action": "Öffne den Kostenvergleich unter Produktion → Investitionsentscheidung.",
		})
	elif utilization > 92.0:
		out.append({
			"id": "high_utilization",
			"severity": "info",
			"title": "Kapazitätsgrenze erreicht",
			"analysis": "Die Auslastung liegt bei %d %%. Deine Anlagen sind fast voll – zusätzliche Aufträge werden nicht mehr zuverlässig bedienbar." % int(utilization),
			"questions": ["Welche Erweiterung hat die beste Kapitalwertrentabilität?"],
			"lesson": "Kapazitätsengpässe zeigen sich zuerst in der Auslastung, nicht im Deckungsbeitrag.",
			"action": "Vergleiche eine Erweiterungsinvestition im Investitionsmodul.",
		})
	return out


## Liquidität: die häufigste Todesursache für Unternehmen.
func _analyze_liquidity(economy: EconomyState) -> Array:
	var out: Array = []
	var liq := economy.liquidity_ratio()
	var health := economy.health_status()

	if health == "critical":
		out.append({
			"id": "critical_liquidity",
			"severity": "critical",
			"title": "Liquiditätskrise",
			"analysis": "Die Kasse ist überzogen (Liquiditätsgrad %.2f). Zahlungswirksame Kosten laufen weiter, auch wenn kein Auftrag hereinkommt." % liq,
			"questions": [
				"Welche zahlungswirksamen Kosten kannst du kurzfristig reduzieren?",
				"Welche Forderungen kannst du faster einziehen?",
			],
			"lesson": "Liquidität wird durch zahlungswirksame Zahlungsströme bestimmt – nicht durch den ausgewiesenen Gewinn.",
			"action": "Prüfe den Kapitalbedarf und die Finanzierung im Finanzierungsmodul.",
		})
	elif liq < 2.0:
		out.append({
			"id": "tense_liquidity",
			"severity": "warning",
			"title": "Liquiditätspuffer wird dünn",
			"analysis": "Der Liquiditätsgrad liegt bei %.2f Monaten Fixkosten. Kurzefristig ist das vertretbar, aber der Puffer schrumpft." % liq,
			"questions": ["Wie viele Monate Fixkosten kannst du zusätzlich tragen?"],
			"lesson": "Der Liquiditätsgrad II vergleicht die Kasse mit den kurzfristigen Fixkosten.",
			"action": "Behalte die Kasse im Blick, bevor du investierst.",
		})

	var dr := economy.debt_ratio()
	if dr > 0.7:
		out.append({
			"id": "high_leverage",
			"severity": "warning",
			"title": "Hohe Verschuldung",
			"analysis": "Die Fremdkapitalquote beträgt %.0f %%. Leverage verstärkt die Eigenkapitalrentabilität nur, wenn die Gesamtkapitalrentabilität über dem Fremdkapitalzins liegt." % (dr * 100.0),
			"questions": [
				"Liegt deine Gesamtkapitalrentabilität über dem Fremdkapitalzins?",
				"Wie wirkt eine höhere Verschuldung auf deine EK-Rentabilität?",
			],
			"lesson": "Leverage-Effekt: r_e = r_g + FK/EK · (r_g − r_f).",
			"action": "Rechne den Leverage-Effekt im Finanzierungsmodul nach.",
		})
	return out


## Kapazität: fehlende oder ungenutzte Kapazität.
func _analyze_capacity(machines: Array[MachineInstance]) -> Array:
	var out: Array = []
	if machines.is_empty():
		out.append({
			"id": "no_machines",
			"severity": "info",
			"title": "Noch keine Anlage im Betrieb",
			"analysis": "Dein Unternehmen produziert noch nicht. Der erste Schritt ist eine Investitionsentscheidung mit sauberer Kostenrechnung.",
			"questions": [
				"Welche Anlage hat die niedrigsten Fixkosten?",
				"Welche Anlage hat die geringsten variablen Stückkosten?",
			],
			"lesson": "Ohne Fixkostenbasis gibt es keinen Break-even und keine Rentabilität.",
			"action": "Bestelle deine erste Maschine unter Produktion → Investition.",
		})
		return out
	return out


## Investitionen: laufende Projekte und Wirtschaftlichkeit.
func _analyze_investments(machines: Array[MachineInstance]) -> Array:
	var out: Array = []
	var sim: SimulationEngine = Simulation
	# Lieferungen unterwegs
	if not sim.deliveries.is_empty():
		var delivery: Dictionary = sim.deliveries[0]
		out.append({
			"id": "delivery_in_progress",
			"severity": "info",
			"title": "Lieferung unterwegs",
			"analysis": "Die Lieferung ist in Phase '%s' (noch %d Tage). Die Investitionsauszahlung ist bereits gebunden – die Anlage wirkt erst nach der Inbetriebnahme auf die Kostenstruktur." % [
				String(delivery.get("phase", "?")), int(delivery.get("days_remaining", 0))
			],
			"questions": ["Wie wirkt sich die neue Fixkostenbasis auf deinen Break-even aus?"],
			"lesson": "Die Anschaffungsauszahlung ist eine Investition; erst die Abschreibung belastet das Ergebnis.",
			"action": "Beobachte die Anlieferung im Betriebsgelände.",
		})

	for m in machines:
		# Der Berater verwendet denselben Diskontsatz wie die
		# Investitionsrechnung: den gewichteten Mittelwert aus Eigen-
		# und Fremdkapitalzins. Sonst widerspricht er dem Vergleichsmodul.
		var rate: float = m.spec.effective_interest_rate()
		var npv: float = m.net_present_value(rate)
		if npv < 0.0:
			out.append({
				"id": "negative_npv_%s" % m.instance_id,
				"severity": "warning",
				"title": "%s: Kapitalwert negativ" % m.spec.display_name,
				"analysis": (
					"Bei einem Diskontsatz von %.1f %% beträgt der Kapitalwert "
					+ "dieser Anlage %s €. Der Kapitaleinsatz ist nicht "
					+ "gerechtfertigt."
				) % [rate * 100.0, BWLEngine.format_eur(npv)],
				"questions": [
					"Bei welcher Menge wäre die Anlage rentabel?",
					"Wie hoch müsste der Verkaufspreis sein, damit der Kapitalwert positiv wird?",
				],
				"lesson": "Der Kapitalwert ist die entscheidende Entscheidungsgröße: KW > 0 bedeutet Wertschöpfung.",
				"action": "Öffne das Investitionsmodul und variiere die Menge.",
			})
			continue

		# Der Kapitalwert ist die Annuität zum Barwert. Er beantwortet
		# die praktische Frage: Welcher Jahresbeitrag waere die
		# Anlage noch wert? Liegt er unter den jaehrlichen Fixkosten,
		# verdient die Anlage ihr Kapital nicht.
		var capital_value: float = BWLEngine.annuity_from_npv(
			npv, rate, m.spec.useful_life_years
		)
		var annual_fixed: float = m.spec.total_fixed_costs()
		if capital_value < annual_fixed:
			out.append({
				"id": "capital_value_below_fixed_%s" % m.instance_id,
				"severity": "warning",
				"title": "%s: Kapitalwert unter den Fixkosten" % m.spec.display_name,
				"analysis": (
					"Der Kapitalwert dieser Anlage beträgt %s € p.a. Ihre "
					+ "jaehrlichen Fixkosten liegen bei %s €. Damit liefert "
					+ "der Einsatz keinen Wertbeitrag."
				) % [
					BWLEngine.format_eur(capital_value),
					BWLEngine.format_eur(annual_fixed),
				],
				"questions": [
					"Was kostet es, die Anlage ein Jahr zu betreiben – und was bringt sie?",
					"Ab welcher Absatzmenge dreht sich das um?",
				],
				"lesson": (
					"Der Kapitalwert ist der Jahresbeitrag, den die "
					+ "Investition gerade noch wert waere. Liegt er unter "
					+ "den Fixkosten, verbrennt die Anlage Kapital."
				),
				"action": "Prüfe die Auslastung im Produktionsbereich.",
			})
	return out


## Materialversorgung: reicht der Bestand bis zur naechsten Lieferung?
##
## Material ohne Vorlauf ist der haeufigste Grund fuer stillstehende
## Produktion. Der Berater warnt, BEVOR die Anlage stoppt – nicht
## danach.
func _analyze_material_supply(sim: SimulationEngine) -> Array:
	var out: Array = []
	var material_types := sim.required_material_types()
	if material_types.is_empty():
		return out

	var lead_time: int = Simulation.MATERIAL_LEAD_TIME_DAYS
	# Jede Materialart wird einzeln geprueft. Ein Bestand ersetzt
	# keinen anderen - wer Stahl hat, kann keine Verpackung
	# produzieren.
	for material_type in material_types:
		var daily_need: float = sim.daily_material_need(material_type)
		if daily_need <= 0.0:
			continue
		var label := MachineCatalog.material_label(material_type)
		var coverage: float = sim.material_coverage_days(material_type)
		out.append_array(
			_analyze_material_type(sim, material_type, label, daily_need, coverage, lead_time)
		)
	return out


## Die Materialversorgung einer einzelnen Materialart pruefen.
func _analyze_material_type(
	sim: SimulationEngine, material_type: StringName, label: String,
	daily_need: float, coverage: float, lead_time: int
) -> Array:
	var out: Array = []

	# Der Bestand reicht nicht bis zur naechsten Lieferung.
	if coverage < lead_time:
		var in_transit: float = sim.material_in_transit(material_type)
		var body := (
			"Der %s-Bestand reicht noch %d Tage. Die Lieferzeit betraegt "
			+ "%d Tage. Ohne Nachbestellung stoppt die Produktion in %d Tagen."
		) % [label, int(coverage), lead_time, int(coverage)]
		if in_transit > 0.0:
			body += " Auf dem Weg sind noch %s kg." % _format_kg(in_transit)
		out.append({
			"id": "material_short_%s_%d" % [label, int(sim.day)],
			"severity": "warning",
			"title": "%s-Bestand reicht nicht bis zur Lieferung" % label,
			"analysis": body,
			"questions": [
				"Wie viele Tage Produktion sichert der Bestand noch?",
				"Was kostet es, jetzt zu bestellen – und was kostet ein Produktionsstopp?",
			],
			"lesson": (
				"Material ohne Vorlauf ist ein stiller Kostenblock: Die "
				+ "Anlage steht, die Fixkosten laufen weiter. Der Bestand "
				+ "muss immer die Lieferzeit überbrücken."
			),
			"action": "Öffne die Produktionsansicht und bestelle Material nach.",
		})
		return out

	# Der Bestand ist knapp, reicht aber noch.
	if coverage < lead_time * 2.0:
		out.append({
			"id": "material_tight_%s_%d" % [label, int(sim.day)],
			"severity": "info",
			"title": "%s-Bestand wird knapp" % label,
			"analysis": (
				"Der %s-Bestand reicht noch %d Tage bei einem Tagesbedarf "
				% [label, int(coverage)]
				+ "von %s kg. Eine Bestellung sollte bald aufgegeben werden."
			) % _format_kg(daily_need),
			"questions": [
				"Wie lange reicht der Bestand bei voller Auslastung?",
				"Welche Bestellmenge deckt die nächsten 30 Tage?",
			],
			"lesson": (
				"Der Materialvorlauf bestimmt, wie lange die Anlage ohne "
				+ "Unterbrechung laufen kann. Er ist Teil der Planung, "
				+ "nicht der Beschaffung."
			),
			"action": "Prüfe die Materialbestände in der Produktionsansicht.",
		})
	return out


## Rahmenvertraege: gebundene Nachfrage, aber auch gebundener Preis.
##
## Ein Vertrag sichert Menge, kostet aber Preisbindung. Der Berater
## stellt die Frage, ob die Kapazitaet ohne den Vertrag besser
## ausgelastet waere.
func _analyze_contracts(sim: SimulationEngine) -> Array:
	var out: Array = []
	var contracts: Array = sim.contracts
	if contracts.is_empty():
		return out

	var contracted := sim.contracted_quantity()
	var capacity: float = sim._total_capacity()
	if capacity <= 0.0:
		return out

	var share := contracted / capacity
	if share > 0.8:
		out.append({
			"id": "contracts_high_commitment",
			"severity": "warning",
			"title": "Fast die gesamte Kapazität ist vertraglich gebunden",
			"analysis": (
				"Die Verträge binden %s Stück p.a. Das ist %.0f %% deiner "
				+ "Kapazität von %s Stück. Der Marktzusatz ist entsprechend "
				+ "gering – und der Preis für die gebundene Menge ist fest."
			) % [
				_format_int(contracted),
				share * 100.0,
				_format_int(capacity),
			],
			"questions": [
				"Wie viel Kapazität bleibt für die freie Nachfrage?",
				"Was passiert, wenn der Vertragspartner weniger abnimmt?",
			],
			"lesson": (
				"Ein Vertrag macht Nachfrage planbar, aber er bindet "
				+ "Kapazität zu einem festen Preis. Das ist Fluch und "
				+ "Segen zugleich."
			),
			"action": "Öffne den Finanzbereich und prüfe die Verträge.",
		})

	# Ein Vertrag unter dem Deckungsbeitrag waere ein Verlust.
	var db: float = sim._weighted_contribution_margin()
	for contract in contracts:
		var price := float(contract.get("price_per_unit", 0.0))
		if db > 0.0 and price < db:
			out.append({
				"id": "contract_loss_%s" % String(contract.get("id", "")),
				"severity": "warning",
				"title": "Vertrag unter dem Deckungsbeitrag",
				"analysis": (
					"Der Vertrag %s liefert %s € je Stück, der Deckungsbeitrag "
					+ "beträgt aber nur %s €. Jedes Stück verliert damit Geld."
				) % [
					String(contract.get("customer", "Vertrag")),
					_format_eur(price),
					_format_eur(db),
				],
				"questions": [
					"Wie viel verliert das Unternehmen an jedem Stück?",
					"Wie viel Stück müssen verkauft werden, um den Verlust zu decken?",
				],
				"lesson": (
					"Ein Vertrag unter dem Deckungsbeitrag ist kein sicherer "
					+ "Umsatz, sondern ein sicherer Verlust."
				),
				"action": "Prüfe die Verträge im Finanzbereich.",
			})
	return out


## Finanzierung: Leverage, Zinsbelastung und Kreditrahmen.
##
## Der Berater zeigt die Konsequenz der Kapitalstruktur, nicht nur die
## Zahlen. Er stellt die Fragen, die der Spieler beantworten muss:
## Wieviel eigenes Kapital steckt im Unternehmen, und wie teuer wird
## das Fremdkapital?
func _analyze_financing(sim: SimulationEngine) -> Array:
	var out: Array = []
	var economy: EconomyState = sim.economy
	var equity := economy.equity
	var debt := economy.debt
	if equity <= 0.0:
		return out

	var debt_share := debt / maxf(equity + debt, 1.0)
	var burden := economy.interest_paid_year / equity

	# Zu hohe Verschuldung: der Zins frisst das Eigenkapital.
	if debt_share > 0.5:
		out.append({
			"id": "financing_high_leverage",
			"severity": "warning",
			"title": "Fremdkapital über 50 %",
			"analysis": (
				"Das Fremdkapital beträgt %s € bei %s € Eigenkapital. "
				+ "Die Zinsbelastung des Eigenkapitals liegt bei %s %% p.a. "
				+ "Der Bank wird damit mehr geschuldet als dem eigenen Unternehmen gehört."
			) % [
				_format_eur(debt),
				_format_eur(equity),
				"%.1f" % (burden * 100.0),
			],
			"questions": [
				"Welcher Teil des Kapitals gehört dem Eigentümer, welcher der Bank?",
				"Was passiert mit dem Eigenkapital, wenn der Zins höher wird als die Rendite?",
			],
			"lesson": (
				"Leverage verstärkt Gewinne – aber auch Verluste. Ab einer "
				+ "Fremdkapitalquote über 50 % ist das Eigenkapital die "
				+ "schwächere Seite der Bilanz."
			),
			"action": "Öffne den Finanzbereich und erhöhe den Tilgungsanteil.",
		})

	# Zinsbelastung: der Zins frisst die Rendite.
	if burden > 0.15:
		out.append({
			"id": "financing_interest_burden",
			"severity": "warning",
			"title": "Zinsen belasten das Eigenkapital stark",
			"analysis": (
				"Die Zinskosten von %s € entsprechen %s %% des Eigenkapitals. "
				+ "Davon müssen %s € übrig bleiben, damit die Geschäftstätigkeit "
				+ "aus eigener Kraft trägt."
			) % [
				_format_eur(economy.interest_paid_year),
				"%.1f" % (burden * 100.0),
				_format_eur(maxf(0.0, economy.operating_result())),
			],
			"questions": [
				"Reicht der operative Cashflow, um die Zinsen zu tragen?",
				"Welche Anlage bringt mehr Rendite als der Kreditzins?",
			],
			"lesson": (
				"Der Kreditzins ist die Hürde, die eine Investition "
				+ "übernehmen muss. Bringt sie weniger als der Zins, "
				+ "vernichtet sie Eigenkapital."
			),
			"action": "Prüfe im Investitionsmodul die interne Rendite deiner Anlagen.",
		})

	# Ungenutzter Kreditrahmen: Kapital bleibt ungenutzt.
	var limit := sim.credit_limit()
	if limit > 20_000.0 and debt_share < 0.3:
		out.append({
			"id": "financing_unused_capacity",
			"severity": "info",
			"title": "Kreditrahmen nicht ausgeschöpft",
			"analysis": (
				"Die Bank würde %s € gewähren. Das Eigenkapital ist "
				+ "zu %s % % vom Fremdkapital finanziert – eine niedrige "
				+ "Fremdkapitalquote ist ein Zeichen gesunder Finanzierung, "
				+ "aber ungenutztes Kapital kostet Rendite."
			) % [_format_eur(limit), "%.0f" % (debt_share * 100.0)],
			"questions": [
				"Gibt es eine Investition, die mehr bringt als der Kreditzins?",
				"Was ist der Unterschied zwischen Eigen- und Fremdkapital für die Rendite?",
			],
			"lesson": (
				"Eigenkapital kostet Opportunitätskosten, Fremdkapital "
				+ "Zinsen. Der billige Zins schont das Eigenkapital nur "
				+ "wenn die Investition mehr bringt als er."
			),
			"action": "Öffne das Investitionsmodul und prüfe den Kapitalwert.",
		})

	return out


## Aufträge: unwirtschaftliche oder unbedienbare Aufträge.
func _analyze_orders(sim: SimulationEngine) -> Array:
	var out: Array = []
	for order in sim.orders:
		if String(order.get("status", "")) != "accepted":
			continue
		var quantity := float(order.get("quantity", 0.0))
		var revenue := float(order.get("revenue", 0.0))
		var price := revenue / quantity if quantity > 0.0 else 0.0
		# Der niedrigste Deckungsbeitrag der laufenden Anlagen ist die
		# strengste sinnvolle Masszahl: Ein Auftrag unter diesem Wert
		# verliert Geld, egal welche Anlage ihn produziert.
		var db := INF
		var producing: Array[MachineInstance] = sim.active_machines()
		for m in producing:
			var m_db := m.spec.contribution_margin_per_unit()
			if m_db < db:
				db = m_db
		if db < INF and db > 0.0 and price < db:
			out.append({
				"id": "unprofitable_order",
				"severity": "warning",
				"title": "Auftrag unter Deckungsbeitrag",
				"analysis": "Der Auftrag bringt %s € je Stück, der Deckungsbeitrag liegt aber nur bei %s €. Jede zusätzliche Einheit würde die Fixkosten nicht decken." % [
					BWLEngine.format_eur(price), BWLEngine.format_eur(db)
				],
				"questions": [
					"Kannst du den Preis nachverhandeln?",
					"Wie viele Einheiten bräuchtest du, um die Fixkosten zu decken?",
				],
				"lesson": "Ein Auftrag unter dem Deckungsbeitrag vernichtet Deckungsbeitrag – er trägt nicht zur Fixkostendeckung bei.",
				"action": "Prüfe die Annahme des Auftrags im Auftragspanel.",
			})
	return out


## Verlorene Auftraege: Ein stornierter Auftrag ist das deutlichste
## Signal fuer fehlende Kapazitaet.
##
## Ein Auftrag wird storniert, wenn die Lieferfrist ablaeuft, bevor
## die Menge produziert werden konnte. Das heisst: die Anlage war zu
## langsam oder die Materialversorgung hat nicht gestimmt.
func _analyze_lost_orders(sim: SimulationEngine) -> Array:
	var out: Array = []
	var cancelled := int(sim.stats.get("orders_cancelled", 0))
	if cancelled <= 0:
		return out

	var machines: Array[MachineInstance] = sim.active_machines()
	var capacity := 0.0
	for m in machines:
		capacity += m.spec.capacity_units_per_year

	out.append({
		"id": "lost_orders",
		"severity": "warning",
		"title": "%d Auftrag/Aufträge nicht erfüllt" % cancelled,
		"analysis": "Die Lieferfrist lief ab, bevor die Menge produziert werden konnte. Bei einer Kapazität von %s Stück p.a. reicht die Produktion nicht für die Nachfrage." % [
			BWLEngine.format_eur(capacity, 0)
		],
		"questions": [
			"Reicht deine Kapazität für die bestellten Mengen?",
			"Welche Anlage erhöht die Kapazität um das meiste je investiertem Euro?",
			"Kann Materialengpass die Produktion gebremst haben?",
		],
		"lesson": "Eine zu kleine Anlage verliert nicht nur Ertrag – sie bindet auch Fixkosten, ohne die Nachfrage bedienen zu können.",
		"action": "Prüfe die Auslastung und vergleiche eine Erweiterungsinvestition.",
	})
	return out


## Effizienz: Fixkosten je Stück, Materialverbrauch.
func _analyze_efficiency(machines: Array[MachineInstance]) -> Array:
	var out: Array = []
	for m in machines:
		var produced := m.quantity_this_year
		if produced <= 0.0:
			continue
		var fixed_per_unit := m.current_cash_fixed_costs() / produced
		if fixed_per_unit > 0.0:
			out.append({
				"id": "fixed_cost_per_unit_%s" % m.instance_id,
				"severity": "info",
				"title": "%s: Fixkosten je Stück" % m.spec.display_name,
				"analysis": "Auf die %d produzierten Stück entfallen %s € zahlungswirksame Fixkosten. Je höher die Auslastung, desto geringer dieser Anteil." % [
					int(produced), BWLEngine.format_eur(fixed_per_unit)
				],
				"questions": ["Wie verändert sich der Fixkostenanteil bei doppelter Auslastung?"],
				"lesson": "Fixkosten bleiben absolut konstant – ihre Verteilung auf die Stückzahl sinkt mit steigender Auslastung.",
				"action": "Beobachte die Auslastungsanzeige der Anlage.",
			})
	return out


## Lieferkette: Maschinen, die bestellt, aber noch nicht in Betrieb sind.
##
## Jede bestellte Maschine bindet Kapital, liefert aber noch keine
## Kapazität. Dieser Zustand wird leicht übersehen – gerade deshalb
## ist er eine der wichtigsten Kennzahlen im laufenden Betrieb.
func _analyze_deliveries(sim: SimulationEngine) -> Array:
	var out: Array = []
	var pending_value := 0.0
	var pending_count := 0
	var oldest_days := 0

	for delivery in sim.deliveries:
		var instance_id := String(delivery.get("instance_id", ""))
		var instance: MachineInstance = sim.machines.get(instance_id)
		if instance == null:
			continue
		pending_count += 1
		pending_value += instance.spec.acquisition_cost
		var waited := int(sim.day) - int(delivery.get("ordered_day", sim.day))
		if waited > oldest_days:
			oldest_days = waited

	if pending_count == 0:
		return out

	var status_text := "Bestellt und unterwegs"
	for delivery in sim.deliveries:
		var instance_id := String(delivery.get("instance_id", ""))
		var instance: MachineInstance = sim.machines.get(instance_id)
		if instance == null:
			continue
		match instance.state:
			MachineInstance.State.ORDERED:
				status_text = "im Wareneingang"
			MachineInstance.State.IN_TRANSIT:
				status_text = "auf dem Weg zur Baustelle"
			MachineInstance.State.ARRIVED:
				status_text = "angekommen, Entladen steht an"
			MachineInstance.State.UNLOADING:
				status_text = "wird entladen"
			MachineInstance.State.INSTALLING:
				status_text = "wird montiert"
		break

	out.append({
		"id": "pending_deliveries",
		"severity": "info" if oldest_days < 60 else "warning",
		"title": "%d Maschine(n) noch nicht betriebsbereit" % pending_count,
		"analysis": "Für %s € Anschaffungswert ist Kapital gebunden, das noch keine Produktion bringt. Die letzte Maschine ist %s und %d Tage alt." % [
			BWLEngine.format_eur(pending_value), status_text, oldest_days
		],
		"questions": [
			"Wann genau wird die Maschine kapazitätswirksam?",
			"Welche Fixkosten laufen bereits, obwohl noch nichts produziert wird?",
		],
		"lesson": "Eine Investition wirkt erst ab dem Zeitpunkt der Inbetriebnahme. Davor bindet sie Kapital, ohne Deckungsbeitrag zu erzeugen.",
		"action": "Beobachte die Lieferkette in der Logistikansicht.",
	})
	return out


## Kapitalbindung: Anlagevermögen im Verhältnis zur Produktion.
##
## Je hoeher das Anlagevermoegen im Verhaeltnis zur Kapazitaet, desto
## mehr Kapital ist gebunden. Das ist der Kern der BWL-Frage "Wann
## lohnt sich die naechste Maschine?".
func _analyze_capital_binding(sim: SimulationEngine, machines: Array[MachineInstance]) -> Array:
	var out: Array = []
	var economy: EconomyState = sim.economy
	if economy.fixed_assets <= 0.0:
		return out

	var capacity := 0.0
	for m in machines:
		capacity += m.spec.capacity_units_per_year

	if capacity <= 0.0:
		return out

	var asset_per_capacity := economy.fixed_assets / capacity
	out.append({
		"id": "capital_binding",
		"severity": "info",
		"title": "Kapitalbindung je Kapazitätseinheit",
		"analysis": "Auf dem Anlagevermögen von %s € entfallen %s € je Kapazitätseinheit. Das ist die Investition, die eine zusätzliche Einheit Kapazität kostet – noch ohne laufende Fixkosten." % [
			BWLEngine.format_eur(economy.fixed_assets), BWLEngine.format_eur(asset_per_capacity)
		],
		"questions": [
			"Steigt dieser Wert, wenn du eine weitere Maschine kaufst?",
			"Wann senkt eine höhere Auslastung diesen Wert?",
		],
		"lesson": "Der Kapazitätswert einer Investition ist der Quotient aus Anlagevermögen und Kapazität. Er sinkt mit steigender Auslastung.",
		"action": "Vergleiche die Maschinen im Investitionsmodul.",
	})
	return out


# ==================================================================
# Veröffentlichung
# ==================================================================

## Der Fahrplan: die naechste Handlung mit konkreter Zielzahl.
##
## Die uebrigen Module melden Probleme. Der Fahrplan geht einen
## Schritt weiter: er nennt, was als Naechstes zu tun ist – mit
## einer Zahl, gegen die der Spieler pruefen kann.
##
## Die Reihenfolge folgt der Logik des Unternehmens:
##   1. Auslastung unter 60 %: erst mehr aus vorhandener Kapazitaet
##      produzieren. Zielzahl: 80 % Auslastung.
##   2. Auslastung passt, aber die Kasse traegt weniger als drei
##      Monatsfixkosten: Liquiditaetsreserve aufbauen. Zielzahl in Euro.
##   3. Beides passt: jetzt lohnt sich eine Investition – mit dem
##      Namen der Anlage, die den besten Kapitalwert hat.
##
## Begruendung und Lektion bleiben erhalten: Der Fahrplan gibt keine
## fertige Entscheidung ab, sondern die Frage, die davor steht.
func _analyze_next_steps(sim: SimulationEngine, machines: Array[MachineInstance]) -> Array:
	var out: Array = []
	if machines.is_empty():
		return out

	# Die Auslastung wird aus den uebergebenen Anlagen berechnet –
	# wie in der Auslastungsanalyse. Sonst wuerde der Fahrplan eine
	# Zahl nennen, die zu einem anderen Betrieb gehoert.
	var total_capacity := 0.0
	var total_produced := 0.0
	for m in machines:
		total_capacity += m.spec.capacity_units_per_year
		total_produced += m.quantity_this_year
	var utilization := 0.0
	if total_capacity > 0.0:
		utilization = (total_produced / total_capacity) * 100.0
	var economy: EconomyState = sim.economy

	# 1) Erst die vorhandene Kapazitaet nutzen.
	if utilization < 60.0:
		var capacity := total_capacity
		var target_quantity := capacity * 0.8
		var current_quantity := total_produced
		out.append({
			"id": "next_step_utilization",
			"severity": "info",
			"title": "Nächster Schritt: Auslastung erhöhen",
			"analysis": "Deine Anlagen laufen zu %d %% Auslastung. Bevor du investierst, lohnt sich zuerst die vorhandene Kapazitaet: Ziel sind 80 %% Auslastung, also %s Stueck statt %s. Das kostet nichts und bringt Deckungsbeitrag auf die bereits bezahlten Fixkosten." % [
				int(utilization),
				_format_int(target_quantity),
				_format_int(current_quantity),
			],
			"questions": [
				"Welche Anlage hat die höchste Kapazität bei den geringsten Fixkosten?",
				"Welche Kundenaufträge lehnt dein Betrieb bisher ab?",
			],
			"lesson": "Fixkosten fallen auch bei leerer Halle an: Sie sind beschäftigungsunabhaengig, aber nicht sunkener Kosten. Erst die vorhandene Kapazitaet zu nutzen ist immer die guenstigste Investition.",
			"action": "Pruefe deine offenen Angebote und stelle die Auftragsannahme auf aktiv.",
		})
		return out

	# 2) Liquiditaetsreserve, wenn die Kasse zu duenn ist.
	var monthly_fixed := sim.monthly_fixed_costs()
	if monthly_fixed > 0.0:
		var reserve_target := monthly_fixed * 3.0
		if economy.cash < reserve_target:
			out.append({
				"id": "next_step_liquidity",
				"severity": "warning",
				"title": "Nächster Schritt: Liquiditätsreserve aufbauen",
				"analysis": "Die Auslastung passt, aber die Kasse liegt bei %s Euro. Drei Monatsfixkosten sind %s Euro. Unter dieser Grenze kann ein Zahlungsverzug die Investition stoppen, obwohl sie rechnerisch rentabel ist." % [
					_format_eur(economy.cash),
					_format_eur(reserve_target),
				],
				"questions": [
					"Welche Zahlung kommt in den nächsten Wochen herein?",
					"Was bindet dein Kapital – Lagerbestand oder Forderungen?",
				],
				"lesson": "Eine Investition, die du nicht finanzieren kannst, bringt dir keinen Deckungsbeitrag. Liquiditaet ist die Voraussetzung fuer Investition.",
				"action": "Oeffne die Finanzierung und pruefe, ob ein Kredit deine Reserve schont.",
			})
			return out

	# 3) Investition: die Anlage mit der besten Kapitalrendite.
	#
	# Verglichen wird nicht der absolute Kapitalwert (der waere bei
	# einer teuren Anlage einfach groesser), sondern die Rendite auf
	# das eingesetzte Kapital. Nur die beantwortet die Frage
	# "wohin soll mein naechster Euro".
	var best_name := ""
	var best_ratio := -INF
	var best_npv := 0.0
	for m in machines:
		var spec := m.spec
		# Nur Endstufen tragen zum Absatz bei – eine Vorstufe wird
		# gemeinsam mit ihrer Endstufe bewertet.
		if spec.is_intermediate_stage():
			continue
		var rate := spec.effective_interest_rate()
		var npv := m.net_present_value(rate)
		var investment := spec.acquisition_cost
		# Bei einer Kette zaehlt die Vorstufe mit: Sie ist Teil
		# derselben Investitionsentscheidung.
		if spec.input_product != &"":
			var producers := sim.producers_of(spec.input_product)
			for p in producers:
				investment += p.spec.acquisition_cost
				npv += sim.chain_net_present_value(m, rate) - m.net_present_value(rate)
		if investment <= 0.0:
			continue
		var ratio := npv / investment
		if ratio > best_ratio:
			best_ratio = ratio
			best_name = spec.display_name
			best_npv = npv
	if best_name.is_empty() or best_ratio <= 0.0:
		# Keine Anlage mit positivem Kapitalwert: dann ist Auslastung
		# die richtige Naechste – aber die wurde oben schon geprueft.
		return out
	out.append({
		"id": "next_step_investment",
		"severity": "info",
		"title": "Nächster Schritt: Kapazität erweitern",
		"analysis": "Auslastung und Liquiditaet passen. Jetzt lohnt sich eine weitere Anlage: '%s' erreicht bei voller Auslastung den besten Kapitalwert im Verhaeltnis zum Kapitaleinsatz (%s Euro bei %s Euro Investition). Vergleiche die Investitionen, bevor du dich entscheidest." % [
			best_name,
			BWLEngine.format_eur(best_npv),
			BWLEngine.format_eur(best_npv / best_ratio) if best_ratio > 0.0 else "-",
		],
		"questions": [
			"Welche Anlage hat den hoechsten Kapitalwert?",
			"Wie viel Kapital bindest du dafuer – und wie lange?",
		],
		"lesson": "Eine Investition schafft Wert, wenn ihr Kapitalwert ihre Anschaffung uebersteigt. Der Kapitalwert ist der Barwert der erwarteten Cashflows.",
		"action": "Oeffne die Investitionsentscheidung und vergleiche die Kapitalwerte.",
	})
	return out


## Produktionskette: die Kopplung der Stufen sichtbar machen.
##
## Drei Faelle sind fuer den Spieler wichtig:
##   * Eine Endstufe ohne Vorstufe steht still.
##   * Die Vorstufe ist der Engpass (Rueckstau im Zwischenlager).
##   * Die Vorstufe produziert mehr, als die Endstufe verbraucht.
func _analyze_production_chain(sim: SimulationEngine, machines: Array[MachineInstance]) -> Array:
	var out: Array = []
	if machines.is_empty():
		return out

	# Endstufen ohne Vorstufe im Betrieb.
	for m in machines:
		if m.spec.input_product == &"":
			continue
		var has_producer := false
		for other in machines:
			if other.spec.output_product == m.spec.input_product:
				has_producer = true
				break
		if has_producer:
			continue
		out.append({
			"id": "chain_missing_stage_%s" % m.spec.id,
			"severity": "warning",
			"title": "Zulieferer fehlt: %s steht still" % m.spec.display_name,
			"analysis": "'%s' verbraucht %s je Einheit, aber keine Anlage im Betrieb liefert dieses Zwischenprodukt. Die Anlage laeuft im Leerlauf – ihre Fixkosten fallen an, ohne dass Ware entsteht." % [
				m.spec.display_name, String(m.spec.input_product)
			],
			"questions": [
				"Welche Anlage stellt dieses Zwischenprodukt her?",
				"Verdient sich diese Vorstufe, wenn die Endstufe stillsteht?",
			],
			"lesson": "In einer Produktionskette begrenzt die langsamste Stufe das Ergebnis. Fehlt eine Stufe, zahlt man deren Fixkosten ohne Gegenwert.",
			"action": "Pruefe im Maschinenkatalog, welche Anlage das Zwischenprodukt herstellt.",
		})
		return out

	# Rueckstau: die Vorstufe liefert mehr, als die Endstufe abnimmt.
	for product in sim.intermediate_products():
		var stock := sim.intermediate_stock(product)
		if stock <= 0.0:
			continue
		# Wie viel braucht die Endstufe pro Tag?
		var daily_demand := 0.0
		var demand_exists := false
		for m in machines:
			if m.spec.input_product != product:
				continue
			demand_exists = true
			daily_demand += (
				m.spec.capacity_units_per_year
				/ 360.0
				* m.spec.input_product_per_unit
			)
		if not demand_exists:
			continue
		# Mehr als ein Tagesbedarf im Lager bedeutet: die Vorstufe
		# produziert schneller, als abgenommen wird.
		if stock > daily_demand:
			out.append({
				"id": "chain_backlog_%s" % product,
				"severity": "info",
				"title": "Rückstau im Zwischenlager: %s" % String(product),
				"analysis": "Im Zwischenlager liegen %s Stueck %s. Das ist mehr als ein Tagesbedarf (%s Stueck). Die Vorstufe produziert schneller, als die Endstufe abnimmt – das bindet Kapital ohne Mehrwert." % [
					_format_int(stock), String(product), _format_int(daily_demand)
				],
				"questions": [
					"Lohnt es sich, die Vorstufe zu erweitern?",
					"Welche Stufe ist wirtschaftlich der Engpass?",
				],
				"lesson": "Zwischenprodukte binden Kapital, ohne Erloes zu bringen. Ein wachsender Lagerbestand zeigt eine Verklemmung in der Kette.",
				"action": "Pruefe, welche Stufe du erweitern willst.",
			})
			return out
	return out


## Nachfrage gegen Kapazitaet: der Kern des Absatzproblems.
##
## Es gibt zwei gegensaetzliche Faelle, beide sind Fehler:
##   * Die Nachfrage uebersteigt die Kapazitaet: Auftraege werden
##     nicht bedient, Umsatz geht verloren.
##   * Die Kapazitaet uebersteigt die Nachfrage: Fixkosten stehen
##     einem zu kleinen Ertrag gegenueber.
func _analyze_demand_vs_capacity(sim: SimulationEngine, machines: Array[MachineInstance]) -> Array:
	var out: Array = []
	if machines.is_empty():
		return out

	# Kapazitaet der Endstufen (nur die kommen in den Absatz).
	var capacity := 0.0
	for m in machines:
		if m.spec.is_intermediate_stage():
			continue
		capacity += m.spec.capacity_units_per_year
	if capacity <= 0.0:
		return out

	# Nachfrage aus dem laufenden Geschaeft: offene Auftraege plus
	# Rahmenvertraege.
	var open_quantity := 0.0
	for order in sim.orders:
		if order.get("status", "") == "accepted":
			open_quantity += float(order.get("quantity", 0.0))
	var contracted := sim.contracted_quantity()
	var demand := open_quantity + contracted

	if demand > capacity * 1.2:
		out.append({
			"id": "demand_over_capacity",
			"severity": "warning",
			"title": "Nachfrage größer als Kapazität",
			"analysis": "Offene Auftraege und Rahmenvertraege ergeben %s Stueck Bedarf – deine Endstufen schaffen %s Stueck. Du kannst nicht alles bedienen: Der Markt sieht, dass du zu langsam bist." % [
				_format_int(demand), _format_int(capacity)
			],
			"questions": [
				"Welche Anlage erweitert die Kapazitaet am guenstigsten?",
				"Wie viel Deckungsbeitrag bringt die zusaetzliche Menge?",
			],
			"lesson": "Kapazitaetsengpaesse kosten Umsatz, den man nicht sieht: Der Auftrag geht an den Wettbewerb.",
			"action": "Pruefe deine Auslastung und vergleiche eine Erweiterungsinvestition.",
		})
	elif capacity > 0.0 and demand > 0.0 and demand < capacity * 0.5:
		out.append({
			"id": "capacity_over_demand",
			"severity": "warning",
			"title": "Kapazität größer als Nachfrage",
			"analysis": "Deine Endstufen schaffen %s Stueck im Jahr, der Markt fragt aber nur %s Stueck nach. Die Fixkosten dieser Kapazitaet stehen einem Ertrag von %s Stueck gegenueber." % [
				_format_int(capacity), _format_int(demand), _format_int(demand)
			],
			"questions": [
				"Ab welcher Menge ist die Investition rentabel?",
				"Kannst du die freie Kapazitaet mit einem anderen Produkt fuellen?",
			],
			"lesson": "Kapazitaet ist kein Ziel, sondern eine Voraussetzung. Zu viel Kapazitaet bedeutet Fixkosten ohne Deckungsbeitrag.",
			"action": "Pruefe deine Auslastung und ueberlege, eine Anlage stillzulegen.",
		})
	return out


## Gibt neue Hinweise an die UI weiter (jede Empfehlung nur einmal).
func _publish(findings: Array) -> void:
	for finding in findings:
		var id := String(finding.get("id", ""))
		if id.is_empty() or _seen.has(id):
			continue
		_seen[id] = true
		var message := {
			"id": id,
			"severity": String(finding.get("severity", "info")),
			"title": String(finding.get("title", "")),
			"analysis": String(finding.get("analysis", "")),
			"questions": finding.get("questions", []),
			"lesson": String(finding.get("lesson", "")),
			"action": String(finding.get("action", "")),
			"day": Simulation.day if Simulation != null else 0,
		}
		_messages.append(message)
		EventBus.advisor_message_added.emit(message)


## Die bisherigen Hinweise.
func get_messages() -> Array:
	return _messages


## Setzt die Analyse zurück (z. B. beim Laden eines Spielstands).
func reset() -> void:
	_messages.clear()
	_seen.clear()
	current_analysis = {}
	_cash_event_counter = 0
