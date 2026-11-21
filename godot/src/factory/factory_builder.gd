class_name FactoryBuilder
extends RefCounted

## Erzeugt die 3D-Geometrie des Betriebsgeländes.
##
## Bewusst *prozedural*: wenige, hochwertige Grundformen statt vieler
## minderwertiger Assets. Die Gebäude entstehen aus präzisen Volumen mit
## funktionaler Typologie (Produktionshalle, Lagerhalle, Ladezone, Büro,
## Straße) – erkennbar als Industrieanlage, aber ohne Cartoon-Look.
##
## Materialien: Stahl, Beton, Glas, gebrochenes Weiß, Akzent in
## Graphit/Blau. Warnfarben (Orange/Rot) nur für Statusanzeigen.

const COLORS := {
	"ground": Color(0.18, 0.19, 0.21),
	"ground_alt": Color(0.22, 0.23, 0.25),
	"asphalt": Color(0.13, 0.14, 0.16),
	"concrete": Color(0.62, 0.63, 0.64),
	"concrete_dark": Color(0.48, 0.49, 0.51),
	"steel": Color(0.42, 0.45, 0.49),
	"steel_light": Color(0.58, 0.61, 0.65),
	"panel": Color(0.75, 0.76, 0.78),
	"glass": Color(0.35, 0.52, 0.58, 0.55),
	"accent_blue": Color(0.29, 0.53, 0.60),
	# Kein Gold: die Signalfarben sind blau (Auswahl, in Bewegung) und
	# orange (Warnung, Arbeit). Gold ist nicht Teil der Palette.
	"signal_busy": Color(0.78, 0.52, 0.20),
	"roof": Color(0.30, 0.32, 0.35),
	"green": Color(0.28, 0.52, 0.36),
	"warning": Color(0.78, 0.42, 0.18),
	"marking": Color(0.85, 0.82, 0.55),
	# Neu: Gummi, Felgen, Holz, Hubzone
	"rubber": Color(0.07, 0.07, 0.08),
	"rim": Color(0.55, 0.57, 0.60),
	"wood": Color(0.46, 0.34, 0.22),
	"loading_zone": Color(0.34, 0.38, 0.42),
	"belt": Color(0.16, 0.17, 0.19),
	"hazard": Color(0.72, 0.56, 0.16),
}


## Baut die Grundformen. Räder, Zylinder und Rohre entstehen nicht
## aus Boxen – das ist der Unterschied zwischen einer Bauzeichnung
## und einer erkennbaren Maschine.
static func _cylinder(radius: float, height: float, position: Vector3, color: Color, roughness: float = 0.5) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	mesh.rings = 1
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = position
	mi.material_override = _material(color, roughness)
	return mi


## Ein Gummirad mit Felge.
static func _wheel(position: Vector3, radius: float = 0.45) -> Array:
	return [
		_cylinder(radius, radius * 0.55, position, COLORS["rubber"], 0.95),
		_cylinder(radius * 0.48, radius * 0.6, position, COLORS["rim"], 0.35),
	]


## Palettierstapel (Bretter auf einer Palette).
static func _pallet(position: Vector3, height: float = 1.0) -> Array:
	var parts: Array = []
	# Palette
	parts.append(_box(Vector3(1.2, 0.12, 0.8), position + Vector3(0, 0.06, 0), COLORS["wood"], 0.85))
	for i in range(3):
		var x := -0.45 + 0.45 * float(i)
		parts.append(_box(Vector3(0.18, 0.1, 0.8), position + Vector3(x, 0.15, 0), COLORS["wood"], 0.85))
	# Ware
	parts.append(_box(Vector3(1.05, height, 0.7), position + Vector3(0, 0.2 + height / 2.0, 0), COLORS["panel"], 0.7))
	return parts


