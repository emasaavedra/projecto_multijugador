extends Node3D

@onready var front: Area3D = $Front
@onready var back: Area3D = $Back


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_back_body_entered(body: Node3D) -> void:
	Debug.log("Un jugador se pasó de listo.")


func _on_front_body_entered(body: Node3D) -> void:
	Debug.log("Un jugador pasó por la meta.")
