extends Control

## Einstiegspunkt des Spiels.
##
## Aufbau:
##   - linke Navigationsleiste
##   - zentrale 3D-Ansicht des Betriebsgeländes (Hauptfläche)
##   - obere Unternehmensleiste (Liquidität, Umsatz, Kosten, Ergebnis)
##   - rechte Seitenleiste (kontextbezogene Informationen, Berater)
##   - untere Zeitleiste (Tag, Geschwindigkeit, Pause)


## Die Farbpalette der Oberfläche.
##
## Anthrazit, Graphit, Stahlgrau und Off-White als Grundtoene. Blau
## ist der einzige Akzent fuer Auswahl und aktive Elemente. Grün
## markiert positive Zustaende, Orange und Rot ausschliesslich
## Warnungen. Gold, Neon und Farbverlaeufe gibt es nicht – die
## Oberflaeche soll wie ein Unternehmenssystem aussehen, nicht wie
## ein Arcade-Spiel.
const UI := {
	"background": Color(0.055, 0.063, 0.075),
	"surface": Color(0.086, 0.098, 0.114),
	"surface_alt": Color(0.110, 0.125, 0.145),
	"border": Color(0.180, 0.200, 0.225),
	"text": Color(0.880, 0.900, 0.920),
	"text_muted": Color(0.520, 0.560, 0.610),
	"text_faint": Color(0.380, 0.420, 0.465),
	"accent": Color(0.290, 0.530, 0.640),
	"accent_soft": Color(0.290, 0.530, 0.640, 0.16),
	"positive": Color(0.280, 0.580, 0.400),
	"warning": Color(0.760, 0.480, 0.180),
	"danger": Color(0.720, 0.330, 0.310),
}


const NAV_ITEMS := [
	{"id": "production", "label": "Produktion", "icon": "🏭"},
	{"id": "logistics", "label": "Logistik", "icon": "🚚"},
	{"id": "storage", "label": "Lager", "icon": "📦"},
	{"id": "invest", "label": "Investition", "icon": "📈"},
	{"id": "finance", "label": "Finanzierung", "icon": "💰"},
	{"id": "learning", "label": "BWL-Labor", "icon": "📖"},
	{"id": "advisor", "label": "Berater", "icon": "💡"},
	{"id": "stats", "label": "Kennzahlen", "icon": "📊"},
]

var factory_view: FactoryView
var camera_rig: CameraRig
var _current_nav: String = "production"


func _ready() -> void:
	_build_ui()
	EventBus.simulation_ticked.connect(_on_tick)
	EventBus.economy_changed.connect(func(_s): _refresh_header())
	EventBus.cash_changed.connect(func(_c, _d): _refresh_header())
	EventBus.day_passed.connect(_on_day_passed)
	EventBus.advisor_message_added.connect(_on_advisor_message)
	EventBus.simulation_speed_changed.connect(func(_i): _refresh_timeline())
	_refresh_header()


# ==================================================================
# Spielstand
#
# Das Spiel wird lokal gespeichert. Ohne diese Funktion waere der
# Fortschritt bei jedem Beenden des Spiels verloren – und ein
# Unternehmenssimulation ohne Fortschritt ergibt keinen Sinn.
# ==================================================================

const SAVE_SLOT := "haupt"


## Baut den kompletten Spielstand.
func _build_save_payload() -> Dictionary:
	return {
		"version": SaveSystem.CURRENT_VERSION,
		"player_name": GameState.player_name,
		"simulation": Simulation.to_dict(),
		"progress": GameState.progress.to_dict(),
		"settings": GameState.settings,
		"saved_at": Time.get_datetime_string_from_system(),
	}


## Speichert den Spielstand.
func _save_game() -> void:
	var ok := SaveService.write_save(SAVE_SLOT, _build_save_payload())
	EventBus.notify(
		"Spielstand gespeichert" if ok else "Speichern fehlgeschlagen",
		"Der Spielstand liegt lokal auf diesem Rechner." if ok else
			"Der Spielstand konnte nicht geschrieben werden.",
		"success" if ok else "error"
	)


## Laedt den Spielstand und setzt Simulation und Fortschritt zurueck.
func _load_game() -> void:
	var data := SaveService.read_save(SAVE_SLOT)
	if data.is_empty():
		EventBus.notify(
			"Kein Spielstand gefunden",
			"Es wurde noch nichts gespeichert.",
			"warning"
		)
		return

	# Der Spielstand wird auf die aktuelle Formatversion gebracht.
	var migrated := SaveSystem.sanitize_save(data)

	var sim_data: Dictionary = migrated.get("simulation", {})
	if not sim_data.is_empty():
		Simulation.from_dict(sim_data)
	GameState.from_dict(migrated)
	# Die Fabrikansicht muss die Maschinen neu aufbauen.
	factory_view.sync_machines()
	_refresh_header()
	_refresh_timeline()
	_refresh_sidebar()
	EventBus.notify(
		"Spielstand geladen",
		"Tag %d, Jahr %d. Die Firma macht weiter." % [Simulation.day, Simulation.year],
		"success"
	)


## Beginnt ein neues Spiel.
func _new_game() -> void:
	Simulation.reset()
	GameState.reset()
	factory_view.sync_machines()
	_refresh_header()
	_refresh_timeline()
	_refresh_sidebar()
	EventBus.notify(
		"Neues Spiel",
		"Die Delizioso AG startet mit einer Anlage A und 50.000 € Kapital.",
		"info"
	)


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = UI["background"]
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# --- 3D-Ansicht (Hauptfläche) ---
	var viewport_container := SubViewportContainer.new()
	viewport_container.name = "FactoryView"
	viewport_container.stretch = true
	viewport_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(viewport_container)

	var viewport := SubViewport.new()
	viewport.name = "Viewport3D"
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	viewport_container.add_child(viewport)

	var world_root := Node3D.new()
	world_root.name = "World"
	viewport.add_child(world_root)

	factory_view = FactoryView.new()
	factory_view.name = "Factory"
	world_root.add_child(factory_view)

	camera_rig = CameraRig.new()
	camera_rig.name = "CameraRig"
	world_root.add_child(camera_rig)

	factory_view.setup(Simulation.grid)
	camera_rig.set_bounds(Simulation.grid)

	# --- Navigationsleiste ---
	var nav := _build_nav()
	add_child(nav)

	# --- Kopfzeile ---
	var header := _build_header()
	add_child(header)

	# --- Seitenleiste ---
	var side := _build_sidebar()
	add_child(side)

	# --- Zeitleiste ---
	var timeline := _build_timeline()
	add_child(timeline)

	# --- Overlay: Toast ---
	var toast_layer := VBoxContainer.new()
	toast_layer.name = "Toasts"
	toast_layer.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	toast_layer.offset_left = -380
	toast_layer.offset_top = -160
	toast_layer.offset_right = -20
	toast_layer.offset_bottom = -70
	toast_layer.alignment = BoxContainer.ALIGNMENT_END
	toast_layer.add_theme_constant_override("separation", 8)
	toast_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toast_layer)


