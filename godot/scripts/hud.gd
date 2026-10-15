class_name UIHud
extends CanvasLayer

const PLAYER_LAPS: PackedScene = preload("uid://blfte43wsa14n")
const TAMANO_CASILLA: float = 96.0
@onready var player_laps_container: VBoxContainer = %PlayerLapsContainer

var _icono_item: TextureRect
var _usos_item: Label

func _ready() -> void:
	for player_data: Statics.PlayerData in Game.instance.players:
		var player_laps: UIPlayerLaps = PLAYER_LAPS.instantiate()
		player_laps_container.add_child(player_laps)
		player_laps.setup(player_data)
	_crear_casilla_item()

## Casilla arriba a la izquierda con el ítem que tiene el jugador
func _crear_casilla_item() -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.position = Vector2(16, 16)
	add_child(panel)
	_icono_item = TextureRect.new()
	_icono_item.custom_minimum_size = Vector2(TAMANO_CASILLA, TAMANO_CASILLA)
	_icono_item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icono_item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	panel.add_child(_icono_item)
	_usos_item = Label.new()
	_usos_item.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_usos_item.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_usos_item.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_usos_item.add_theme_font_size_override("font_size", 24)
	_usos_item.add_theme_color_override("font_outline_color", Color.BLACK)
	_usos_item.add_theme_constant_override("outline_size", 6)
	_icono_item.add_child(_usos_item)
	mostrar_item(Items.Tipo.NINGUNO, 0)

func mostrar_item(tipo: Items.Tipo, usos: int) -> void:
	_icono_item.texture = Items.ICONOS.get(tipo)
	_usos_item.text = "x%d" % usos if usos > 1 else ""
