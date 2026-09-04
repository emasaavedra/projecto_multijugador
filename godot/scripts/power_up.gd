extends Area3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body is VehicleBody3D:
		pick_item(body)
		queue_free()
		

func pick_item(player: Auto) -> void:
	#Debug.log(player.name + " ha recogido el item!", 10)
	player.picked_an_item.rpc()
	
