extends RefCounted

## Tests des Unternehmensberaters.
##
## Der Berater analysiert den tatsaechlichen Zustand des Unternehmens
## und gibt question-basierte Hinweise. Geprueft wird:
##
##   * dass er die richtigen Probleme erkennt (Engpass, Nachfrage,
##     Kette, Liquiditaet, Auslastung),
##   * dass er keine fertigen Entscheidungen liefert, sondern Fragen
##     stellt und den Analyseweg erklaert,
##   * dass jeder Hinweis eine belegbare Zahl aus dem Betrieb nennt.
##
## Wichtig: Der Berater darf nicht raten. Jeder Hinweis muss sich auf
## den echten Simulationszustand beziehen. Deshalb wird hier eine
## echte Simulation aufgebaut und der Berater auf sie angesetzt.

## Baut eine Simulation mit einer einzelne aktiven Anlage.
static func _make_sim(
	spec: MachineSpec, instance_id: String = "anlage-1"
) -> SimulationEngine:
	var sim := SimulationEngine.new()
	sim.specs[spec.id] = spec
	var instance := MachineInstance.new(spec, instance_id)
	instance.state = MachineInstance.State.ACTIVE
	instance.commissioned_year = 1
	sim.machines[instance_id] = instance
	return sim


## Eine einfache Anlage fuer die Grundbefunde.
static func _basic_spec() -> MachineSpec:
	var spec := MachineSpec.new()
	spec.id = &"TEST"
	spec.display_name = "Testanlage"
	spec.acquisition_cost = 30_000.0
	spec.residual_value = 5_000.0
	spec.useful_life_years = 5
	spec.imputed_interest_rate = 0.08
	spec.fixed_operating_costs = 8_000.0
	spec.variable_cost_per_unit = 5.0
	spec.price_per_unit = 20.0
	spec.capacity_units_per_year = 10_000.0
	spec.material_per_unit = 0.0
	return spec


## Eine eigene Instanz des Beraters.
##
## Der Berater ist im Spiel ein Autoload. In einem statischen
## Testskript ist der Autoload-Name aber kein gueltiger Bezeichner -
## er existiert nur zur Laufzeit, nicht beim Parsen. Deshalb wird
## hier die Klasse selbst verwendet (AdvisorAgent).
##
## Der Vorteil: Die Rueckgabetypen der Analysemodule sind bekannt,
## damit die Pruefungen typisiert lesbar bleiben.
static func _advisor() -> Node:
	# Der Berater ist im Spiel ein Autoload. Ein Autoload darf
	# keinen class_name tragen - ein Klassenname, der zum Autoload
	# gehoert, fuehrt beim Import zum Fehler. Deshalb laesst sich
	# die Klasse hier nicht ueber ihren Namen erzeugen; sie wird
	# stattdessen aus der Datei geladen.
	#
	# Die Aufrufe der Analysemodule bekommen ihren Rueckgabetyp
	# deshalb ueber eine eigene Typannotation (Array) zugewiesen.
	var script: GDScript = load("res://src/advisor/advisor.gd")
	if script == null:
		print("ADVISOR-TEST: Skript nicht ladbar (load() lieferte null).")
		return null
	if not script.can_instantiate():
		print("ADVISOR-TEST: Skript geladen, aber nicht instanziierbar - vermutlich ein Kompilierfehler im Berater-Skript. Details stehen als SCRIPT ERROR in der Prozessausgabe.")
		return null
	var instance: Object = script.new()
	if instance == null:
		print("ADVISOR-TEST: new() lieferte null.")
		return null
	return instance as Node


## Findet einen Hinweis nach seiner ID.
static func _find(findings: Array, id_prefix: String) -> Dictionary:
	for f in findings:
		var finding: Dictionary = f
		if String(finding.get("id", "")).begins_with(id_prefix):
			return finding
	return {}


# ------------------------------------------------------------------

static func run(t: TestFramework) -> void:
	t.suite("Berater · Grundbefunde")
	_test_basic_findings(t)
	t.suite("Berater · Frage statt fertiger Antwort")
	_test_questions_not_answers(t)
	t.suite("Berater · Nachfrage gegen Kapazität")
	_test_demand_vs_capacity(t)
	t.suite("Berater · Produktionskette")
	_test_chain_findings(t)
	t.suite("Berater · Fahrplan mit Zielzahl")
	_test_next_steps(t)
	t.suite("Berater · Finanzierungsbefunde")
	_test_financing_findings(t)


