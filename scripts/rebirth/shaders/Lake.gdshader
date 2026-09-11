shader_type spatial;
render_mode cull_disabled;

uniform vec4 deep : source_color = vec4(0.035, 0.12, 0.155, 1.0);
varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_position.xz;
	float broad = sin(p.x * 0.23 + p.y * 0.16 + TIME * 0.22);
	float crossing = sin(p.x * 0.57 - p.y * 0.31 - TIME * 0.33);
	float fine = sin(p.x * 3.7 + p.y * 2.1 + TIME * 0.7) * sin(p.y * 4.9 - TIME * 0.61);
	float glints = pow(max(0.0, sin(p.x * 1.5 + p.y * 0.85 + sin(p.y * 0.45) * 1.5 + TIME * 0.25)), 24.0);
	glints *= smoothstep(0.4, 0.95, sin(p.x * 0.55 - p.y * 0.7));
	ALBEDO = deep.rgb + vec3(0.009, 0.019, 0.022) * (broad * 0.5 + 0.5);
	ALBEDO += vec3(0.015, 0.021, 0.02) * glints * (crossing * 0.5 + 0.5);
	METALLIC = 0.46;
	ROUGHNESS = 0.32 + fine * 0.035;
	SPECULAR = 0.65;
	NORMAL_MAP = vec3(0.5 + broad * 0.013 + fine * 0.009, 0.5 + crossing * 0.015, 1.0);
}
