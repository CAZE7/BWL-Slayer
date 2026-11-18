class_name CompanyLab
extends RefCounted

## Der Betriebs-Lab: BWL-Aufgaben aus dem laufenden Betrieb.
##
## Das BWL-Labor der Lernwelten arbeitet mit festen Beispielwerten
## aus dem geschuetzten Lerninhalt. Der Betriebs-Lab schliesst die
## Luecke: Hier entstehen die Aufgaben aus den ECHTEN Zahlen des
## Spielbetriebs.
##
## Der Spieler rechnet also mit seiner eigenen Firma: seinem
## Umsatz, seinen Fixkosten, seinem Kapitalbedarf, seinem
## Deckungsbeitrag. Die Loesung wird aus derselben Quelle berechnet
## wie die Aufgabe – deshalb ist sie immer richtig.
##
## Der Betriebs-Lab ersetzt den Lerninhalt NICHT. Er ergaenzt ihn:
## Die Welten erklaeren die Konzepte, der Betriebs-Lab wendet sie auf
## das eigene Unternehmen an.

## Ein erzeugtes Aufgabenfeld mit Loesung.
class Field extends RefCounted:
	var key: String = ""
	var label: String = ""
	var ans: float = 0.0
	var unit: String = ""
	var tol: float = 0.01

	func _init(p_key: String, p_label: String, p_ans: float, p_unit: String = "", p_tol: float = 0.01) -> void:
		key = p_key
		label = p_label
		ans = p_ans
		unit = p_unit
		tol = p_tol


## Eine erzeugte Betriebsaufgabe.
class Task extends RefCounted:
	var id: String = ""
	var topic: String = ""
	var prompt: String = ""
	var given: String = ""
	var fields: Array = []
	var solution: String = ""
	var hint: String = ""


## Die Betriebsdaten, aus denen die Aufgaben entstehen.
##
## Die Werte werden einmal aus der Simulation gelesen und dann
## verwendet. So ist die Aufgabe in sich konsistent: Wenn der
## Spieler waehrend der Bearbeitung nichts aendert, passt die
## Loesung.
class Snapshot extends RefCounted:
	var revenue: float = 0.0
	var variable_costs: float = 0.0
	var fixed_costs: float = 0.0
	var depreciation: float = 0.0
	var imputed_interest: float = 0.0
	var interest_paid: float = 0.0
	var profit: float = 0.0
	var cash: float = 0.0
	var equity: float = 0.0
	var debt: float = 0.0
	var fixed_assets: float = 0.0
	var inventory: float = 0.0
	var receivables: float = 0.0
	var quantity: float = 0.0
	var capacity: float = 0.0
	var price_per_unit: float = 0.0
	var variable_cost_per_unit: float = 0.0
	var contribution_per_unit: float = 0.0
	var material_coverage_days: float = 0.0
	var material_daily_need: float = 0.0
	var material_stock_kg: float = 0.0
	var day: int = 0
	var year: int = 0

	## Der Deckungsbeitrag insgesamt (Stueck × Stueckdeckungsbeitrag).
	func total_contribution() -> float:
		return quantity * contribution_per_unit


