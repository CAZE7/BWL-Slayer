class_name FactoryView
extends Node3D

## Die 3D-Ansicht des Betriebsgeländes.
##
## Bindet die Simulationsdaten an die Darstellung: Maschinen werden an
## ihren Positionen erzeugt, Lieferungen fahren mit dem LKW über das
## Gelände, Gebäude werden bei Bedarf angelegt.
##
## Wichtig: Die Darstellung liest nur aus der Simulation und schreibt
## niemals direkt in die Wirtschaftsdaten. Alle wirtschaftlichen Folgen
## entstehen in `Simulation`, nicht hier.

const TRUCK_SPEED := 9.0  ## Meter pro Sekunde

var grid: FactoryGrid
var camera_rig: CameraRig

var _machine_nodes: Dictionary = {}   ## instance_id -> Node3D
var _delivery_nodes: Dictionary = {}  ## instance_id -> {truck, cargo, path}
var _building_nodes: Dictionary = {}
var _environment: WorldEnvironment
var _sun: DirectionalLight3D
var _selection_marker: MeshInstance3D


func _ready() -> void:
	_build_environment()
	_build_selection_marker()


func setup(p_grid: FactoryGrid) -> void:
	grid = p_grid
	_build_ground()
	_build_roads()
	_build_base_buildings()


# ==================================================================
# Umgebung
# ==================================================================

func _build_environment() -> void:
	_environment = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	# Ueblicher Industriesommer: kühler Himmel, warmer Horizont.
	sky_material.sky_top_color = Color(0.26, 0.34, 0.44)
	sky_material.sky_horizon_color = Color(0.62, 0.66, 0.70)
	sky_material.ground_bottom_color = Color(0.13, 0.14, 0.16)
	sky_material.ground_horizon_color = Color(0.42, 0.44, 0.46)
	sky_material.sun_angle_max = 18.0
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 1.0
	env.ambient_light_energy = 0.85
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0
	env.tonemap_white = 6.0
	# Weiche Kontakt-Schatten: sie geben den Gebaeuden und Maschinen
	# die Plastik, die einen Blockout als Raum lesbar macht.
	env.ssao_enabled = true
	env.ssao_intensity = 1.8
	env.ssao_radius = 1.4
	env.ssao_bias = 0.02
	env.ssil_enabled = true
	env.ssil_intensity = 1.2
	# Dezenter Dunst fuer Tiefenwirkung, nicht fuer Effekthasch.
	env.fog_enabled = true
	env.fog_light_color = Color(0.52, 0.56, 0.62)
	env.fog_density = 0.0035
	env.fog_sky_affect = 0.35
	_environment.environment = env
	add_child(_environment)

	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-48.0, -34.0, 0.0)
	_sun.light_energy = 1.35
	_sun.light_color = Color(1.0, 0.97, 0.92)
	_sun.shadow_enabled = true
	_sun.directional_shadow_max_distance = 140.0
	_sun.directional_shadow_blend_splits = true
	_sun.shadow_bias = 0.04
	add_child(_sun)

	# Weiche Aufhellung von der Gegenseite: damit die Schattenseiten
	# nicht absaufen und die Stahlflächen lesbar bleiben.
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-24.0, 142.0, 0.0)
	fill.light_energy = 0.28
	fill.light_color = Color(0.78, 0.84, 0.94)
	fill.shadow_enabled = false
	add_child(fill)


func _build_selection_marker() -> void:
	_selection_marker = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 1.6
	torus.outer_radius = 1.8
	torus.rings = 24
	torus.ring_segments = 8
	_selection_marker.mesh = torus
	_selection_marker.visible = false
	var mat := StandardMaterial3D.new()
	mat.albedo_color = FactoryBuilder.COLORS["accent_blue"]
	mat.emission_enabled = true
	mat.emission = FactoryBuilder.COLORS["accent_blue"]
	mat.emission_energy_multiplier = 0.6
	_selection_marker.material_override = mat
	add_child(_selection_marker)


