shader_type canvas_item;

render_mode unshaded;

uniform sampler2D normal_map;
uniform float normal_strength : hint_range(0.0, 2.0) = 1.0;
uniform float specular_strength : hint_range(0.0, 1.0) = 0.3;
uniform float specular_power : hint_range(1.0, 128.0) = 32.0;
uniform vec3 ambient_color : source_color = vec3(0.1, 0.1, 0.1);
uniform float ambient_intensity : hint_range(0.0, 1.0) = 0.2;

void fragment() {
	vec2 uv = UV;
	vec4 base_color = texture(TEXTURE, uv);
	
	// Sample normal map
	vec3 normal = texture(normal_map, uv).rgb * 2.0 - 1.0;
	normal.xy *= normal_strength;
	normal = normalize(normal);
	
	// Ambient lighting
	vec3 lighting = base_color.rgb * ambient_color * ambient_intensity;
	
	// Process 2D lights (handled by Godot's Light2D system)
	// This shader works with Godot's built-in 2D lighting
	
	COLOR = vec4(base_color.rgb + lighting, base_color.a);
}

void light() {
	// Custom light processing if needed
	// Godot handles Light2D automatically for canvas items
}