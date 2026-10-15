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
	await get_tree().create_timer(2.0).timeout
	#finish_line.area.body_entered.connect(_on_finish_line_body_entered)
	#Game.checkpoints_amount = get_children().size()
	
var last_checkpoint: Checkpoint

func spawn_all_checkpoints() -> void:
	for i: int in get_children().size():
		# Obtenemos el marker
		var child: Marker3D = get_child(i) as Marker3D
		# Creamos un checkpoint en su posición
		var checkpoint_inst: Checkpoint = checkpoint_scene.instantiate()
		checkpoints.add_child(checkpoint_inst)
		checkpoint_inst.global_position = child.global_position
		checkpoint_inst.body_entered.connect(sennal.bind(checkpoint_inst, i))
		if not last_checkpoint:
			last_checkpoint = checkpoint_inst
		else:
			checkpoint_inst.previous_checkpoint = last_checkpoint
			last_checkpoint = checkpoint_inst
		Game.checkpoints_amount += 1
	var first_checkpoint: Checkpoint = checkpoints.get_child(0)
	first_checkpoint.previous_checkpoint = last_checkpoint
	print("checkpoints listos :D")
	print(checkpoints.get_children())
	for i: int in checkpoints.get_children().size():
		var checkpoint: Checkpoint = checkpoints.get_child(i)
		print(" el previo es "+str(checkpoint.previous_checkpoint)+", luego viene "+str(checkpoint))

func sennal(body: Auto, index: Checkpoint) -> void:
	body.checkpoint_reached(index)
	#Debug.log("Player " + body.name + " has reached " + str(body.checkpoints) + " checkpoints. Last checkpoint: " + str(body.last_checkpoint))

func _on_finish_line_body_entered(_body: Auto) -> void:
	spawn_all_checkpoints()