## Gabelstapler: Mast, Gabeln, Kabine, Räder.
static func build_forklift() -> Array:
	var parts: Array = []
	# Fahrgestell
	parts.append(_box(Vector3(1.6, 0.55, 1.1), Vector3(0, 0.45, 0), COLORS["warning"], 0.5))
	# Kabine
	parts.append(_box(Vector3(0.8, 0.9, 1.0), Vector3(-0.35, 1.15, 0), COLORS["steel"], 0.45))
	# Schutzbügel
	parts.append(_box(Vector3(0.06, 1.1, 1.0), Vector3(0.0, 1.5, 0), COLORS["steel"], 0.5))
	parts.append(_box(Vector3(0.06, 1.1, 1.0), Vector3(-0.7, 1.5, 0), COLORS["steel"], 0.5))
	# Mast
	parts.append(_box(Vector3(0.12, 2.4, 0.1), Vector3(0.75, 1.2, -0.4), COLORS["steel"], 0.45))
	parts.append(_box(Vector3(0.12, 2.4, 0.1), Vector3(0.75, 1.2, 0.4), COLORS["steel"], 0.45))
	# Gabeln
	parts.append(_box(Vector3(1.1, 0.07, 0.16), Vector3(1.25, 0.18, -0.3), COLORS["rim"], 0.35))
	parts.append(_box(Vector3(1.1, 0.07, 0.16), Vector3(1.25, 0.18, 0.3), COLORS["rim"], 0.35))
	# Räder
	for wheel_part in _wheel(Vector3(0.5, 0.28, -0.58), 0.28):
		parts.append(wheel_part)
	for wheel_part in _wheel(Vector3(0.5, 0.28, 0.58), 0.28):
		parts.append(wheel_part)
	for wheel_part in _wheel(Vector3(-0.65, 0.22, -0.5), 0.22):
		parts.append(wheel_part)
	for wheel_part in _wheel(Vector3(-0.65, 0.22, 0.5), 0.22):
		parts.append(wheel_part)
	return parts


## Förderband: Rahmen, Rollen, Band, Stützen, Ware.
static func build_conveyor(length: float = 6.0, width: float = 0.8) -> Array:
	var parts: Array = []
	# Band
	parts.append(_box(Vector3(length, 0.08, width), Vector3(0, 0.85, 0), COLORS["belt"], 0.8))
	# Seitenholme
	parts.append(_box(Vector3(length, 0.16, 0.06), Vector3(0, 0.9, -width / 2.0 - 0.05), COLORS["steel"], 0.45))
	parts.append(_box(Vector3(length, 0.16, 0.06), Vector3(0, 0.9, width / 2.0 + 0.05), COLORS["steel"], 0.45))
	# Rollen
	var rollers := int(length / 0.5)
	for i in range(rollers + 1):
		var x := -length / 2.0 + (length / float(maxi(rollers, 1))) * float(i)
		parts.append(_cylinder(width * 0.45, width, Vector3(x, 0.82, 0), COLORS["rim"], 0.3))
	# Stützen
	var legs := int(length / 3.0)
	for i in range(legs + 1):
		var x := -length / 2.0 + (length / float(maxi(legs, 1))) * float(i)
		parts.append(_box(Vector3(0.1, 0.8, 0.1), Vector3(x, 0.4, -width / 2.0), COLORS["steel"], 0.5))
		parts.append(_box(Vector3(0.1, 0.8, 0.1), Vector3(x, 0.4, width / 2.0), COLORS["steel"], 0.5))
	# Ware auf dem Band
	parts.append(_box(Vector3(0.7, 0.5, width * 0.7), Vector3(length * 0.15, 1.15, 0), COLORS["panel"], 0.7))
	return parts


## Ladezone: markierte Fläche mit Bodenmarkierung und Torebene.
##
## Die Zone ist der sichtbare Übergang vom LKW zur Anlage – sie macht
## die Lieferkette räumlich lesbar.
static func build_loading_zone(size: Vector2 = Vector2(7.0, 5.0)) -> Array:
	var parts: Array = []
	# Bodenplatte
	parts.append(_box(Vector3(size.x, 0.06, size.y), Vector3(0, 0.03, 0), COLORS["loading_zone"], 0.9))
	# Warnmarkierung (schraeg gestreift als Einzelquadrate)
	var stripe_count := int(size.x / 0.8)
	for i in range(stripe_count):
		var x := -size.x / 2.0 + 0.4 + 0.8 * float(i)
		parts.append(_box(Vector3(0.35, 0.03, size.y * 0.9), Vector3(x, 0.08, 0), COLORS["hazard"], 0.85))
	# Ladekante
	parts.append(_box(Vector3(size.x, 0.18, 0.3), Vector3(0, 0.09, size.y / 2.0), COLORS["warning"], 0.6))
	return parts