# ------------------------------------------------------------------
# Grundbefunde
# ------------------------------------------------------------------
static func _test_basic_findings(t: TestFramework) -> void:
	var advisor := _advisor()
	t.check_true("Berater laesst sich instanziieren", advisor != null)
	if advisor == null:
		return

	# Ohne Anlage: der Berater muss sagen, dass noch nichts laeuft.
	advisor.reset()
	var empty_findings: Array = advisor._analyze_capacity([] as Array[MachineInstance])
	t.check_true(
		"Ohne Anlage wird die fehlende Produktion gemeldet",
		not _find(empty_findings, "no_machines").is_empty()
	)

	# Auslastung zu gering: der Berater muss die Kennzahl nennen.
	var spec := _basic_spec()
	var sim := _make_sim(spec)
	# Die Anlage hat noch nichts produziert: Auslastung 0 %.
	var low: Array = advisor._analyze_utilization(sim.active_machines())
	var finding := _find(low, "low_utilization")
	t.check_true("Zu geringe Auslastung wird erkannt", not finding.is_empty())
	t.check_true(
		"Der Hinweis nennt die Auslastung als Zahl",
		String(finding.get("analysis", "")).contains("0 %")
	)

	# Auslastung zu hoch: Kapazitätsgrenze.
	var full := spec.with_overrides({"capacity_units_per_year": 10_000.0})
	var sim2 := _make_sim(full)
	var instance: MachineInstance = sim2.machines["anlage-1"]
	instance.quantity_this_year = 9_800.0
	var high: Array = advisor._analyze_utilization(sim2.active_machines())
	t.check_true(
		"Kapazitätsgrenze wird erkannt",
		not _find(high, "high_utilization").is_empty()
	)

	# Liquidität: eine dünne Kasse muss gemeldet werden. Der
	# Liquiditätsgrad ist die Kasse im Verhältnis zu einem Monat
	# Fixkosten - ohne Fixkosten gibt es nichts zu decken.
	var economy := EconomyState.new()
	economy.cash = 1_000.0
	economy.equity = 50_000.0
	economy.fixed_costs_year = 24_000.0
	var liq: Array = advisor._analyze_liquidity(economy)
	t.check_true(
		"Dünne Kasse wird erkannt",
		not _find(liq, "tense_liquidity").is_empty()
	)

	# Eine ueberzogene Kasse ist der schwere Fall.
	var crisis := EconomyState.new()
	crisis.cash = -5_000.0
	crisis.equity = 50_000.0
	crisis.fixed_costs_year = 24_000.0
	var crisis_findings: Array = advisor._analyze_liquidity(crisis)
	t.check_true(
		"Überzogene Kasse wird erkannt",
		not _find(crisis_findings, "critical_liquidity").is_empty()
	)


# ------------------------------------------------------------------
# Der Berater stellt Fragen, er liefert keine fertigen Antworten
# ------------------------------------------------------------------
static func _test_questions_not_answers(t: TestFramework) -> void:
	var advisor := _advisor()
	t.check_true("Berater laesst sich instanziieren", advisor != null)
	if advisor == null:
		return
	var spec := _basic_spec()
	var sim := _make_sim(spec)

	var findings: Array = advisor._analyze_utilization(sim.active_machines())
	var finding := _find(findings, "low_utilization")
	t.check_true(
		"Jeder Hinweis stellt mindestens eine Frage",
		(finding.get("questions", []) as Array).size() >= 1
	)
	t.check_true(
		"Jeder Hinweis nennt eine Lektion",
		String(finding.get("lesson", "")) != ""
	)
	t.check_true(
		"Jeder Hinweis nennt einen konkreten Ort im Menü",
		String(finding.get("action", "")) != ""
	)
	# Die Lektion darf nicht die fertige Entscheidung nennen: sie
	# formuliert den Zusammenhang, nicht die Handlung.
	var lesson := String(finding.get("lesson", ""))
	t.check_true(
		"Die Lektion erklärt den Zusammenhang statt der Handlung",
		lesson.contains("kritische Menge") or lesson.contains("Fixkosten")
	)


