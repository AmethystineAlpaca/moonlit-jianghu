shader_type spatial;
render_mode cull_disabled;

uniform vec4 tint : source_color = vec4(0.62, 0.35, 0.19, 1.0);
uniform float wind_strength = 0.1;

void vertex() {
	vec3 p = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float gust = sin(p.x * 0.41 + p.z * 0.29 + TIME * 0.82);
	float flutter = sin(p.x * 2.7 - p.z * 1.8 + TIME * 2.2);
	VERTEX.x += (gust * 0.75 + flutter * 0.25) * wind_strength;
	VERTEX.y += sin(p.z * 0.7 + TIME * 1.15) * wind_strength * 0.4;
}

void fragment() {
	ALBEDO = tint.rgb * COLOR.rgb;
	ROUGHNESS = 0.88;
	BACKLIGHT = tint.rgb * 0.22;
}
