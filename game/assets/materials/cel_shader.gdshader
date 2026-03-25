shader_type spatial;
render_mode diffuse_toon, specular_toon;

// Cel-shader inspirado em Zelda BotW
// Cores suaves com bordas marcadas

uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float toon_steps : hint_range(1.0, 5.0) = 3.0;
uniform float outline_width : hint_range(0.0, 0.05) = 0.02;
uniform vec4 outline_color : source_color = vec4(0.1, 0.1, 0.1, 1.0);
uniform float rim_amount : hint_range(0.0, 1.0) = 0.3;
uniform vec4 rim_color : source_color = vec4(1.0, 1.0, 1.0, 0.5);

void vertex() {
	// Outline via vertex extrusion (backface pass)
}

void fragment() {
	ALBEDO = albedo_color.rgb;
	ROUGHNESS = 1.0;
	SPECULAR = 0.2;

	// Rim lighting (borda iluminada como BotW)
	float rim = 1.0 - dot(NORMAL, VIEW);
	rim = smoothstep(0.5, 1.0, rim) * rim_amount;
	EMISSION = rim_color.rgb * rim;
}

void light() {
	// Toon shading com steps
	float NdotL = dot(NORMAL, LIGHT);
	float stepped = floor(NdotL * toon_steps) / toon_steps;
	stepped = max(stepped, 0.15); // Minimo de luz ambiente

	DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR * stepped;
}
