extends Node3D

@export var player_scene: PackedScene
@onready var spawn_points: Node3D = $SpawnPoints
@onready var players: Node3D = $Players
@onready var checkpoint_markers: CheckpointsMarkers = $"Checkpoint Markers"
@onready var checkpoints: Node3D = $Checkpoints

#var checkpoints_amount: int:
#	get:
#		return checkpoint_markers.checkpoints_amount

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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

func get_checkpoints_amount() -> int:
	return checkpoint_markers.checkpoints_amount