# ==================================================================
# Aufbau der Bedienoberfläche
# ==================================================================

func _build_nav() -> Control:
	var panel := PanelContainer.new()
	panel.name = "Nav"
	panel.custom_minimum_size = Vector2(212, 0)
	panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	panel.offset_right = 212
	panel.add_theme_stylebox_override("panel", _style(Color(0.067, 0.078, 0.094, 0.97), 0))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)

	# Marke
	var brand := HBoxContainer.new()
	brand.add_theme_constant_override("separation", 10)
	var mark := PanelContainer.new()
	mark.custom_minimum_size = Vector2(38, 38)
	mark.add_theme_stylebox_override("panel", _style(UI["accent"], 4))
	var mark_label := Label.new()
	mark_label.text = "D"
	mark_label.add_theme_font_size_override("font_size", 20)
	mark_label.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	mark_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mark.add_child(mark_label)

	var brand_text := VBoxContainer.new()
	var b1 := Label.new()
	b1.text = "DELIZIOSO AG"
	b1.add_theme_font_size_override("font_size", 14)
	var b2 := Label.new()
	b2.text = "BWL SLAYER"
	b2.add_theme_font_size_override("font_size", 10)
	b2.add_theme_color_override("font_color", UI["text_faint"])
	box.add_child(brand)
	box.add_child(brand_text)

	box.add_child(HSeparator.new())

	var section := Label.new()
	section.text = "BETRIEBSFÜHRUNG"
	section.add_theme_font_size_override("font_size", 10)
	section.add_theme_color_override("font_color", UI["text_faint"])
	box.add_child(section)

	for item in NAV_ITEMS:
		var button := Button.new()
		button.text = "  %s  %s" % [item["icon"], item["label"]]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 34)
		button.flat = true
		button.add_theme_stylebox_override("normal", _style(Color(0, 0, 0, 0), 5))
		button.add_theme_stylebox_override("hover", _style(Color(1, 1, 1, 0.04), 5))
		button.add_theme_stylebox_override("pressed", _style(Color(0, 0, 0, 0), 5))
		button.pressed.connect(_on_nav_pressed.bind(String(item["id"])))
		box.add_child(button)
		if String(item["id"]) == _current_nav:
			button.add_theme_stylebox_override("normal", _style(UI["accent_soft"], 4))
			button.add_theme_color_override("font_color", Color(0.72, 0.85, 0.93))

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)

	var company := Label.new()
	company.name = "CompanyName"
	company.text = "Unternehmen · Tag %d" % Simulation.day
	company.add_theme_font_size_override("font_size", 11)
	company.add_theme_color_override("font_color", UI["text_muted"])
	box.add_child(company)

	# Spielstand: sichern, laden, neues Spiel
	#
	# Der Spielstand liegt lokal auf diesem Rechner. Ohne diese
	# Funktion waere der Fortschritt bei jedem Beenden verloren.
	box.add_child(HSeparator.new())

	var save_button := Button.new()
	save_button.text = "Speichern"
	save_button.custom_minimum_size = Vector2(0, 28)
	save_button.pressed.connect(_save_game)
	box.add_child(save_button)

	var load_button := Button.new()
	load_button.text = "Laden"
	load_button.custom_minimum_size = Vector2(0, 28)
	load_button.pressed.connect(_load_game)
	box.add_child(load_button)

	var new_button := Button.new()
	new_button.text = "Neues Spiel"
	new_button.custom_minimum_size = Vector2(0, 28)
	new_button.pressed.connect(_new_game)
	box.add_child(new_button)

	return panel


func _build_header() -> Control:
	var panel := PanelContainer.new()
	panel.name = "Header"
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.offset_left = 212
	panel.offset_right = -320
	panel.offset_bottom = 58
	panel.add_theme_stylebox_override("panel", _style(Color(0.075, 0.086, 0.102, 0.96), 0))

	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 26)
	box.alignment = BoxContainer.ALIGNMENT_BEGIN
	panel.add_child(box)

	# Titel
	var title := VBoxContainer.new()
	title.custom_minimum_size = Vector2(200, 0)
	var t1 := Label.new()
	t1.name = "CompanyTitle"
	t1.text = "DELIZIOSO AG"
	t1.add_theme_font_size_override("font_size", 16)
	var t2 := Label.new()
	t2.name = "StatusLine"
	t2.text = "Betrieb aktiv"
	t2.add_theme_font_size_override("font_size", 11)
	t2.add_theme_color_override("font_color", UI["text_muted"])
	title.add_child(t1)
	title.add_child(t2)
	box.add_child(title)

	# Kennzahlen
	for key in ["cash", "revenue", "costs", "result"]:
		var col := VBoxContainer.new()
		col.custom_minimum_size = Vector2(130, 0)
		var label := Label.new()
		label.text = {"cash": "LIQUIDITÄT", "revenue": "UMSATZ", "costs": "KOSTEN", "result": "ERGEBNIS"}[key]
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", UI["text_faint"])
		var value := Label.new()
		value.name = "Stat_" + key
		value.text = "–"
		value.add_theme_font_size_override("font_size", 16)
		col.add_child(label)
		col.add_child(value)
		box.add_child(col)

	return panel


func _build_sidebar() -> Control:
	var panel := PanelContainer.new()
	panel.name = "Sidebar"
	panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	panel.offset_left = -320
	panel.offset_right = 0
	panel.offset_bottom = -56
	panel.add_theme_stylebox_override("panel", _style(Color(0.075, 0.086, 0.102, 0.97), 0))

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var box := VBoxContainer.new()
	box.name = "Content"
	box.custom_minimum_size = Vector2(300, 0)
	box.add_theme_constant_override("separation", 14)
	scroll.add_child(box)

	return panel


func _build_timeline() -> Control:
	var panel := PanelContainer.new()
	panel.name = "Timeline"
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 212
	panel.offset_right = -320
	panel.offset_top = -56
	panel.add_theme_stylebox_override("panel", _style(Color(0.075, 0.086, 0.102, 0.96), 0))

	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	var day_label := Label.new()
	day_label.name = "DayLabel"
	day_label.text = "Tag %d · Jahr %d" % [Simulation.day, Simulation.year]
	day_label.custom_minimum_size = Vector2(150, 0)
	day_label.add_theme_font_size_override("font_size", 13)
	box.add_child(day_label)

	var play := Button.new()
	play.name = "PlayPause"
	play.text = "⏸ Pause"
	play.custom_minimum_size = Vector2(96, 0)
	play.pressed.connect(func(): Simulation.toggle_pause())
	box.add_child(play)

	for i in range(1, Simulation.SPEEDS.size()):
		var speed_button := Button.new()
		speed_button.text = "×%d" % int(Simulation.SPEEDS[i])
		speed_button.custom_minimum_size = Vector2(46, 0)
		speed_button.pressed.connect(func(): Simulation.set_speed(i))
		box.add_child(speed_button)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)

	var util := Label.new()
	util.name = "UtilizationLabel"
	util.text = "Auslastung 0 %"
	util.add_theme_font_size_override("font_size", 13)
	box.add_child(util)

	# Tastaturhilfe: die Bedienung muss ohne Anleitung erkennbar sein.
	var help := Label.new()
	help.name = "KeyHelp"
	help.text = "Leertaste Pause · 1–5 Tempo · Alt+1–8 Bereich · +/− Zoom · R Ansicht · F Zentrum"
	help.add_theme_font_size_override("font_size", 11)
	help.add_theme_color_override("font_color", UI["text_faint"])
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(help)

	return panel


