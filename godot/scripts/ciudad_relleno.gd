@tool
class_name CiudadRelleno
extends Node3D

const SHADER_FACHADA: Shader = preload("res://shaders/fachada.gdshader")

## Rellena el escenario con edificios genéricos (en damero, como el centro de Santiago)
## y árboles a los costados de la pista, sin tapar la pista ni los hitos.
## Todo va en MultiMesh y sin colisión: las barreras de la pista mantienen a los autos dentro.

@export var pista: PistaGenerador
## Los hijos de este nodo se consideran hitos; nada se genera dentro de su radio.
@export var hitos: Node3D
@export var radio_hito: float = 30.0
@export var semilla: int = 26
@export_group("Edificios")
@export var zona: Rect2 = Rect2(-300, -200, 640, 400)
@export var tamano_manzana: float = 28.0
@export var ancho_calle: float = 8.0
@export var margen_pista: float = 16.0
@export var altura_min: float = 8.0
@export var altura_max: float = 30.0
@export var colores: PackedColorArray = PackedColorArray([
	Color(0.86, 0.82, 0.72), Color(0.75, 0.73, 0.7), Color(0.8, 0.62, 0.5),
	Color(0.92, 0.88, 0.8), Color(0.6, 0.62, 0.66), Color(0.85, 0.75, 0.55),
])
@export_group("Fachadas")
## Texturas de fachada repetibles. Cada edificio usa una al azar; si está vacío, se usan solo colores.
@export var fachadas: Array[Texture2D] = []
## Cuántos pisos muestra cada textura de `fachadas` (mismo orden), para darle tamaño real.
@export var pisos_por_fachada: PackedInt32Array = PackedInt32Array()
@export var metros_por_piso: float = 3.5
@export var color_techo: Color = Color(0.45, 0.45, 0.47)
@export_group("Arboles")
@export var separacion_arboles: float = 14.0
@export var distancia_arboles: float = 10.0
@export_tool_button("Regenerar") var _boton_regenerar: Callable = generar


func _ready() -> void:
	# la pista genera su malla en su propio _ready; esperamos un frame por si acaso
	generar.call_deferred()


func generar() -> void:
	if not is_inside_tree() or pista == null or pista.recorrido == null:
		return
	for hijo: Node in get_children():
		if hijo.has_meta("generado"):
			remove_child(hijo)
			hijo.queue_free()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = semilla
	_generar_edificios(rng)
	_generar_arboles(rng)


func _libre_de_hitos(punto: Vector3, margen: float) -> bool:
	if hitos == null:
		return true
	for hito: Node in hitos.get_children():
		var nodo: Node3D = hito as Node3D
		if nodo == null:
			continue
		var radio: float = nodo.get_meta("radio", radio_hito)
		var delta: Vector3 = nodo.global_position - punto
		if Vector2(delta.x, delta.z).length() < radio + margen:
			return false
	return true


func _generar_edificios(rng: RandomNumberGenerator) -> void:
	# Un grupo por fachada (o uno solo si no hay fachadas)
	var grupos: int = maxi(fachadas.size(), 1)
	var transformaciones: Array = []
	var tonos: Array = []
	for g: int in grupos:
		var lista_transformaciones: Array[Transform3D] = []
		var lista_tonos: Array[Color] = []
		transformaciones.append(lista_transformaciones)
		tonos.append(lista_tonos)
	# RNG aparte para elegir fachada, así la ciudad no cambia de forma
	var rng_fachadas: RandomNumberGenerator = RandomNumberGenerator.new()
	rng_fachadas.seed = semilla + 1
	var paso: float = tamano_manzana + ancho_calle
	var x: float = zona.position.x
	while x < zona.end.x:
		var z: float = zona.position.y
		while z < zona.end.y:
			# cada manzana se divide en 1 a 4 edificios
			var divisiones: int = rng.randi_range(1, 2)
			var lado: float = tamano_manzana / divisiones
			for i: int in divisiones:
				for j: int in divisiones:
					var centro: Vector3 = global_position + Vector3(x + lado * (i + 0.5), 0.0, z + lado * (j + 0.5))
					var radio: float = lado * 0.71
					if pista.distancia_al_eje(centro) < pista.ancho / 2.0 + margen_pista + radio:
						continue
					if not _libre_de_hitos(centro, radio):
						continue
					var alto: float = rng.randf_range(altura_min, altura_max)
					var escala: Vector3 = Vector3(lado - rng.randf_range(0.5, 3.0), alto, lado - rng.randf_range(0.5, 3.0))
					var base: Basis = Basis.from_scale(escala)
					var g: int = rng_fachadas.randi() % grupos
					transformaciones[g].append(Transform3D(base, to_local(centro) + Vector3.UP * alto / 2.0))
					var color: Color = colores[rng.randi() % colores.size()]
					tonos[g].append(color.darkened(rng.randf_range(0.0, 0.15)))
			z += paso
		x += paso

	if fachadas.is_empty():
		var malla: BoxMesh = BoxMesh.new()
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.vertex_color_use_as_albedo = true
		malla.material = material
		_crear_multimesh("Edificios", malla, transformaciones[0], tonos[0])
		return

	for g: int in grupos:
		var textura: Texture2D = fachadas[g]
		var pisos: int = pisos_por_fachada[g] if g < pisos_por_fachada.size() else 3
		var alto_tile: float = pisos * metros_por_piso
		var ancho_tile: float = alto_tile * textura.get_width() / textura.get_height()
		var material_fachada: ShaderMaterial = ShaderMaterial.new()
		material_fachada.shader = SHADER_FACHADA
		material_fachada.set_shader_parameter("textura", textura)
		material_fachada.set_shader_parameter("metros_por_tile", Vector2(ancho_tile, alto_tile))
		material_fachada.set_shader_parameter("color_techo", color_techo)
		var malla_fachada: BoxMesh = BoxMesh.new()
		malla_fachada.material = material_fachada
		_crear_multimesh("Edificios%d" % g, malla_fachada, transformaciones[g], tonos[g])


