shader_type spatial;
render_mode cull_disabled;

void vertex() {
	float phase = fract(TIME * (0.04 + INSTANCE_CUSTOM.y * 0.025) + INSTANCE_CUSTOM.x);
	float turn = TIME * (0.75 + INSTANCE_CUSTOM.z) + INSTANCE_CUSTOM.x * 6.28318;
	mat2 spin = mat2(vec2(cos(turn), -sin(turn)), vec2(sin(turn), cos(turn)));
	VERTEX.xz = spin * VERTEX.xz;
	VERTEX.y += (1.0 - phase) * 5.2;
	VERTEX.x += sin(phase * 6.28318 + INSTANCE_CUSTOM.z * 10.0) * 0.85;
	VERTEX.z += cos(phase * 7.0 + INSTANCE_CUSTOM.x * 10.0) * 0.55;
}

void fragment() {
	ALBEDO = vec3(0.38, 0.09, 0.023) * COLOR.rgb;
	ROUGHNESS = 0.92;
	BACKLIGHT = vec3(0.07, 0.016, 0.004);
}
