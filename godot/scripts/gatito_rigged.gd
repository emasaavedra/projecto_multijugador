extends Node3D

@onready var animador: AnimationPlayer = _buscar_animador()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

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
