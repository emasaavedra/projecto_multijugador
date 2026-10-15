extends Area3D

func _ready() -> void:
	# Solo el servidor procesa la recogida, así se aplica una sola vez
	if multiplayer.is_server():
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	var player: Auto = body as Auto
	if player:
		pick_item(player)
		remove_item.rpc()

func pick_item(player: Auto) -> void:
	#Debug.log(player.name + " ha recogido el item!", 10)
	player.picked_an_item.rpc()

@rpc("authority", "call_local", "reliable")
func remove_item() -> void:
	queue_free()
