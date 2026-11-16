class_name InvestmentPanel
extends Control

## Investitionsentscheidung: der Kostenvergleich als Spielmechanik.
##
## Der Spieler wählt zwei Anlagen, sieht ihre Kostenfunktionen, verschiebt
## die geplante Produktionsmenge und erkennt daraus die kritische Menge.
## Die Entscheidung hat reale Folgen: Kapital wird gebunden, eine Lieferung
## wird ausgelöst, die Kostenstruktur des Unternehmens ändert sich.

var machine_a: MachineSpec
var machine_b: MachineSpec
var quantity: float = 5000.0

var _chart: Control
var _quantity_label: Label
var _xkrit_label: Label
var _result_label: Label
var _table: GridContainer
var _slider: HSlider
var _order_buttons: Array[Button] = []
var _mode: String = "COST"


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.055, 0.063, 0.075, 0.97)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)

	# --- Kopf ---
	var header := HBoxContainer.new()
	var title := Label.new()
	title.text = "INVESTITIONSENTSCHEIDUNG"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.29, 0.53, 0.64))
	header.add_child(title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var close := Button.new()
	close.text = "✕ Schließen"
	close.pressed.connect(func(): queue_free())
	header.add_child(close)
	root.add_child(header)

	# --- Anlagenwahl ---
	var picker := HBoxContainer.new()
	picker.add_theme_constant_override("separation", 12)
	picker.add_child(_label("Anlage A:"))
	var option_a := OptionButton.new()
	for spec in MachineCatalog.all():
		option_a.add_item(spec.display_name)
	option_a.item_selected.connect(func(i): _select_a(i))
	picker.add_child(option_a)
	picker.add_child(_label("Anlage B:"))
	var option_b := OptionButton.new()
	for spec in MachineCatalog.all():
		option_b.add_item(spec.display_name)
	option_b.item_selected.connect(func(i): _select_b(i))
	picker.add_child(option_b)

	var mode_button := Button.new()
	mode_button.text = "Modus: Kostenvergleich"
	mode_button.pressed.connect(func():
		_mode = "PROFIT" if _mode == "COST" else "COST"
		mode_button.text = "Modus: Gewinnvergleich" if _mode == "PROFIT" else "Modus: Kostenvergleich"
		_refresh()
	)
	picker.add_child(mode_button)
	root.add_child(picker)

	# --- Chart ---
	_chart = Control.new()
	_chart.custom_minimum_size = Vector2(0, 260)
	_chart.draw.connect(_draw_chart)
	root.add_child(_chart)

	# --- Mengenregler ---
	var slider_row := HBoxContainer.new()
	slider_row.add_theme_constant_override("separation", 14)
	slider_row.add_child(_label("Geplante Produktionsmenge:"))
	_slider = HSlider.new()
	_slider.custom_minimum_size = Vector2(420, 0)
	_slider.min_value = 100.0
	_slider.max_value = 20000.0
	_slider.step = 100.0
	_slider.value = quantity
	_slider.value_changed.connect(func(v):
		quantity = v
		_refresh()
	)
	slider_row.add_child(_slider)
	_quantity_label = Label.new()
	_quantity_label.custom_minimum_size = Vector2(160, 0)
	slider_row.add_child(_quantity_label)
	root.add_child(slider_row)

	# --- Ergebnis ---
	_xkrit_label = Label.new()
	_xkrit_label.add_theme_font_size_override("font_size", 16)
	root.add_child(_xkrit_label)

	_result_label = Label.new()
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_label.add_theme_font_size_override("font_size", 13)
	_result_label.add_theme_color_override("font_color", Color(0.72, 0.77, 0.84))
	root.add_child(_result_label)

	# --- Entscheidungstabelle ---
	_table = GridContainer.new()
	_table.columns = 5
	root.add_child(_table)

	# --- Bestellbuttons ---
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	for i in range(2):
		var button := Button.new()
		button.custom_minimum_size = Vector2(240, 40)
		button.pressed.connect(_on_order.bind(i))
		buttons.add_child(button)
		_order_buttons.append(button)
	root.add_child(buttons)

	# Startzustand
	machine_a = MachineCatalog.car_a()
	machine_b = MachineCatalog.car_b()
	_refresh()


func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	return label


func _select_a(index: int) -> void:
	var specs := MachineCatalog.all()
	if index >= 0 and index < specs.size():
		machine_a = specs[index]
		_refresh()


func _select_b(index: int) -> void:
	var specs := MachineCatalog.all()
	if index >= 0 and index < specs.size():
		machine_b = specs[index]
		_refresh()


# ==================================================================
# Auswertung
# ==================================================================

func _refresh() -> void:
	# Die geplante Menge fliesst in die Empfehlung ein: erst dadurch
	# kann die Rechnung sagen, welche Anlage in dieser Lage richtig ist.
	var result := CostComparison.compare(machine_a, machine_b, _mode, 60, quantity)
	_quantity_label.text = "%s Stück/Jahr" % _num(quantity)

	if result.valid:
		_xkrit_label.text = "Kritische Menge: %s Stück pro Jahr" % _num(result.x_critical)
		_xkrit_label.add_theme_color_override("font_color", Color(0.90, 0.88, 0.84))
		_result_label.text = result.recommendation
	else:
		_xkrit_label.text = "Kritische Menge nicht bestimmbar"
		_xkrit_label.add_theme_color_override("font_color", Color(0.72, 0.77, 0.84))
		_result_label.text = result.recommendation

	_fill_table()
	_update_order_buttons(result)
	_chart.queue_redraw()


func _fill_table() -> void:
	for child in _table.get_children():
		child.queue_free()

	var rows := CostComparison.evaluate_at(machine_a, machine_b, quantity)
	var headers := ["", "Anlage A", "Anlage B"]
	for header in headers:
		var label := Label.new()
		label.text = header
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color(0.42, 0.47, 0.54))
		_table.add_child(label)

	var entries := [
		["Anschaffung", ["acq", "€"]],
		["Fixkosten p.a.", ["fixed", "€"]],
		["davon Abschreibung", ["dep", "€"]],
		["davon kalk. Zinsen", ["imp", "€"]],
		["Variable Stückkosten", ["kvar", "€"]],
		["Umsatz", ["rev", "€"]],
		["Gewinn", ["profit", "€"]],
		["Cashflow", ["cf", "€"]],
		["Break-even", ["be", "Stück"]],
		["Amortisation", ["pay", "Jahre"]],
		["Barwert (NPV)", ["npv", "€"]],
		["Kapitalwert", ["kw", "€"]],
		["Rentabilitätsindex", ["pi", ""]],
		["Interne Rendite", ["irr", "%"]],
	]

	for entry in entries:
		var label := Label.new()
		label.text = String(entry[0])
		label.add_theme_font_size_override("font_size", 12)
		_table.add_child(label)

		for row in rows:
			var value := _value_for(row, String(entry[1][0]))
			var value_label := Label.new()
			value_label.text = value
			value_label.add_theme_font_size_override("font_size", 13)
			# Guenstige Werte gruen, ungünstige rot. Das gilt fuer
			# Gewinn, Barwert und Kapitalwert.
			var sign_key := String(entry[1][0])
			if sign_key in ["profit", "npv", "kw"]:
				var raw := float(row.get(sign_key, 0.0))
				value_label.add_theme_color_override("font_color",
					Color(0.45, 0.78, 0.58) if raw >= 0.0 else Color(0.81, 0.37, 0.37))
			_table.add_child(value_label)


