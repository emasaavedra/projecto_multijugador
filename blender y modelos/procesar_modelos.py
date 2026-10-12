# Convierte los modelos .dae (exportados desde SketchUp / 3D Warehouse) a .glb listos para Godot:
#  - quita el terreno con foto satelital de Google Earth y las losas de suelo
#  - apoya el edificio en y=0 (según la altura del terreno bajo él) y lo centra
#  - une todo en una malla con un solo mapa UV y reduce las texturas a 512 px
#
# Uso (desde la raíz del repo):
#   "C:/Program Files/Blender Foundation/Blender 3.4/blender.exe" -b -P "blender y modelos/procesar_modelos.py" -- \
#       "blender y modelos/dae" godot/pistas/alameda/modelos
# Para un modelo nuevo, agrega su nombre de salida en NOMBRES (abajo).
# Quita el terreno de Google Earth, apoya el modelo en z=0, lo centra, une las mallas y exporta .glb
import bpy, bmesh, sys, os, glob, math, statistics
from mathutils import Vector

carpeta, salida = sys.argv[sys.argv.index("--") + 1:][:2]
os.makedirs(salida, exist_ok=True)

NOMBRES = {
    "Palacio": "la_moneda", "Entel[1]": "torre_entel", "U__de_Chile": "casa_central_uchile",
    "Edificio+Diego+Portales": "edificio_diego_portales", "Copia_automática_torre+santander": "torre_santander",
    "Alameda": "torres_alameda", "aguas+1": "edificio_aguas", "Edificio+residencial": "edificio_residencial",
    "Hotel+marriot+2": "hotel_marriott", "s14": "torre_s14_a", "s14 (1)": "torre_s14_b", "s14 (2)": "torre_s14_c",
    "s14 (3)": "torre_s14_d", "s14 (4)": "torre_s14_e",
}

# el Palacio trae también los ministerios a los lados; nos quedamos con La Moneda
RECORTES = {"la_moneda": (-65, 66, -20, 110)}
# losas de suelo con foto satelital que no son planas (no las detecta el filtro de pisos)
QUITAR_MATERIALES = {"edificio_diego_portales": {"mat_68", "mat_69", "mat_70", "mat_71"}}
TEXTURA_MAX = 512

def materiales(o):
    return {m.name for m in o.data.materials if m}

