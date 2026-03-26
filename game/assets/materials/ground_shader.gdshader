shader_type spatial;

uniform vec4 color_a : source_color = vec4(0.12, 0.15, 0.08, 1.0);
uniform vec4 color_b : source_color = vec4(0.10, 0.12, 0.06, 1.0);
uniform float tile_size : hint_range(0.5, 10.0) = 4.0;
uniform float edge_blend : hint_range(0.0, 0.5) = 0.05;

void fragment() {
	vec2 uv_scaled = UV * tile_size;
	vec2 grid = abs(fract(uv_scaled) - 0.5);
	float line = smoothstep(0.48 - edge_blend, 0.48, max(grid.x, grid.y));
	ALBEDO = mix(color_a.rgb, color_b.rgb, line);
	ROUGHNESS = 0.95;
}