## Liest die aktuellen Betriebsdaten aus der Simulation.
static func snapshot(sim: Node) -> Snapshot:
	var s := Snapshot.new()
	if sim == null:
		return s

	var economy: EconomyState = sim.economy
	s.revenue = economy.revenue_current_year
	# Die laufenden Jahresfixkosten der betriebsbereiten Anlagen.
	# economy.fixed_costs_year wird erst beim Jahresabschluss
	# gesetzt - der Lab fragt aber den Betrieb von JETZT ab.
	s.fixed_costs = sim.monthly_fixed_costs() * 12.0
	s.depreciation = economy.depreciation_year
	s.imputed_interest = economy.imputed_interest_year
	s.interest_paid = economy.interest_paid_year
	s.profit = economy.operating_result()
	s.cash = economy.cash
	s.equity = economy.equity
	s.debt = economy.debt
	s.fixed_assets = economy.fixed_assets
	s.inventory = economy.inventory_value
	s.receivables = economy.receivables
	s.day = int(sim.day)
	s.year = int(sim.year)

	# Die Maschinendaten: der gewichtete Durchschnitt des Werks.
	var capacity := 0.0
	var weighted_price := 0.0
	var weighted_variable := 0.0
	var weighted_contribution := 0.0
	var machines: Array[MachineInstance] = sim.active_machines()
	for m in machines:
		var cap := m.spec.capacity_units_per_year
		capacity += cap
		weighted_price += m.spec.price_per_unit * cap
		weighted_variable += m.spec.full_variable_cost_per_unit() * cap
		# Der volle Deckungsbeitrag inkl. Material: der Lab rechnet
		# mit denselben voll beladenen Stueckkosten wie
		# variable_cost_per_unit eine Zeile darueber. Ohne Material
		# waere der Deckungsbeitrag geschoent.
		weighted_contribution += m.spec.full_contribution_margin_per_unit() * cap
	s.capacity = capacity
	if capacity > 0.0:
		s.price_per_unit = weighted_price / capacity
		s.variable_cost_per_unit = weighted_variable / capacity
		s.contribution_per_unit = weighted_contribution / capacity
	s.quantity = 0.0
	for m in machines:
		s.quantity += m.quantity_this_year

	s.material_daily_need = sim.daily_material_need()
	s.material_coverage_days = sim.material_coverage_days()
	s.material_stock_kg = sim.total_material_stock()
	return s


## Erzeugt die Betriebsaufgaben aus den aktuellen Daten.
##
## Es werden nur Aufgaben erzeugt, deren Zahlen im Betrieb auch
## vorhanden sind. Ein leeres Werk erzeugt keine Aufgaben – dann
## waere der Betriebs-Lab leer.
static func build_tasks(sim: Node) -> Array:
	var s := snapshot(sim)
	var tasks: Array = []
	if s.capacity <= 0.0:
		return tasks

	tasks.append(_task_contribution(s))
	tasks.append(_task_break_even(s))
	tasks.append(_task_total_costs(s))
	tasks.append(_task_profit(s))
	tasks.append(_task_roi(s))
	tasks.append(_task_balance(s))
	tasks.append(_task_capital_need(s))
	tasks.append(_task_material_cover(s))
	return tasks


## Der Deckungsbeitrag: Erloes minus variable Kosten.
static func _task_contribution(s: Snapshot) -> Task:
	var t := Task.new()
	t.id = "betrieb-deckungsbeitrag"
	t.topic = "Deckungsbeitrag"
	t.prompt = (
		"<b>Dein Deckungsbeitrag.</b> Dein Werk hat %s Stück produziert. "
		+ "Der durchschnittliche Preis je Stück beträgt %s €, die variablen "
		+ "Kosten je Stück %s €."
	) % [
		_format_int(s.quantity),
		_format_eur(s.price_per_unit),
		_format_eur(s.variable_cost_per_unit),
	]
	t.given = "Deckungsbeitrag = Stück × (Preis − variable Stückkosten)"
	t.hint = "Der Deckungsbeitrag ist das, was zur Deckung der Fixkosten bleibt."
	t.fields = [
		Field.new(
			"db", "Deckungsbeitrag je Stück", s.contribution_per_unit, "€", 0.05
		),
		Field.new(
			"dbt", "Deckungsbeitrag insgesamt",
			s.quantity * s.contribution_per_unit, "€", 1.0
		),
	]
	t.solution = (
		"Der Deckungsbeitrag je Stück ist %s − %s = %s €. Insgesamt sind das "
		% [
			_format_eur(s.price_per_unit),
			_format_eur(s.variable_cost_per_unit),
			_format_eur(s.contribution_per_unit),
		]
		+ "%s €. Davon müssen die Fixkosten von %s € gedeckt werden."
	) % [
		_format_eur(s.quantity * s.contribution_per_unit),
		_format_eur(s.fixed_costs),
	]
	return t


