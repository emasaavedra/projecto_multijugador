class_name UIPlayerLaps
extends HBoxContainer

@onready var name_label: Label = %NameLabel
@onready var number_laps: Label = %"Number Laps"

var _player_data: Statics.PlayerData

func setup(player_data: Statics.PlayerData) -> void:
	_player_data = player_data
	name_label.text = player_data.name
	_on_checkpoints_change(player_data.checkpoints)
	player_data.checkpoints_changed.connect(_on_checkpoints_change)

func _on_checkpoints_change(value: int) -> void:
	if Game.checkpoints_amount <= 0:
		number_laps.text = "0"
		return
	@warning_ignore("integer_division")
	number_laps.text = str(value / Game.checkpoints_amount)
