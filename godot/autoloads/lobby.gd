extends Node

static var instance: Lobby

@export var return_to_lobby_on_player_disconnect : bool = true
@export var debug : bool = false

var _skip_server_disconnect_action: bool = false

@onready var player_disconnected: MarginContainer = %PlayerDisconnected
@onready var server_disconnected: MarginContainer = %ServerDisconnected
@onready var message_container: Panel = %MessageContainer


func _enter_tree() -> void:
	instance = self


func _ready() -> void:
	multiplayer.connected_to_server.connect(_handle_connected_to_server)
	multiplayer.connection_failed.connect(_handle_connection_failed)
	multiplayer.peer_connected.connect(_handle_peer_connected)
	multiplayer.peer_disconnected.connect(_handle_peer_disconnected)
	multiplayer.server_disconnected.connect(_handle_server_disconnected)

	message_container.hide()
	player_disconnected.hide()
	server_disconnected.hide()


func _handle_connected_to_server() -> void:
	if debug:
		Debug.log("Connected to server")
	Game.instance.update_player_id()


func _handle_connection_failed() -> void:
	if debug:
		Debug.log("Connection Failed")


func _handle_peer_connected(id: int) -> void:
	if debug:
		Debug.log("Peer connected %d" % id)
	
	if not Game.instance.get_current_player():
		# exception for lobby test
		return
	
	# If it's server or I already have an index assigned
	if id == 1 or Game.instance.get_current_player().index != -1:
		send_data.rpc_id(id, Game.instance.get_current_player().to_dict())


func _handle_peer_disconnected(id: int) -> void:
	if debug:
		Debug.log("Peer disconnected %d" % id)
		
	if id == 1:
		# server disconnect will handle it
		return
	
	if return_to_lobby_on_player_disconnect and \
		get_tree().current_scene is not LobbyWaitingScreen:
		go_to_lobby()
	
	Game.instance.remove_player(id)


func _handle_server_disconnected() -> void:
	if debug:
		Debug.log("Server disconnected")
	
	if _skip_server_disconnect_action:
		_skip_server_disconnect_action = false
		return
	
	get_tree().paused = true
	message_container.show()
	server_disconnected.show()
	await get_tree().create_timer(2.5).timeout
	server_disconnected.hide()
	message_container.hide()
	go_to_menu()
	get_tree().paused = false


@rpc("any_peer", "call_local", "reliable")
func go_to_lobby() -> void:
	get_tree().change_scene_to_file("res://lobby/waiting_screen.tscn")


func go_to_menu() -> void:
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
	multiplayer.multiplayer_peer.close()
	reset()


func go_to_host() -> void:
	get_tree().change_scene_to_file("res://lobby/host_screen.tscn")
	_skip_server_disconnect_action = true
	reset()


func go_to_join() -> void:
	get_tree().change_scene_to_file("res://lobby/join_screen.tscn")
	reset()


@rpc("any_peer", "reliable")
func send_data(data: Dictionary) -> void:
	if multiplayer.is_server():
		# A new player sent its data to the server, assing an index
		data.index = Game.instance.players.size()
		send_data.rpc(data)
	if debug:
		Debug.log("Player data from %s received" % data.name)
	Game.instance.add_player(Statics.PlayerData.from_dict(data))
	if data.id == multiplayer.get_unique_id():
		Debug.index = data.index
		Debug.add_to_window_title("Client %d" % data.index)


func reset() -> void:
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	Game.instance.players = []
	Debug.reset_window_title()
	Game.instance.update_player_id()