## Hochregallager: Ständer, Regale, Paletten.
static func build_racking(height: float = 4.0, bays: int = 3) -> Array:
	var parts: Array = []
	var bay_width := 2.4
	var total := bay_width * float(bays)
	for i in range(bays + 1):
		var x := -total / 2.0 + bay_width * float(i)
		for z in [-0.6, 0.6]:
			parts.append(_box(Vector3(0.12, height, 0.12), Vector3(x, height / 2.0, z), COLORS["steel"], 0.45))
	# Querträger und Ebenen
	for level in range(3):
		var y := 0.6 + 1.2 * float(level)
		for z in [-0.6, 0.6]:
			parts.append(_box(Vector3(total, 0.1, 0.08), Vector3(0, y, z), COLORS["warning"], 0.55))
		# Paletten auf den Ebenen
		for i in range(bays):
			var x := -total / 2.0 + bay_width * (float(i) + 0.5)
			if level < 2:
				for pallet_part in _pallet(Vector3(x, y + 0.05, 0), 0.7):
					parts.append(pallet_part)
	return parts


## Erzeugt das Gelände-Mesh (Boden, Straßen, Zonen-Markierungen).
static func build_ground(grid: FactoryGrid) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	var size := Vector3(
		grid.width * FactoryGrid.TILE_SIZE,
		0.4,
		grid.height * FactoryGrid.TILE_SIZE
	)
	mesh.size = size

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.name = "Gelände"
	mi.position = Vector3(0, -0.2, 0)
	mi.material_override = _material(COLORS["ground"], 0.85)

	return mi


## Erzeugt eine Straße (langgestreckter Asphaltstreifen mit Markierungen).
static func build_road(from: Vector3, to: Vector3, width: float = 4.0) -> Array:
	var result: Array = []
	var length := Vector2(to.x - from.x, to.z - from.z).length()
	if length < 0.1:
		return result

	# Mittelmarkierung
	var steps := int(length / 3.0)
	for i in range(steps):
		var t := (float(i) + 0.5) / float(maxi(steps, 1))
		var pos: Vector3 = from.lerp(to, t)
		var dash := BoxMesh.new()
		dash.size = Vector3(0.35, 0.03, 1.4)
		var mi := MeshInstance3D.new()
		mi.mesh = dash
		mi.position = Vector3(pos.x, 0.03, pos.z)
		mi.rotation.y = atan2(to.z - from.z, to.x - from.x)
		mi.material_override = _material(COLORS["marking"], 0.9)
		result.append(mi)
	return result


## Produktionshalle: klare Stahl-Konstruktion mit Sheddach und Toren.
static func build_production_hall(width: float, depth: float, height: float) -> Array:
	var parts: Array = []

	# Sockel
	parts.append(_box(Vector3(width, 0.5, depth), Vector3(0, 0.25, 0), COLORS["concrete_dark"], 0.9))

	# Wände
	parts.append(_box(Vector3(width, height, 0.4), Vector3(0, height / 2.0 + 0.5, -depth / 2.0), COLORS["panel"], 0.75))
	parts.append(_box(Vector3(width, height, 0.4), Vector3(0, height / 2.0 + 0.5, depth / 2.0), COLORS["panel"], 0.75))
	parts.append(_box(Vector3(0.4, height, depth), Vector3(-width / 2.0, height / 2.0 + 0.5, 0), COLORS["panel"], 0.75))
	parts.append(_box(Vector3(0.4, height, depth), Vector3(width / 2.0, height / 2.0 + 0.5, 0), COLORS["panel"], 0.75))

	# Stahlstreben (vertikal, akzentuiert)
	var posts := int(width / 4.0)
	for i in range(posts + 1):
		var x := -width / 2.0 + (width / float(posts)) * float(i)
		parts.append(_box(Vector3(0.25, height, 0.25), Vector3(x, height / 2.0 + 0.5, depth / 2.0 + 0.2), COLORS["steel"], 0.5))

	# Sheddach (drei Segmente)
	var seg := depth / 3.0
	for i in range(3):
		var h := height + 0.5 + (0.9 if i == 1 else 0.0)
		parts.append(_box(
			Vector3(width, 0.25, seg),
			Vector3(0, h, -depth / 2.0 + seg * (float(i) + 0.5)),
			COLORS["roof"], 0.4
		))

	# Rolltore
	for i in range(2):
		var x := -width / 4.0 + width / 2.0 * float(i)
		parts.append(_box(Vector3(width / 3.0, height * 0.55, 0.12), Vector3(x, height * 0.275 + 0.5, depth / 2.0 + 0.25), COLORS["steel_light"], 0.35))

	# Fensterband
	parts.append(_box(Vector3(width * 0.92, 0.7, 0.1), Vector3(0, height * 0.82 + 0.5, -depth / 2.0 - 0.22), COLORS["glass"], 0.2))

	return parts