func _value_for(row: Dictionary, key: String) -> String:
	match key:
		"acq":
			return _money(row.get("acquisition", 0.0))
		"fixed":
			return _money(row.get("fixed_costs", 0.0))
		"dep":
			return _money(row.get("depreciation", 0.0))
		"imp":
			return _money(row.get("imputed_interest", 0.0))
		"kvar":
			return _money(row.get("variable_costs", 0.0))
		"rev":
			return _money(row.get("revenue", 0.0))
		"profit":
			return _money(row.get("profit", 0.0))
		"cf":
			return _money(row.get("cashflow", 0.0))
		"be":
			var be := float(row.get("break_even", -1.0))
			return _num(be) if be > 0.0 else "–"
		"pay":
			var pay := float(row.get("payback", INF))
			return _num(pay) if is_finite(pay) else "–"
		"npv":
			return _money(row.get("npv", 0.0))
		"kw":
			return _money(row.get("capital_value", 0.0))
		"pi":
			return "%.2f" % float(row.get("profitability_index", 0.0))
		"irr":
			var irr := float(row.get("irr", -1.0))
			return "%.1f %%" % (irr * 100.0) if irr >= 0.0 else "–"
	return "–"


func _update_order_buttons(result: CostComparison.Result) -> void:
	if _order_buttons.size() < 2:
		return
	# Der günstigere Anlagen-Typ wird hervorgehoben, aber der Spieler
	# entscheidet selbst – der Berater gibt nur die Begründung.
	var spec_a := machine_a
	var spec_b := machine_b
	_order_buttons[0].text = "%s bestellen\n%s" % [spec_a.display_name, _money(spec_a.acquisition_cost)]
	_order_buttons[1].text = "%s bestellen\n%s" % [spec_b.display_name, _money(spec_b.acquisition_cost)]
	_order_buttons[0].tooltip = "Anschaffung %s · Lieferzeit %d Tage" % [_money(spec_a.acquisition_cost), spec_a.delivery_days]
	_order_buttons[1].tooltip = "Anschaffung %s · Lieferzeit %d Tage" % [_money(spec_b.acquisition_cost), spec_b.delivery_days]


