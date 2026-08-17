extends Node


@onready var canvas_layer: CanvasLayer  = CanvasLayer.new()
@onready var container: VBoxContainer = VBoxContainer.new()

var index: int = 0
var window_title: String = ""


func _ready() -> void:
	if not OS.is_debug_build():
		return
	add_child(canvas_layer)
	canvas_layer.layer = 128
	canvas_layer.add_child(container)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	window_title = get_window().title


func log(message: Variant, seconds: float = 2) -> void:
	if not OS.is_debug_build():
		return
	if is_online():
		var prefix: String = _get_prefix()
		print_rich("[b]%s:[/b] " % prefix, message)
		add_message.rpc("%s: %s" % [prefix, str(message)], seconds)
	else:
		add_message(str(message), seconds)
		print(message)


@rpc("any_peer", "reliable", "call_local")
func add_message(message: String, seconds: float) -> void:
	var label: Label = Label.new()
	label.text = message
	label.set("theme_override_constants/outline_size", 2)
	label.set("theme_override_colors/font_outline_color", Color.BLACK)
	container.add_child(label)
	container.move_child(label, 0)
	await get_tree().create_timer(seconds).timeout
	container.remove_child(label)
	label.queue_free()


func add_to_window_title(text: String) -> void:
	if not OS.is_debug_build():
		return
	get_window().title = "%s - %s" % [window_title, text]


func reset_window_title() -> void:
	get_window().title = window_title


func is_online() -> bool:
	return multiplayer.multiplayer_peer and \
		not multiplayer.multiplayer_peer is OfflineMultiplayerPeer and \
		multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


func _get_prefix() -> String:
	if multiplayer.is_server():
		return "Server"
	elif index:
		return "Client %d" % index
	else:
		return "Client"
