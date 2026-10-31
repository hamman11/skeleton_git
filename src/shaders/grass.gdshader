shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, unshaded, skip_vertex_transform;

uniform sampler2D grass_texture : filter_nearest, source_color;
uniform sampler2D gradient_texture : filter_linear_mipmap, source_color;
uniform float gradient_blend : hint_range(0, 1) = 0.5;

void vertex() {
    // 1. Apply the wind displacement in local space before billing board transformation
    VERTEX.x += sin(NODE_POSITION_WORLD.x + TIME * 1.25 + UV.y) * (1.0 - UV.y) * 0.2;
    VERTEX.z += cos(NODE_POSITION_WORLD.z + TIME * 0.45 + UV.y) * (1.0 - UV.y) * 0.15;

    // 2. Extract model scale from the ModelView matrix to preserve original mesh size
    vec3 scale = vec3(
        length(MODELVIEW_MATRIX[0].xyz),
        length(MODELVIEW_MATRIX[1].xyz),
        length(MODELVIEW_MATRIX[2].xyz)
    );

    // 3. Create the Y-Billboard orientation matrix (keeps it upright while facing the camera)
    // For a full billboard (including vertical tilt), change MODELVIEW_MATRIX[1].xyz to vec3(0.0, scale.y, 0.0)
    MODELVIEW_MATRIX[0].xyz = vec3(scale.x, 0.0, 0.0);
    MODELVIEW_MATRIX[1].xyz = vec3(0.0, scale.y, 0.0);
    MODELVIEW_MATRIX[2].xyz = vec3(0.0, 0.0, scale.z);

    // 4. Complete the view space transform (required due to skip_vertex_transform)
    VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
    NORMAL = vec3(0.0, 1.0, 0.0);
}

void fragment() {
    vec4 grass_sample = texture(grass_texture, UV);
    vec3 base_color = grass_sample.rgb;
    float alpha = grass_sample.a;
    
    vec3 gradient_color = texture(gradient_texture, vec2(UV.y, 0.5)).rgb;
    vec3 final_color = mix(base_color, base_color * gradient_color, gradient_blend);
    
    ALBEDO = final_color;
    ALPHA = alpha;
}
