extends Node3D

@export var player_scene: PackedScene
@onready var spawn_points: Node3D = $SpawnPoints
@onready var players: Node3D = $Players
@onready var checkpoint_markers: CheckpointsMarkers = $"Checkpoint Markers"
@onready var checkpoints: Node3D = $Checkpoints
@onready var meta: FinishLine = $Meta

@export var laps: int = 1

var _race_finished: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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
		player_inst.global_position = spawn_points.get_child(i).global_position

		player_inst.last_checkpoint = checkpoints.get_child(
			checkpoints.get_child_count() - 1
		)

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

func get_checkpoints_amount() -> int:
	return checkpoint_markers.checkpoints_amount
