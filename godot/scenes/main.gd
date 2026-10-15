extends Node3D

@export var player_scene: PackedScene
@onready var spawn_points: Node3D = $SpawnPoints
@onready var players: Node3D = $Players
@onready var checkpoint_markers: CheckpointsMarkers = $"Checkpoint Markers"
@onready var checkpoints: Node3D = $Checkpoints
@onready var meta: FinishLine = $Meta

@export var laps: int = 1

#var checkpoints_amount: int:
#	get:
#		return checkpoint_markers.checkpoints_amount

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Game.laps_amount = laps
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
		
# Called every frame. 'delta' is the elapsed time since the previous frame.

func on_game_over(body: Node3D) -> void:
	if body is not Auto:
		return
	var winner: Auto = body as Auto
	print(winner.name + " tiene " + str(winner.checkpoints) + "/" +  str(Game.checkpoints_amount) + " de " + str(Game.laps_amount) + " vueltas.")
	if (winner.checkpoints / Game.checkpoints_amount) == Game.laps_amount:
		# player es el ganador!
		#hay que escribir en todos que es el winner y mostrar la victory screen
		for i: int in players.get_children().size():
			var player: Auto = players.get_child(i)
			player.victory_screen.winner_label.text = winner.name
			player.victory_screen.show()

func get_checkpoints_amount() -> int:
	return checkpoint_markers.checkpoints_amount
