extends MainMenu

## Menú de inicio de ejemplo: atardecer en Santiago, edificios, calle animada
## e ítems flotando. Los botones usan la lógica de main_menu.gd (Host, Join, Credits, Quit).
## Para cambiar los assets: reemplazar el Fondo y los ICONOS_FLOTANTES.
## Fotos de gatitos: basta con agregar imágenes (.png, .jpg, .webp) a CARPETA_FOTOS
## y aparecen solas en la rotación, sin tocar código.

const CARPETA_FOTOS: String = "res://resources/fotos inicio/"
const SEGUNDOS_POR_FOTO: float = 4.0

const ICONOS_FLOTANTES: Array[Texture2D] = [
	preload("res://assets/items/churu.png"),
	preload("res://assets/items/triple_churu.png"),
	preload("res://assets/items/pepino.png"),
	preload("res://assets/items/bip.png"),
	preload("res://assets/items/milk-cat-cat.png"),
]

const COLOR_EDIFICIOS: Color = Color("1b1035")
const COLOR_VENTANA: Color = Color("ffd27a")
const COLOR_CALLE: Color = Color("2a2a35")
const COLOR_LINEA: Color = Color("ffcf3f")
const ALTURA_CALLE: float = 90.0

@onready var skyline: Control = %Skyline
@onready var calle: Control = %Calle
@onready var titulo: Control = %Titulo
@onready var mascota: Control = %Mascota
@onready var botones: VBoxContainer = %Botones
@onready var flotantes: Control = %Flotantes
@onready var foto: TextureRect = %Foto

var _fotos: Array[Texture2D] = []
var _indice_foto: int = 0
var _edificios: Array[Rect2] = []
var _ventanas: Array[Rect2] = []
var _desplazamiento_calle: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	super._ready()
	skyline.draw.connect(_dibujar_skyline)
	calle.draw.connect(_dibujar_calle)
	skyline.resized.connect(_generar_ciudad)
	_generar_ciudad()
	_animar_entrada()
	_animar_mascota()
	_iniciar_fotos()
	for boton: Button in botones.get_children():
		_preparar_boton(boton)
	for i: int in 10:
		_crear_flotante(true)


func _process(delta: float) -> void:
	# Las líneas de la calle avanzan para dar sensación de velocidad
	_desplazamiento_calle = fposmod(_desplazamiento_calle + 260.0 * delta, 120.0)
	calle.queue_redraw()
	titulo.rotation = sin(Time.get_ticks_msec() / 600.0) * 0.03


# --- Ciudad -----------------------------------------------------------------

func _generar_ciudad() -> void:
	_rng.seed = 7 # siempre la misma ciudad
	_edificios.clear()
	_ventanas.clear()
	var ancho: float = skyline.size.x
	var piso: float = skyline.size.y
	var x: float = -10.0
	while x < ancho:
		var w: float = _rng.randf_range(50.0, 120.0)
		var h: float = _rng.randf_range(90.0, 260.0)
		_edificios.append(Rect2(x, piso - h, w, h))
		# Ventanas encendidas al azar
		var vy: float = piso - h + 14.0
		while vy < piso - 20.0:
			var vx: float = x + 10.0
			while vx < x + w - 16.0:
				if _rng.randf() < 0.35:
					_ventanas.append(Rect2(vx, vy, 8.0, 10.0))
				vx += 18.0
			vy += 22.0
		x += w + _rng.randf_range(2.0, 14.0)
	# Una torre alta con antena, al estilo de las torres de telecomunicaciones del centro
	var tx: float = ancho * 0.45
	_edificios.append(Rect2(tx, piso - 330.0, 46.0, 330.0))
	_edificios.append(Rect2(tx + 21.0, piso - 380.0, 4.0, 50.0))
	skyline.queue_redraw()


func _dibujar_skyline() -> void:
	for rect: Rect2 in _edificios:
		skyline.draw_rect(rect, COLOR_EDIFICIOS)
	for rect: Rect2 in _ventanas:
		skyline.draw_rect(rect, COLOR_VENTANA)


func _dibujar_calle() -> void:
	var tam: Vector2 = calle.size
	calle.draw_rect(Rect2(Vector2.ZERO, tam), COLOR_CALLE)
	calle.draw_rect(Rect2(0, 0, tam.x, 6), Color("4a4a5a"))
	var y: float = tam.y * 0.5 - 4.0
	var x: float = -120.0 + _desplazamiento_calle
	while x < tam.x:
		calle.draw_rect(Rect2(x, y, 60, 8), COLOR_LINEA)
		x += 120.0


