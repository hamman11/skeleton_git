shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, unshaded;

uniform vec3 albedo : source_color;
uniform vec3 foam_color : source_color = vec3(1.0, 1.0, 1.0); 
uniform sampler2D water_texture1;
uniform sampler2D water_texture2;
uniform sampler2D noise_texture;
uniform vec2 scroll_speed1 = vec2(0.05, 0.0);
uniform vec2 scroll_speed2 = vec2(-0.03, 0.0);
uniform float blend_factor = 0.5;
uniform vec2 scale1 = vec2(1.0, 1.0);
uniform vec2 scale2 = vec2(1.0, 1.0);
uniform float wave_strength = 1.0;
uniform float wave_scale = 0.02;
uniform int pixelation_level = 64;
uniform float FoamSize = 0.5;
uniform sampler2D DepthTexture : hint_depth_texture;
uniform float WaterOpacity = 1.0;
uniform float FoamGlowIntensity = 1.0;

void vertex() {
	vec2 global_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
	float noise_value = texture(noise_texture, global_position * wave_scale).r;
	float wave = sin(global_position.x * 0.2 + global_position.y * 0.2 + TIME + noise_value * 10.0) * wave_strength;
	VERTEX.y += wave;
}

void fragment() {
	vec2 scaledUV1 = UV * scale1;
	vec2 scaledUV2 = UV * scale2;
	vec2 scrolledUV1 = scaledUV1 + scroll_speed1 * TIME;
	vec2 scrolledUV2 = scaledUV2 + scroll_speed2 * TIME;
	
	scrolledUV1 = mod(scrolledUV1, vec2(1.0, 1.0));
	scrolledUV2 = mod(scrolledUV2, vec2(1.0, 1.0));
	
	scrolledUV1 = floor(scrolledUV1 * float(pixelation_level)) / float(pixelation_level);
	scrolledUV2 = floor(scrolledUV2 * float(pixelation_level)) / float(pixelation_level);
	
	vec4 water_color1 = texture(water_texture1, scrolledUV1);
	vec4 water_color2 = texture(water_texture2, scrolledUV2);
	vec4 blended_water_color = mix(water_color1, water_color2, blend_factor);
	
	float depthValue = texture(DepthTexture, SCREEN_UV).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depthValue);
	vec4 view_pos = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view_pos.xyz /= view_pos.w;
	
	float depth_diff = -view_pos.z + VERTEX.z;
	
	float foam_mask = step(depth_diff, FoamSize);
	
	vec3 final_water_color = albedo;
	vec3 final_foam_color = foam_color * FoamGlowIntensity;
	
	ALBEDO = mix(final_water_color, final_foam_color, foam_mask);
	ALPHA = WaterOpacity;
}