## Die Break-even-Menge.
static func _task_break_even(s: Snapshot) -> Task:
	var t := Task.new()
	t.id = "betrieb-break-even"
	t.topic = "Break-even"
	var break_even := 0.0
	if s.contribution_per_unit > 0.0:
		break_even = s.fixed_costs / s.contribution_per_unit
	t.prompt = (
		"<b>Deine Break-even-Menge.</b> Deine Fixkosten betragen %s € p.a., "
		+ "der Deckungsbeitrag je Stück %s €."
	) % [_format_eur(s.fixed_costs), _format_eur(s.contribution_per_unit)]
	t.given = "Break-even-Menge = Fixkosten ÷ Deckungsbeitrag je Stück"
	t.hint = "Unterhalb dieser Menge arbeitest du im Verlust."
	t.fields = [
		Field.new("be", "Break-even-Menge", break_even, "Stück", 1.0),
	]
	t.solution = (
		"%s € ÷ %s € = %s Stück. Unterhalb dieser Menge kannst du die "
		% [
			_format_eur(s.fixed_costs),
			_format_eur(s.contribution_per_unit),
			_format_int(break_even),
		]
		+ "Fixkosten nicht decken."
	)
	return t


## Die Gesamtkostenfunktion bei der aktuellen Menge.
static func _task_total_costs(s: Snapshot) -> Task:
	var t := Task.new()
	t.id = "betrieb-gesamtkosten"
	t.topic = "Kostenfunktion"
	var variable := s.quantity * s.variable_cost_per_unit
	var total := variable + s.fixed_costs
	t.prompt = (
		"<b>Deine Gesamtkosten.</b> Bei %s Stück Produktion: variable "
		+ "Stückkosten %s €, Fixkosten %s €, Abschreibung %s €, "
		+ "kalkulatorische Zinsen %s €."
	) % [
		_format_int(s.quantity),
		_format_eur(s.variable_cost_per_unit),
		_format_eur(s.fixed_costs),
		_format_eur(s.depreciation),
		_format_eur(s.imputed_interest),
	]
	t.given = (
		"K_fix = Fixkosten + Abschreibung + kalkulatorische Zinsen; "
		+ "K(x) = variable Stückkosten × x + K_fix"
	)
	t.hint = "Die kalkulatorischen Zinsen gehören zu den Fixkosten, sind aber nicht zahlungswirksam."
	t.fields = [
		Field.new(
			"kfix", "Fixkostenblock",
			s.fixed_costs + s.depreciation + s.imputed_interest, "€", 1.0
		),
		Field.new("kg", "Gesamtkosten", total, "€", 1.0),
	]
	t.solution = (
		"Der Fixkostenblock ist %s + %s + %s = %s €. Die Gesamtkosten sind "
		% [
			_format_eur(s.fixed_costs),
			_format_eur(s.depreciation),
			_format_eur(s.imputed_interest),
			_format_eur(s.fixed_costs + s.depreciation + s.imputed_interest),
		]
		+ "%s € × %s Stück + %s € = %s €."
	) % [
		_format_eur(s.variable_cost_per_unit),
		_format_int(s.quantity),
		_format_eur(s.fixed_costs + s.depreciation + s.imputed_interest),
		_format_eur(total),
	]
	return t


