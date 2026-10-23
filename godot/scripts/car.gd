extends CharacterBody3D
class_name Auto

## Jugador: un gato que corre por la pista con movimiento arcade estilo kart.
## Cada cliente mueve su propio gato y manda su posición a los demás.

signal item_cambiado(tipo: Items.Tipo, usos: int)

const GATO_MICRO: PackedScene = preload("res://scenes/gato_micro.tscn")

@export var max_speed: float = 22.0
@export var reverse_speed: float = 7.0
@export var acceleration: float = 30.0
@export var brake_deceleration: float = 40.0
@export var friction: float = 14.0
@export var turn_speed: float = 2.5
@export var gravity: float = 25.0
@export var jump_force: float = 8.0
@export var mouse_sensitivity: float = 0.01
@export var camera_min_pitch: float = -20
@export var camera_max_pitch: float = 30
@export_group("Items")
## Churu: multiplica la velocidad máxima durante unos segundos
@export var churu_multiplicador: float = 1.6
@export var churu_duracion: float = 1.2
## Tarjeta Bip: el gato se vuelve micro y sigue la pista solo
@export var micro_velocidad: float = 36.0
@export var micro_duracion: float = 4.0
@export var micro_radio_choque: float = 3.0
## Pepino u otro golpe: queda quieto y luego un rato invulnerable
@export var susto_duracion: float = 1.0
@export var invulnerable_duracion: float = 2.0
## Velocidad extra para el último lugar (0.08 = 8%), para que siempre pueda alcanzar
@export var ayuda_rezagados: float = 0.08
var last_checkpoint: Checkpoint

# Velocidad hacia adelante (negativa = reversa)
var speed: float = 0.0
var item: Items.Tipo = Items.Tipo.NINGUNO
var usos_item: int = 0
# Lo envía el servidor (0 = primer lugar)
var posicion_carrera: int = 0
var total_jugadores: int = 1

var _churu_tiempo: float = 0.0
var _micro_tiempo: float = 0.0
var _micro_offset: float = 0.0
var _susto_tiempo: float = 0.0
var _invulnerable_tiempo: float = 0.0
var _golpeados: Dictionary = {}
var _recorrido: Path3D
var _micro_visual: Node3D
var _gato_base: Transform3D
var _label_altura: float
# Efectos que ven todos los jugadores
var _giro_visual: float = 0.0
var _parpadeo_visual: float = 0.0

@onready var spring_arm_3d: SpringArm3D = $SpringArm3D
@onready var gato: Node3D = $Gato
@onready var label_3d: Label3D = $Label3D
@onready var camera_3d: Camera3D = $SpringArm3D/Camera3D
@onready var input_synchronizer: InputSynchronizer = $InputSynchronizer
@onready var hud: UIHud = $HUD
@onready var victory_screen: VictoryScreen = $VictoryScreen

func _ready() -> void:
	add_to_group("jugadores")
	var player_data: Statics.PlayerData = Game.instance.get_player(get_multiplayer_authority())
	label_3d.text = player_data.name
	#hud.visible = is_multiplayer_authority()
	hud.visible = true
	victory_screen.hide()
	# Que la cámara no choque con el propio gato
	spring_arm_3d.add_excluded_object(get_rid())
	_recorrido = get_tree().get_first_node_in_group("recorrido") as Path3D
	_micro_visual = GATO_MICRO.instantiate()
	_micro_visual.hide()
	add_child(_micro_visual)
	_gato_base = gato.transform
	_label_altura = label_3d.position.y
	item_cambiado.connect(hud.mostrar_item)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("test") and is_multiplayer_authority():
		test.rpc()

func setup(player_data: Statics.PlayerData) -> void:
	label_3d.text = player_data.name
	set_multiplayer_authority(player_data.id)
	camera_3d.current = is_multiplayer_authority()

func _process(delta: float) -> void:
	_actualizar_efectos_visuales(delta)

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		gato._actualizar_animacion(speed, max_speed)
		return

	_churu_tiempo = maxf(_churu_tiempo - delta, 0.0)
	_susto_tiempo = maxf(_susto_tiempo - delta, 0.0)
	_invulnerable_tiempo = maxf(_invulnerable_tiempo - delta, 0.0)

	if _micro_tiempo > 0.0:
		_mover_como_micro(delta)
	else:
		_mover_como_gato(delta)

	gato._actualizar_animacion(speed, max_speed)
	send_data.rpc(global_position, global_rotation, speed)