# ==================================================================
# Aktualisierung
# ==================================================================

func _process(_delta: float) -> void:
	factory_view.sync_machines()
	factory_view.sync_deliveries(_delta)


## Globale Tastatursteuerung.
##
## Das Spiel muss ohne Maus bedienbar sein:
##
##   Leertaste   Simulation anhalten / fortsetzen
##   Shift+Leer  Pause
##   1..5       Geschwindigkeit (Pause, 1x, 3x, 8x, 20x)
##   Alt+1..8   Bereich wechseln
##   +/-        Kamera zoomen
##   R          Kamera zuruecksetzen
##   F          Kamera auf das Gelände zentrieren
##   Strg+S     Spielstand speichern
##   Strg+O     Spielstand laden
##   Escape     Lernlabor schliessen
##
## Eingaben in Textfeldern werden nicht abgefangen – sonst waere das
## Rechen-Labor nicht bedienbar.
## Mausklick auf das Betriebsgelaende.
##
## Ein Klick auf eine Maschine waehlt sie aus und zeigt ihre
## Wirtschaftsdaten in der Seitenleiste. Ohne diese Auswahl kann der
## Spieler die Maschine auf der Szene nicht mit ihren Zahlen
## verbinden.
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse := event as InputEventMouseButton
	if not mouse.pressed or mouse.button_index != MOUSE_BUTTON_LEFT:
		return

	# Wo wurde geklickt? Der Bildschirm wird in die 3D-Welt
	# umgerechnet.
	var world_point := _screen_to_world(mouse.position)
	if world_point == Vector3.INF:
		return

	var instance_id := factory_view.machine_at(world_point)
	if instance_id == "":
		factory_view.clear_selection()
		_selected_machine = ""
		_refresh_sidebar()
		return

	_selected_machine = instance_id
	factory_view.select_at(world_point)
	# Der Bereich wechselt auf die Produktion, damit die Daten der
	# gewaehlten Maschine sichtbar sind.
	_current_nav = "production"
	_refresh_sidebar()


## Die ausgewaehlte Maschine (oder Leerstring).
var _selected_machine: String = ""


## Bildschirmposition in eine Weltposition umrechnen.
##
## Die Kamera ist orthogonal (isometrisch). Die Umrechnung geht daher
## ueber die Kamera-Ebene: der Strahl durch den Bildschirmpunkt wird
## auf die Ebene y = 0 gelegt.
func _screen_to_world(screen_pos: Vector2) -> Vector3:
	if camera_rig == null:
		return Vector3.INF
	var camera := camera_rig.camera()
	if camera == null:
		return Vector3.INF

	var origin := camera.project_ray_origin(screen_pos)
	var direction := camera.project_ray_normal(screen_pos)
	if absf(direction.y) < 0.0001:
		return Vector3.INF
	var distance := -origin.y / direction.y
	if distance < 0.0:
		return Vector3.INF
	return origin + direction * distance


func _unhandled_key_input(event: InputEventKey) -> void:
	if not event.pressed or event.echo:
		return

	# Keine Globalshortcuts, während ein Eingabefeld den Fokus hat.
	var focused := get_viewport().gui_get_focus_owner()
	if focused is LineEdit or focused is TextEdit:
		return

	# Lernlabor schliessen
	if event.keycode == KEY_ESCAPE:
		var overlay := get_tree().root.get_node_or_null("LearningOverlay")
		if overlay != null:
			overlay.queue_free()
			get_viewport().set_input_as_handled()
			return

	# Speichern und Laden (Strg+S / Strg+O)
	if event.ctrl_pressed and event.keycode == KEY_S:
		_save_game()
		get_viewport().set_input_as_handled()
		return
	if event.ctrl_pressed and event.keycode == KEY_O:
		_load_game()
		get_viewport().set_input_as_handled()
		return

	# Simulationsgeschwindigkeit
	#
	# Leertaste schaltet zwischen Pause und der eingestellten
	# Geschwindigkeit um. Shift+Leertaste setzt die Geschwindigkeit
	# direkt auf Pause.
	if event.keycode == KEY_SPACE:
		if event.shift_pressed:
			Simulation.set_speed(0)
		else:
			Simulation.running = not Simulation.running
		_refresh_timeline()
		get_viewport().set_input_as_handled()
		return

	# Geschwindigkeit direkt waehlen: 1 = Pause, 2 = 1x, 3 = 3x,
	# 4 = 8x, 5 = 20x (die in Simulation.SPEEDS hinterlegten Stufen).
	if event.keycode >= KEY_1 and event.keycode <= KEY_5:
		Simulation.set_speed(int(event.keycode - KEY_1))
		_refresh_timeline()
		get_viewport().set_input_as_handled()
		return

	# Bereich wechseln (Alt + Ziffer)
	if event.alt_pressed and event.keycode >= KEY_1 and event.keycode <= KEY_8:
		var index := int(event.keycode - KEY_1)
		if index < NAV_ITEMS.size():
			_on_nav_pressed(String(NAV_ITEMS[index]["id"]))
			get_viewport().set_input_as_handled()
			return

	# Kamera
	if camera_rig != null and camera_rig.handle_key(event):
		get_viewport().set_input_as_handled()
		return


func _on_tick(_day: int, _tick: int) -> void:
	_refresh_timeline()


func _on_day_passed(_year: int, _report: Dictionary) -> void:
	_refresh_header()


func _refresh_header() -> void:
	var header := get_node_or_null("Header") as Control
	if header == null:
		return
	var eco := Simulation.economy
	var values := {
		"cash": eco.cash,
		"revenue": eco.revenue_current_year,
		"costs": eco.costs_current_year,
		"result": eco.operating_result(),
	}
	for key in values:
		var label := header.find_child("Stat_" + key, true, false) as Label
		if label == null:
			continue
		label.text = _format_currency(values[key])
		var color := UI["text"]
		if key == "result":
			color = UI["positive"] if values[key] >= 0.0 else UI["danger"]
		label.add_theme_color_override("font_color", color)


