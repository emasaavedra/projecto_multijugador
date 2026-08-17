class_name LobbyWaitingScreen
extends Control

@onready var player_texture: TextureRect = %PlayerTexture
@onready var player_name: Label = %PlayerName
@onready var role_button: Button = %RoleButton
@onready var ready_button: Button = %ReadyButton
@onready var player_list: VBoxContainer = %PlayerList
@onready var waiting_label: Label = %WaitingLabel
@onready var back_button: Button = %BackButton
@onready var role_container: PanelContainer = %RoleContainer
@onready var role_list: VBoxContainer = %RoleList
@onready var start_timer: Timer = $StartTimer
@onready var game_start_container: PanelContainer = %GameStartContainer
@onready var game_start_counter: Label = %GameStartCounter



var LOBBY_PLAYER_SCENE: PackedScene = preload("res://lobby/lobby_player.tscn")


func _ready() -> void:
	player_name.text = Game.instance.get_current_player().name
	ready_button.pressed.connect(_toggle_ready)
	Game.instance.players_updated.connect(_handle_players_updated)
	Game.instance.player_updated.connect(func(_id: int) -> void: _update_ready_button())
	Game.instance.vote_updated.connect(func(_id: int) -> void: _handle_vote_updated())
	if multiplayer.is_server():
		start_timer.timeout.connect(func() -> void: _start_game.rpc())
	_handle_players_updated()
	role_button.visible = Game.instance.use_roles
	back_button.pressed.connect(_handle_back_pressed)
	role_button.pressed.connect(_handle_role_pressed)
	role_container.hide()
	game_start_container.hide()
	
	_update_ready_button()
	
	if Game.instance.use_roles:
		_fill_role_container()
		var role: Statics.Role = Game.instance.get_current_player().role
		role_button.text = Statics.get_role_name(role)
		if role == Statics.Role.NONE:
			role_button.text = "Role?"


func _process(_delta: float) -> void:
	game_start_counter.text = str(int(ceil(start_timer.time_left)))


func _toggle_ready() -> void:
	Game.instance.set_current_player_vote(not Game.instance.get_current_player().vote)
	_update_player()


func _update_player() -> void:
	var player_ready: bool = Game.instance.get_current_player().vote
	player_texture.modulate = Color.GREEN if player_ready else Color.WHITE
	role_container.hide()


func _handle_players_updated() -> void:
	for child: Node in player_list.get_children():
		child.queue_free()
	waiting_label.visible = Game.instance.players.size() == 1
	for player: Statics.PlayerData in Game.instance.players:
		if player.id != multiplayer.get_unique_id():
			var lobby_player_inst: LobbyPlayer = LOBBY_PLAYER_SCENE.instantiate()
			lobby_player_inst.set_player(player)
			player_list.add_child(lobby_player_inst)
	_update_ready_button()
	if multiplayer.is_server():
		Game.instance.reset_votes()


func _handle_back_pressed() -> void:
	if multiplayer.is_server():
		Lobby.instance.go_to_host()
	else:
		Lobby.instance.go_to_join()


func _handle_role_pressed() -> void:
	role_container.visible = not role_container.visible


func _fill_role_container() -> void:
	# Skip Role.NONE
	for i: int in Statics.Role.size() - 1:
		var button: Button = Button.new()
		button.text = Statics.get_role_name(i + 1)
		button.pressed.connect(func() -> void: _update_role(i + 1))
		role_list.add_child(button)


func _update_role(role: Statics.Role) -> void:
	Game.instance.set_current_player_role(role)
	role_button.text = Statics.get_role_name(role)
	role_container.hide()


func _handle_vote_updated() -> void:
	_update_player()
	if multiplayer and multiplayer.is_server():
		var all_voted: bool = true
		for player: Statics.PlayerData in Game.instance.players:
			all_voted = all_voted and player.vote
		if all_voted and _can_start_game():
			_start_timer.rpc()
		elif not start_timer.is_stopped():
			_stop_timer.rpc()

@rpc("reliable", "call_local")
func _start_timer() -> void:
	start_timer.start()
	game_start_container.show()
	role_button.disabled = true


@rpc("reliable", "call_local")
func _stop_timer() -> void:
	start_timer.stop()
	game_start_container.hide()
	role_button.disabled = false
	


@rpc("reliable", "call_local")
func _start_game() -> void:
	Game.instance.set_current_player_vote(false)
	get_tree().change_scene_to_packed(Game.instance.main_scene)


func _can_start_game() -> bool:
	var quantity: bool = Game.instance.players.size() >= Game.instance.min_players
	var completion: bool = not Game.instance.use_roles or not Game.instance.all_roles or _are_all_roles_selected()
	var uniqueness: bool = not Game.instance.use_roles or not Game.instance.unique_roles or _are_all_roles_unique()
	var fullness: bool = not Game.instance.use_roles or _all_players_selected_role()
	return quantity and completion and uniqueness and fullness


func _update_ready_button() -> void:
	ready_button.disabled = not _can_start_game()


func _are_all_roles_selected() -> bool:
	var roles: Array = Statics.Role.values()
	# remove NONE
	roles.pop_front()
	for player: Statics.PlayerData in Game.instance.players:
		roles.erase(player.role)
	return roles.is_empty()


func _are_all_roles_unique() -> bool:
	var roles: Array = Statics.Role.values()
	# remove NONE
	roles.pop_front()
	for player: Statics.PlayerData in Game.instance.players:
		if roles.has(player.role):
			roles.erase(player.role)
		else:
			return false
	return true

func _all_players_selected_role() -> bool:
	for player: Statics.PlayerData in Game.instance.players:
		if player.role == Statics.Role.NONE:
			return false
	return true