func _mover_como_gato(delta: float) -> void:
	var steer_input: float = input_synchronizer.steer_input
	var force_input: float = input_synchronizer.force_input
	if _susto_tiempo > 0.0:
		# Asustado: no responde a los controles
		steer_input = 0.0
		force_input = 0.0
		speed = move_toward(speed, 0.0, brake_deceleration * 2.0 * delta)

	var velocidad_maxima: float = max_speed * (1.0 + ayuda_rezagados * _avance_en_carrera())
	if _churu_tiempo > 0.0 and force_input >= 0.0:
		# El churu empuja aunque no se esté acelerando
		speed = maxf(speed, velocidad_maxima * churu_multiplicador)
	elif force_input > 0.0:
		speed = move_toward(speed, velocidad_maxima * force_input, acceleration * delta)
	elif force_input < 0.0:
		var deceleration: float = brake_deceleration if speed > 0.0 else acceleration
		speed = move_toward(speed, -reverse_speed, deceleration * delta)
	elif _susto_tiempo <= 0.0:
		speed = move_toward(speed, 0.0, friction * delta)

	# Girar: al ir en reversa se invierte, como en un kart
	var direction: float = -1.0 if speed < 0.0 else 1.0
	rotate_y(-steer_input * turn_speed * direction * delta)

	# Gravedad y salto
	if is_on_floor():
		if input_synchronizer.jump and _susto_tiempo <= 0.0:
			velocity.y = jump_force
	else:
		velocity.y -= gravity * delta
	input_synchronizer.jump = false

	# El frente del gato es +Z
	var forward: Vector3 = global_basis.z
	velocity.x = forward.x * speed
	velocity.z = forward.z * speed
	move_and_slide()

func _mover_como_micro(delta: float) -> void:
	_micro_tiempo -= delta
	speed = micro_velocidad
	if _recorrido and _recorrido.curve:
		# Avanza solo por el centro de la pista
		var curva: Curve3D = _recorrido.curve
		var largo: float = curva.get_baked_length()
		_micro_offset = fposmod(_micro_offset + micro_velocidad * delta, largo)
		var punto: Vector3 = _recorrido.to_global(curva.sample_baked(_micro_offset))
		var adelante: Vector3 = _recorrido.to_global(curva.sample_baked(fposmod(_micro_offset + 4.0, largo)))
		var direccion: Vector3 = adelante - punto
		direccion.y = 0.0
		global_position = global_position.lerp(punto, minf(1.0, 10.0 * delta))
		if direccion.length_squared() > 0.001:
			global_basis = Basis.looking_at(-direccion.normalized(), Vector3.UP)
	else:
		# Sin pista conocida: sigue derecho
		velocity = global_basis.z * speed
		move_and_slide()
	velocity = Vector3.ZERO
	_chocar_cercanos()
	if _micro_tiempo <= 0.0:
		_micro_tiempo = 0.0
		speed = max_speed
		_invulnerable_tiempo = maxf(_invulnerable_tiempo, 1.0)
		_set_micro_visual.rpc(false)

func _chocar_cercanos() -> void:
	var ahora: float = Time.get_ticks_msec() / 1000.0
	for otro: Auto in get_tree().get_nodes_in_group("jugadores"):
		if otro == self or global_position.distance_to(otro.global_position) > micro_radio_choque:
			continue
		var id: int = otro.get_multiplayer_authority()
		if ahora - _golpeados.get(id, -10.0) < 1.5:
			continue
		_golpeados[id] = ahora
		otro.recibir_golpe.rpc_id(id)

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if event.is_action_pressed("usar_item"):
		usar_item()
		return
	var mouse_motion: InputEventMouseMotion = event as InputEventMouseMotion
	if mouse_motion:
		spring_arm_3d.rotation.y -= mouse_motion.relative.x * mouse_sensitivity
		camera_3d.rotation.x = clamp(camera_3d.rotation.x - mouse_motion.relative.y * mouse_sensitivity,
									deg_to_rad(camera_min_pitch),
									deg_to_rad(camera_max_pitch))

