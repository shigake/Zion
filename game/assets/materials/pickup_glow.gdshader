shader_type spatial;
render_mode unshaded;

uniform vec4 glow_color : source_color = vec4(0.2, 0.6, 1.0, 1.0);
uniform float pulse_speed : hint_range(0.5, 5.0) = 2.0;
uniform float glow_intensity : hint_range(0.5, 5.0) = 2.0;
uniform float min_alpha : hint_range(0.3, 1.0) = 0.6;

void fragment() {
	float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
	ALBEDO = glow_color.rgb;
	EMISSION = glow_color.rgb * (glow_intensity + pulse);
	ALPHA = mix(min_alpha, 1.0, pulse);
}