# ------------------------------------------------------------------
# Nachfrage gegen Kapazität
# ------------------------------------------------------------------
static func _test_demand_vs_capacity(t: TestFramework) -> void:
	var advisor := _advisor()
	t.check_true("Berater laesst sich instanziieren", advisor != null)
	if advisor == null:
		return
	var spec := _basic_spec()

	# Nachfrage übersteigt die Kapazität deutlich.
	var sim := _make_sim(spec)
	sim.orders.append({
		"id": "gross",
		"status": "accepted",
		"quantity": 20_000.0,
		"revenue": 400_000.0,
	})
	var over: Array = advisor._analyze_demand_vs_capacity(sim, sim.active_machines())
	var finding := _find(over, "demand_over_capacity")
	t.check_true("Nachfrage über Kapazität wird erkannt", not finding.is_empty())
	# Die Zahlen werden mit Tausenderpunkt geschrieben.
	t.check_true(
		"Der Hinweis nennt Bedarf und Kapazität",
		String(finding.get("analysis", "")).contains("20.000")
		and String(finding.get("analysis", "")).contains("10.000")
	)

	# Kapazität übersteigt die Nachfrage deutlich.
	var sim2 := _make_sim(spec)
	sim2.orders.append({
		"id": "klein",
		"status": "accepted",
		"quantity": 1_000.0,
		"revenue": 20_000.0,
	})
	var under: Array = advisor._analyze_demand_vs_capacity(sim2, sim2.active_machines())
	t.check_true(
		"Kapazität über Nachfrage wird erkannt",
		not _find(under, "capacity_over_demand").is_empty()
	)

	# Passt die Nachfrage zur Kapazität, gibt es keinen Hinweis.
	var sim3 := _make_sim(spec)
	sim3.orders.append({
		"id": "passend",
		"status": "accepted",
		"quantity": 8_000.0,
		"revenue": 160_000.0,
	})
	var balanced: Array = advisor._analyze_demand_vs_capacity(sim3, sim3.active_machines())
	t.check_true(
		"Bei passender Nachfrage kein Hinweis",
		_find(balanced, "demand_over_capacity").is_empty()
		and _find(balanced, "capacity_over_demand").is_empty()
	)


# ------------------------------------------------------------------
# Produktionskette
# ------------------------------------------------------------------
static func _test_chain_findings(t: TestFramework) -> void:
	var advisor := _advisor()
	t.check_true("Berater laesst sich instanziieren", advisor != null)
	if advisor == null:
		return

	var stage1 := MachineSpec.new()
	stage1.id = &"VOR"
	stage1.display_name = "Vorstufe"
	stage1.acquisition_cost = 40_000.0
	stage1.useful_life_years = 5
	stage1.fixed_operating_costs = 8_000.0
	stage1.variable_cost_per_unit = 4.0
	stage1.price_per_unit = 21.0
	stage1.capacity_units_per_year = 36_000.0
	stage1.output_product = &"halb"
	stage1.material_per_unit = 0.0

	var stage2 := MachineSpec.new()
	stage2.id = &"END"
	stage2.display_name = "Endstufe"
	stage2.acquisition_cost = 24_000.0
	stage2.useful_life_years = 6
	stage2.fixed_operating_costs = 5_400.0
	stage2.variable_cost_per_unit = 3.0
	stage2.price_per_unit = 18.0
	stage2.capacity_units_per_year = 36_000.0
	stage2.input_product = &"halb"
	stage2.input_product_per_unit = 2.0
	stage2.material_per_unit = 0.0

	# Endstufe ohne Vorstufe: der Berater muss den fehlenden
	# Zulieferer melden.
	var sim := SimulationEngine.new()
	sim.specs[stage1.id] = stage1
	sim.specs[stage2.id] = stage2
	var only_end := MachineInstance.new(stage2, "end-1")
	only_end.state = MachineInstance.State.ACTIVE
	sim.machines["end-1"] = only_end
	var missing: Array = advisor._analyze_production_chain(sim, sim.active_machines())
	t.check_true(
		"Fehlender Zulieferer wird gemeldet",
		not _find(missing, "chain_missing_stage").is_empty()
	)

	# Beide Stufen, aber zu wenig Zwischenprodukt: kein Rueckstau.
	var sim2 := SimulationEngine.new()
	sim2.specs[stage1.id] = stage1
	sim2.specs[stage2.id] = stage2
	var producer := MachineInstance.new(stage1, "vor-1")
	producer.state = MachineInstance.State.ACTIVE
	sim2.machines["vor-1"] = producer
	var finisher := MachineInstance.new(stage2, "end-1")
	finisher.state = MachineInstance.State.ACTIVE
	sim2.machines["end-1"] = finisher
	var normal: Array = advisor._analyze_production_chain(sim2, sim2.active_machines())
	t.check_true(
		"Ohne Rueckstau kein Kettenhinweis",
		_find(normal, "chain_backlog").is_empty()
		and _find(normal, "chain_missing_stage").is_empty()
	)

	# Ueberproduktion der Vorstufe: Rueckstau im Zwischenlager.
	sim2.set_intermediate_stock(&"halb", 50_000.0)
	var backlog: Array = advisor._analyze_production_chain(sim2, sim2.active_machines())
	t.check_true(
		"Rückstau wird gemeldet",
		not _find(backlog, "chain_backlog").is_empty()
	)


