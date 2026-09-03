@tool
extends MeshInstance3D

@export var ancho: float = 8.0
@export var segmentos: int = 300


func _ready():
	generar_carretera()

	var recorrido = get_node_or_null("../recorrido")

	if recorrido and recorrido.curve:
		if not recorrido.curve.changed.is_connected(generar_carretera):
			recorrido.curve.changed.connect(generar_carretera)


func generar_carretera():
	var recorrido = get_node_or_null("../recorrido")

	if recorrido == null:
		return

	var curva: Curve3D = recorrido.curve

	if curva == null:
		return

	var longitud = curva.get_baked_length()

	if longitud <= 0:
		return

	var vertices = PackedVector3Array()
	var normales = PackedVector3Array()
	var indices = PackedInt32Array()

	for i in range(segmentos):

		var distancia = (float(i) / segmentos) * longitud

		var posicion = curva.sample_baked(distancia)

		var siguiente_distancia = distancia + longitud / segmentos

		if siguiente_distancia >= longitud:
			siguiente_distancia -= longitud

		var siguiente = curva.sample_baked(siguiente_distancia)

		var direccion = siguiente - posicion

		if direccion.length_squared() < 0.0001:
			direccion = Vector3.FORWARD
		else:
			direccion = direccion.normalized()

		var perpendicular = Vector3(
			-direccion.z,
			0,
			direccion.x
		).normalized()

		var izquierda = posicion + perpendicular * (ancho / 2.0)
		var derecha = posicion - perpendicular * (ancho / 2.0)

		vertices.append(izquierda)
		vertices.append(derecha)

		# Normal apuntando hacia arriba
		normales.append(Vector3.UP)
		normales.append(Vector3.UP)


	# Triángulos
	for i in range(segmentos):

		var siguiente = (i + 1) % segmentos

		var v = i * 2
		var s = siguiente * 2

		indices.append(v)
		indices.append(v + 1)
		indices.append(s)

		indices.append(v + 1)
		indices.append(s + 1)
		indices.append(s)


	# Crear ArrayMesh
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)

	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normales
	arrays[Mesh.ARRAY_INDEX] = indices

	var nueva_malla = ArrayMesh.new()

	nueva_malla.add_surface_from_arrays(
		Mesh.PRIMITIVE_TRIANGLES,
		arrays
	)

	mesh = nueva_malla
