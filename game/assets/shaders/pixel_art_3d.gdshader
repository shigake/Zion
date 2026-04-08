shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;

// Sprite texture
uniform sampler2D albedo_texture : source_color, filter_nearest;
// Outline
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_width : hint_range(0.0, 4.0) = 1.0;
// Cel shading
uniform bool cel_shading_enabled = true;
uniform int cel_levels : hint_range(2, 5) = 3;
uniform float cel_light_direction_y : hint_range(-1.0, 1.0) = -0.7;
// Tint
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// Emission glow
uniform float emission_strength : hint_range(0.0, 2.0) = 0.0;
uniform vec4 emission_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 tex = texture(albedo_texture, UV);

	// Discard transparent pixels
	if (tex.a < 0.1) {
		// Check neighbors for outline
		vec2 pixel_size = 1.0 / vec2(textureSize(albedo_texture, 0));
		float outline_px = outline_width;

		float a_up = texture(albedo_texture, UV + vec2(0.0, -pixel_size.y * outline_px)).a;
		float a_down = texture(albedo_texture, UV + vec2(0.0, pixel_size.y * outline_px)).a;
		float a_left = texture(albedo_texture, UV + vec2(-pixel_size.x * outline_px, 0.0)).a;
		float a_right = texture(albedo_texture, UV + vec2(pixel_size.x * outline_px, 0.0)).a;

		// Diagonal checks for smoother outline
		float a_ul = texture(albedo_texture, UV + vec2(-pixel_size.x * outline_px, -pixel_size.y * outline_px)).a;
		float a_ur = texture(albedo_texture, UV + vec2(pixel_size.x * outline_px, -pixel_size.y * outline_px)).a;
		float a_dl = texture(albedo_texture, UV + vec2(-pixel_size.x * outline_px, pixel_size.y * outline_px)).a;
		float a_dr = texture(albedo_texture, UV + vec2(pixel_size.x * outline_px, pixel_size.y * outline_px)).a;

		float neighbor_alpha = max(max(max(a_up, a_down), max(a_left, a_right)), max(max(a_ul, a_ur), max(a_dl, a_dr)));

		if (neighbor_alpha > 0.1) {
			ALBEDO = outline_color.rgb;
			ALPHA = outline_color.a;
		} else {
			discard;
		}
	} else {
		vec3 color = tex.rgb * tint_color.rgb;

		// Cel shading: quantize brightness based on UV.y (simulates top-lit)
		if (cel_shading_enabled) {
			float brightness = 1.0 - (UV.y * 0.3); // Top brighter, bottom darker
			// Add slight directional influence
			brightness += (0.5 - UV.x) * 0.1;
			// Quantize to cel levels
			brightness = floor(brightness * float(cel_levels)) / float(cel_levels);
			brightness = clamp(brightness, 0.4, 1.0);
			color *= brightness;
		}

		ALBEDO = color;
		ALPHA = tex.a;

		// Emission
		if (emission_strength > 0.0) {
			EMISSION = emission_color.rgb * emission_strength;
		}
	}
}