func _refresh_timeline() -> void:
	var timeline := get_node_or_null("Timeline") as Control
	if timeline == null:
		return
	var day_label := timeline.find_child("DayLabel", true, false) as Label
	if day_label != null:
		day_label.text = "Tag %d · Jahr %d" % [Simulation.day, Simulation.year]
	var util := timeline.find_child("UtilizationLabel", true, false) as Label
	if util != null:
		util.text = "Auslastung %d %%" % int(Simulation.current_utilization())
	var play := timeline.find_child("PlayPause", true, false) as Button
	if play != null:
		play.text = "⏸ Pause" if Simulation.running else "▶ Start"


func _on_nav_pressed(nav_id: String) -> void:
	_current_nav = nav_id
	_refresh_sidebar()
	EventBus.screen_changed.emit(nav_id)


## Der Kurzhinweis des Beraters.
##
## Der Hinweis erscheint als Toast und ist anklickbar: er fuehrt in die
## Berateransicht, wo die Fragen und die fachliche Lektion stehen.
## Der Toast verschwindet nach zehn Sekunden von selbst.
func _on_advisor_message(message: Dictionary) -> void:
	var toast_layer := get_node_or_null("Toasts") as VBoxContainer
	if toast_layer == null:
		return

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(UI["surface"], 6))
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var severity := String(message.get("severity", "info"))
	var border_color := {
		"critical": UI["danger"],
		"warning": UI["warning"],
	}.get(severity, UI["accent"])

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)

	var title := Label.new()
	title.text = String(message.get("title", ""))
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", border_color)
	v.add_child(title)

	var text := Label.new()
	text.text = String(message.get("analysis", ""))
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(300, 0)
	text.add_theme_font_size_override("font_size", 11)
	text.add_theme_color_override("font_color", UI["text_muted"])
	v.add_child(text)

	# Handlungsempfehlung als klickbarer Aufruf in die Berateransicht
	var action := String(message.get("action", ""))
	if action != "":
		var link := Button.new()
		link.text = "Analyse öffnen →"
		link.alignment = HORIZONTAL_ALIGNMENT_LEFT
		link.flat = true
		link.add_theme_font_size_override("font_size", 11)
		link.add_theme_color_override("font_color", UI["accent"])
		link.pressed.connect(func():
			_on_nav_pressed("advisor")
			panel.queue_free()
		)
		v.add_child(link)

	panel.add_child(v)
	toast_layer.add_child(panel)

	# Der Hinweis verschwindet nach zehn Sekunden. Die Zeit laeuft
	# unabhaengig von der Simulationsgeschwindigkeit.
	var timer := get_tree().create_timer(10.0)
	timer.timeout.connect(func():
		if is_instance_valid(panel):
			panel.queue_free()
	)


# ==================================================================
# Inhalte der Seitenleiste
# ==================================================================

func _refresh_sidebar() -> void:
	var sidebar := get_node_or_null("Sidebar") as Control
	if sidebar == null:
		return
	var box := sidebar.find_child("Content", true, false) as VBoxContainer
	if box == null:
		return
	for child in box.get_children():
		child.queue_free()

	match _current_nav:
		"production": _fill_production(box)
		"logistics": _fill_logistics(box)
		"storage": _fill_storage(box)
		"invest": _fill_invest(box)
		"finance": _fill_finance(box)
		"learning": _fill_learning(box)
		"advisor": _fill_advisor(box)
		"stats": _fill_stats(box)


## Die Produktionsansicht.
##
## Je Anlage werden nicht nur technische Werte gezeigt, sondern die
## wirtschaftlich entscheidenden Groessen: Deckungsbeitrag, Fixkosten
## je Stueck und der Break-even. Daran laesst sich ablesen, ob die
## Anlage ihr Geld verdient.
func _fill_production(box: VBoxContainer) -> void:
	_add_section(box, "WERK 01 · PRODUKTIONSSTANDORT")

	# Die auf der Szene ausgewaehlte Maschine kommt nach oben.
	if _selected_machine != "":
		var selected: MachineInstance = Simulation.machines.get(_selected_machine)
		if selected != null:
			box.add_child(_machine_card(selected, true))

	var machines: Array[MachineInstance] = Simulation.active_machines()
	if machines.is_empty():
		if _selected_machine == "":
			box.add_child(_muted("Keine Anlage im Betrieb. Starte eine Investition."))
		return
	for m in machines:
		if m.instance_id == _selected_machine:
			continue
		box.add_child(_machine_card(m, false))


## Die Karte einer Maschine mit ihren Wirtschaftsdaten.
func _machine_card(m: MachineInstance, selected: bool) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(UI["surface_alt"], 4))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)

	var title := Label.new()
	title.text = ("▸ " if selected else "") + m.spec.display_name
	title.add_theme_font_size_override("font_size", 14)
	if selected:
		title.add_theme_color_override("font_color", UI["accent"])
	v.add_child(title)

	var status := Label.new()
	status.text = "%s · %d %% Auslastung" % [
		m.state_label(), int(m.spec.utilization_at(m.quantity_this_year))
	]
	status.add_theme_font_size_override("font_size", 12)
	status.add_theme_color_override("font_color",
		UI["positive"] if m.is_operational() else UI["warning"])
	v.add_child(status)

	# Auslastungsbalken
	var utilization := m.spec.utilization_at(m.quantity_this_year)
	var bar := ProgressBar.new()
	bar.max_value = 100.0
	bar.value = utilization
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 6)
	bar.add_theme_stylebox_override("fill", _style(_utilization_color(utilization), 0))
	bar.add_theme_stylebox_override("background", _style(UI["surface"], 0))
	v.add_child(bar)

	# Die wirtschaftlichen Groessen
	var produced := m.quantity_this_year
	var fixed_per_unit := 0.0
	if produced > 0.0:
		fixed_per_unit = m.current_cash_fixed_costs() / produced

	v.add_child(_metric_row("Produktion", "%d Stück" % int(produced)))
	v.add_child(_metric_row("Fixkosten p.a.", BWLEngine.format_eur(m.current_cash_fixed_costs(), 0)))
	v.add_child(_metric_row("Fixkosten je Stück",
		BWLEngine.format_eur(fixed_per_unit, 2) if produced > 0.0 else "—"))
	v.add_child(_metric_row("Deckungsbeitrag je Stück",
		BWLEngine.format_eur(m.spec.contribution_margin_per_unit(), 2)))
	v.add_child(_metric_row("Break-even", "%d Stück p.a." % int(m.spec.break_even_quantity())))
	if m.spec.material_per_unit > 0.0:
		v.add_child(_metric_row("Materialverbrauch",
			"%.2f kg/Stück" % m.spec.material_per_unit))

	# Der Buchwert: der Wert der Maschine im Anlagevermoegen.
	v.add_child(_metric_row("Buchwert", BWLEngine.format_eur(m.book_value, 0)))

	panel.add_child(v)
	return panel


