extends Node

## Der Unternehmensberater.
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
	var sim := Simulation
	if sim == null:
		return
	var quantity := float(order.get("quantity", 0.0))
	var revenue := float(order.get("revenue", 0.0))
	var margin := 0.0
	var machines: Array[MachineInstance] = sim.active_machines()
	for m in machines:
		margin += m.spec.contribution_margin_per_unit() * minf(
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
	var sim := Simulation
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
	var sim := Simulation
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
	# Groessere Zahlungen sind erfahrungsgemaess die interessanten.
	if absf(delta) < 5000.0:
		return
	var sim := Simulation
	if sim == null:
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
	var sim := Simulation
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
	var sim := Simulation
	var utilization := sim.current_utilization()

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
	var sim := Simulation
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
		var npv := m.net_present_value(0.08)
		if npv < 0.0:
			out.append({
				"id": "negative_npv_%s" % m.instance_id,
				"severity": "warning",
				"title": "%s: Kapitalwert negativ" % m.spec.display_name,
				"analysis": "Bei 8 %% Diskontsatz beträgt der Kapitalwert dieser Anlage %s €. Der Kapitaleinsatz ist nicht gerechtfertigt." % BWLEngine.format_eur(npv),
				"questions": [
					"Bei welcher Menge wäre die Anlage rentabel?",
					"Wie hoch müsste der Verkaufspreis sein, damit der Kapitalwert positiv wird?",
				],
				"lesson": "Der Kapitalwert ist die entscheidende Entscheidungsgröße: KW > 0 bedeutet Wertschöpfung.",
				"action": "Öffne das Investitionsmodul und variiere die Menge.",
			})
	return out


## Finanzierung: Leverage, Zinsbelastung und Kreditrahmen.
##
## Der Berater zeigt die Konsequenz der Kapitalstruktur, nicht nur die
## Zahlen. Er stellt die Fragen, die der Spieler beantworten muss:
## Wieviel eigenes Kapital steckt im Unternehmen, und wie teuer wird
## das Fremdkapital?
func _analyze_financing(sim: Node) -> Array:
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
func _analyze_orders(sim: Node) -> Array:
	var out: Array = []
	for order in sim.orders:
		if String(order.get("status", "")) != "accepted":
			continue
		var quantity := float(order.get("quantity", 0.0))
		var revenue := float(order.get("revenue", 0.0))
		var price := revenue / quantity if quantity > 0.0 else 0.0
		var db := 0.0
		for m in sim.active_machines():
			db = m.spec.contribution_margin_per_unit()
			break
		if db > 0.0 and price < db:
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
func _analyze_lost_orders(sim: Node) -> Array:
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
func _analyze_deliveries(sim: Node) -> Array:
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
func _analyze_capital_binding(sim: Node, machines: Array[MachineInstance]) -> Array:
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
