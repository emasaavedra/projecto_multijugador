extends Node3D

## Gato micro (modelo de Blender). Le da color a cada pieza según su nombre.
## Si una pieza ya trae su propio material desde Blender, se respeta.

@export var color_cuerpo: Color = Color(0.85, 0.1, 0.12)
@export var color_pelaje: Color = Color(0.95, 0.6, 0.25)
@export var color_ruedas: Color = Color(0.06, 0.06, 0.06)
@export var color_ojos: Color = Color(0.05, 0.05, 0.05)
@export var color_nariz: Color = Color(0.95, 0.55, 0.6)
@export var color_bigotes: Color = Color(0.95, 0.95, 0.95)

func _ready() -> void:
	for nodo: Node in find_children("*", "MeshInstance3D", true, false):
		_pintar(nodo as MeshInstance3D)

func _color_para(nombre: String) -> Color:
	if nombre == "Cube":
		return color_cuerpo
	if nombre.begins_with("R"):
		return color_ruedas
	if nombre.begins_with("Ojo"):
		return color_ojos
	if nombre.begins_with("Nariz"):
		return color_nariz
	if nombre.begins_with("Bigote"):
		return color_bigotes
	# Cabeza, orejas y cola
	return color_pelaje

func _pintar(pieza: MeshInstance3D) -> void:
	if pieza.mesh == null:
		return
	for i: int in pieza.mesh.get_surface_count():
		var actual: Material = pieza.mesh.surface_get_material(i)
		# "Material" es el material gris por defecto de Blender
		if actual != null and actual.resource_name != "Material":
			continue
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = _color_para(pieza.name)
		material.roughness = 0.5
		pieza.set_surface_override_material(i, material)