## Die Farbe der Auslastung: Grün im gesunden Bereich, Orange ab 70 %,
## Rot ab 95 %. Rot bleibt Warnungen vorbehalten.
func _utilization_color(utilization: float) -> Color:
	if utilization >= 95.0:
		return UI["danger"]
	if utilization >= 70.0:
		return UI["warning"]
	return UI["positive"]


## Eine Zeile "Bezeichnung: Wert" fuer die Seitenleiste.
func _metric_row(label_text: String, value_text: String) -> Control:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", UI["text_muted"])
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 11)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value)
	return row


## Die Lieferkette als Tabelle.
##
## Jede Maschine, die noch nicht betriebsbereit ist, bekommt eine Zeile
## mit der aktuellen Phase, den verbleibenden Tagen und einem
## Fortschrittsbalken. Die Phase entspricht dem Zustand der
## Zustandsmaschine – Anzeige und Simulation sprechen dieselbe
## Sprache.
func _fill_logistics(box: VBoxContainer) -> void:
	_add_section(box, "LOGISTIK")

	# Lieferungen, die noch laufen
	if not Simulation.deliveries.is_empty():
		for delivery in Simulation.deliveries:
			var instance: MachineInstance = Simulation.machines.get(delivery.get("instance_id"))
			if instance == null:
				continue
			box.add_child(_delivery_row(instance, delivery))

	# Maschinen im Bestand, deren Lieferung abgeschlossen ist
	var in_stock := 0
	for instance_id in Simulation.machines:
		var instance: MachineInstance = Simulation.machines[instance_id]
		if instance.state == MachineInstance.State.ACTIVE:
			continue
		if instance.state == MachineInstance.State.DECOMMISSIONED:
			continue
		if Simulation.deliveries.any(func(d): return String(d.get("instance_id", "")) == String(instance_id)):
			continue
		in_stock += 1
		box.add_child(_delivery_row(instance, {}))

	if Simulation.deliveries.is_empty() and in_stock == 0:
		box.add_child(_muted("Keine Lieferung unterwegs."))
		return

	# Zusammenfassung
	var pending_value := 0.0
	for delivery in Simulation.deliveries:
		var instance: MachineInstance = Simulation.machines.get(delivery.get("instance_id"))
		if instance != null:
			pending_value += instance.spec.acquisition_cost
	box.add_child(HSeparator.new())
	var summary := Label.new()
	summary.text = "Gebundenes Kapital in Lieferung: %s" % BWLEngine.format_eur(pending_value, 0)
	summary.add_theme_font_size_override("font_size", 12)
	summary.add_theme_color_override("font_color", UI["text_muted"])
	box.add_child(summary)


## Eine Zeile der Lieferkette.
func _delivery_row(instance: MachineInstance, delivery: Dictionary) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 2)

	var title := Label.new()
	title.text = instance.spec.display_name
	title.add_theme_font_size_override("font_size", 13)
	row.add_child(title)

	var phase := _phase_text(instance)
	var remaining := int(delivery.get("days_remaining", 0))
	var info := Label.new()
	info.text = "%s · noch %d Tage" % [phase, remaining] if remaining > 0 else phase
	info.add_theme_font_size_override("font_size", 11)
	info.add_theme_color_override("font_color", _phase_color(instance))
	row.add_child(info)

	# Fortschrittsbalken: Wie weit ist die Maschine auf ihrem Weg?
	var progress := _delivery_progress(instance)
	if progress > 0.0:
		var bar := ProgressBar.new()
		bar.max_value = 100.0
		bar.value = progress * 100.0
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 6)
		bar.add_theme_stylebox_override("fill", _style(_phase_color(instance), 0))
		bar.add_theme_stylebox_override("background", _style(UI["surface_alt"], 0))
		row.add_child(bar)

	return row


## Die Phase als lesbarer Text.
func _phase_text(instance: MachineInstance) -> String:
	match instance.state:
		MachineInstance.State.ORDERED:
			return "Bestellt – Ware im Wareneingang"
		MachineInstance.State.IN_TRANSIT:
			return "Unterwegs zur Baustelle"
		MachineInstance.State.ARRIVED:
			return "Angekommen – Entladen steht an"
		MachineInstance.State.UNLOADING:
			return "Wird entladen"
		MachineInstance.State.INSTALLING:
			return "Wird montiert"
		MachineInstance.State.ACTIVE:
			return "In Betrieb"
		MachineInstance.State.DECOMMISSIONED:
			return "Außer Betrieb"
	return "Unbekannt"


## Die Farbe der Phase: Blau für den Weg, Orange für die Arbeit,
## Grün für Betrieb.
func _phase_color(instance: MachineInstance) -> Color:
	match instance.state:
		MachineInstance.State.ORDERED, MachineInstance.State.IN_TRANSIT:
			return UI["accent"]
		MachineInstance.State.ARRIVED, MachineInstance.State.UNLOADING, MachineInstance.State.INSTALLING:
			return UI["warning"]
		MachineInstance.State.ACTIVE:
			return UI["positive"]
	return UI["text_muted"]


## Der Fortschritt der Lieferkette (0 bis 1).
##
## Die Schritte entsprechen den Phasen der Zustandsmaschine. Eine
## Maschine, die gerade entladen wird, ist weiter als eine, die gerade
## bestellt wurde.
func _delivery_progress(instance: MachineInstance) -> float:
	match instance.state:
		MachineInstance.State.ORDERED:
			return 0.05
		MachineInstance.State.IN_TRANSIT:
			return 0.30
		MachineInstance.State.ARRIVED:
			return 0.55
		MachineInstance.State.UNLOADING:
			return 0.70
		MachineInstance.State.INSTALLING:
			return 0.88
		MachineInstance.State.ACTIVE:
			return 1.0
	return 0.0