## Lagerhalle: flacher Baukörper mit Ladebuchten und Rampe.
static func build_storage_hall(width: float, depth: float, height: float) -> Array:
	var parts: Array = []
	parts.append(_box(Vector3(width, height, depth), Vector3(0, height / 2.0, 0), COLORS["panel"], 0.8))
	parts.append(_box(Vector3(width + 0.6, 0.3, depth + 0.6), Vector3(0, height + 0.15, 0), COLORS["roof"], 0.4))
	# Ladebuchten
	for i in range(3):
		var x := -width / 3.0 + width / 3.0 * float(i)
		parts.append(_box(Vector3(width / 5.0, height * 0.35, 0.15), Vector3(x, height * 0.175 + 0.5, depth / 2.0 + 0.1), COLORS["steel"], 0.4))
	# Rampe
	parts.append(_box(Vector3(width * 0.9, 0.25, 2.2), Vector3(0, 0.35, depth / 2.0 + 1.3), COLORS["concrete"], 0.9))
	return parts


## Bürogebäude: Glasfassade, schlanke Proportionen.
static func build_office(width: float, depth: float, height: float) -> Array:
	var parts: Array = []
	parts.append(_box(Vector3(width, height, depth), Vector3(0, height / 2.0, 0), COLORS["glass"], 0.25))
	# Rahmen
	parts.append(_box(Vector3(width + 0.3, 0.3, depth + 0.3), Vector3(0, height, 0), COLORS["steel"], 0.5))
	parts.append(_box(Vector3(width + 0.3, 0.3, depth + 0.3), Vector3(0, 0.15, 0), COLORS["concrete_dark"], 0.9))
	# vertikale Pfosten
	for i in range(4):
		var x := -width / 2.0 + width / 3.0 * float(i)
		parts.append(_box(Vector3(0.18, height, 0.18), Vector3(x, height / 2.0, depth / 2.0 + 0.1), COLORS["steel"], 0.5))
	return parts


