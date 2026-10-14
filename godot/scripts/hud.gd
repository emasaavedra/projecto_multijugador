class_name UIHud
extends CanvasLayer

const PLAYER_LAPS: PackedScene = preload("uid://blfte43wsa14n")
@onready var player_laps_container: VBoxContainer = %PlayerLapsContainer

func _ready() -> void:
	for player_data: Statics.PlayerData in Game.instance.players:
		var player_laps: UIPlayerLaps = PLAYER_LAPS.instantiate()
		player_laps_container.add_child(player_laps)
		player_laps.setup(player_data)

func set_max_laps(value: int) -> void:
	pass
	#player_laps_container.max_laps = value
