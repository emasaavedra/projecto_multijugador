@tool
extends CollisionShape3D

@export var ancho_carretera: float = 8.0
@export var distancia_borde: float = 0.2
@export var altura: float = 1.0
@export var grosor: float = 0.3
@export var segmentos: int = 150


func _ready():
	call_deferred("generar_barrera")


func generar_barrera():
	var recorrido = get_node_or_null("../../recorrido")

	if recorrido == null:
		recorrido = get_node_or_null("../recorrido")

	if recorrido == null or recorrido.curve == null:
		print("ERROR: no se encontró recorrido")
		return

	var curva: Curve3D = recorrido.curve
	var longitud = curva.get_baked_length()

	if longitud <= 0:
		return

	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()

	var lado = 1.0

	if name == "Colisionador_Borde_Der":
		lado = -1.0

	var distancia_centro = ancho_carretera / 2.0 + distancia_borde

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

		var centro = posicion + perpendicular * lado * distancia_centro

		var p1 = centro - perpendicular * (grosor / 2.0)
		var p2 = centro + perpendicular * (grosor / 2.0)

		vertices.append(p1)
		vertices.append(p2)
		vertices.append(p1 + Vector3.UP * altura)
		vertices.append(p2 + Vector3.UP * altura)

	for i in range(segmentos):

		var siguiente = (i + 1) % segmentos

		var a = i * 4
		var b = siguiente * 4

		# Cara superior
		indices.append(a + 2)
		indices.append(a + 3)
		indices.append(b + 2)

		indices.append(a + 3)
		indices.append(b + 3)
		indices.append(b + 2)

		# Cara exterior
		indices.append(a + 1)
		indices.append(b + 1)
		indices.append(a + 3)

		indices.append(a + 3)
		indices.append(b + 1)
		indices.append(b + 3)

		# Cara interior
		indices.append(a)
		indices.append(a + 2)
		indices.append(b)

		indices.append(a + 2)
		indices.append(b + 2)
		indices.append(b)

	# -------------------------
	# COLISIÓN
	# -------------------------

	var caras = PackedVector3Array()

	for indice in indices:
		caras.append(vertices[indice])

	var forma = ConcavePolygonShape3D.new()
	forma.set_faces(caras)

	shape = forma

	# -------------------------
	# MALLA VISIBLE DE PRUEBA
	# -------------------------

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)

	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh = ArrayMesh.new()

	mesh.add_surface_from_arrays(
		Mesh.PRIMITIVE_TRIANGLES,
		arrays
	)

	var visual = get_node_or_null("Visual")

	if visual == null:
		visual = MeshInstance3D.new()
		visual.name = "Visual"
		add_child(visual)

	visual.mesh = mesh

	# Material visible
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 0, 0, 0.5)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	visual.material_override = material

	print(name, ": BARRERA GENERADA")
