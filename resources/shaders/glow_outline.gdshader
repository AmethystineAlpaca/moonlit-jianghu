shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(0.25, 0.88, 0.82, 0.85);
uniform float outline_width : hint_range(0.5, 3.0) = 1.2;
uniform float glow_strength : hint_range(0.0, 2.0) = 0.55;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 texel = outline_width / vec2(textureSize(TEXTURE, 0));
	float neighbors =
		texture(TEXTURE, UV + vec2(texel.x, 0.0)).a +
		texture(TEXTURE, UV + vec2(-texel.x, 0.0)).a +
		texture(TEXTURE, UV + vec2(0.0, texel.y)).a +
		texture(TEXTURE, UV + vec2(0.0, -texel.y)).a;
	float is_outline = clamp(neighbors, 0.0, 1.0) * (1.0 - c.a);
	vec4 out_color = outline_color * vec4(1.0 + glow_strength, 1.0 + glow_strength, 1.0 + glow_strength, is_outline);
	COLOR = mix(out_color, c, c.a);
}
