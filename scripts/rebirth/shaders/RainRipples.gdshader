shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

varying vec4 instance_data;

void vertex() {
	instance_data = INSTANCE_CUSTOM;
}

void fragment() {
	float life = fract(TIME * 0.29 + instance_data.x);
	float phase = life * 2.5;
	float radius = phase * 0.43 + 0.025;
	float distance_from_center = length(UV - vec2(0.5));
	float ring = 1.0 - smoothstep(0.008, 0.019, abs(distance_from_center - radius));
	float echo = 1.0 - smoothstep(0.006, 0.013, abs(distance_from_center - radius * 0.64));
	float fade = pow(max(0.0, 1.0 - phase), 1.8);
	ALBEDO = vec3(0.66, 0.82, 0.8);
	ALPHA = (ring + echo * 0.35) * fade * 0.17;
}
