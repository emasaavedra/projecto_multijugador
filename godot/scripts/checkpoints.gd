class_name CheckpointsMarkers
extends Node3D

@export var checkpoint_scene: PackedScene
var checkpoints_amount: int:
	get:
		return get_child_count()
@export var max_laps: int

@onready var checkpoints: Node3D = $"../Checkpoints"
@onready var finish_line: FinishLine = $"../Meta"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawn_all_checkpoints()

var last_checkpoint: Checkpoint

func spawn_all_checkpoints() -> void:
	# Se reinicia para que no se acumule entre carreras
	Game.checkpoints_amount = 0
	for i: int in get_children().size():
		# Obtenemos el marker
		var child: Marker3D = get_child(i) as Marker3D
		# Creamos un checkpoint en su posición
		var checkpoint_inst: Checkpoint = checkpoint_scene.instantiate()
		checkpoints.add_child(checkpoint_inst)
		checkpoint_inst.global_position = child.global_position
		if not last_checkpoint:
			last_checkpoint = checkpoint_inst
		else:
			checkpoint_inst.previous_checkpoint = last_checkpoint
			last_checkpoint = checkpoint_inst
		Game.checkpoints_amount += 1
	var first_checkpoint: Checkpoint = checkpoints.get_child(0)
	first_checkpoint.previous_checkpoint = last_checkpoint
