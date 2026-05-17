shader_type canvas_item;

uniform float wind_strength : hint_range(0.0, 8.0) = 2.5;
uniform float wind_speed : hint_range(0.0, 6.0) = 1.4;
uniform float wind_frequency : hint_range(0.0, 4.0) = 1.2;
uniform vec2 wind_dir = vec2(1.0, 0.0);

void vertex() {
	float bend = pow(1.0 - UV.y, 2.0);
	vec2 world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	float phase = world_pos.x * 0.05 + world_pos.y * 0.03;
	float wave = sin(TIME * wind_speed + phase + UV.x * wind_frequency * 6.2831853);
	VERTEX += wind_dir * wave * wind_strength * bend;
}
