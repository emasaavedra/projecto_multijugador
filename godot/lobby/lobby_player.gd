class_name LobbyPlayer
extends HBoxContainer


var player: Statics.PlayerData

@onready var name_label: Label = %NameLabel
@onready var role_label: Label = %RoleLabel
@onready var ready_icon: TextureRect = %ReadyIcon


func _ready() -> void:
	role_label.visible = Game.instance.use_roles
	Game.instance.player_updated.connect(_handle_player_updated)
	update()


func set_player(value: Statics.PlayerData) -> void:
	player = value
	if is_node_ready():
		update()


func update() -> void:
	if not player:
		return
	name_label.text = player.name
	role_label.text = Statics.get_role_name(player.role)
	ready_icon.modulate = Color.GREEN if player.vote else Color.WHITE


func _handle_player_updated(id: int) -> void:
	if player and player.id == id:
		update()
