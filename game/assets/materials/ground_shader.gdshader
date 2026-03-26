shader_type spatial;

uniform vec4 color_a : source_color = vec4(0.12, 0.15, 0.08, 1.0);
uniform vec4 color_b : source_color = vec4(0.10, 0.12, 0.06, 1.0);
uniform vec4 accent_color : source_color = vec4(0.24, 0.30, 0.28, 1.0);
uniform float tile_size : hint_range(0.5, 10.0) = 3.0;
uniform float edge_blend : hint_range(0.0, 0.5) = 0.05;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
	vec2 uv_scaled = UV * tile_size;
	float macro_noise = noise(uv_scaled * 0.55);
	float detail_noise = noise(uv_scaled * 1.8 + macro_noise * 0.8);
	float mist_band = smoothstep(0.10, 0.95, UV.y + macro_noise * 0.10);

	vec2 stone_grid = abs(fract(uv_scaled + vec2(detail_noise * 0.15, macro_noise * 0.10)) - 0.5);
	float cell = smoothstep(0.48 - edge_blend, 0.48, max(stone_grid.x, stone_grid.y));
	float seams = smoothstep(0.60, 0.92, detail_noise + mist_band * 0.18);

	vec3 base = mix(color_a.rgb, color_b.rgb, macro_noise);
	base = mix(base, accent_color.rgb, seams * 0.55);
	base *= mix(0.88, 1.08, cell * 0.45 + mist_band * 0.20);

	ALBEDO = base;
	ROUGHNESS = 0.95;
	SPECULAR = 0.06;
}
