shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 tint : source_color = vec4(0.45, 0.77, 0.7, 1.0);
uniform float strength = 0.25;
uniform float identity = 0.0;
uniform float engaged = 0.0;

float line(float distance_value, float width) {
	return 1.0 - smoothstep(width, width + 0.004, abs(distance_value));
}

void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float circle = line(r - 0.77, 0.004) + line(r - 0.84, 0.002);
	float ticks = line(sin(a * 12.0 + identity * 0.4), 0.10);
	ticks *= step(0.79, r) * step(r, 0.86);
	float inner = line(r - 0.57, 0.002) * step(0.12, abs(sin(a * 4.0)));
	float orbit = line(r - 0.69, 0.003) * smoothstep(0.75, 0.99, sin(a * 3.0 - TIME * 0.42));
	float breath = 0.88 + sin(TIME * 1.1 + identity) * 0.12;
	float ink = circle * 0.52 + ticks * 0.65 + inner * 0.34 + orbit * engaged;
	ALBEDO = tint.rgb;
	EMISSION = tint.rgb * 0.5;
	ALPHA = min(ink, 1.0) * strength * breath;
}