## Das Betriebsergebnis.
static func _task_profit(s: Snapshot) -> Task:
	var t := Task.new()
	t.id = "betrieb-ergebnis"
	t.topic = "Betriebsergebnis"
	t.prompt = (
		"<b>Dein Betriebsergebnis.</b> Umsatz %s €, variable Kosten %s €, "
		+ "Fixkosten %s €, Abschreibung %s €, kalkulatorische Zinsen %s €, "
		+ "Zinsaufwand Fremdkapital %s €."
	) % [
		_format_eur(s.revenue),
		_format_eur(s.quantity * s.variable_cost_per_unit),
		_format_eur(s.fixed_costs),
		_format_eur(s.depreciation),
		_format_eur(s.imputed_interest),
		_format_eur(s.interest_paid),
	]
	t.given = (
		"Betriebsergebnis = Umsatz − variable Kosten − Fixkosten "
		+ "− Abschreibung − kalkulatorische Zinsen − Zinsaufwand"
	)
	t.hint = "Die Abschreibung ist ein Aufwand, aber keine Zahlung."
	t.fields = [
		Field.new("ergebnis", "Betriebsergebnis", s.profit, "€", 1.0),
	]
	t.solution = (
		"Das Betriebsergebnis beträgt %s €. Davon gehen %s € an "
		% [_format_eur(s.profit), _format_eur(s.depreciation)]
		+ "Abschreibung ab, die nicht zahlungswirksam ist."
	)
	return t


## Die Eigenkapitalrendite.
static func _task_roi(s: Snapshot) -> Task:
	var t := Task.new()
	t.id = "betrieb-ekr"
	t.topic = "Eigenkapitalrendite"
	var equity := s.equity
	var roi := 0.0
	if equity > 0.0:
		roi = s.profit / equity
	t.prompt = (
		"<b>Deine Eigenkapitalrendite.</b> Betriebsergebnis %s €, "
		+ "Eigenkapital %s €."
	) % [_format_eur(s.profit), _format_eur(equity)]
	t.given = "Eigenkapitalrendite = Betriebsergebnis ÷ Eigenkapital"
	t.hint = "Je größer das Eigenkapital, desto kleiner die Rendite."
	t.fields = [
		Field.new("ekr", "Eigenkapitalrendite", roi * 100.0, "%", 0.1),
	]
	# WICHTIG: nur EINMAL formatieren. Eine zweite %-Runde ueber den
	# bereits formatierten Text wuerde am entstandenen literalen
	# Prozentzeichen ("... = 12,3 %.") mit einem Laufzeitfehler
	# scheitern und den Text unformatiert lassen.
	t.solution = (
		"%s € ÷ %s € = %.1f %%. Das bedeutet: Auf jeden Euro Eigenkapital "
		+ "entstehen %.1f Cent Gewinn."
	) % [_format_eur(s.profit), _format_eur(equity), roi * 100.0, roi * 100.0]
	return t


## Der Bilanzcheck: Aktiva gegen Passiva.
static func _task_balance(s: Snapshot) -> Task:
	var t := Task.new()
	t.id = "betrieb-bilanz"
	t.topic = "Bilanz"
	var assets := s.fixed_assets + s.cash + s.inventory + s.receivables
	var liabilities := s.equity + s.debt
	t.prompt = (
		"<b>Deine Bilanz.</b> Anlagevermögen %s €, Kasse %s €, "
		+ "Lagerbestand %s €, Forderungen %s €. Eigenkapital %s €, "
		+ "Fremdkapital %s €."
	) % [
		_format_eur(s.fixed_assets),
		_format_eur(s.cash),
		_format_eur(s.inventory),
		_format_eur(s.receivables),
		_format_eur(s.equity),
		_format_eur(s.debt),
	]
	t.given = "Aktiva = Anlagevermögen + Kasse + Lagerbestand + Forderungen"
	t.hint = "Die Bilanz muss aufgehen. Sonst stimmt eine Buchung nicht."
	t.fields = [
		Field.new("aktiva", "Summe Aktiva", assets, "€", 1.0),
		Field.new("passiva", "Summe Passiva", liabilities, "€", 1.0),
	]
	t.solution = (
		"Die Aktiva summe sich auf %s €, die Passiva auf %s €. Die Bilanz "
		% [_format_eur(assets), _format_eur(liabilities)]
		+ "geht auf."
	)
	return t