func _generar_arboles(rng: RandomNumberGenerator) -> void:
	var troncos: Array[Transform3D] = []
	var copas: Array[Transform3D] = []
	var tonos: Array[Color] = []
	var curva: Curve3D = pista.recorrido.curve
	var longitud: float = curva.get_baked_length()
	var d: float = 0.0
	while d < longitud:
		var p: Vector3 = pista.recorrido.to_global(curva.sample_baked(d))
		var q: Vector3 = pista.recorrido.to_global(curva.sample_baked(fposmod(d + 1.0, longitud)))
		var lateral: Vector3 = (q - p).cross(Vector3.UP).normalized()
		for lado: float in [-1.0, 1.0]:
			var punto: Vector3 = p + lateral * lado * distancia_arboles
			punto.y = 0.0
			# si otro tramo de la pista pasa más cerca, el árbol quedaría encima de la carretera
			if pista.distancia_al_eje(punto) < distancia_arboles - 0.5:
				continue
			if not _libre_de_hitos(punto, 2.0):
				continue
			var alto: float = rng.randf_range(4.0, 6.5)
			var local: Vector3 = to_local(punto)
			troncos.append(Transform3D(Basis.from_scale(Vector3(0.5, alto, 0.5)), local + Vector3.UP * alto / 2.0))
			var copa: float = rng.randf_range(3.5, 5.0)
			copas.append(Transform3D(Basis.from_scale(Vector3.ONE * copa), local + Vector3.UP * (alto + copa * 0.3)))
			tonos.append(Color(0.25, 0.5, 0.2).lightened(rng.randf_range(0.0, 0.2)))
		d += separacion_arboles

	var tronco: CylinderMesh = CylinderMesh.new()
	tronco.height = 1.0
	tronco.top_radius = 0.5
	tronco.bottom_radius = 0.5
	tronco.radial_segments = 6
	tronco.rings = 1
	var material_tronco: StandardMaterial3D = StandardMaterial3D.new()
	material_tronco.albedo_color = Color(0.4, 0.3, 0.2)
	tronco.material = material_tronco
	_crear_multimesh("Troncos", tronco, troncos, [])

	var esfera: SphereMesh = SphereMesh.new()
	esfera.radius = 0.5
	esfera.height = 1.0
	esfera.radial_segments = 8
	esfera.rings = 4
	var material_copa: StandardMaterial3D = StandardMaterial3D.new()
	material_copa.vertex_color_use_as_albedo = true
	esfera.material = material_copa
	_crear_multimesh("Copas", esfera, copas, tonos)


func _crear_multimesh(nombre: String, malla: Mesh, transformaciones: Array[Transform3D], tonos: Array[Color]) -> void:
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = not tonos.is_empty()
	mm.mesh = malla
	mm.instance_count = transformaciones.size()
	for i: int in transformaciones.size():
		mm.set_instance_transform(i, transformaciones[i])
		if mm.use_colors:
			mm.set_instance_color(i, tonos[i])
	var instancia: MultiMeshInstance3D = MultiMeshInstance3D.new()
	instancia.name = nombre
	instancia.multimesh = mm
	instancia.set_meta("generado", true)
	add_child(instancia)
