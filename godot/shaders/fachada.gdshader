shader_type spatial;

// Fachada para cajas (BoxMesh): la textura va en las paredes y el techo queda de un color.
// Modo normal: la textura se repite según metros reales (sirve con cajas escaladas, como las del MultiMesh).
// Modo estirar: la textura cubre cada pared una vez (para hitos con forma fija).
uniform sampler2D textura : source_color, filter_linear_mipmap, repeat_enable;
uniform vec2 metros_por_tile = vec2(8.0, 10.0);
uniform bool estirar = false;
// Tamaño de la caja, solo se usa en modo estirar
uniform vec3 tamano = vec3(1.0);
uniform vec3 color_techo : source_color = vec3(0.45, 0.45, 0.47);
// Cuánto tiñe el color de instancia (MultiMesh) a la textura
uniform float tinte : hint_range(0.0, 1.0) = 0.3;

varying vec3 posicion;
varying vec3 normal_fachada;

void vertex() {
	if (estirar) {
		posicion = VERTEX;
		normal_fachada = NORMAL;
	} else {
		posicion = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		normal_fachada = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	}
}

void fragment() {
	vec3 n = normal_fachada;
	vec3 color;
	if (abs(n.y) > 0.5) {
		color = color_techo;
	} else {
		// Coordenada horizontal a lo largo de la pared, sin espejar la imagen
		bool cara_x = abs(n.x) > abs(n.z);
		float horizontal = cara_x ? -posicion.z * sign(n.x) : posicion.x * sign(n.z);
		vec2 uv;
		if (estirar) {
			float ancho = cara_x ? tamano.z : tamano.x;
			uv = vec2(horizontal / ancho + 0.5, 0.5 - posicion.y / tamano.y);
		} else {
			// v = 0 en el suelo: la parte de abajo de la textura queda a ras de piso
			uv = vec2(horizontal / metros_por_tile.x, -posicion.y / metros_por_tile.y);
		}
		color = texture(textura, uv).rgb * mix(vec3(1.0), COLOR.rgb, tinte);
	}
	ALBEDO = color;
	ROUGHNESS = 0.85;
}
