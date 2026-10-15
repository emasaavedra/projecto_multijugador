class_name Statics
extends Node


const MAX_CLIENTS: int = 3
const PORT: int = 5409 # Number between 1024 and 65535.


enum Role {
	NONE,
	ROLE_A,
	ROLE_B,
	ROLE_C,
}


static func get_role_name(role: Role) -> String:
	match role:
		Role.NONE:
			return "None"
		Role.ROLE_A:
			return "Role A"
		Role.ROLE_B:
			return "Role B"
		Role.ROLE_C:
			return "Role C"
	return "Unknown"


class PlayerData:
	
	signal checkpoints_changed(value: int)
	
	var id: int
	var name: String
	# Position relative to other players
	var index: int = -1
	var role: Role
	var vote: bool = false
	var checkpoints: int:
		set(value):
			checkpoints = value
			checkpoints_changed.emit(checkpoints)

	
	func _init(new_id: int, new_name: String, new_index: int = -1, new_role: Role = Role.NONE) -> void:
		id = new_id
		name = new_name
		index = new_index
		role = new_role
		checkpoints = 0
	
	func _to_string() -> String:
		return "Player: {id: %d, name: %s, index: %d, role: %s}" % [id, name, index, Statics.get_role_name(role)]
	
	func to_dict() -> Dictionary:
		return {
			"id": id,
			"name": name,
			"index": index,
			"role": role,
			"vote": vote,
			"checkpoints": checkpoints,
		}
	
	static func from_dict(data: Dictionary) -> PlayerData:
		var player: PlayerData = PlayerData.new(data.id, data.name, data.index, data.role)
		player.vote = data.vote
		player.checkpoints = data.checkpoints
		return player
	
	func update(player_data: PlayerData) -> void:
		if id != player_data.id:
			return
		name = player_data.name
		index = player_data.index
		role = player_data.role
		vote = player_data.vote
		checkpoints = player_data.checkpoints