## Die Lageransicht.
##
## Hier wird das Material gekauft. Ohne Material laeuft eine Anlage mit
## Materialbedarf im Leerlauf – der Bestand ist daher eine
## eigenstaendige Entscheidung, keine Nebensache.
func _fill_storage(box: VBoxContainer) -> void:
	_add_section(box, "LAGER")

	var eco := Simulation.economy
	var label := Label.new()
	label.text = "Materialbestand: %s kg" % String.num(Simulation.inventory_material, 0)
	label.add_theme_font_size_override("font_size", 12)
	box.add_child(label)

	var value := Label.new()
	value.text = "Lagerwert: %s" % BWLEngine.format_eur(eco.inventory_value, 0)
	value.add_theme_font_size_override("font_size", 12)
	value.add_theme_color_override("font_color", UI["text_muted"])
	box.add_child(value)

	# Materialbestand je Materialart. Jede Anlage verbraucht ihre
	# eigene Art - ein Bestand ersetzt keinen anderen.
	var material_types := Simulation.required_material_types()
	if not material_types.is_empty():
		var lead_days := Simulation.MATERIAL_LEAD_TIME_DAYS
		for material_type in material_types:
			var daily_need: float = Simulation.daily_material_need(material_type)
			var cover_days: float = Simulation.material_coverage_days(material_type)
			var stock: float = Simulation.material_stock(material_type)

			var head := Label.new()
			head.text = "%s" % MachineCatalog.material_label(material_type).to_upper()
			head.add_theme_font_size_override("font_size", 11)
			head.add_theme_color_override("font_color", UI["text_muted"])
			box.add_child(head)

			var cover := Label.new()
			cover.text = "Bestand %s kg · Bedarf %s kg/Tag · Reichweite %d Tage" % [
				String.num(stock, 0),
				String.num(daily_need, 1),
				int(cover_days),
			]
			cover.add_theme_font_size_override("font_size", 12)
			# Unter zehn Tagen Reichweite ist ein Warnzustand.
			cover.add_theme_color_override("font_color",
				UI["danger"] if cover_days < 10.0 else UI["text"])
			box.add_child(cover)

			# Material auf dem Weg: Das zaehlt zur Reichweite dazu, ist
			# aber noch nicht im Lager.
			var in_transit: float = Simulation.material_in_transit(material_type)
			if in_transit > 0.0:
				var transit_label := Label.new()
				transit_label.text = "Auf dem Weg: %s kg" % String.num(in_transit, 0)
				transit_label.add_theme_font_size_override("font_size", 11)
				transit_label.add_theme_color_override("font_color", UI["accent"])
				box.add_child(transit_label)

			# Ist die Lieferzeit laenger als die Reichweite, laeuft die
			# Produktion leer, bevor das Material da ist.
			if cover_days < lead_days:
				var warning := Label.new()
				warning.text = "Reichweite kürzer als die Lieferzeit (%d Tage)." % lead_days
				warning.add_theme_font_size_override("font_size", 11)
				warning.add_theme_color_override("font_color", UI["danger"])
				box.add_child(warning)

	# Einkauf je Materialart. Zwei Wege: sofort kaufen (die Ware ist
	# sofort da) oder mit Lieferzeit bestellen (die Zahlung erfolgt
	# sofort, die Ware kommt in einigen Tagen). Der Spieler muss also
	# zwischen Liquiditaet und Planungssicherheit entscheiden – und
	# das fuer jede Materialart getrennt.
	for material_type in material_types:
		var type_label := Label.new()
		type_label.text = MachineCatalog.material_label(material_type)
		type_label.add_theme_font_size_override("font_size", 11)
		type_label.add_theme_color_override("font_color", UI["text_muted"])
		box.add_child(type_label)

		var buy_row := HBoxContainer.new()
		buy_row.add_theme_constant_override("separation", 6)
		for amount in [500.0, 2000.0, 10000.0]:
			var button := Button.new()
			button.text = "+ %s kg" % String.num(amount, 0)
			button.custom_minimum_size = Vector2(0, 30)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.tooltip_text = "Sofort kaufen – die Ware ist sofort im Lager."
			button.pressed.connect(func():
				Simulation.buy_material(amount, material_type)
				_refresh_sidebar()
			)
			buy_row.add_child(button)
		box.add_child(buy_row)

		var order_row := HBoxContainer.new()
		order_row.add_theme_constant_override("separation", 6)
		var order_button := Button.new()
		order_button.text = "Bestellen (+ %d Tage)" % Simulation.MATERIAL_LEAD_TIME_DAYS
		order_button.custom_minimum_size = Vector2(0, 30)
		order_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		order_button.tooltip_text = (
			"Zahlung sofort, Lieferung in %d Tagen. "
			% Simulation.MATERIAL_LEAD_TIME_DAYS
			+ "Das Material muss bis dahin reichen."
		)
		order_button.pressed.connect(func():
			# Bestellt wird der Bedarf von 30 Tagen – das ist die
			# uebliche Vorlaufmenge.
			var needed: float = Simulation.daily_material_need(material_type) * 30.0
			var result := Simulation.order_material(
				maxf(500.0, needed), -1, material_type
			)
			if not bool(result.get("ok", false)):
				EventBus.notify(
					"Bestellung nicht moeglich",
					String(result.get("error", "Die Bestellung wurde abgelehnt.")),
					"warning"
				)
			_refresh_sidebar()
		)
		order_row.add_child(order_button)
		box.add_child(order_row)

	var price := Label.new()
	price.text = "Materialpreis: %s €/kg · Lieferzeit %d Tage" % [
		BWLEngine.format_eur(Simulation.material_price(), 2),
		Simulation.MATERIAL_LEAD_TIME_DAYS,
	]
	price.add_theme_font_size_override("font_size", 11)
	price.add_theme_color_override("font_color", UI["text_faint"])
	box.add_child(price)


func _fill_invest(box: VBoxContainer) -> void:
	_add_section(box, "INVESTITIONSENTSCHEIDUNG")
	box.add_child(_muted("Wähle eine Anlage. Der Kostenvergleich zeigt, ab welcher Menge welche Alternative günstiger ist."))
	for spec_id in Simulation.specs:
		var spec: MachineSpec = Simulation.specs[spec_id]
		var button := Button.new()
		button.text = "%s · %s" % [spec.display_name, BWLEngine.format_eur(spec.acquisition_cost, 0)]
		button.custom_minimum_size = Vector2(0, 32)
		button.pressed.connect(_on_order_machine.bind(spec_id))
		box.add_child(button)


func _on_order_machine(spec_id: StringName) -> void:
	var result := Simulation.order_machine(spec_id)
	if bool(result.get("ok", false)):
		_refresh_sidebar()
	else:
		_on_advisor_message({
			"title": "Bestellung nicht möglich",
			"analysis": String(result.get("error", "")),
		})


