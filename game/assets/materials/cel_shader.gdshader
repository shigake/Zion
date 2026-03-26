shader_type spatial;
render_mode diffuse_toon, specular_toon, cull_disabled;

uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float toon_steps : hint_range(1.0, 5.0) = 3.0;
uniform vec4 shadow_color : source_color = vec4(0.15, 0.1, 0.2, 1.0);
uniform float rim_amount : hint_range(0.0, 1.0) = 0.4;
uniform vec4 rim_color : source_color = vec4(1.0, 1.0, 1.0, 0.6);
uniform float rim_threshold : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	ALBEDO = albedo_color.rgb;
	ROUGHNESS = 1.0;
	SPECULAR = 0.1;

	// Rim/fresnel lighting
	float rim = 1.0 - dot(NORMAL, VIEW);
	rim = smoothstep(rim_threshold, 1.0, rim) * rim_amount;
	EMISSION = rim_color.rgb * rim;
}

void light() {
	float NdotL = dot(NORMAL, LIGHT);
	// Step the lighting for toon effect
	float stepped = floor(NdotL * toon_steps + 0.5) / toon_steps;
	stepped = clamp(stepped, 0.0, 1.0);

	// Mix between shadow color and lit color
	vec3 lit_color = ATTENUATION * LIGHT_COLOR;
	vec3 final_color = mix(shadow_color.rgb * ALBEDO, lit_color, stepped);

	DIFFUSE_LIGHT += final_color;
}
