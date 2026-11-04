class_name Lana
extends Area3D

## Bola de lana lanzable que rebota en paredes hasta 3 veces y destruye pepinos.
## El servidor gestiona las colisiones, la física de rebote y la sincronización.

@export var velocidad: float = 32.0
@export var tiempo_de_vida: float = 12.0
@export var gracia_dueno: float = 0.5
@export var max_rebotes: int = 3

var dueno_id: int = 0
var direccion: Vector3 = Vector3.FORWARD
var _tiempo_gracia: float = 0.0
var _rebotes_actuales: int = 0

func _ready() -> void:
	_tiempo_gracia = gracia_dueno
	if multiplayer.is_server():
		body_entered.connect(_on_body_entered)
		area_entered.connect(_on_area_entered)
		get_tree().create_timer(tiempo_de_vida).timeout.connect(_vencer)

func _physics_process(delta: float) -> void:
	if _tiempo_gracia > 0.0:
		_tiempo_gracia -= delta

	if multiplayer.is_server():
		_comprobar_rebote_pared(delta)

	# Desplazamiento en la dirección actual
	global_position += direccion * velocidad * delta

func _comprobar_rebote_pared(delta: float) -> void:
	# Detectar normales de pared antes del impacto
	var space_state := get_world_3d().direct_space_state
	var desde := global_position
	var hasta := global_position + direccion * (velocidad * delta + 0.6)
	
	var query := PhysicsRayQueryParameters3D.create(desde, hasta)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [get_rid()]
	
	var colision := space_state.intersect_ray(query)
	if colision:
		var collider = colision.collider
		
		# Ignorar el piso y a los vehículos en la prueba de rebotes
		if collider.is_in_group("piso") or collider.name == "piso" or collider is Auto:
			return
		
		if collider is Pepino or collider is Lana:
			return
			
		var normal: Vector3 = colision.normal
		normal.y = 0.0 # Mantener movimiento en el plano horizontal
		
		if normal.length_squared() > 0.001:
			_rebotes_actuales += 1
			if _rebotes_actuales > max_rebotes:
				eliminar.rpc()
			else:
				# Reflejar el vector de dirección según la normal de la pared
				var nueva_dir := direccion.bounce(normal.normalized()).normalized()
				sincronizar_rebote.rpc(global_position, nueva_dir)

@rpc("authority", "call_local", "reliable")
func sincronizar_rebote(pos: Vector3, nueva_dir: Vector3) -> void:
	global_position = pos
	direccion = nueva_dir

func _on_body_entered(body: Node3D) -> void:
	if not multiplayer.is_server():
		return

	# Ignorar piso
	if body.is_in_group("piso") or body.name == "piso" or body.name == "StaticBody3D":
		return

	if body is Auto:
		var jugador: Auto = body as Auto
		var id: int = jugador.get_multiplayer_authority()
		if id == dueno_id and _tiempo_gracia > 0.0:
			return
		jugador.recibir_golpe.rpc_id(id)
		eliminar.rpc()

func _on_area_entered(area: Area3D) -> void:
	if not multiplayer.is_server():
		return

	# Impacto con un Pepino:
	if area is Pepino:
		area.eliminar.rpc()
		eliminar.rpc()
	# Impacto con otra Lana: destruye ambas
	elif area is Lana and area != self:
		eliminar.rpc()

func _vencer() -> void:
	if is_inside_tree() and multiplayer.is_server():
		eliminar.rpc()

@rpc("authority", "call_local", "reliable")
func eliminar() -> void:
	queue_free()