## Die Finanzansicht: GuV, Bilanz und Cashflow.
##
## Die Trennung ist der Punkt: eine Investition steht als Anlagevermoegen
## in der Bilanz, nicht als Aufwand in der GuV. Der Bilanzcheck muss null
## sein – er weist nach, dass nichts doppelt gebucht wurde.
func _fill_finance(box: VBoxContainer) -> void:
	var eco := Simulation.economy

	_add_section(box, "GEWINN- UND VERLUSTRECHNUNG")
	_add_metric(box, "Umsatz", BWLEngine.format_eur(eco.revenue_current_year, 0))
	_add_metric(box, "Materialkosten", BWLEngine.format_eur(eco.material_costs_year, 0))
	_add_metric(box, "Fixkosten", BWLEngine.format_eur(eco.fixed_costs_year, 0))
	_add_metric(box, "Abschreibung", BWLEngine.format_eur(eco.depreciation_year, 0))
	_add_metric(box, "Kalkulatorische Zinsen", BWLEngine.format_eur(eco.imputed_interest_year, 0))
	_add_metric(box, "Zinsaufwand FK", BWLEngine.format_eur(eco.interest_paid_year, 0))
	_add_metric(box, "Betriebsergebnis", BWLEngine.format_eur(eco.operating_result(), 0))
	_add_metric(box, "Cashflow", BWLEngine.format_eur(eco.cash_flow(), 0))

	_add_section(box, "BILANZ")
	_add_metric(box, "Anlagevermögen", BWLEngine.format_eur(eco.fixed_assets, 0))
	_add_metric(box, "Kasse", BWLEngine.format_eur(eco.cash, 0))
	_add_metric(box, "Forderungen", BWLEngine.format_eur(eco.receivables, 0))
	_add_metric(box, "Lagerbestand", BWLEngine.format_eur(eco.inventory_value, 0))
	_add_metric(box, "Summe Aktiva", BWLEngine.format_eur(eco.total_assets(), 0))
	_add_metric(box, "Eigenkapital", BWLEngine.format_eur(eco.equity, 0))
	_add_metric(box, "Fremdkapital", BWLEngine.format_eur(eco.debt, 0))
	_add_metric(box, "Summe Passiva", BWLEngine.format_eur(eco.total_liabilities_and_equity(), 0))

	# Der Bilanzcheck: null heisst, die Bilanz stimmt.
	var balance := eco.balance_check()
	var check := Label.new()
	if absf(balance) < 0.01:
		check.text = "✓ Bilanz stimmt"
		check.add_theme_color_override("font_color", UI["positive"])
	else:
		check.text = "✗ Bilanzabweichung: %s" % BWLEngine.format_eur(balance, 2)
		check.add_theme_color_override("font_color", UI["danger"])
	check.add_theme_font_size_override("font_size", 12)
	box.add_child(check)

	_add_section(box, "KENNZAHLEN")
	_add_metric(box, "FK-Quote", BWLEngine.format_pct(eco.debt_ratio() * 100.0, 1))
	_add_metric(box, "EK-Quote", BWLEngine.format_pct(Simulation.equity_ratio() * 100.0, 1))
	_add_metric(box, "EK-Rentabilität", BWLEngine.format_pct(eco.roe_percent(), 1))
	_add_metric(box, "Liquiditätsgrad II", String.num(eco.liquidity_ratio(), 2))
	_add_metric(box, "Tilgung im Jahr", BWLEngine.format_eur(eco.repayment_year, 0))
	_add_metric(box, "Zinsbelastung EK", BWLEngine.format_pct(Simulation.interest_burden() * 100.0, 2))

	# --- Finanzierung: eine echte Entscheidung --------------------
	_add_section(box, "FINANZIERUNG")

	var limit: float = Simulation.credit_limit()
	_add_metric(box, "Kreditrahmen der Bank", BWLEngine.format_eur(limit, 0))
	_add_metric(box, "Zinssatz (Bonität)", BWLEngine.format_pct(eco.debt_rate * 100.0, 2))

	# Der Tilgungsanteil steuert, wie viel Fremdkapital pro Jahr
	# zurueckgeht. 0 % haelt Liquiditaet, kostet aber Zinsen.
	var repay_row := HBoxContainer.new()
	repay_row.add_theme_constant_override("separation", 6)
	var repay_label := Label.new()
	repay_label.text = "Tilgung p.a."
	repay_label.custom_minimum_size = Vector2(110, 0)
	repay_label.add_theme_font_size_override("font_size", 12)
	repay_row.add_child(repay_label)

	var repay_slider := HSlider.new()
	repay_slider.min_value = 0.0
	repay_slider.max_value = 100.0
	repay_slider.step = 5.0
	repay_slider.value = eco.repayment_share * 100.0
	repay_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	repay_slider.custom_minimum_size = Vector2(0, 24)
	repay_slider.tooltip_text = "Anteil des Fremdkapitals, der pro Jahr getilgt wird."
	repay_row.add_child(repay_slider)

	var repay_value := Label.new()
	repay_value.text = "%d %%" % int(eco.repayment_share * 100.0)
	repay_value.custom_minimum_size = Vector2(48, 0)
	repay_value.add_theme_font_size_override("font_size", 12)
	repay_value.add_theme_color_override("font_color", UI["accent"])
	repay_row.add_child(repay_value)

	repay_slider.value_changed.connect(func(value: float):
		repay_value.text = "%d %%" % int(value)
	)
	repay_slider.drag_ended.connect(func(changed: bool):
		if changed:
			Simulation.set_repayment_share(repay_slider.value / 100.0)
			_refresh_sidebar()
	)
	box.add_child(repay_row)

	# Die Kreditaufnahme richtet sich nach dem Kreditrahmen.
	var loan_amount := minf(25_000.0, limit)
	if loan_amount > 0.0:
		var loan := Button.new()
		loan.text = "Kredit aufnehmen: %s" % BWLEngine.format_eur(loan_amount, 0)
		loan.custom_minimum_size = Vector2(0, 32)
		loan.pressed.connect(func():
			var result := Simulation.take_loan(loan_amount)
			if not bool(result.get("ok", false)):
				EventBus.notify(
					"Kredit abgelehnt",
					String(result.get("error", "Die Bank gewaehrt keinen Kredit.")),
					"warning"
				)
			_refresh_sidebar()
		)
		box.add_child(loan)
	else:
		box.add_child(_muted("Kein Kreditrahmen. Die Bank gewaehrt kein weiteres Fremdkapital."))

	# Die Tilgung kann auch manuell gesteuert werden.
	if eco.debt > 0.0:
		var repay_manual := Button.new()
		repay_manual.text = "Fremdkapital tilgen: %s" % BWLEngine.format_eur(minf(10_000.0, eco.debt), 0)
		repay_manual.custom_minimum_size = Vector2(0, 32)
		repay_manual.pressed.connect(func():
			Simulation.repay_loan(minf(10_000.0, eco.debt))
			_refresh_sidebar()
		)
		box.add_child(repay_manual)


func _fill_learning(box: VBoxContainer) -> void:
	_add_section(box, "BWL-LABOR")
	for world in LearningContent.get_worlds():
		var progress := GameState.progress
		var unlocked := progress.is_world_unlocked(world.id)
		var button := Button.new()
		var done := 0
		for stage in range(3):
			if progress.is_stage_done(world.id, stage):
				done += 1
		button.text = "%s %s  (%d/3)" % [world.icon, world.title, done]
		button.custom_minimum_size = Vector2(0, 30)
		button.disabled = not unlocked
		button.pressed.connect(func(): _open_world(world.id))
		box.add_child(button)

		# Der Umfang der Welt sichtbar machen: eine Welt gilt nicht als
		# erledigt, wenn nur ein Teil davon bearbeitet wurde.
		var detail := Label.new()
		detail.text = "%d Aufgaben · %d Originalaufgaben" % [
			world.concept_items.size(), world.lab_tasks.size()
		]
		detail.add_theme_font_size_override("font_size", 11)
		detail.add_theme_color_override("font_color", UI["text_faint"])
		detail.custom_minimum_size = Vector2(0, 18)
		box.add_child(detail)


