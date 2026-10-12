@tool
class_name PistaGenerador
extends Node3D

## Genera la carretera (con UVs) y las dos barreras con colisión a partir de un Path3D cerrado.
## Al mover los puntos de la curva en el editor, la pista se regenera sola.

@export var recorrido: Path3D:
	set(value):
		if recorrido and recorrido.curve and recorrido.curve.changed.is_connected(generar):
			recorrido.curve.changed.disconnect(generar)
		recorrido = value
		if recorrido and recorrido.curve and not recorrido.curve.changed.is_connected(generar):
			recorrido.curve.changed.connect(generar)
		generar()
@export var ancho: float = 12.0
## Distancia en metros entre cada corte transversal de la malla.
@export var paso: float = 2.0
@export var altura_carretera: float = 0.03
@export_group("Barreras")
@export var distancia_borde: float = 0.4
@export var altura_barrera: float = 1.0
@export var grosor_barrera: float = 0.5
@export_group("Materiales")
@export var material_carretera: Material
@export var material_barrera: Material
@export_tool_button("Regenerar") var _boton_regenerar: Callable = generar


func _ready() -> void:
	generar()


func generar() -> void:
	if not is_inside_tree() or recorrido == null or recorrido.curve == null:
		return
	var curva: Curve3D = recorrido.curve
	var longitud: float = curva.get_baked_length()
	if longitud <= 0.0:
		return

	for hijo: Node in get_children():
		if hijo.has_meta("generado"):
			remove_child(hijo)
			hijo.queue_free()

	var muestras: int = maxi(int(longitud / paso), 8)
	var centros: PackedVector3Array = PackedVector3Array()
	var laterales: PackedVector3Array = PackedVector3Array()
	var distancias: PackedFloat32Array = PackedFloat32Array()
	for i: int in muestras:
		var d: float = longitud * i / muestras
		var anterior: Vector3 = curva.sample_baked(fposmod(d - paso, longitud))
		var siguiente: Vector3 = curva.sample_baked(fposmod(d + paso, longitud))
		var direccion: Vector3 = (siguiente - anterior)
		direccion.y = 0.0
		direccion = direccion.normalized() if direccion.length_squared() > 0.0001 else Vector3.FORWARD
		centros.append(recorrido.transform * curva.sample_baked(d))
		# lateral apunta a la derecha del sentido de avance
		laterales.append(direccion.cross(Vector3.UP).normalized())
		distancias.append(d)

	_crear_carretera(centros, laterales, distancias, longitud)
	var distancia_centro: float = ancho / 2.0 + distancia_borde + grosor_barrera / 2.0
	_crear_barrera("BarreraDerecha", centros, laterales, distancias, longitud, distancia_centro)
	_crear_barrera("BarreraIzquierda", centros, laterales, distancias, longitud, -distancia_centro)


## Distancia horizontal desde un punto (en coordenadas globales) al eje de la pista.
func distancia_al_eje(punto: Vector3) -> float:
	var local: Vector3 = recorrido.to_local(punto)
	var cercano: Vector3 = recorrido.curve.get_closest_point(local)
	return Vector2(local.x - cercano.x, local.z - cercano.z).length()


func _crear_carretera(centros: PackedVector3Array, laterales: PackedVector3Array,
		distancias: PackedFloat32Array, longitud: float) -> void:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = centros.size()
	for i: int in n + 1:
		var k: int = i % n
		var v: float = distancias[k] if i < n else longitud
		var arriba: Vector3 = Vector3.UP * altura_carretera
		st.set_normal(Vector3.UP)
		# UV.x: 0 borde izquierdo, 1 borde derecho. UV.y: metros recorridos.
		st.set_uv(Vector2(0.0, v))
		st.add_vertex(centros[k] - laterales[k] * ancho / 2.0 + arriba)
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(1.0, v))
		st.add_vertex(centros[k] + laterales[k] * ancho / 2.0 + arriba)
	for i: int in n:
		var a: int = i * 2
		st.add_index(a)
		st.add_index(a + 2)
		st.add_index(a + 1)
		st.add_index(a + 1)
		st.add_index(a + 2)
		st.add_index(a + 3)
	st.generate_tangents()

	var malla: MeshInstance3D = MeshInstance3D.new()
	malla.name = "Carretera"
	malla.mesh = st.commit()
	malla.material_override = material_carretera
	malla.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	malla.set_meta("generado", true)
	add_child(malla)


func _crear_barrera(nombre: String, centros: PackedVector3Array, laterales: PackedVector3Array,
		distancias: PackedFloat32Array, longitud: float, desplazamiento: float) -> void:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var caras: PackedVector3Array = PackedVector3Array()
	var n: int = centros.size()
	var g: float = grosor_barrera / 2.0
	var h: Vector3 = Vector3.UP * altura_barrera
	for i: int in n:
		var j: int = (i + 1) % n
		var v0: float = distancias[i]
		var v1: float = distancias[j] if j > 0 else longitud
		var c0: Vector3 = centros[i] + laterales[i] * desplazamiento
		var c1: Vector3 = centros[j] + laterales[j] * desplazamiento
		var interior0: Vector3 = c0 - laterales[i] * g * signf(desplazamiento)
		var interior1: Vector3 = c1 - laterales[j] * g * signf(desplazamiento)
		var exterior0: Vector3 = c0 + laterales[i] * g * signf(desplazamiento)
		var exterior1: Vector3 = c1 + laterales[j] * g * signf(desplazamiento)
		# cara interior, superior y exterior
		var invertir: bool = desplazamiento > 0.0
		_quad(st, caras, interior0, interior1, interior1 + h, interior0 + h, v0, v1, invertir)
		_quad(st, caras, interior0 + h, interior1 + h, exterior1 + h, exterior0 + h, v0, v1, invertir)
		_quad(st, caras, exterior1, exterior0, exterior0 + h, exterior1 + h, v1, v0, invertir)
	st.generate_normals()

	var forma: ConcavePolygonShape3D = ConcavePolygonShape3D.new()
	forma.backface_collision = true
	forma.set_faces(caras)

	var cuerpo: StaticBody3D = StaticBody3D.new()
	cuerpo.name = nombre
	cuerpo.set_meta("generado", true)
	var colision: CollisionShape3D = CollisionShape3D.new()
	colision.shape = forma
	cuerpo.add_child(colision)
	var malla: MeshInstance3D = MeshInstance3D.new()
	malla.mesh = st.commit()
	malla.material_override = material_barrera
	cuerpo.add_child(malla)
	add_child(cuerpo)


func _quad(st: SurfaceTool, caras: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		va: float, vb: float, invertir: bool) -> void:
	# a-b abajo, c-d arriba. La barrera derecha es un espejo de la izquierda,
	# así que se invierte el orden para que las caras sigan mirando hacia fuera.
	var uvs: Array[Vector2] = [Vector2(0, va), Vector2(0, vb), Vector2(1, vb), Vector2(1, va)]
	var vertices: Array[Vector3] = [a, b, c, d]
	var orden: PackedInt32Array = PackedInt32Array([0, 1, 2, 0, 2, 3]) if invertir else PackedInt32Array([0, 2, 1, 0, 3, 2])
	for idx: int in orden:
		st.set_uv(uvs[idx])
		st.add_vertex(vertices[idx])
		caras.append(vertices[idx])