# ==================================================================
# Gelände
# ==================================================================

func _build_ground() -> void:
	var ground := FactoryBuilder.build_ground(grid)
	add_child(ground)


func _build_roads() -> void:
	var half_w := grid.width * FactoryGrid.TILE_SIZE * 0.5
	var half_h := grid.height * FactoryGrid.TILE_SIZE * 0.5
	# Hauptstraße entlang der Südseite
	for part in FactoryBuilder.build_road(
		Vector3(-half_w, 0, half_h - 8.0),
		Vector3(half_w, 0, half_h - 8.0), 5.0
	):
		add_child(part)
	# Zufahrt vom Westen
	for part in FactoryBuilder.build_road(
		Vector3(-half_w + 8.0, 0, -half_h),
		Vector3(-half_w + 8.0, 0, half_h - 8.0), 4.0
	):
		add_child(part)


func _build_base_buildings() -> void:
	# Bürogebäude (feste Position, Nordwest)
	var office_pos := grid.cell_to_world(2, 2)
	var office := Node3D.new()
	office.name = "Buero"
	office.position = office_pos
	for part in FactoryBuilder.build_office(14.0, 9.0, 7.0):
		office.add_child(part)
	add_child(office)
	_building_nodes["Buero"] = office

	# Lagerhalle (Nordost)
	var storage_pos := grid.cell_to_world(17, 2)
	var storage := Node3D.new()
	storage.name = "Lager"
	storage.position = storage_pos
	for part in FactoryBuilder.build_storage_hall(16.0, 12.0, 5.5):
		storage.add_child(part)
	add_child(storage)
	_building_nodes["Lager"] = storage

	# Produktionshalle (Mitte)
	var hall_pos := grid.cell_to_world(9, 7)
	var hall := Node3D.new()
	hall.name = "Produktionshalle"
	hall.position = hall_pos
	for part in FactoryBuilder.build_production_hall(22.0, 16.0, 7.0):
		hall.add_child(part)
	add_child(hall)
	_building_nodes["Produktionshalle"] = hall

	# Ladezone vor der Produktionshalle: der sichtbare Uebergang
	# vom LKW zur Anlage. Hier wird entladen und montiert.
	var zone_pos := grid.cell_to_world(9, 13)
	var zone := Node3D.new()
	zone.name = "Ladezone"
	zone.position = zone_pos
	for part in FactoryBuilder.build_loading_zone(Vector2(9.0, 6.0)):
		zone.add_child(part)
	add_child(zone)
	_building_nodes["Ladezone"] = zone

	# Foerderband: verbindet die Ladezone mit der Produktionshalle.
	var belt_pos := grid.cell_to_world(13, 10)
	var belt := Node3D.new()
	belt.name = "Foerderband"
	belt.position = belt_pos
	for part in FactoryBuilder.build_conveyor(10.0, 0.9):
		belt.add_child(part)
	add_child(belt)
	_building_nodes["Foerderband"] = belt

	# Hochregallager an der Lagerhalle
	var rack_pos := grid.cell_to_world(15, 5)
	var rack := Node3D.new()
	rack.name = "Hochregallager"
	rack.position = rack_pos
	for part in FactoryBuilder.build_racking(4.5, 3):
		rack.add_child(part)
	add_child(rack)
	_building_nodes["Hochregallager"] = rack

	# Gabelstapler an der Lagerhalle
	var forklift_pos := grid.cell_to_world(14, 7)
	var forklift := Node3D.new()
	forklift.name = "Gabelstapler"
	forklift.position = forklift_pos
	forklift.rotation.y = PI * 0.5
	for part in FactoryBuilder.build_forklift():
		forklift.add_child(part)
	add_child(forklift)
	_building_nodes["Gabelstapler"] = forklift


# ==================================================================
# Maschinen
# ==================================================================