func _on_order(index: int) -> void:
	var spec := machine_a if index == 0 else machine_b
	var result := Simulation.order_machine(spec.id)
	if bool(result.get("ok", false)):
		queue_free()
	else:
		_result_label.text = String(result.get("error", ""))
		_result_label.add_theme_color_override("font_color", Color(0.81, 0.37, 0.37))


# ==================================================================
# Grafik
# ==================================================================

func _draw_chart() -> void:
	var size := _chart.size
	if size.x < 10.0 or size.y < 10.0:
		return

	var result := CostComparison.compare(machine_a, machine_b, _mode, 60, quantity)
	var pad_left := 70.0
	var pad_bottom := 34.0
	var pad_top := 14.0
	var pad_right := 16.0
	var plot_w := size.x - pad_left - pad_right
	var plot_h := size.y - pad_top - pad_bottom
	if plot_w <= 0.0 or plot_h <= 0.0:
		return

	# Achsen
	_chart.draw_rect(Rect2(Vector2(pad_left, pad_top), Vector2(plot_w, plot_h)), Color(0.043, 0.051, 0.063), true)
	_chart.draw_rect(Rect2(Vector2(pad_left, pad_top), Vector2(plot_w, plot_h)), Color(1, 1, 1, 0.10), false, 1.0)

	# Maximalwert bestimmen
	var max_cost := 0.0
	var max_x := 1.0
	for point in result.costs_a:
		max_cost = maxf(max_cost, float(point["a"]))
		max_cost = maxf(max_cost, float(point["b"]))
		max_x = maxf(max_x, float(point["x"]))
	if max_cost <= 0.0:
		return

	# Gitter
	for i in range(5):
		var gy := pad_top + plot_h * float(i) / 4.0
		_chart.draw_line(Vector2(pad_left, gy), Vector2(pad_left + plot_w, gy), Color(1, 1, 1, 0.05), 1.0)
		var y_value := max_cost * (1.0 - float(i) / 4.0)
		var y_label := _num(y_value)
		_chart.draw_string(ThemeDB.fallback_font, Vector2(6.0, gy + 4.0), y_label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.45, 0.50, 0.57))
	for i in range(6):
		var gx := pad_left + plot_w * float(i) / 5.0
		_chart.draw_line(Vector2(gx, pad_top), Vector2(gx, pad_top + plot_h), Color(1, 1, 1, 0.05), 1.0)
		var x_value := max_x * float(i) / 5.0
		_chart.draw_string(ThemeDB.fallback_font, Vector2(gx - 16.0, size.y - 12.0), _num(x_value),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.45, 0.50, 0.57))

	# Kostenkurven
	_draw_curve(result.costs_a, "a", pad_left, pad_top, plot_w, plot_h, max_x, max_cost, Color(0.38, 0.66, 0.74))
	_draw_curve(result.costs_a, "b", pad_left, pad_top, plot_w, plot_h, max_x, max_cost, Color(0.80, 0.56, 0.30))

	# Kritische Menge
	if result.valid and result.x_critical <= max_x:
		var cx := pad_left + plot_w * (result.x_critical / max_x)
		_chart.draw_line(Vector2(cx, pad_top), Vector2(cx, pad_top + plot_h), Color(0.90, 0.88, 0.84, 0.55), 1.5, true)
		_chart.draw_string(ThemeDB.fallback_font, Vector2(cx + 4.0, pad_top + 14.0),
			"x_krit = %s" % _num(result.x_critical), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.90, 0.88, 0.84))

	# Aktuelle Menge
	var qx := pad_left + plot_w * clampf(quantity / max_x, 0.0, 1.0)
	_chart.draw_line(Vector2(qx, pad_top), Vector2(qx, pad_top + plot_h), Color(0.45, 0.78, 0.58, 0.7), 1.5, true)
	_chart.draw_string(ThemeDB.fallback_font, Vector2(qx + 4.0, pad_top + plot_h - 6.0),
		"deine Menge", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.45, 0.78, 0.58))


func _draw_curve(points: Array, key: String, ox: float, oy: float, w: float, h: float, max_x: float, max_cost: float, color: Color) -> void:
	var prev := Vector2.ZERO
	var first := true
	for point in points:
		var x := ox + w * clampf(float(point["x"]) / max_x, 0.0, 1.0)
		var y := oy + h * (1.0 - clampf(float(point[key]) / max_cost, 0.0, 1.0))
		var current := Vector2(x, y)
		if not first:
			_chart.draw_line(prev, current, color, 2.0, true)
		prev = current
		first = false


# ==================================================================
# Formatierung
# ==================================================================

func _num(value: float) -> String:
	return String.num(value, 0).replace(".", ",")


func _money(value: float) -> String:
	return String.num(value, 0).replace(".", ",") + " €"
