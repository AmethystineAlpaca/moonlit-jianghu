shader_type spatial;
render_mode cull_disabled;

void vertex() {
	vec3 p = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float bend = max(VERTEX.y + 0.215, 0.0);
	VERTEX.x += sin(p.x * 0.8 + p.z * 0.6 + TIME * 1.3) * bend * 0.22;
	VERTEX.z += cos(p.z * 1.1 + TIME * 0.9) * bend * 0.1;
}

void fragment() {
	ALBEDO = vec3(0.047, 0.079, 0.041) * COLOR.rgb;
	ROUGHNESS = 0.95;
	BACKLIGHT = vec3(0.018, 0.025, 0.006);
}
