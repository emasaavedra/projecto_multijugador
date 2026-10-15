class_name Pepino
extends Area3D

## Pepino tirado en la pista: el gato que lo pisa se asusta y queda quieto un momento.
## Solo el servidor detecta el choque.

@export var tiempo_de_vida: float = 40.0
## Segundos en que el gato que lo tiró no puede pisarlo
@export var gracia_dueno: float = 1.0

var dueno_id: int = 0

func _ready() -> void:
	if multiplayer.is_server():
		body_entered.connect(_on_body_entered)
		get_tree().create_timer(tiempo_de_vida).timeout.connect(_vencer)

func _process(delta: float) -> void:
	gracia_dueno -= delta

func _on_body_entered(body: Node3D) -> void:
	var jugador: Auto = body as Auto
	if not jugador:
		return
	var id: int = jugador.get_multiplayer_authority()
	if id == dueno_id and gracia_dueno > 0.0:
		return
	jugador.recibir_golpe.rpc_id(id)
	eliminar.rpc()

func _vencer() -> void:
	if is_inside_tree():
		eliminar.rpc()

@rpc("authority", "call_local", "reliable")
func eliminar() -> void:
	queue_free()
