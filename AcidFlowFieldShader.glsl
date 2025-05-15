#version 300 es

precision highp float;
precision highp sampler2D;

in vec2 uv;
out vec4 out_color;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec4 u_mouse; // unused for this version, but keep for compatibility
// uniform sampler2D u_textures[16]; // unused

#include "https://raw.githubusercontent.com/stegu/psrdnoise/main/src/psrdnoise2.glsl"
// #include <lygia/animation/easing/bounce> // Not used in this version

#pragma region rotate
// Optional rotation, can be applied to 'st' if desired
vec2 rot(vec2 v, float a){
    float s = sin(a);
    float c = cos(a);
    return mat2x2(c, -s, s, c) * v;
}
#pragma endregion

// Helper for smooth HSV to RGB, good for psychedelic effects
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}


void main(){
    // 1. Aspect-corrected screen coordinates
    vec2 st = uv * vec2(u_resolution.x / u_resolution.y, 1.0);
    
    // Optional: Global rotation for the whole pattern
    // st = rot(st, -PI / 12.0 * sin(u_time * 0.05));


    // 2. Define tile size and transform 'st' to 'tile_space_uv'
    //    where 1.0 unit in tile_space_uv corresponds to 128 screen pixels.
    float TILE_PIXEL_SIZE = 128.0;
    vec2 tile_space_uv = st * (u_resolution.y / TILE_PIXEL_SIZE);

    // --- Noise Layer 1: Warping field ---
    float warp_zoom = 1.8; // How many features for the warping field per tile
    float warp_time_scale = 0.15;
    vec2 warp_grad;
    // Animate the input position for a scrolling effect on the warp field
    vec2 warp_input_pos = tile_space_uv * warp_zoom + vec2(u_time * warp_time_scale * 0.5, u_time * warp_time_scale * 0.3);
    float warp_noise_val = psrdnoise(
        warp_input_pos,
        vec2(warp_zoom),     // Period must match the scaling of tile_space_uv
        u_time * 0.2,        // Animate the rotation angle of noise features
        warp_grad            // Output gradient of the warp noise
    );
    float warp_strength = 0.45; // How much the warp_grad displaces the main pattern

    // --- Noise Layer 2: Main visual pattern ---
    float base_zoom = 2.5;   // How many features for the main pattern per tile
    float base_time_scale = 0.25;
    vec2 base_grad;
    // Apply warp: displace tile_space_uv using the gradient from the warp_noise
    vec2 warped_base_input_pos = tile_space_uv * base_zoom + warp_grad * warp_strength;
    // Add a separate time-based scroll to the base pattern itself
    warped_base_input_pos += vec2(-u_time * base_time_scale * 0.4, u_time * base_time_scale * 0.6);

    float base_noise_val = psrdnoise(
        warped_base_input_pos,
        vec2(base_zoom),     // Period must match the scaling of the (pre-warped) input
        u_time * 0.3 + warp_noise_val * 2.0, // Modulate rotation by warp_noise for more interaction
        base_grad            // Output gradient of the base noise
    );

    // --- Coloring ---
    // Normalize base_noise_val (approx -0.7 to 0.7) to 0-1 range
    float n_norm = base_noise_val * 0.5 + 0.5;

    // Psychedelic color palette using HSV to RGB
    // Hue changes with noise value and time
    float hue = fract(n_norm * 0.5 + u_time * 0.05);
    // Saturation can be modulated, e.g., by the warp noise or gradient magnitude
    float saturation = 0.7 + 0.3 * smoothstep(0.0, 0.5, length(warp_grad));
    // Value (brightness) can also be modulated
    float value = 0.6 + 0.4 * smoothstep(0.2, 0.8, n_norm); // Brighter for higher noise values

    vec3 color = hsv2rgb(vec3(hue, saturation, value));

    // Add some highlights or "energy lines" based on the base gradient
    // This creates a sort of pseudo-lighting effect following the flow
    float highlight_strength = 0.5;
    // Dot product with a fixed direction, or use atan2 for angular patterns
    float flow_highlight = dot(normalize(base_grad + vec2(0.001)), normalize(vec2(0.707, 0.707))); // add small epsilon to avoid normalize(0,0)
    flow_highlight = pow(smoothstep(-0.4, 0.4, flow_highlight), 3.0); // Emphasize strong alignment
    
    color = mix(color, vec3(1.0, 0.95, 0.9), flow_highlight * highlight_strength);

    // Darken based on warp_noise to add more depth
    float darkness_factor = smoothstep(0.7, 0.2, warp_noise_val * 0.5 + 0.5); // Darker where warp_noise is high (more distorted)
    color *= mix(vec3(0.4, 0.3, 0.5), vec3(1.0), darkness_factor);


    out_color = vec4(color, 1.0);
}