## Produktionsmaschine: Typologie erkennbar, funktionale Form.
##
## Aufbau: Grundrahmen, Maschinenblock, Oberaggregat mit Tank und
## Rohren, Bedienpult, Schutzzaun, Statusleuchte und Auslastungsanzeige.
static func build_machine(
	spec: MachineSpec, state: int, utilization: float, material_short: bool = false
) -> Array:
	var parts: Array = []
	var w := 3.2
	var d := 2.4

	# Fundament
	parts.append(_box(Vector3(w + 0.8, 0.25, d + 0.8), Vector3(0, 0.125, 0), COLORS["concrete_dark"], 0.9))

	# Maschinenblock
	parts.append(_box(Vector3(w, 1.6, d), Vector3(0, 1.05, 0), COLORS["steel_light"], 0.35))

	# Oberer Aggregatblock
	parts.append(_box(Vector3(w * 0.7, 0.7, d * 0.8), Vector3(-w * 0.1, 2.2, 0), COLORS["steel"], 0.3))

	# Prozessbehälter (Zylinder) auf dem Aggregat
	parts.append(_cylinder(0.42, 1.0, Vector3(-w * 0.25, 3.0, 0), COLORS["rim"], 0.3))
	parts.append(_cylinder(0.46, 0.12, Vector3(-w * 0.25, 3.52, 0), COLORS["steel"], 0.35))

	# Rohrleitungen: waagerecht und senkrecht
	parts.append(_cylinder(0.09, 1.5, Vector3(w * 0.22, 2.3, -d * 0.3), COLORS["rim"], 0.3))
	parts.append(_cylinder(0.09, 1.2, Vector3(w * 0.22, 2.9, -d * 0.3), COLORS["rim"], 0.3))

	# Bedienpult mit Blendung
	parts.append(_box(Vector3(0.7, 1.1, 0.5), Vector3(w / 2.0 + 0.45, 0.8, 0.4), COLORS["accent_blue"], 0.4))
	parts.append(_box(Vector3(0.5, 0.32, 0.06), Vector3(w / 2.0 + 0.42, 1.3, 0.66), COLORS["glass"], 0.2))

	# Schutzzaun (Pfosten + Holm)
	for i in range(4):
		var sx := -w / 2.0 + w / 3.0 * float(i)
		parts.append(_box(Vector3(0.08, 1.1, 0.08), Vector3(sx, 0.55, d / 2.0 + 0.7), COLORS["warning"], 0.6))
	parts.append(_box(Vector3(w, 0.08, 0.08), Vector3(0, 1.05, d / 2.0 + 0.7), COLORS["warning"], 0.6))

	# Statusleuchte: Farbe = Betriebszustand
	#
	# Der Zustand UNLOADING wird bewusst getrennt von ARRIVED
	# dargestellt: Entladen ist ein eigener Arbeitsschritt.
	var status_color := COLORS["green"]
	if state == MachineInstance.State.ORDERED:
		status_color = COLORS["steel_light"]
	elif state == MachineInstance.State.IN_TRANSIT:
		status_color = COLORS["signal_busy"]
	elif state == MachineInstance.State.ARRIVED:
		status_color = COLORS["signal_busy"]
	elif state == MachineInstance.State.UNLOADING:
		status_color = COLORS["warning"]
	elif state == MachineInstance.State.INSTALLING:
		status_color = COLORS["warning"]
	elif state == MachineInstance.State.DECOMMISSIONED:
		status_color = COLORS["concrete_dark"]

	# Materialengpass: Die Anlage steht, ist aber betriebsbereit
	# installiert. Die Leuchte zeigt rot, damit der Grund auf dem
	# Gelände sofort sichtbar ist - nicht erst in der Seitenleiste.
	if material_short and state == MachineInstance.State.ACTIVE:
		status_color = COLORS["warning"]

	# Signalmast
	parts.append(_cylinder(0.05, 0.8, Vector3(w / 2.0 - 0.2, 2.2, -d / 2.0 + 0.2), COLORS["steel"], 0.45))
	parts.append(_box(Vector3(0.18, 0.18, 0.18), Vector3(w / 2.0 - 0.2, 2.68, -d / 2.0 + 0.2), status_color, 0.3))

	# Auslastungsanzeige: farbiger Balken an der Maschine
	var fill := clampf(utilization / 100.0, 0.0, 1.0)
	if fill > 0.0:
		var bar_color := COLORS["green"] if fill < 0.7 else COLORS["signal_busy"]
		if fill >= 0.95:
			bar_color = COLORS["warning"]
		parts.append(_box(
			Vector3(w * fill, 0.12, 0.12),
			Vector3(-w / 2.0 + (w * fill) / 2.0, 1.75, d / 2.0 + 0.05),
			bar_color, 0.3
		))
		# Träger der Anzeige
		parts.append(_box(
			Vector3(w, 0.06, 0.06),
			Vector3(0, 1.72, d / 2.0 + 0.05),
			COLORS["steel"], 0.4
		))

	# Transportrahmen: in der Anlieferung liegt die Maschine noch auf
	# einem Rahmen. Im Betrieb verschwindet er.
	if state == MachineInstance.State.ORDERED or state == MachineInstance.State.IN_TRANSIT:
		parts.append(_box(Vector3(w + 0.5, 0.16, d + 0.5), Vector3(0, 0.05, 0), COLORS["wood"], 0.85))

	return parts


