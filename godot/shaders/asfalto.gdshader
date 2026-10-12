shader_type spatial;

// UV.x: 0 = borde izquierdo, 1 = borde derecho. UV.y: metros recorridos (ver pista_generador.gd).
uniform vec3 color_asfalto : source_color = vec3(0.23, 0.23, 0.25);
uniform vec3 color_linea : source_color = vec3(0.95, 0.95, 0.9);
uniform vec3 color_piano_a : source_color = vec3(0.85, 0.1, 0.1);
uniform vec3 color_piano_b : source_color = vec3(0.95, 0.95, 0.95);
uniform float ancho_piano = 0.06;
uniform float largo_piano = 2.0;
uniform float ancho_linea_central = 0.012;
uniform float largo_segmento = 3.0;

float ruido(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec3 color = color_asfalto * (0.92 + 0.08 * ruido(floor(UV * vec2(60.0, 6.0))));

	// línea central segmentada
	bool en_centro = abs(UV.x - 0.5) < ancho_linea_central;
	bool en_segmento = fract(UV.y / (largo_segmento * 2.0)) < 0.5;
	if (en_centro && en_segmento) {
		color = color_linea;
	}

	// pianos en ambos bordes
	float borde = min(UV.x, 1.0 - UV.x);
	if (borde < ancho_piano) {
		color = mod(floor(UV.y / largo_piano), 2.0) < 1.0 ? color_piano_a : color_piano_b;
	}

	ALBEDO = color;
	ROUGHNESS = 0.9;
}
