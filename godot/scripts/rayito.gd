extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if multiplayer.is_server():
		body_entered.connect(_on_body_entered)
		get_tree().create_timer(tiempo_de_vida).timeout.connect(_vencer)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func rayito_effect(body: Auto) -> void:
	# aqui deberia activarse la animación del rayito
	var gato_modelo = body.gato_modelo
	var rotation_modelo = body.rotation_modelo
	var tween: Tween = create_tween()
	var duracion: float = 1.0
	var cooldown: float = 5.0
	tween.parallel().tween_property(
		gato_modelo,
		"rotation:y",
		rotation_modelo + deg_to_rad(720),
		duracion
	)
	
	tween.parallel().tween_property(
		gato_modelo,
		"scale",
		Vector3(0.5, 0.5, 0.5),
		duracion)

	tween.tween_interval(cooldown)

	tween.tween_property(
		gato_modelo,
		"scale",
		Vector3(2.0, 2.0, 2.0),
		1.0
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	gato_modelo.rotation.y = rotation_modelo
	

@rpc("authority", "call_local", "reliable")
func eliminar() -> void:
	queue_free()
