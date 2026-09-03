class_name InputSynchronizer
extends MultiplayerSynchronizer

@export var steer_input: float
@export var force_input: float
@export var jump: bool

func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	steer_input = Input.get_axis("girar_izquierda", "girar_derecha")
	force_input = Input.get_axis("frenar", "acelerar")
	if Input.is_action_just_pressed("saltar"):
		broadcast_jump.rpc()

@rpc("call_local")
func broadcast_jump() -> void:
	jump = true
