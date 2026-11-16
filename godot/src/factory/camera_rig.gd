class_name CameraRig
extends Node3D

## Isometrische Kamera mit Zoom, Schwenk und sanfter Bewegung.
##
## Orthografische Projektion für den klassischen Industrie-Look.
## Die Kamera folgt einem Zielpunkt, das per Tastatur/Maus bewegt wird.

const MIN_ZOOM := 14.0
const MAX_ZOOM := 70.0
const ZOOM_SPEED := 1.0
const PAN_SPEED := 22.0
const EDGE_PAN_SPEED := 16.0
const EDGE_MARGIN := 12.0

## Blickwinkel der isometrischen Kamera
const PITCH := deg_to_rad(-35.264)
const YAW := deg_to_rad(-45.0)

var target: Vector3 = Vector3.ZERO
var zoom: float = 34.0
var target_zoom: float = 34.0
var pan_velocity: Vector3 = Vector3.ZERO
var _camera: Camera3D
var _bounds: Rect2 = Rect2(Vector2(-60, -60), Vector2(120, 120))
var input_enabled: bool = true


func _ready() -> void:
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = zoom
	_camera.near = 0.5
	_camera.far = 400.0
	add_child(_camera)
	_apply()


func camera() -> Camera3D:
	return _camera


## Grenzen des Geländes setzen.
func set_bounds(grid: FactoryGrid) -> void:
	var half_x := grid.width * FactoryGrid.TILE_SIZE * 0.5
	var half_z := grid.height * FactoryGrid.TILE_SIZE * 0.5
	_bounds = Rect2(Vector2(-half_x, -half_z), Vector2(half_x * 2.0, half_z * 2.0))


func _process(delta: float) -> void:
	if not input_enabled:
		return
	_handle_input(delta)
	# weiche Annäherung
	zoom = lerpf(zoom, target_zoom, clampf(delta * 9.0, 0.0, 1.0))
	target += pan_velocity * delta
	pan_velocity = pan_velocity.lerp(Vector3.ZERO, clampf(delta * 8.0, 0.0, 1.0))
	_clamp_target()
	_apply()


func _handle_input(delta: float) -> void:
	var dir := Vector3.ZERO
	if Input.is_action_pressed("ui_left"):
		dir.x -= 1.0
	if Input.is_action_pressed("ui_right"):
		dir.x += 1.0
	if Input.is_action_pressed("ui_up"):
		dir.z -= 1.0
	if Input.is_action_pressed("ui_down"):
		dir.z += 1.0

	if dir != Vector3.ZERO:
		# Bewegung in Kamerabasis (diagonal)
		var basis_dir := (transform.basis * Vector3(dir.x, 0, dir.z)).normalized()
		pan_velocity += basis_dir * PAN_SPEED * delta * 6.0

	# Zoom
	if Input.is_key_pressed(KEY_EQUAL) or Input.is_key_pressed(KEY_KP_ADD):
		target_zoom = maxf(MIN_ZOOM, target_zoom - ZOOM_SPEED * 12.0 * delta)
	if Input.is_key_pressed(KEY_MINUS) or Input.is_key_pressed(KEY_KP_SUBTRACT):
		target_zoom = minf(MAX_ZOOM, target_zoom + ZOOM_SPEED * 12.0 * delta)

	# Mausrad
	var wheel := Input.get_axis("ui_page_down", "ui_page_up")
	if absf(wheel) > 0.01:
		target_zoom = clampf(target_zoom - wheel * 6.0, MIN_ZOOM, MAX_ZOOM)


## Tastaturbefehle der Kamera.
##
## Die Kamera muss ohne Maus bedienbar sein: Plus/Minus zoomen,
## R setzt die Ansicht zurueck, F zentriert auf das Gelände.
func handle_key(event: InputEventKey) -> bool:
	if not input_enabled:
		return false
	match event.keycode:
		KEY_EQUAL, KEY_KP_ADD:
			target_zoom = maxf(MIN_ZOOM, target_zoom - ZOOM_SPEED * 3.0)
			return true
		KEY_MINUS, KEY_KP_SUBTRACT:
			target_zoom = minf(MAX_ZOOM, target_zoom + ZOOM_SPEED * 3.0)
			return true
		KEY_R:
			reset_view()
			return true
		KEY_F:
			target = Vector3.ZERO
			target_zoom = 26.0
			return true
	return false


## Zoom auf einen bestimmten Punkt (z. B. bei Auswahl eines Gebäudes).
func focus_on(world_point: Vector3, new_zoom: float = -1.0) -> void:
	target = Vector3(world_point.x, 0.0, world_point.z)
	if new_zoom > 0.0:
		target_zoom = clampf(new_zoom, MIN_ZOOM, MAX_ZOOM)


## Kamera auf das Gelände zentrieren.
func reset_view() -> void:
	target = Vector3.ZERO
	target_zoom = 34.0


func _clamp_target() -> void:
	target.x = clampf(target.x, _bounds.position.x, _bounds.position.x + _bounds.size.x)
	target.z = clampf(target.z, _bounds.position.y, _bounds.position.y + _bounds.size.y)


func _apply() -> void:
	if _camera == null:
		return
	_camera.size = zoom
	# Die Kamera ist ein Kind des Rig. Ihre Position wird deshalb
	# lokal gesetzt – global und lokal zu mischen ergaebe zwei
	# konkurrierende Transformierungen.
	_camera.position = Vector3.ZERO
	_camera.rotation = Vector3(PITCH, YAW, 0)
	# Der Blickpunkt ist das Ziel des Rigs: der Rig selbst sitzt
	# auf dem Zielpunkt, die Kamera relativ dazu.
	position = target
	# Kamera sitzt relativ zum Ziel, damit Zoom die Perspektive nicht ändert
	_camera.global_position = target + (Vector3(0, 40, 0) + Vector3(0, 0, 40) * 0.0)
	_camera.look_at(target, Vector3.UP)
