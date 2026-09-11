shader_type spatial;

uniform vec4 tint : source_color;
uniform float grain = 3.0;
varying vec3 world_position;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.1, 0.2, 0.3));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 p) {
	vec3 i = floor(p), f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1,0,0)), f.x),
		mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x),
		mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y), f.z);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float broad = noise(world_position * grain);
	float fine = noise(world_position * grain * 12.0);
	float age = noise(world_position * 0.8);
	float moss = smoothstep(0.6, 0.83, age);
	// Large uneven wet patches give rain-lit stone a soft, moving specular read.
	float wet = smoothstep(0.25, 0.7, noise(world_position * 0.36 + vec3(7.0)));
	ALBEDO = tint.rgb * (0.71 + broad * 0.30 + fine * 0.11);
	ALBEDO = mix(ALBEDO, vec3(0.14, 0.21, 0.15), moss * 0.26);
	ALBEDO *= 1.0 - wet * 0.25;
	ROUGHNESS = mix(0.76 + fine * 0.17, 0.22 + fine * 0.10, wet * 0.87);
	METALLIC = 0.08;
	SPECULAR = 0.52;
	NORMAL_MAP = vec3(0.5 + (fine - 0.5) * 0.095, 0.5 + (broad - 0.5) * 0.075, 1.0);
}
