shader_type spatial;

// Pulled mostly from https://www.youtube.com/watch?v=WfRb50J7hD8 there's some stuff I skipped because I don't thinjk it matters too much.

global uniform vec3 ocean_pos; // Global shader value for the player position (Odd. You have to declare it)

//Fragment variables
uniform vec3 albedo : source_color;
uniform vec3 albedo2 : source_color;
uniform float metallic : hint_range(0.0, 1.0) = 0;
uniform float roughness : hint_range(0.0, 1.0) = 0.02;

//vertex variables
uniform sampler2D wave;
uniform float noise_scale = 10.0;
uniform float height_scale = 0.15;
uniform float wave_time;
uniform float wave_speed;

//Pixel wave definition bump map stuff
uniform sampler2D texture_normal;
uniform sampler2D texture_normal2;

//Wave direction and speed
uniform vec2 wave_direction = vec2(2.0, 0.0);
uniform vec2 wave_direction2 = vec2(0.0, 1.0);
uniform float time_scale : hint_range(0.0, 1.0, 0.005) = 0.025;

//Depth related stuff (Beers Law)
uniform vec4 color_deep : source_color;
uniform vec4 color_shallow : source_color;
uniform float beers_law = 2.0;
uniform float depth_offset = -0.75;

uniform sampler2D DEPTH_TEXTURE: hint_depth_texture;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture;

//Edge variables
uniform float edge_scale = 0.3;
uniform float near = 1.0;
uniform float far = 100.0;
uniform vec3 edge_color : source_color;

//Varying variables (sorta globals)
varying float height;
varying vec3 world_pos;
varying float vertex_distance;
varying float vertex_distance_clamped;
varying vec2 vertex_pos;

float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}

float edge(float depth)
{
	depth = 1.0 - 2.0 * depth;
	return near * far / (far + depth * (near - far));
}

float waveheight(vec2 offset, int mode)
{
	float h1 = 0.0; //Wave 1 texture height

	h1 = texture(wave, (world_pos.xz + offset) / noise_scale + (TIME * wave_direction) * time_scale).r;
	return h1;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	height = texture(wave, world_pos.xz / noise_scale + wave_time * time_scale).r;
	VERTEX.y += height * height_scale;
}

void fragment() {
	// Depth variables and calculation (Beers law)
	float depth_texture = texture(DEPTH_TEXTURE, SCREEN_UV).r * 2.0 - 1.0;
	float depth = PROJECTION_MATRIX[3][2] / (depth_texture + PROJECTION_MATRIX[2][2]);
	float depth_blend = exp((depth + VERTEX.z + depth_offset) * -beers_law);
	depth_blend = clamp(1.0 - depth_blend, 0.0, 1.0);
	float depth_blend_power = clamp(pow(depth_blend, 2.5), 0.0, 1.0);

	vec3 screen_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, depth_blend_power * 2.5).rgb;
	vec3 depth_color = mix(color_shallow.rgb, color_deep.rgb, depth_blend_power);
	vec3 color = mix(screen_color * depth_color, depth_color * 0.25, depth_blend_power * 0.5);

	//Edge detection calculations
	float z_depth = edge(texture(DEPTH_TEXTURE, SCREEN_UV).x);
	float z_pos = edge(FRAGCOORD.z);
	float z_diff = z_depth - z_pos;

	//Move it time calculations
	vec2 time = (TIME * wave_direction) * time_scale;
	vec2 time2 = (TIME * wave_direction2) * time_scale;

	//Blend the 2 texture normal maps received into 1 normal map
	vec3 normal_blend = mix(texture(texture_normal,world_pos.xz + time).rgb, texture(texture_normal2,world_pos.xz + time2).rgb, 0.5);

	//Fresnel calculations (change colour of water based on camera angle)
	float fresnel = fresnel(5.0, NORMAL, VIEW);
	vec3 surface_colour = mix(albedo, albedo2, fresnel); //Interpolate albedor values by fresnel

	//New albedor calc
	vec3 depth_color_adj = mix(edge_color, color, step(edge_scale, z_diff));

	//Set pixel shader values
	//ALBEDO = mix(surface_colour, color, 0.75);
	ALBEDO = clamp(surface_colour + depth_color_adj, vec3(0.0), vec3(1.0));
	METALLIC = metallic;
	ROUGHNESS = roughness;
	NORMAL_MAP = normal_blend;

}
