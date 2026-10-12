extends Node3D

@export var checkpoint_scene: PackedScene
@export var cant_markers: int = 0
@export var max_laps: int


@onready var checkpoints: Node3D = $"../Checkpoints"
@onready var finish_line: FinishLine = $"../Meta"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawn_all_checkpoints()
	await get_tree().create_timer(2.0).timeout
	finish_line.area.body_entered.connect(_on_finish_line_body_entered)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func spawn_all_checkpoints() -> void:
	# al cruzar la meta sin haber tomado todos, no deben quedar checkpoints duplicados
	for viejo: Node in checkpoints.get_children():
		viejo.queue_free()
	for i: int in get_children().size():
		# Obtenemos el marker
		var child: Marker3D = get_child(i) as Marker3D
		# Creamos un checkpoint en su posición
		var checkpoint_inst: Area3D = checkpoint_scene.instantiate()
		checkpoints.add_child(checkpoint_inst)
		checkpoint_inst.global_position = child.global_position
		checkpoint_inst.body_entered.connect(sennal.bind(checkpoint_inst, i))

func sennal(body: Node3D, inst: Node, index: int) -> void:
	# el área también detecta el suelo, las barreras y al gato
	var auto: Auto = body as Auto
	if auto == null:
		return
	auto.checkpoint_reached(index)
	Debug.log("Player " + auto.name + " has reached " + str(auto.checkpoints) + " checkpoints. Last checkpoint: " + str(auto.last_checkpoint))
	inst.queue_free()

func _on_finish_line_body_entered(body: Node3D) -> void:
	if body is not Auto:
		return
	spawn_all_checkpoints()
