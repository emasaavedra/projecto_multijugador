extends VehicleBody3D
@export var steer_acceleration: float = 3.0
@export var steer_max: float = 0.5
@export var engine_power: float = 600.0
@export var brake_force: float = 300.0

func _physics_process(delta: float) -> void:
	var steer_input: float = Input.get_axis("left", "right")
	var force_input: float = Input.get_axis("backward", "forward")
	
	engine_force = force_input * engine_power
	brake = brake_force if is_zero_approx(force_input) else 0.0
	steering = move_toward(steering, -steer_input * steer_max, steer_acceleration * delta)