func _open_world(world_id: String) -> void:
	# Der Welt-Bereich ist ein Overlay im Lernlabor.
	var overlay := get_tree().root.get_node_or_null("LearningOverlay")
	if overlay != null:
		overlay.queue_free()
	overlay = LearningOverlay.new()
	overlay.name = "LearningOverlay"
	get_tree().root.add_child(overlay)
	overlay.open_world(world_id)


## Der Unternehmensberater.
##
## Jeder Hinweis besteht aus vier Teilen: der Analyse mit Zahlen aus
## dem Betrieb, den Fragen, die zum Nachdenken fuehren, der
## fachlichen Lektion und der Handlungsempfehlung. Der Berater gibt
## niemals eine fertige Loesung.
func _fill_advisor(box: VBoxContainer) -> void:
	_add_section(box, "UNTERNEHMENSBERATER")
	var analysis := Advisor.current_analysis
	if analysis.is_empty():
		box.add_child(_muted("Analyse läuft mit der Simulation."))
		return
	var findings: Array = analysis.get("findings", [])
	if findings.is_empty():
		box.add_child(_muted("Keine Auffälligkeiten. Das Unternehmen läuft sauber."))
	for finding in findings:
		box.add_child(_advisor_card(finding))


## Eine Beraterkarte.
func _advisor_card(finding: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(UI["surface_alt"], 4))

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 5)

	# Titel mit Schweregrad
	var severity := String(finding.get("severity", "info"))
	var title := Label.new()
	title.text = String(finding.get("title", ""))
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", {
		"critical": UI["danger"],
		"warning": UI["warning"],
	}.get(severity, UI["accent"]))
	v.add_child(title)

	# Die Analyse mit den Zahlen aus dem Betrieb
	var text := Label.new()
	text.text = String(finding.get("analysis", ""))
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", 11)
	text.add_theme_color_override("font_color", UI["text"])
	v.add_child(text)

	# Die Fragen: sie fuehren zum Nachdenken, statt die Antwort zu
	# verraten.
	var questions: Array = finding.get("questions", [])
	if not questions.is_empty():
		var q_label := Label.new()
		q_label.text = "Fragen zur Analyse"
		q_label.add_theme_font_size_override("font_size", 10)
		q_label.add_theme_color_override("font_color", UI["text_faint"])
		v.add_child(q_label)
		for question in questions:
			var q := Label.new()
			q.text = "• %s" % String(question)
			q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			q.add_theme_font_size_override("font_size", 11)
			q.add_theme_color_override("font_color", UI["text_muted"])
			v.add_child(q)

	# Die fachliche Lektion
	var lesson := String(finding.get("lesson", ""))
	if lesson != "":
		var l_label := Label.new()
		l_label.text = "→ %s" % lesson
		l_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l_label.add_theme_font_size_override("font_size", 11)
		l_label.add_theme_color_override("font_color", UI["accent"])
		v.add_child(l_label)

	# Die Handlungsempfehlung
	var action := String(finding.get("action", ""))
	if action != "":
		var a_label := Label.new()
		a_label.text = "↳ %s" % action
		a_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		a_label.add_theme_font_size_override("font_size", 11)
		a_label.add_theme_color_override("font_color", UI["text_faint"])
		v.add_child(a_label)

	panel.add_child(v)
	return panel


## Die Kennzahlenansicht.
##
## Zusaetzlich zur Renditestruktur wird die Du-Pont-Kette gezeigt:
## Umsatzrentabilitaet x Umschlag x Eigenkapitalquote = ROE. So ist
## erkennbar, WIE die Eigenkapitalrentabilitaet zustande kommt.
func _fill_stats(box: VBoxContainer) -> void:
	var eco := Simulation.economy

	_add_section(box, "RENTABILITAET")
	_add_metric(box, "Gesamtkapitalrendite", BWLEngine.format_pct(eco.roic_percent(), 1))
	_add_metric(box, "EK-Rentabilität", BWLEngine.format_pct(eco.roe_percent(), 1))

	# Du-Pont: ROE = Umsatzrentabilitaet x Umschlag x EK-Quote
	var margin := 0.0
	if eco.revenue_current_year > 0.0:
		margin = eco.profit_current_year / eco.revenue_current_year
	var turnover := 0.0
	if eco.total_assets() > 0.0:
		turnover = eco.revenue_current_year / eco.total_assets()
	var equity_ratio := 0.0
	if eco.total_assets() > 0.0:
		equity_ratio = eco.equity / eco.total_assets()
	_add_metric(box, "Umsatzrentabilität", BWLEngine.format_pct(margin * 100.0, 1))
	_add_metric(box, "Kapitalturnover", String.num(turnover, 2))
	_add_metric(box, "EK-Quote", BWLEngine.format_pct(equity_ratio * 100.0, 1))

	_add_section(box, "CASHFLOW")
	_add_metric(box, "Cashflow p.a.", BWLEngine.format_eur(eco.cash_flow(), 0))
	_add_metric(box, "AfA p.a.", BWLEngine.format_eur(eco.depreciation_year, 0))
	_add_metric(box, "Kalk. Zinsen p.a.", BWLEngine.format_eur(eco.imputed_interest_year, 0))
	_add_metric(box, "Zinsaufwand FK", BWLEngine.format_eur(eco.interest_paid_year, 0))
	_add_metric(box, "Tilgung p.a.", BWLEngine.format_eur(eco.repayment_year, 0))

	_add_section(box, "BETRIEB")
	_add_metric(box, "Auslastung", "%d %%" % int(Simulation.current_utilization()))
	_add_metric(box, "Forderungen", BWLEngine.format_eur(eco.receivables, 0))
	_add_metric(box, "Anlagevermögen", BWLEngine.format_eur(eco.fixed_assets, 0))
	_add_metric(box, "Liquiditätsgrad II", String.num(eco.liquidity_ratio(), 2))

	_add_section(box, "AUFTRÄGE")
	_add_metric(box, "Aufträge angenommen", "%d" % int(Simulation.stats.get("orders_received", 0)))
	_add_metric(box, "Aufträge erfüllt", "%d" % int(Simulation.stats.get("orders_completed", 0)))
	_add_metric(box, "Aufträge storniert", "%d" % int(Simulation.stats.get("orders_cancelled", 0)))
	_add_metric(box, "Maschinen im Betrieb", "%d" % Simulation.active_machines().size())


# ==================================================================
# Hilfsfunktionen
# ==================================================================

func _add_section(box: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.40, 0.45, 0.52))
	box.add_child(label)


func _add_metric(box: VBoxContainer, label_text: String, value_text: String) -> void:
	var row := HBoxContainer.new()
	var l := Label.new()
	l.text = label_text
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", 12)
	var v := Label.new()
	v.text = value_text
	v.add_theme_font_size_override("font_size", 13)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(l)
	row.add_child(v)
	box.add_child(row)


func _muted(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.45, 0.50, 0.57))
	return label


func _style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func _format_currency(value: float) -> String:
	return BWLEngine.format_eur(value, 0)
