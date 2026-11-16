shader_type canvas_item;

uniform float vignette_strength : hint_range(0.0, 1.0) = 0.5;
uniform float vignette_radius : hint_range(0.0, 1.0) = 0.7;
uniform float vignette_softness : hint_range(0.0, 1.0) = 0.5;

uniform float noise_amount : hint_range(0.0, 1.0) = 0.05;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.1;
uniform float scanline_spacing : hint_range(1.0, 10.0) = 4.0;

uniform float chromatic_aberration : hint_range(0.0, 0.01) = 0.0;

uniform float damage_flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 damage_color : source_color = vec4(1.0, 0.1, 0.1, 1.0);

uniform float infection_overlay : hint_range(0.0, 1.0) = 0.0;
uniform vec4 infection_color : source_color = vec4(0.5, 0.0, 0.5, 1.0);

uniform float low_health_pulse : hint_range(0.0, 1.0) = 0.0;

uniform float night_vision : hint_range(0.0, 1.0) = 0.0;
uniform vec3 night_vision_color : source_color = vec3(0.1, 1.0, 0.1);

void fragment() {
	vec2 uv = UV;
	vec4 color = texture(TEXTURE, uv);
	
	// Vignette
	float dist = length(uv - 0.5) / (0.7071 * vignette_radius);
	float vignette = smoothstep(1.0, 0.0, dist * vignette_strength);
	color.rgb *= vignette;
	
	// Scanlines
	float scanlines = sin(uv.y * SCREEN_PIXEL_SIZE.y * 100.0 * scanline_spacing) * scanline_intensity;
	color.rgb += scanlines;
	
	// Film grain / noise
	float noise = (fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * noise_amount;
	color.rgb += noise;
	
	// Chromatic aberration
	if (chromatic_aberration > 0.0) {
		vec2 offset = vec2(chromatic_aberration, 0.0);
		float r = texture(TEXTURE, uv + offset).r;
		float g = color.g;
		float b = texture(TEXTURE, uv - offset).b;
		color.rgb = vec3(r, g, b);
	}
	
	// Damage flash
	if (damage_flash > 0.0) {
		color.rgb = mix(color.rgb, damage_color.rgb, damage_flash * damage_color.a);
	}
	
	// Infection overlay
	if (infection_overlay > 0.0) {
		color.rgb = mix(color.rgb, infection_color.rgb, infection_overlay * infection_color.a);
	}
	
	// Low health pulse
	if (low_health_pulse > 0.0) {
		float pulse = sin(TIME * 10.0) * 0.5 + 0.5;
		float pulse_intensity = low_health_pulse * pulse * 0.3;
		color.rgb = mix(color.rgb, vec3(1.0, 0.1, 0.1), pulse_intensity);
	}
	
	// Night vision
	if (night_vision > 0.0) {
		float luminance = dot(color.rgb, vec3(0.299, 0.587, 0.114));
		color.rgb = mix(color.rgb, luminance * night_vision_color, night_vision);
	}
	
	COLOR = color;
}