extends VehicleBody3D
class_name Auto
@export var steer_acceleration: float = 3.0
@export var steer_max: float = 0.5
@export var engine_power: float = 600.0
@export var brake_force: float = 300.0

@onready var gato: CharacterBody3D = $Gato
@onready var label_3d: Label3D = $Label3D
@onready var camera_3d: Camera3D = $SpringArm3D/Camera3D
@onready var input_synchronizer: InputSynchronizer = $InputSynchronizer
@onready var sync_timer: Timer = $SyncTimer

func _ready() -> void:
	var player_data: Statics.PlayerData = Game.instance.get_player(get_multiplayer_authority())
	label_3d.text = player_data.name
	#sync_timer.timeout.connect(_on_sync_timeout)
	#if is_multiplayer_authority():
	#	sync_timer.start()
	

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("test") and is_multiplayer_authority():
		test.rpc()

func setup(player_data: Statics.PlayerData) -> void:
	label_3d.text = player_data.name
	set_multiplayer_authority(player_data.id)
	camera_3d.current = is_multiplayer_authority()
	#if is_multiplayer_authority():
	#	sync_timer.start()
	
func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	var steer_input: float = input_synchronizer.steer_input
	var force_input: float = input_synchronizer.force_input

	engine_force = force_input * engine_power
	brake = brake_force if is_zero_approx(force_input) else 0.0
	steering = move_toward(steering, -steer_input * steer_max, steer_acceleration * delta)
	gato._actualizar_animacion(force_input, steer_max)
	
	send_data.rpc(global_position, global_rotation, engine_force, brake, steering)
	

@rpc("any_peer", "call_local", "reliable")
func test() -> void:
	Debug.log(name, 10)

@rpc("authority", "call_remote", "unreliable_ordered")
func send_data(pos: Vector3, rot: Vector3, engine: float, freno: float, steer_f: float) -> void:
	global_position = pos
	global_rotation = rot
	engine_force = engine
	brake = freno
	steering = steer_f

#func _on_sync_timeout() -> void:
#	_sync.rpc(global_position, global_rotation, brake, engine_force, steering)

#@rpc("reliable")
#func _sync(pos: Vector3, rot: Vector3, freno: float, engine: float, steer_f: float) -> void:
#	global_position = global_position.lerp(pos, 0.1)
#	global_rotation = global_rotation.lerp(rot, 0.1)
	#brake = brake.lerp(freno, 0.5)
#	brake = freno
#	engine_force = engine
#	steering = steer_f

@rpc("any_peer", "call_local")
func picked_an_item() -> void:
	Debug.log("he tomado el item :D", 10)
