extends Area3D

## Caja de ítem. Solo el servidor detecta quién la toca y sortea el ítem;
## luego la caja desaparece en todos y reaparece después de unos segundos.

@export var tiempo_reaparicion: float = 4.0
@export var velocidad_giro: float = 1.5

var _activa: bool = true
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	_rng.randomize()
	if multiplayer.is_server():
		body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	mesh.rotate_y(velocidad_giro * delta)

func _on_body_entered(body: Node3D) -> void:
	var jugador: Auto = body as Auto
	if not _activa or not jugador:
		return
	var id: int = jugador.get_multiplayer_authority()
	var posicion: int = 0
	var total: int = 1
	var carrera: Node = get_tree().get_first_node_in_group("carrera")
	if carrera:
		posicion = carrera.get_race_position(id)
		total = carrera.players.get_child_count()
	jugador.recibir_item.rpc_id(id, Items.sortear(posicion, total, _rng))
	set_activa.rpc(false)
	await get_tree().create_timer(tiempo_reaparicion).timeout
	if is_inside_tree():
		set_activa.rpc(true)

@rpc("authority", "call_local", "reliable")
func set_activa(valor: bool) -> void:
	_activa = valor
	visible = valor
