extends Node3D

## Modelo y animación del gato. El movimiento lo maneja el jugador (car.gd).

## Multiplica la velocidad de la animación "Correr" (1.0 = velocidad original del modelo).
@export var velocidad_animacion: float = 2.2
@export var velocidad_animacion_min: float = 1.0
@export var velocidad_animacion_max: float = 3.5

@onready var animador: AnimationPlayer = _buscar_animador()


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
		var proporcion: float = abs(velocidad_actual) / velocidad_maxima
		animador.speed_scale = clamp(proporcion * velocidad_animacion,
				velocidad_animacion_min, velocidad_animacion_max)
	else:
		animador.stop()
