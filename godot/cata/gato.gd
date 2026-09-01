extends CharacterBody3D

## Script de movimiento arcade para el Gato/Auto.
## Cada cliente controla solo su propio gato (is_multiplayer_authority());
## la posicion/rotacion resultante se replica a los demas via MultiplayerSynchronizer.

@export var velocidad_maxima: float = 10.0
@export var velocidad_reversa: float = 4.0
@export var aceleracion: float = 12.0
@export var friccion: float = 8.0
@export var velocidad_giro: float = 2.2
@export var gravedad: float = 20.0

var velocidad_actual: float = 0.0

@onready var synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer
@onready var camara: Camera3D = $SpringArm3D/Camera3D
@onready var label_nombre: Label3D = $Label3D
@onready var animador: AnimationPlayer = _buscar_animador()


func _ready() -> void:
	_configurar_sincronizacion()
	# La camara solo se activa para el jugador dueño de este gato.
	camara.current = is_multiplayer_authority()

	var datos_jugador: Statics.PlayerData = Game.instance.get_player(get_multiplayer_authority())
	if datos_jugador:
		label_nombre.text = datos_jugador.name


func _configurar_sincronizacion() -> void:
	var config := SceneReplicationConfig.new()
	config.add_property(NodePath(".:position"))
	config.add_property(NodePath(".:rotation"))
	synchronizer.replication_config = config


func _buscar_animador() -> AnimationPlayer:
	# Busca el AnimationPlayer que trae el modelo importado (gatito_rigged.glb),
	# sin depender de la ruta exacta que genere el importador de Godot.
	var nodo := find_child("AnimationPlayer", true, false)
	return nodo as AnimationPlayer


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	if not is_on_floor():
		velocity.y -= gravedad * delta
	else:
		velocity.y = 0.0

	var entrada_adelante := Input.get_action_strength("acelerar")
	var entrada_atras := Input.get_action_strength("frenar")

	if entrada_adelante > 0.0:
		velocidad_actual = move_toward(velocidad_actual, velocidad_maxima * entrada_adelante, aceleracion * delta)
	elif entrada_atras > 0.0:
		velocidad_actual = move_toward(velocidad_actual, -velocidad_reversa * entrada_atras, aceleracion * delta)
	else:
		velocidad_actual = move_toward(velocidad_actual, 0.0, friccion * delta)

	# Girar solo si hay movimiento (como un auto real). Si el giro te queda
	# invertido, cambia el signo de "direccion_giro".
	var direccion_giro := Input.get_axis("girar_derecha", "girar_izquierda")
	if abs(velocidad_actual) > 0.1:
		var factor_velocidad: float = clamp(abs(velocidad_actual) / velocidad_maxima, 0.3, 1.0)
		var sentido: float = sign(velocidad_actual)
		rotate_y(direccion_giro * velocidad_giro * delta * factor_velocidad * sentido)

	var direccion := -global_transform.basis.z
	velocity.x = direccion.x * velocidad_actual
	velocity.z = direccion.z * velocidad_actual

	move_and_slide()

	_actualizar_animacion()


func _actualizar_animacion() -> void:
	if animador == null:
		return
	if abs(velocidad_actual) > 0.3:
		if not animador.is_playing() or animador.current_animation != "Correr":
			animador.play("Correr")
		animador.speed_scale = clamp(abs(velocidad_actual) / velocidad_maxima, 0.5, 2.0)
	else:
		animador.stop()
