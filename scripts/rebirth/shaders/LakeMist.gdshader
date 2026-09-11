shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform float offset = 0.0;

void fragment() {
	vec2 p = (UV - vec2(0.5)) * vec2(1.0, 1.5);
	float edge = 1.0 - smoothstep(0.16, 0.5, length(p));
	float wisps = sin(UV.x * 19.0 + UV.y * 9.0 + TIME * 0.12 + offset);
	float detail = sin(UV.x * 31.0 - UV.y * 17.0 - TIME * 0.09);
	ALBEDO = vec3(0.4, 0.56, 0.59);
	ALPHA = edge * (0.055 + wisps * 0.025 + detail * 0.015);
}