## Synchronisiert die Maschinen-Darstellung mit der Simulation.
func sync_machines() -> void:
	if Simulation == null:
		return
	for instance_id in Simulation.machines:
		var instance: MachineInstance = Simulation.machines[instance_id]
		if not _machine_nodes.has(instance_id):
			_create_machine_node(instance)
			continue
		# Das Visual wird nur neu aufgebaut, wenn sich etwas geaendert
		# hat, das sichtbar ist: der Zustand der Lieferkette oder die
		# Auslastung. Sonst wuerde jedes Bild die Szene neu aufbauen.
		var node: Node3D = _machine_nodes[instance_id]
		var last_state := int(node.get_meta("state", -1))
		var last_fill := float(node.get_meta("fill", -1.0))
		var fill := instance.spec.utilization_at(instance.quantity_this_year)
		if last_state != instance.state or absf(last_fill - fill) > 0.005:
			update_machine_visual(instance_id)
	# Entfernte Maschinen entfernen
	for node_id in _machine_nodes.keys():
		if not Simulation.machines.has(node_id):
			var node: Node3D = _machine_nodes[node_id]
			node.queue_free()
			_machine_nodes.erase(node_id)


func _create_machine_node(instance: MachineInstance) -> void:
	var root := Node3D.new()
	root.name = instance.instance_id
	root.position = instance.position

	# Maschinenvisual
	var fill := instance.spec.utilization_at(instance.quantity_this_year)
	for part in FactoryBuilder.build_machine(instance.spec, instance.state, fill):
		root.add_child(part)

	# Merkwerte fuer die Aktualisierung: die Szene wird nur neu
	# aufgebaut, wenn sich der Zustand oder die Auslastung aendert.
	root.set_meta("state", instance.state)
	root.set_meta("fill", fill)

	# Statusanzeige / Auslastung
	var label := Label3D.new()
	label.text = instance.spec.display_name
	label.font_size = 48
	label.pixel_size = 0.006
	label.position = Vector3(0, 3.4, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(0.85, 0.88, 0.92)
	label.no_depth_test = true
	root.add_child(label)

	add_child(root)
	_machine_nodes[instance.instance_id] = root


## Aktualisiert das Visual einer Maschine.
##
## Das Visual wird vollstaendig neu aufgebaut. Das ist einfacher als
## eine inkrementelle Aktualisierung einzelner Teile und wird nur
## aufgerufen, wenn sich der Zustand oder die Auslastung tatsaechlich
## geaendert hat.
func update_machine_visual(instance_id: String) -> void:
	var node: Node3D = _machine_nodes.get(instance_id)
	if node == null:
		return
	var instance: MachineInstance = Simulation.machines.get(instance_id)
	if instance == null:
		return
	node.queue_free()
	_machine_nodes.erase(instance_id)
	_create_machine_node(instance)


# ==================================================================
# Lieferungen & LKW
# ==================================================================

## Synchronisiert die Lieferungen (LKW-Fahrten).
func sync_deliveries(delta: float) -> void:
	if Simulation == null:
		return
	for delivery in Simulation.deliveries:
		var instance_id := String(delivery.get("instance_id", ""))
		var instance: MachineInstance = Simulation.machines.get(instance_id)
		if instance == null:
			continue
		if instance.state == MachineInstance.State.ORDERED:
			_spawn_truck(instance_id, instance)
		elif instance.state == MachineInstance.State.IN_TRANSIT:
			_drive_truck(instance_id, instance, delivery, delta)
		else:
			_remove_truck(instance_id)


func _spawn_truck(instance_id: String, instance: MachineInstance) -> void:
	if _delivery_nodes.has(instance_id):
		return
	var truck_root := Node3D.new()
	truck_root.name = "LKW_" + instance_id
	for part in FactoryBuilder.build_truck():
		truck_root.add_child(part)

	# Startposition: Einfahrt am westlichen Rand
	var half_w := grid.width * FactoryGrid.TILE_SIZE * 0.5
	var half_h := grid.height * FactoryGrid.TILE_SIZE * 0.5
	truck_root.position = Vector3(-half_w - 14.0, 0, half_h - 8.0)
	truck_root.rotation.y = PI / 2.0

	add_child(truck_root)
	_delivery_nodes[instance_id] = {
		"truck": truck_root,
		"phase": "ordered",
	}


func _drive_truck(instance_id: String, instance: MachineInstance, delivery: Dictionary, delta: float) -> void:
	var entry = _delivery_nodes.get(instance_id)
	if entry == null:
		_spawn_truck(instance_id, instance)
		return
	var truck: Node3D = entry["truck"]

	# Der LKW folgt der Hauptstrasse am suedlichen Rand und haelt
	# anschliessend an der Ladezone. Er faehrt nicht diagonal ueber
	# das Gelande – das sieht unmoeglich aus.
	var half_h := grid.height * FactoryGrid.TILE_SIZE * 0.5
	var road_z := half_h - 8.0
	var zone_x := grid.cell_to_world(9, 13).x

	# Zielphase 1: an der Hauptstrasse bis zur Ladezone.
	if absf(truck.position.z - road_z) > 0.6 or truck.position.x < zone_x - 1.0:
		var to_road := Vector3(0.0, 0.0, road_z - truck.position.z)
		if absf(to_road.z) > 0.05:
			truck.rotation.y = lerp_angle(truck.rotation.y, 0.0 if to_road.z > 0.0 else PI, clampf(delta * 3.0, 0.0, 1.0))
		truck.position += to_road.normalized() * TRUCK_SPEED * delta
		entry["phase"] = "transit"
		return

	# Zielphase 2: in die Ladezone einfahren.
	var stop := Vector3(zone_x, 0.0, grid.cell_to_world(9, 13).z)
	var to_stop := stop - truck.position
	to_stop.y = 0.0

	if to_stop.length() < TRUCK_SPEED * delta:
		truck.position = stop
		# Ausrichtung zur Maschine
		var dx := instance.position.x - truck.position.x
		var dz := instance.position.z - truck.position.z
		if absf(dx) > 0.01 or absf(dz) > 0.01:
			truck.rotation.y = lerp_angle(truck.rotation.y, atan2(dz, dx), clampf(delta * 3.0, 0.0, 1.0))
	else:
		truck.position += to_stop.normalized() * TRUCK_SPEED * delta
		var dx := to_stop.x
		var dz := to_stop.z
		if absf(dx) > 0.01 or absf(dz) > 0.01:
			truck.rotation.y = lerp_angle(truck.rotation.y, atan2(dz, dx), clampf(delta * 3.0, 0.0, 1.0))

	entry["phase"] = "transit"


func _remove_truck(instance_id: String) -> void:
	var entry = _delivery_nodes.get(instance_id)
	if entry == null:
		return
	var truck: Node3D = entry["truck"]
	if is_instance_valid(truck):
		truck.queue_free()
	_delivery_nodes.erase(instance_id)


# ==================================================================
# Auswahl
# ==================================================================

## Wählt ein Objekt aus (Puls-Ring).
func select_at(world_point: Vector3) -> void:
	_selection_marker.visible = true
	_selection_marker.global_position = Vector3(world_point.x, 0.3, world_point.z)


func clear_selection() -> void:
	_selection_marker.visible = false


## Die Maschine an einer Weltposition (für Klick-Auswahl).
func machine_at(world_point: Vector3) -> String:
	var best := ""
	var best_dist := 4.0
	for instance_id in _machine_nodes:
		var node: Node3D = _machine_nodes[instance_id]
		var d := Vector2(node.position.x - world_point.x, node.position.z - world_point.z).length()
		if d < best_dist:
			best_dist = d
			best = instance_id
	return best
