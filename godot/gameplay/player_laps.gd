class_name UIPlayerLaps
extends HBoxContainer

@onready var name_label: Label = %NameLabel
@onready var number_laps: Label = %"Number Laps"

var _player_data: Statics.PlayerData

var checkpoints_amount: int

func _ready() -> void:
	checkpoints_amount = Game.checkpoints_amount
	print("Checkpoints amount: ", checkpoints_amount)

func setup(player_data: Statics.PlayerData) -> void:
	checkpoints_amount = Game.checkpoints_amount
	_player_data = player_data
	name_label.text = player_data.name
	number_laps.text = str(player_data.checkpoints)
	player_data.checkpoints_changed.connect(_on_checkpoints_change)

func _on_checkpoints_change(value: int) -> void:
	number_laps.text = str(floor(value/checkpoints_amount))
