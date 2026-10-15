extends CharacterBody3D
class_name Auto

## Jugador: un gato que corre por la pista con movimiento arcade estilo kart.
## Cada cliente mueve su propio gato y manda su posición a los demás.

@export var max_speed: float = 22.0
@export var reverse_speed: float = 7.0
@export var acceleration: float = 30.0
@export var brake_deceleration: float = 40.0
@export var friction: float = 14.0
@export var turn_speed: float = 2.5
@export var gravity: float = 25.0
@export var jump_force: float = 8.0
@export var mouse_sensitivity: float = 0.01
@export var camera_min_pitch: float = -20
@export var camera_max_pitch: float = 30
var last_checkpoint: Checkpoint

# Velocidad hacia adelante (negativa = reversa)
var speed: float = 0.0

@onready var spring_arm_3d: SpringArm3D = $SpringArm3D
@onready var gato: Node3D = $Gato
@onready var label_3d: Label3D = $Label3D
@onready var camera_3d: Camera3D = $SpringArm3D/Camera3D
@onready var input_synchronizer: InputSynchronizer = $InputSynchronizer
@onready var hud: UIHud = $HUD
@onready var victory_screen: VictoryScreen = $VictoryScreen

func _ready() -> void:
	var player_data: Statics.PlayerData = Game.instance.get_player(get_multiplayer_authority())
	label_3d.text = player_data.name
	hud.visible = is_multiplayer_authority()
	victory_screen.hide()
	# Que la cámara no choque con el propio gato
	spring_arm_3d.add_excluded_object(get_rid())

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("test") and is_multiplayer_authority():
		test.rpc()

func setup(player_data: Statics.PlayerData) -> void:
	label_3d.text = player_data.name
	set_multiplayer_authority(player_data.id)
	camera_3d.current = is_multiplayer_authority()

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		gato._actualizar_animacion(speed, max_speed)
		return
	var steer_input: float = input_synchronizer.steer_input
	var force_input: float = input_synchronizer.force_input

	# Acelerar / frenar / reversa
	if force_input > 0.0:
		speed = move_toward(speed, max_speed * force_input, acceleration * delta)
	elif force_input < 0.0:
		var deceleration: float = brake_deceleration if speed > 0.0 else acceleration
		speed = move_toward(speed, -reverse_speed, deceleration * delta)
	else:
		speed = move_toward(speed, 0.0, friction * delta)

	# Girar: al ir en reversa se invierte, como en un kart
	var direction: float = -1.0 if speed < 0.0 else 1.0
	rotate_y(-steer_input * turn_speed * direction * delta)

	# Gravedad y salto
	if is_on_floor():
		if input_synchronizer.jump:
			velocity.y = jump_force
	else:
		velocity.y -= gravity * delta
	input_synchronizer.jump = false

	# El frente del gato es +Z
	var forward: Vector3 = global_basis.z
	velocity.x = forward.x * speed
	velocity.z = forward.z * speed
	move_and_slide()

	gato._actualizar_animacion(speed, max_speed)
	send_data.rpc(global_position, global_rotation, speed)

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	var mouse_motion: InputEventMouseMotion = event as InputEventMouseMotion
	if mouse_motion:
		spring_arm_3d.rotation.y -= mouse_motion.relative.x * mouse_sensitivity
		camera_3d.rotation.x = clamp(camera_3d.rotation.x - mouse_motion.relative.y * mouse_sensitivity,
									deg_to_rad(camera_min_pitch),
									deg_to_rad(camera_max_pitch))

@rpc("any_peer", "call_local", "reliable")
func test() -> void:
	Debug.log(name, 10)

@rpc("authority", "call_remote", "unreliable_ordered")
func send_data(pos: Vector3, rot: Vector3, new_speed: float) -> void:
	global_position = pos
	global_rotation = rot
	speed = new_speed

@rpc("any_peer", "call_local")
func picked_an_item() -> void:
	Debug.log("he tomado el item :D", 10)

func write_winner(winner: String) -> void:
	victory_screen.winner_label.text = winner
	victory_screen.show()