func usar_item() -> void:
	if item == Items.Tipo.NINGUNO or _susto_tiempo > 0.0 or _micro_tiempo > 0.0:
		return
	match item:
		Items.Tipo.CHURU, Items.Tipo.TRIPLE_CHURU:
			_churu_tiempo = churu_duracion
		Items.Tipo.BIP:
			_micro_tiempo = micro_duracion
			_churu_tiempo = 0.0
			if _recorrido and _recorrido.curve:
				_micro_offset = _recorrido.curve.get_closest_offset(_recorrido.to_local(global_position))
			_set_micro_visual.rpc(true)
		Items.Tipo.PEPINO:
			var carrera: Node = get_tree().get_first_node_in_group("carrera")
			if carrera:
				# Se deja detrás del gato (el frente es +Z)
				carrera.request_pepino.rpc_id(1, global_position - global_basis.z * 2.5)
	usos_item -= 1
	if usos_item <= 0:
		item = Items.Tipo.NINGUNO
		usos_item = 0
	item_cambiado.emit(item, usos_item)

## El servidor le da un ítem a este jugador al tocar una caja
@rpc("any_peer", "call_local", "reliable")
func recibir_item(tipo: Items.Tipo) -> void:
	if multiplayer.get_remote_sender_id() != 1 or not is_multiplayer_authority():
		return
	if item != Items.Tipo.NINGUNO:
		return
	item = tipo
	usos_item = Items.USOS.get(tipo, 1)
	item_cambiado.emit(item, usos_item)

## Pisó un pepino o lo atropelló un micro. Se ejecuta en el dueño de este gato.
@rpc("any_peer", "call_local", "reliable")
func recibir_golpe() -> void:
	if not is_multiplayer_authority():
		return
	if _micro_tiempo > 0.0 or _susto_tiempo > 0.0 or _invulnerable_tiempo > 0.0:
		return
	_susto_tiempo = susto_duracion
	_invulnerable_tiempo = susto_duracion + invulnerable_duracion
	_churu_tiempo = 0.0
	speed = minf(speed, max_speed * 0.3)
	velocity.y = jump_force * 0.6
	_mostrar_golpe.rpc(susto_duracion, invulnerable_duracion)

## El servidor avisa la posición en la carrera
@rpc("any_peer", "call_local", "unreliable_ordered")
func actualizar_posicion(posicion: int, total: int) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return
	posicion_carrera = posicion
	total_jugadores = total

func _avance_en_carrera() -> float:
	# 0.0 = va primero, 1.0 = va último
	if total_jugadores <= 1:
		return 0.0
	return float(posicion_carrera) / float(total_jugadores - 1)

@rpc("authority", "call_local", "reliable")
func _set_micro_visual(activo: bool) -> void:
	_micro_visual.visible = activo
	gato.visible = not activo
	label_3d.position.y = _label_altura + (2.0 if activo else 0.0)

@rpc("authority", "call_local", "reliable")
func _mostrar_golpe(duracion_giro: float, duracion_parpadeo: float) -> void:
	_giro_visual = duracion_giro
	_parpadeo_visual = duracion_giro + duracion_parpadeo

func _actualizar_efectos_visuales(delta: float) -> void:
	if _giro_visual > 0.0:
		_giro_visual -= delta
		# El gato da vueltas del susto
		gato.transform = _gato_base.rotated_local(Vector3.UP, _giro_visual * TAU * 2.0)
		if _giro_visual <= 0.0:
			gato.transform = _gato_base
	if _parpadeo_visual > 0.0:
		_parpadeo_visual -= delta
		var visible_ahora: bool = _parpadeo_visual <= 0.0 or int(_parpadeo_visual * 10.0) % 2 == 0
		if not _micro_visual.visible:
			gato.visible = visible_ahora

@rpc("any_peer", "call_local", "reliable")
func test() -> void:
	Debug.log(name, 10)

@rpc("authority", "call_remote", "unreliable_ordered")
func send_data(pos: Vector3, rot: Vector3, new_speed: float) -> void:
	global_position = pos
	global_rotation = rot
	speed = new_speed

func write_winner(winner: String) -> void:
	victory_screen.winner_label.text = winner
	victory_screen.show()