# ------------------------------------------------------------------
# Der Fahrplan nennt eine Zielzahl
# ------------------------------------------------------------------
static func _test_next_steps(t: TestFramework) -> void:
	var advisor := _advisor()
	t.check_true("Berater laesst sich instanziieren", advisor != null)
	if advisor == null:
		return
	var spec := _basic_spec()

	# Auslastung zu gering: der Fahrplan nennt die Zielmenge.
	var sim := _make_sim(spec)
	var low: Array = advisor._analyze_next_steps(sim, sim.active_machines())
	var finding := _find(low, "next_step_utilization")
	t.check_true(
		"Bei geringer Auslastung nennt der Fahrplan die Auslastung",
		not finding.is_empty()
	)
	t.check_true(
		"Der Fahrplan nennt eine Zielzahl",
		String(finding.get("analysis", "")).contains("80")
	)
	t.check_true(
		"Der Fahrplan stellt eine Frage",
		(finding.get("questions", []) as Array).size() >= 1
	)

	# Auslastung passt, aber die Kasse ist zu duenn.
	var sim2 := _make_sim(spec)
	var instance: MachineInstance = sim2.machines["anlage-1"]
	instance.quantity_this_year = 9_000.0
	sim2.economy.cash = 100.0
	var reserve: Array = advisor._analyze_next_steps(sim2, sim2.active_machines())
	t.check_true(
		"Bei dünnner Kasse nennt der Fahrplan die Reserve",
		not _find(reserve, "next_step_liquidity").is_empty()
	)

	# Auslastung und Kasse passen: jetzt erst die Investition.
	var sim3 := _make_sim(spec)
	var instance3: MachineInstance = sim3.machines["anlage-1"]
	instance3.quantity_this_year = 9_000.0
	sim3.economy.cash = 500_000.0
	var invest: Array = advisor._analyze_next_steps(sim3, sim3.active_machines())
	t.check_true(
		"Bei guter Lage nennt der Fahrplan die Investition",
		not _find(invest, "next_step_investment").is_empty()
	)


# ------------------------------------------------------------------
# Finanzierungsbefunde
#
# Der Zehn-Jahres-Lauf deckte einen stillen Formatfehler auf: Ein
# "% %" statt "%%" im Befundtext liess die Formatierung an jedem
# Simulationstag scheitern - ohne dass ein Test rot wurde, weil der
# Befund nie inhaltlich geprueft wurde. Diese Tests formatieren
# beide Finanzierungsbefunde wirklich und stellen sicher, dass alle
# Platzhalter ersetzt sind.
# ------------------------------------------------------------------
static func _test_financing_findings(t: TestFramework) -> void:
	var advisor := _advisor()
	if advisor == null:
		return
	advisor.reset()

	# Fall 1: Niedrige Verschuldung + freier Kreditrahmen -> der
	# Hinweis auf ungenutzten Kreditrahmen muss sauber formatiert
	# sein (hier sass der Fehler).
	var sim := SimulationEngine.new()
	var unused: Array = advisor._analyze_financing(sim)
	var unused_finding := _find(unused, "financing_unused_capacity")
	t.check_true("Ungenutzter Kreditrahmen wird erkannt", not unused_finding.is_empty())
	var unused_text := String(unused_finding.get("analysis", ""))
	t.check_true(
		"Befundtext vollstaendig formatiert (kein %s uebrig)",
		not unused_text.contains("%s")
	)
	t.check_true(
		"Befundtext nennt den Kreditrahmen",
		unused_text.contains("€")
	)
	# Der Formatierer haengt KEIN Waehrungszeichen mehr an - das
	# macht das Template. Beide zusammen ergaeben "25.000 € €".
	t.check_true(
		"Befundtext ohne doppeltes Waehrungszeichen",
		not unused_text.contains("€ €")
	)

	# Fall 2: Hohe Verschuldung -> Leverage-Warnung, ebenfalls
	# vollstaendig formatiert.
	var sim2 := SimulationEngine.new()
	sim2.economy.debt = 60_000.0
	sim2.economy.interest_paid_year = 3_600.0
	var levered: Array = advisor._analyze_financing(sim2)
	var leverage_finding := _find(levered, "financing_high_leverage")
	t.check_true("Hohe Verschuldung wird erkannt", not leverage_finding.is_empty())
	var leverage_text := String(leverage_finding.get("analysis", ""))
	t.check_true(
		"Leverage-Befund vollstaendig formatiert",
		not leverage_text.contains("%s")
	)
	t.check_true(
		"Leverage-Befund ohne doppeltes Waehrungszeichen",
		not leverage_text.contains("€ €")
	)