for ruta in sorted(glob.glob(os.path.join(carpeta, "*", "*.dae"))):
    original = os.path.splitext(os.path.basename(ruta))[0]
    nombre = NOMBRES.get(original) or NOMBRES.get(original.encode("cp1252", "ignore").decode("utf-8", "ignore"))
    if nombre is None:
        nombre = "".join(c if c.isalnum() else "_" for c in original).lower()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.wm.collada_import(filepath=ruta)
    mallas = [o for o in bpy.context.scene.objects if o.type == "MESH"]

    # El terreno de Google Earth cubre el 100% del área del modelo; ningún edificio lo hace.
    def caja(objs):
        p = [o.matrix_world @ Vector(c) for o in objs for c in o.bound_box]
        return Vector(map(min, *p)), Vector(map(max, *p))
    tmn, tmx = caja(mallas)
    por_material = {}
    for o in mallas:
        for m in materiales(o):
            por_material.setdefault(m, []).append(o)
    TERRENO = set()
    # solo los modelos con terreno de Google Earth son así de grandes
    if (tmx.x - tmn.x) > 150 and (tmx.y - tmn.y) > 150:
        for m, objs in por_material.items():
            a, b = caja(objs)
            if (b.x - a.x) >= 0.95 * (tmx.x - tmn.x) and (b.y - a.y) >= 0.95 * (tmx.y - tmn.y):
                TERRENO.add(m)
    def plano_y_horizontal(o):
        if not materiales(o) or not materiales(o) & TERRENO:
            return False
        a, b = caja([o])
        if (b.z - a.z) >= 20:
            return False
        n3 = o.matrix_world.to_3x3()
        return all(abs((n3 @ p.normal).normalized().z) > 0.6 for p in o.data.polygons)
    candidatos = [o for o in mallas if plano_y_horizontal(o)]
    # las baldosas están a nivel de calle; un techo plano con la misma textura queda muy por encima
    nivel = statistics.median([caja([o])[1].z for o in candidatos]) if candidatos else 0.0
    def es_terreno(o):
        return o in candidatos and caja([o])[1].z < nivel + 15
    terreno = [o for o in mallas if es_terreno(o)
               or (materiales(o) and materiales(o) <= QUITAR_MATERIALES.get(nombre, set()))]
    edificio = [o for o in mallas if o not in terreno]
    tiene_terreno = len(terreno) > 0

    # caja del edificio (en coordenadas de mundo)
    pts = [o.matrix_world @ v.co for o in edificio for v in o.data.vertices]
    mn = Vector(map(min, *pts)); mx = Vector(map(max, *pts))

    # altura del terreno bajo el edificio: mediana de los vértices de terreno dentro de su huella
    suelo = mn.z
    if tiene_terreno:
        zs = [w.z for o in terreno for v in o.data.vertices
              for w in [o.matrix_world @ v.co] if mn.x <= w.x <= mx.x and mn.y <= w.y <= mx.y]
        if zs:
            suelo = statistics.median(zs)
    for o in terreno:
        bpy.data.objects.remove(o, do_unlink=True)
    # pisos planos grandes a nivel de calle (plazas/veredas modeladas como un plano gigante)
    pisos = []
    for o in edificio:
        a, b = caja([o])
        if (b.z - a.z) < 0.5 and b.z < suelo + 2.0 and (b.x - a.x) * (b.y - a.y) > 3000:
            pisos.append(o)
    for o in pisos:
        edificio.remove(o)
        bpy.data.objects.remove(o, do_unlink=True)
    pts = [o.matrix_world @ v.co for o in edificio for v in o.data.vertices]
    mn = Vector(map(min, *pts)); mx = Vector(map(max, *pts))

    # unir todo en una malla (primero soltar la jerarquía: el nodo raíz trae la escala pulgadas→metros)
    # cada objeto trae su mapa UV con otro nombre; al unir quedarían varias capas y la textura leería la equivocada
    for o in edificio:
        uvs = o.data.uv_layers
        if not uvs:
            uvs.new(name="UVMap")
            continue
        activa = uvs.active or uvs[0]
        for capa in [c for c in uvs if c != activa]:
            uvs.remove(capa)
        uvs[0].name = "UVMap"
    bpy.ops.object.select_all(action="DESELECT")
    for o in edificio:
        o.select_set(True)
    bpy.context.view_layer.objects.active = edificio[0]
    bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
    bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    obj.name = nombre
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    # quitar jerarquía de nodos vacíos que deja el importador
    for o in list(bpy.context.scene.objects):
        if o.type == "EMPTY":
            bpy.data.objects.remove(o, do_unlink=True)
    centro = Vector(((mn.x + mx.x) / 2, (mn.y + mx.y) / 2, suelo))
    obj.data.transform(__import__("mathutils").Matrix.Translation(-centro))
    obj.location = (0, 0, 0)
    # limpiar duplicados y, si corresponde, recortar (coordenadas Blender ya centradas: x este, y norte)
    bm = bmesh.new(); bm.from_mesh(obj.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.001)
    if nombre in RECORTES:
        x0, x1, y0, y1 = RECORTES[nombre]
        fuera = [f for f in bm.faces if not (x0 <= f.calc_center_median().x <= x1 and y0 <= f.calc_center_median().y <= y1)]
        bmesh.ops.delete(bm, geom=fuera, context="FACES")
        bm.verts.ensure_lookup_table()
        cx = (min(v.co.x for v in bm.verts) + max(v.co.x for v in bm.verts)) / 2
        cy = (min(v.co.y for v in bm.verts) + max(v.co.y for v in bm.verts)) / 2
        for v in bm.verts:
            v.co.x -= cx; v.co.y -= cy
    bm.to_mesh(obj.data); bm.free()
    # texturas a máx. 512 px para no inflar el repositorio
    for img in bpy.data.images:
        if img.size[0] > 0 and max(img.size) > TEXTURA_MAX:
            f = TEXTURA_MAX / max(img.size)
            img.scale(max(1, int(img.size[0] * f)), max(1, int(img.size[1] * f)))
    for m in list(bpy.data.materials):
        if m.users == 0:
            bpy.data.materials.remove(m)

    d = mx - mn
    tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)
    destino = os.path.join(salida, nombre + ".glb")
    bpy.ops.export_scene.gltf(filepath=destino, export_format="GLB", export_yup=True,
                              export_apply=True, export_image_format="AUTO")
    print(f"LISTO {original} -> {nombre}.glb | terreno={sorted(TERRENO)} pisos={len(pisos)} "
          f"suelo={suelo - mn.z:+.1f}m sobre la base | dim(ancho_x, fondo_y, alto)=({d.x:.1f}, {d.y:.1f}, {mx.z - suelo:.1f}) "
          f"tris={tris} mats={len(obj.data.materials)} | {os.path.getsize(destino) / 1e6:.1f} MB")