## Der Kapitalbedarf aus der Kapitalbindungsdauer.
##
## Die Kapitalbindungsdauer ergibt sich aus dem Materialvorlauf, der
## Produktionszeit, der Lagerzeit und dem Zahlungsziel. Mit dem
## Tagesbedarf ergibt sich der Kapitalbedarf.
static func _task_capital_need(s: Snapshot) -> Task:
	var t := Task.new()
	t.id = "betrieb-kapitalbedarf"
	t.topic = "Kapitalbedarf"
	var cover := s.material_coverage_days
	var daily_costs := 0.0
	if s.capacity > 0.0:
		daily_costs = (
			s.variable_cost_per_unit * s.capacity / 360.0
			+ s.fixed_costs / 360.0
		)
	# Die Kapitalbindungsdauer: Materialvorlauf plus ein halbes Jahr
	# Produktions- und Lagerzeit plus das Zahlungsziel.
	var binding_days := 0.0
	if is_finite(cover):
		binding_days = minf(cover, 60.0) + 90.0 + 30.0
	var need := binding_days * daily_costs
	t.prompt = (
		"<b>Dein Kapitalbedarf.</b> Dein Material reicht %d Tage. "
		+ "Produktions- und Lagerzeit: 90 Tage. Zahlungsziel der Kunden: "
		+ "30 Tage. Deine täglichen Kosten betragen %s €."
	) % [
		int(cover) if is_finite(cover) else 0,
		_format_eur(daily_costs),
	]
	t.given = "Kapitalbedarf = Kapitalbindungsdauer × Tageskosten"
	t.hint = (
		"Je länger das Kapital gebunden ist, desto mehr Kapital brauchst du."
	)
	t.fields = [
		Field.new(
			"bindung", "Kapitalbindungsdauer", binding_days, "Tage", 1.0
		),
		Field.new("bedarf", "Kapitalbedarf", need, "€", 10.0),
	]
	t.solution = (
		"Die Kapitalbindungsdauer ist %d Tage (Materialvorlauf + Produktion "
		% int(binding_days)
		+ "und Lager + Zahlungsziel). Bei %s € Tageskosten ergibt das "
	) % _format_eur(daily_costs) + "einen Kapitalbedarf von %s €." % _format_eur(need)
	return t


## Die Materialreichweite: Wie lange reicht der Bestand?
static func _task_material_cover(s: Snapshot) -> Task:
	var t := Task.new()
	t.id = "betrieb-materialreichweite"
	t.topic = "Materialreichweite"
	var cover := s.material_coverage_days
	t.prompt = (
		"<b>Deine Materialreichweite.</b> Dein Tagesbedarf beträgt %s kg, "
		+ "dein Bestand %s kg."
	) % [
		_format_kg(s.material_daily_need),
		_format_kg(s.material_stock_kg),
	]
	t.given = "Reichweite = Bestand ÷ Tagesbedarf"
	t.hint = (
		"Die Lieferzeit brauchst du zum Vergleich: Der Bestand muss sie "
		+ "überbrücken."
	)
	t.fields = [
		Field.new(
			"reichweite", "Reichweite", cover if is_finite(cover) else 0.0,
			"Tage", 1.0
		),
	]
	t.solution = (
		"Der Bestand reicht %d Tage. Die Lieferzeit beträgt %d Tage – %s."
		% [
			int(cover) if is_finite(cover) else 0,
			5,
			"der Bestand reicht" if cover >= 5.0 else "der Bestand reicht NICHT",
		]
	)
	return t


## Formatiert eine Ganzzahl mit Tausenderpunkt.
static func _format_int(value: float) -> String:
	var negative := value < 0.0
	var text := "%.0f" % absf(value)
	var grouped := ""
	var count := 0
	for i in range(text.length() - 1, -1, -1):
		grouped = text[i] + grouped
		count += 1
		if count % 3 == 0 and i > 0:
			grouped = "." + grouped
	return ("-" if negative else "") + grouped


## Formatiert einen Geldbetrag.
static func _format_eur(value: float) -> String:
	return "%s €" % _format_int(value)


## Formatiert eine Kilogramm-Menge.
static func _format_kg(value: float) -> String:
	return "%s kg" % _format_int(value)
