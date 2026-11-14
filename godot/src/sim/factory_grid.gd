class_name FactoryGrid
extends RefCounted

## Das Betriebsgelände: Grundstück, Raster, Zonen und Belegung.
##
## Das Gelände ist kein Hintergrundbild, sondern eine echte Ressource:
## Fläche ist begrenzt, Zonen haben Regeln, Gebäude belegen Rasterzellen.

const TILE_SIZE := 4.0  ## Meter pro Rasterzelle

enum Zone {
	PRODUCTION,  ## Produktionshallen & Maschinen
	STORAGE,     ## Lagerhallen
	LOGISTICS,   ## Ladezonen, Straßen, Anlieferung
	OFFICE,      ## Bürogebäude
	GREEN,       ## Erweiterungsfläche (Brachland)
}

const ZONE_NAMES := {
	Zone.PRODUCTION: "Produktion",
	Zone.STORAGE: "Lager",
	Zone.LOGISTICS: "Logistik",
	Zone.OFFICE: "Büro",
	Zone.GREEN: "Erweiterungsfläche",
}

var width: int = 24
var height: int = 18
## 2D-Array: Zone pro Zelle
var zones: Array = []
## Belegte Zellen pro Zone-Zelle: leer = frei
var occupied: Dictionary = {}
## Gebäude-Instanzen: id -> {type, position, footprint, ...}
var buildings: Dictionary = {}


func _init(p_width: int = 24, p_height: int = 18) -> void:
	width = p_width
	height = p_height
	zones = []
	for y in height:
		var row: Array = []
		for x in width:
			row.append(Zone.GREEN)
		zones.append(row)


## Weltkoordinate einer Rasterzelle (Zentrum).
func cell_to_world(cx: int, cz: int) -> Vector3:
	return Vector3((cx - width * 0.5) * TILE_SIZE, 0.0, (cz - height * 0.5) * TILE_SIZE)


## Rasterzelle zu einer Weltkoordinate.
func world_to_cell(world: Vector3) -> Vector2i:
	return Vector2i(
		int(round(world.x / TILE_SIZE + width * 0.5)),
		int(round(world.z / TILE_SIZE + height * 0.5))
	)


func in_bounds(cx: int, cz: int) -> bool:
	return cx >= 0 and cz >= 0 and cx < width and cz < height


func zone_at(cx: int, cz: int) -> int:
	if not in_bounds(cx, cz):
		return Zone.GREEN
	return zones[cz][cx]


func set_zone(cx: int, cz: int, zone: int) -> void:
	if in_bounds(cx, cz):
		zones[cz][cx] = zone


## Markiert eine rechteckige Fläche als Produktionszone.
func set_production_area(origin_x: int, origin_z: int, w: int, h: int) -> void:
	for z in range(origin_z, origin_z + h):
		for x in range(origin_x, origin_x + w):
			set_zone(x, z, Zone.PRODUCTION)


## Markiert eine rechteckige Fläche als Lagerzone.
func set_storage_area(origin_x: int, origin_z: int, w: int, h: int) -> void:
	for z in range(origin_z, origin_z + h):
		for x in range(origin_x, origin_x + w):
			set_zone(x, z, Zone.STORAGE)


## Markiert die Logistik-Infrastruktur (Straßen, Ladezonen).
func set_logistics_infrastructure() -> void:
	# Straße entlang der Südseite
	for x in width:
		set_zone(x, height - 2, Zone.LOGISTICS)
		set_zone(x, height - 1, Zone.LOGISTICS)
	# Zufahrt vom Westen
	for z in range(height - 2, height):
		set_zone(0, z, Zone.LOGISTICS)
		set_zone(1, z, Zone.LOGISTICS)
	# Ladezone (Anlieferung)
	for x in range(2, 8):
		set_zone(x, height - 3, Zone.LOGISTICS)


## Prüft, ob eine Fläche frei ist (nicht durch anderes Gebäude belegt).
func is_area_free(origin_x: int, origin_z: int, w: int, h: int) -> bool:
	for z in range(origin_z, origin_z + h):
		for x in range(origin_x, origin_x + w):
			if not in_bounds(x, z):
				return false
			if occupied.has(Vector2i(x, z)):
				return false
	return true


## Belegt eine Fläche mit einem Gebäude.
func occupy(origin_x: int, origin_z: int, w: int, h: int, building_id: String) -> bool:
	if not is_area_free(origin_x, origin_z, w, h):
		return false
	for z in range(origin_z, origin_z + h):
		for x in range(origin_x, origin_x + w):
			occupied[Vector2i(x, z)] = building_id
	return true


## Gibt eine Fläche wieder frei.
func release(building_id: String) -> void:
	var to_remove: Array = []
	for key in occupied:
		if occupied[key] == building_id:
			to_remove.append(key)
	for key in to_remove:
		occupied.erase(key)


## Freie Fläche in der angegebenen Zone (deterministisch: von links oben).
## Gibt Vector2i(-1,-1) zurück, wenn keine gefunden wird.
func find_free_spot(zone: int, w: int, h: int) -> Vector2i:
	for z in height:
		for x in width:
			if zones[z][x] != zone:
				continue
			var ok := true
			for dz in range(h):
				for dx in range(w):
					if not in_bounds(x + dx, z + dz):
						ok = false
						break
					if zones[z + dz][x + dx] != zone:
						ok = false
						break
					if occupied.has(Vector2i(x + dx, z + dz)):
						ok = false
						break
				if not ok:
					break
			if ok:
				return Vector2i(x, z)
	return Vector2i(-1, -1)


## Zählt freie Zellen je Zone.
func free_cells_by_zone() -> Dictionary:
	var counts := {}
	for zone in Zone.values():
		counts[zone] = 0
	for z in height:
		for x in width:
			var key := Vector2i(x, z)
			if occupied.has(key):
				continue
			counts[zones[z][x]] = counts.get(zones[z][x], 0) + 1
	return counts


## Gesamte Fläche in Quadratmetern (1 Zelle = 16 m² bei 4 m Kantenlänge).
func total_area_sqm() -> float:
	return float(width * height) * (TILE_SIZE * TILE_SIZE)


## Belegte Fläche in Quadratmetern.
func used_area_sqm() -> float:
	return float(occupied.size()) * (TILE_SIZE * TILE_SIZE)


## Serialisierbarer Zustand.
func to_dict() -> Dictionary:
	var zone_rows: Array = []
	for row in zones:
		zone_rows.append(row.duplicate())
	var occ: Dictionary = {}
	for key in occupied:
		occ["%d,%d" % [key.x, key.y]] = occupied[key]
	return {
		"width": width,
		"height": height,
		"zones": zone_rows,
		"occupied": occ,
		"buildings": buildings,
	}


## Stellt den Geländestand aus einem Save wieder her.
func from_dict(data: Dictionary) -> void:
	width = int(data.get("width", 24))
	height = int(data.get("height", 18))
	var rows: Array = data.get("zones", [])
	if rows.size() == height:
		zones = []
		for row in rows:
			zones.append((row as Array).duplicate())
	occupied.clear()
	var occ: Dictionary = data.get("occupied", {})
	for key in occ:
		var parts: PackedStringArray = String(key).split(",")
		if parts.size() == 2:
			occupied[Vector2i(int(parts[0]), int(parts[1]))] = occ[key]
	buildings = data.get("buildings", {})
