extends Node3D

const PEPINO: PackedScene = preload("res://scenes/pepino.tscn")

@export var player_scene: PackedScene
@onready var spawn_points: Node3D = $SpawnPoints
@onready var players: Node3D = $Players
@onready var checkpoints: Node3D = $Checkpoints
@onready var meta: FinishLine = $Meta

@export var laps: int = 1
## Cada cuántos segundos el servidor recalcula las posiciones de la carrera
@export var intervalo_posiciones: float = 0.5

var _race_finished: bool = false
var _pepinos_creados: int = 0
var _proyectiles: Node3D
var _tiempo_posiciones: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("carrera")
	_proyectiles = Node3D.new()
	_proyectiles.name = "Proyectiles"
	add_child(_proyectiles)
	Game.laps_amount = laps
	Game.reset_race()
	# Solo el servidor decide quién gana
	if multiplayer.is_server():
		meta.area.body_entered.connect(on_game_over)
	for i: int in Game.players.size():
		var player_data: Statics.PlayerData = Game.players[i]
		var player_inst = player_scene.instantiate()
		player_inst.name = str(player_data.id)
		players.add_child(player_inst)
		player_inst.setup(player_data)
		player_inst.global_transform = spawn_points.get_child(i).global_transform

		player_inst.last_checkpoint = checkpoints.get_child(
			checkpoints.get_child_count() - 1
		)

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	_tiempo_posiciones -= delta
	if _tiempo_posiciones > 0.0:
		return
	_tiempo_posiciones = intervalo_posiciones
	var orden: Array[int] = get_race_order()
	for player: Auto in players.get_children():
		player.actualizar_posicion.rpc(orden.find(player.get_multiplayer_authority()), orden.size())

func on_game_over(body: Node3D) -> void:
	if _race_finished or body is not Auto:
		return
	var winner: Auto = body as Auto
	var player_data: Statics.PlayerData = Game.get_player(winner.get_multiplayer_authority())
	if not player_data:
		return
	if player_data.checkpoints >= Game.checkpoints_amount * Game.laps_amount:
		announce_winner.rpc(player_data.id)

@rpc("authority", "call_local", "reliable")
func announce_winner(winner_id: int) -> void:
	_race_finished = true
	var winner_data: Statics.PlayerData = Game.get_player(winner_id)
	var winner_name: String = winner_data.name if winner_data else str(winner_id)
	# Cada peer muestra la pantalla de victoria solo en su propio auto
	for player: Auto in players.get_children():
		if player.is_multiplayer_authority():
			player.write_winner(winner_name)

## IDs de los jugadores ordenados del primero al último lugar
func get_race_order() -> Array[int]:
	var puntajes: Array[Dictionary] = []
	var cantidad: int = checkpoints.get_child_count()
	for player: Auto in players.get_children():
		var id: int = player.get_multiplayer_authority()
		var data: Statics.PlayerData = Game.get_player(id)
		var pasados: int = data.checkpoints if data else 0
		var puntaje: float = pasados * 100000.0
		if cantidad > 0:
			# Entre dos jugadores con los mismos checkpoints, va adelante el más cerca del siguiente
			var siguiente: Node3D = checkpoints.get_child(pasados % cantidad)
			puntaje -= player.global_position.distance_to(siguiente.global_position)
		puntajes.append({"id": id, "puntaje": puntaje})
	puntajes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.puntaje > b.puntaje)
	var orden: Array[int] = []
	for p: Dictionary in puntajes:
		orden.append(p.id)
	return orden

## Posición del jugador en la carrera (0 = primer lugar)
func get_race_position(player_id: int) -> int:
	return maxi(get_race_order().find(player_id), 0)

@rpc("any_peer", "call_local", "reliable")
func request_pepino(posicion: Vector3) -> void:
	if not multiplayer.is_server():
		return
	_pepinos_creados += 1
	spawn_pepino.rpc("Pepino%d" % _pepinos_creados, posicion, multiplayer.get_remote_sender_id())

@rpc("authority", "call_local", "reliable")
func spawn_pepino(nombre: String, posicion: Vector3, dueno: int) -> void:
	var pepino: Pepino = PEPINO.instantiate()
	pepino.name = nombre
	pepino.dueno_id = dueno
	_proyectiles.add_child(pepino)
	pepino.global_position = posicion
