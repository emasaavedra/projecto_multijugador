class_name FinishLine
extends Node3D

@onready var area: Area3D = $Area
var laps: int
var checkpoints: int
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	laps = Game.laps_amount
	checkpoints = Game.checkpoints_amount

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#func _on_body_entered(body: Node3D) -> void:
#	if area.body_entered
#	var player: Auto = body as Auto
#	var laps: int = Game.laps_amount
#	var checkpoints: int = Game.checkpoints_amount
#	if not player:
#		return
#	if player.checkpoints / checkpoints == laps:
#		pass
#	Game.instance.checkpoint_reached(player.get_multiplayer_authority(), 1)


#func _on_area_body_entered(body: Auto) -> Auto:
#	print(body.name + " tiene " + str(body.checkpoints / checkpoints) + " de " + str(laps) + " vueltas.")
#	if (body.checkpoints / checkpoints) == laps:
#		return body
#	else:
#		return
