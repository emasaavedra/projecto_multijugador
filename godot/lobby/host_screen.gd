class_name LobbyHostScreen
extends Control

@onready var player_name: LineEdit = %PlayerName
@onready var host_button: Button = %HostButton
@onready var back_button: Button = %BackButton
@onready var error_label: Label = %ErrorLabel
@onready var error_timer: Timer = $ErrorTimer


func _ready() -> void:
	player_name.text = OS.get_environment("USERNAME") + (str(randi() % 1000) if OS.has_feature("editor")
 else "")
	player_name.caret_column = player_name.text.length()
	player_name.grab_focus()
	host_button.pressed.connect(_host)
	error_timer.timeout.connect(func() -> void: error_label.hide())
	error_label.hide()
	back_button.pressed.connect(func() -> void: Lobby.instance.go_to_menu())


func _host() -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var err: Error = peer.create_server(Statics.PORT, Statics.MAX_CLIENTS)
	if err != OK:
		error_label.show()
		error_timer.stop()
		error_timer.start()
		return
	multiplayer.multiplayer_peer = peer
	Game.instance.add_player(Statics.PlayerData.new(multiplayer.get_unique_id(), player_name.text, 0))
	Debug.add_to_window_title("Server")
	Game.instance.update_player_id()
	get_tree().change_scene_to_file("res://lobby/waiting_screen.tscn")
