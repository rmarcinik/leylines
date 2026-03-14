shader_type spatial;

varying vec3 v_global_pos;

uniform float max_distance = 4000.0;
uniform float emission_strength = 0.1;

// Smooth HSV to RGB conversion
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void vertex() {
    v_global_pos = (MODEL_MATRIX * vec4(VERTEX, 1)).xyz;
}

void fragment() {
    // Calculate distance from origin
    float dist = length(v_global_pos);
    float norm_dist = clamp(length(v_global_pos) / max_distance, 0.0, 1.0);

    // Normalize distance (0 to 1 range)
    float norm_x = clamp(length(v_global_pos.x) / max_distance, 0.0, 1.0);
    float norm_y = clamp(length(v_global_pos.y) / max_distance, 0.0, 1.0);
    float norm_z = clamp(length(v_global_pos.z) / max_distance, 0.0, 1.0);

    // Create color gradient using HSV space for smoother transitions
    vec3 hsv_color = vec3(
        mix(norm_x,norm_y, norm_z), // Hue (yellow to green range)
        1.0,                             // Full saturation
        norm_dist                 // Value (brightness)
    );

    // Convert to RGB
    ALBEDO = hsv2rgb(hsv_color);

    // Optional emission
    EMISSION = ALBEDO * emission_strength;
}