# --- Animaciones --------------------------------------------------------------

func _animar_entrada() -> void:
	# El título cae desde arriba con rebote
	var y_final: float = titulo.position.y
	titulo.position.y -= 300.0
	titulo.pivot_offset = titulo.size / 2.0
	var t: Tween = create_tween()
	t.tween_property(titulo, "position:y", y_final, 0.9) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	# Los botones entran uno por uno desde la derecha
	var retraso: float = 0.4
	for boton: Button in botones.get_children():
		boton.modulate.a = 0.0
		var tb: Tween = create_tween()
		tb.tween_interval(retraso)
		tb.tween_property(boton, "modulate:a", 1.0, 0.35)
		retraso += 0.12


func _animar_mascota() -> void:
	mascota.pivot_offset = mascota.size / 2.0
	var t: Tween = create_tween().set_loops()
	t.tween_property(mascota, "position:y", mascota.position.y - 14.0, 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(mascota, "position:y", mascota.position.y, 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# --- Fotos de gatitos ---------------------------------------------------------

func _iniciar_fotos() -> void:
	# list_directory también funciona en el juego exportado (donde las imágenes
	# originales ya no existen, solo sus versiones importadas)
	for archivo: String in ResourceLoader.list_directory(CARPETA_FOTOS):
		if archivo.ends_with("/"):
			continue
		var textura: Texture2D = ResourceLoader.load(CARPETA_FOTOS + archivo, "Texture2D") as Texture2D
		if textura:
			_fotos.append(textura)
	if _fotos.is_empty():
		return
	_fotos.shuffle()
	foto.texture = _fotos[0]
	if _fotos.size() < 2:
		return
	var timer: Timer = Timer.new()
	timer.wait_time = SEGUNDOS_POR_FOTO
	timer.timeout.connect(_siguiente_foto)
	add_child(timer)
	timer.start()


## Gira el marco como una carta y cambia la foto justo cuando queda de canto
func _siguiente_foto() -> void:
	_indice_foto = (_indice_foto + 1) % _fotos.size()
	var t: Tween = create_tween()
	t.tween_property(mascota, "scale:x", 0.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_callback(func() -> void: foto.texture = _fotos[_indice_foto])
	t.tween_property(mascota, "scale:x", 1.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _preparar_boton(boton: Button) -> void:
	boton.pivot_offset = boton.custom_minimum_size / 2.0
	boton.mouse_entered.connect(_escalar.bind(boton, 1.08))
	boton.mouse_exited.connect(_escalar.bind(boton, 1.0))
	boton.focus_entered.connect(_escalar.bind(boton, 1.08))
	boton.focus_exited.connect(_escalar.bind(boton, 1.0))


func _escalar(boton: Button, escala: float) -> void:
	boton.pivot_offset = boton.size / 2.0
	create_tween().tween_property(boton, "scale", Vector2.ONE * escala, 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Un ítem que sube flotando y girando; al salir de la pantalla se crea otro
func _crear_flotante(posicion_inicial_al_azar: bool) -> void:
	var icono: TextureRect = TextureRect.new()
	icono.texture = ICONOS_FLOTANTES[_rng.randi() % ICONOS_FLOTANTES.size()]
	icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var tam: float = _rng.randf_range(36.0, 72.0)
	icono.size = Vector2(tam, tam)
	icono.pivot_offset = icono.size / 2.0
	icono.modulate.a = _rng.randf_range(0.25, 0.55)
	icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flotantes.add_child(icono)

	var pantalla: Vector2 = flotantes.size
	var x: float = _rng.randf_range(0.0, pantalla.x - tam)
	var y_inicio: float = _rng.randf_range(0.0, pantalla.y) if posicion_inicial_al_azar else pantalla.y + 20.0
	icono.position = Vector2(x, y_inicio)
	var duracion: float = _rng.randf_range(8.0, 14.0) * (y_inicio + tam) / (pantalla.y + tam)

	var t: Tween = create_tween().set_parallel()
	t.tween_property(icono, "position:y", -tam - 10.0, duracion)
	t.tween_property(icono, "rotation", _rng.randf_range(-TAU, TAU), duracion)
	t.chain().tween_callback(func() -> void:
		icono.queue_free()
		_crear_flotante(false))
