class_name Checkpoint
extends Area3D

var previous_checkpoint: Checkpoint

func _ready() -> void:
	if multiplayer.is_server():
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	var player: Auto = body as Auto
	if not player:
		return
	if player.last_checkpoint != previous_checkpoint:
		return
	Game.instance.checkpoint_reached(player.get_multiplayer_authority(), 1)
	player.last_checkpoint = self
