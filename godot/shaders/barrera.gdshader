shader_type spatial;

// Franjas alternadas a lo largo de la barrera (UV.y en metros).
uniform vec3 color_a : source_color = vec3(0.85, 0.1, 0.1);
uniform vec3 color_b : source_color = vec3(0.95, 0.95, 0.95);
uniform float largo_franja = 3.0;

void fragment() {
	ALBEDO = mod(floor(UV.y / largo_franja), 2.0) < 1.0 ? color_a : color_b;
	ROUGHNESS = 0.7;
}
