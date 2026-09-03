extends CharacterBody3D

## Script de movimiento arcade para el Gato/Auto.
## Cada cliente controla solo su propio gato (is_multiplayer_authority());
## la posicion/rotacion resultante se replica a los demas via MultiplayerSynchronizer.

#@export var velocidad_maxima: float = 10.0
@export var velocidad_reversa: float = 4.0
@export var aceleracion: float = 12.0
@export var friccion: float = 8.0
@export var velocidad_giro: float = 2.2
@export var gravedad: float = 20.0

#var velocidad_actual: float = 0.0

@onready var synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer


@onready var animador: AnimationPlayer = _buscar_animador()


func _ready() -> void:
	_configurar_sincronizacion()
	# La camara solo se activa para el jugador dueño de este gato.
	


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


func _actualizar_animacion(velocidad_actual: float, velocidad_maxima: float) -> void:
	if animador == null:
		return
	if abs(velocidad_actual) > 0.3:
		if not animador.is_playing() or animador.current_animation != "Correr":
			animador.play("Correr")
		animador.speed_scale = clamp(abs(velocidad_actual) / velocidad_maxima, 0.5, 2.0)
	else:
		animador.stop()