## LKW: Fahrerhaus, Aufbau, Räder. Für die Anlieferungs-Animation.
##
## Die Räder sind echte Zylinder mit Felge – eine LKW-Silhouette aus
## Boxen wirkt nicht wie ein LKW.
static func build_truck() -> Array:
	var parts: Array = []
	# Fahrerhaus
	parts.append(_box(Vector3(2.0, 1.5, 2.2), Vector3(1.6, 1.1, 0), COLORS["accent_blue"], 0.4))
	# Windschutzscheibe
	parts.append(_box(Vector3(0.08, 0.6, 1.9), Vector3(2.55, 1.5, 0), COLORS["glass"], 0.2))
	# Fenster seitlich
	parts.append(_box(Vector3(1.1, 0.5, 0.06), Vector3(1.7, 1.45, 1.12), COLORS["glass"], 0.2))
	parts.append(_box(Vector3(1.1, 0.5, 0.06), Vector3(1.7, 1.45, -1.12), COLORS["glass"], 0.2))
	# Sonnenblende
	parts.append(_box(Vector3(0.25, 0.3, 2.1), Vector3(2.62, 1.95, 0), COLORS["steel"], 0.4))
	# Aufladung (Container)
	parts.append(_box(Vector3(4.2, 1.6, 2.3), Vector3(-1.2, 1.15, 0), COLORS["panel"], 0.75))
	# Containerrippen
	for i in range(5):
		var x := -3.0 + 0.85 * float(i)
		parts.append(_box(Vector3(0.06, 1.5, 2.34), Vector3(x, 1.15, 0), COLORS["steel_light"], 0.5))
	# Ladefläche
	parts.append(_box(Vector3(4.4, 0.12, 2.4), Vector3(-1.2, 0.42, 0), COLORS["steel"], 0.4))
	# Stirnblende des Aufliegers
	parts.append(_box(Vector3(0.08, 1.6, 2.3), Vector3(-3.28, 1.15, 0), COLORS["steel_light"], 0.5))
	# Räder
	for i in range(3):
		var x := 1.7 - float(i) * 1.9
		for z in [-1.15, 1.15]:
			for wheel_part in _wheel(Vector3(x, 0.45, z), 0.45):
				parts.append(wheel_part)
	# Radkästen
	parts.append(_box(Vector3(1.3, 0.18, 0.12), Vector3(1.7, 0.62, -1.18), COLORS["steel"], 0.5))
	parts.append(_box(Vector3(1.3, 0.18, 0.12), Vector3(1.7, 0.62, 1.18), COLORS["steel"], 0.5))
	# Auspuff
	parts.append(_cylinder(0.09, 1.1, Vector3(2.45, 1.9, -0.85), COLORS["rim"], 0.4))
	return parts


## Container / Maschine in der Lieferung.
static func build_cargo() -> Array:
	return [
		_box(Vector3(2.6, 1.4, 1.4), Vector3(0, 0.7, 0), COLORS["steel_light"], 0.35),
		_box(Vector3(2.7, 0.1, 1.5), Vector3(0, 1.45, 0), COLORS["steel"], 0.4),
	]


# ==================================================================
# Hilfsfunktionen
# ==================================================================

static func _box(size: Vector3, position: Vector3, color: Color, roughness: float) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = position
	mi.material_override = _material(color, roughness)
	return mi


static func _material(color: Color, roughness: float = 0.6) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	# Metallische Oberflächen sind bei dunkleren, kühleren Farben
	# stärker metallisch. Gummi und Holz sind es nicht.
	if color.r > 0.4 and color.b > 0.35:
		mat.metallic = 0.05
	elif color.r < 0.12:
		mat.metallic = 0.0
		mat.roughness = maxf(roughness, 0.85)
	else:
		mat.metallic = 0.35
	# Glas ist transparent und glatt.
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.metallic = 0.1
		mat.roughness = 0.15
	return mat
