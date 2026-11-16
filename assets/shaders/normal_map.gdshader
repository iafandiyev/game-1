shader_type canvas_item;

render_mode unshaded;

uniform sampler2D normal_map;
uniform float normal_strength : hint_range(0.0, 2.0) = 1.0;
uniform float specular_strength : hint_range(0.0, 1.0) = 0.3;
uniform float specular_power : hint_range(1.0, 128.0) = 32.0;
uniform vec3 ambient_color : source_color = vec3(0.15, 0.1, 0.08);
uniform float ambient_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float roughness : hint_range(0.0, 1.0) = 0.7;
uniform float metalness : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = UV;
	vec4 base_color = texture(TEXTURE, uv);
	
	// Discard transparent pixels
	if (base_color.a < 0.01) {
		discard;
	}
	
	// Sample normal map
	vec3 normal = texture(normal_map, uv).rgb * 2.0 - 1.0;
	normal.xy *= normal_strength;
	normal = normalize(normal);
	
	// Get light direction from Godot's 2D lighting
	// LIGHT_VERTEX is the vector from fragment to light in view space
	// We need to convert to tangent space for normal mapping
	
	// Ambient lighting
	vec3 lighting = base_color.rgb * ambient_color * ambient_intensity;
	
	// Process each light (Godot calls light() for each light)
	// The accumulated lighting is in LIGHT_COLOR
	
	COLOR = vec4(base_color.rgb + lighting, base_color.a);
}

void light() {
	// Light vector in view space (from fragment to light)
	vec3 light_dir = normalize(LIGHT_VERTEX);
	
	// Convert to tangent space for normal mapping
	// For 2D, we assume the surface faces the camera (0, 0, 1)
	// The normal map is in tangent space (x: right, y: up, z: out of screen)
	
	// For 2D sprites, the light direction in tangent space:
	// light_dir.x = horizontal component
	// light_dir.y = vertical component (flipped for screen coords)
	// light_dir.z = depth component
	
	vec3 L = vec3(light_dir.x, -light_dir.y, light_dir.z);
	
	// Diffuse lighting (Lambert)
	float NdotL = max(dot(normal, L), 0.0);
	
	// Specular lighting (Blinn-Phong)
	vec3 V = vec3(0.0, 0.0, 1.0); // View direction (camera faces -z)
	vec3 H = normalize(L + V);
	float NdotH = max(dot(normal, H), 0.0);
	float specular = pow(NdotH, specular_power) * specular_strength;
	
	// Attenuation
	float attenuation = LIGHT_ATTENUATION;
	
	// Color
	vec3 diffuse = base_color.rgb * LIGHT_COLOR.rgb * NdotL;
	vec3 spec = vec3(specular) * LIGHT_COLOR.rgb;
	
	LIGHT_COLOR.rgb = (diffuse + spec) * attenuation;
}