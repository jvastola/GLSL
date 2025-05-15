#version 300 es

precision highp float;
precision highp sampler2D;

in vec2 uv;
out vec4 out_color;

uniform vec2 u_resolution;
uniform float u_time;
// uniform vec4 u_mouse; // unused in this version
// uniform sampler2D u_textures[16]; // unused

#include "https://raw.githubusercontent.com/stegu/psrdnoise/main/src/psrdnoise2.glsl"

// Helper for smooth HSV to RGB - essential for wild colors
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// PI, because why not
#define PI 3.14159265359

void main(){
    // 1. Aspect-corrected screen coordinates
    vec2 aspect_ratio_correction = vec2(u_resolution.x / u_resolution.y, 1.0);
    vec2 st = uv * aspect_ratio_correction;
    
    // 2. Define tile size and transform 'st' to 'tile_space_uv'
    //    where 1.0 unit in tile_space_uv corresponds to 128 screen pixels.
    float TILE_PIXEL_SIZE = 128.0;
    vec2 tile_uv = st * (u_resolution.y / TILE_PIXEL_SIZE);

    // --- Time variables for insanity ---
    float time = u_time * 2.8; // Faster base time
    // A more chaotic time signal using noise itself for unpredictable pulsing
    vec2 time_noise_grad_dummy; // We don't need this gradient
    float time_noise_val = psrdnoise(
        vec2(time * 0.06, -time * 0.04), // Animate input for time_noise
        vec2(0.0), // Period 0 means non-repeating for this specific utility noise
        time * 0.15,      // Rotate features of time_noise
        time_noise_grad_dummy
    );
    float chaotic_time = time + sin(time * 0.25) * 2.5 + time_noise_val * 3.5;


    // --- Layer 1: Base Warp / Low Frequency Chaos ---
    // Zoom pulsates slowly and warps based on chaotic time
    float zoom1 = 1.2 + 0.6 * sin(time*0.13 + chaotic_time * 0.05);
    vec2 pos1_offset = vec2(sin(chaotic_time * 0.12), cos(chaotic_time * 0.10)) * 0.7;
    vec2 pos1 = tile_uv * zoom1 + pos1_offset;
    vec2 grad1;
    float noise1_alpha = chaotic_time * 0.35 + sin(time*0.77)*PI; // Rotation parameter
    float noise1 = psrdnoise(pos1, vec2(zoom1) /*period*/, noise1_alpha, grad1);

    // --- Layer 2: Mid Frequency Warp / Details, warped by Layer 1 ---
    // Zoom pulsates with time and is influenced by noise1
    float zoom2 = 3.0 + 1.5 * abs(sin(time*0.33 + noise1 * 2.5));
    float warp1_strength = 0.6 + 0.4 * sin(time * 0.55); // Pulsating warp strength
    vec2 pos2 = (tile_uv + grad1 * warp1_strength) * zoom2;
    
    // Glitchy coordinate jumps driven by chaotic_time and noise1
    pos2.xy += vec2(pow(fract(chaotic_time * 0.065 + noise1 * 0.6), 7.0) * (18.0 * sin(time * 0.45)),
                    pow(fract(chaotic_time * 0.075 - noise1 * 0.4), 7.0) * (18.0 * cos(time * 0.38)));
    vec2 grad2;
    // Rotation for noise2 is heavily modulated by noise1 and grad1's angle
    float noise2_alpha = chaotic_time * 0.55 + noise1 * 4.5 + atan(grad1.y, grad1.x + 0.001) * 0.8;
    float noise2 = psrdnoise(pos2, vec2(zoom2) /*period*/, noise2_alpha, grad2);

    // --- Layer 3: High Frequency Detail / Color Driver, warped by Layer 1 & 2 ---
    // Zoom for noise3 pulsates and is influenced by noise2 for more intricate detail variations
    float zoom3 = 6.5 + 3.0 * abs(sin(chaotic_time * 0.85 + noise2 * 2.0)); // Spatially constant zoom for this frame
    float warp2_strength = 0.35 + 0.25 * sin(chaotic_time * 0.65 + noise1 * PI); // Warp strength modulated by noise1
    
    // Additional displacement from noise2, strength modulated by noise1
    vec2 noise2_displacement = grad2 * (abs(noise2) * 0.25 * (0.5 + 0.5 * abs(noise1)));

    vec2 pos3_base = tile_uv + grad1 * warp1_strength * 0.15 + grad2 * warp2_strength + noise2_displacement;
    vec2 pos3 = pos3_base * zoom3;
    
    vec2 grad3;
    // Alpha (rotation) for noise3 is extremely dynamic
    float noise3_alpha = chaotic_time * 1.8 + noise1 * 2.5 + noise2 * 5.5 + atan(grad2.y, grad2.x + 0.001) * 1.8;
    // Add high-frequency spatial rotation flicker using dot product with pos3_base (more stable)
    noise3_alpha += sin(dot(pos3_base * zoom3 * 0.015, vec2(31.3,73.7)) + chaotic_time * 6.0)*PI*2.5;
    float noise3 = psrdnoise(pos3, vec2(zoom3) /*period*/, noise3_alpha, grad3);


    // --- Insane Coloring ---
    // Hue: A chaotic mix of all noises, their gradients' angles, and time.
    float hue = fract(
        noise1 * 1.7 +
        noise2 * 2.6 +
        noise3 * 3.8 +
        (atan(grad1.y, grad1.x + 0.001) / (2.0*PI)) * 0.6 + // grad1 angle
        (atan(grad2.y, grad2.x + 0.001) / (2.0*PI)) * 0.4 + // grad2 angle
        (atan(grad3.y, grad3.x + 0.001) / (2.0*PI)) * 0.2 + // grad3 angle
        chaotic_time * 0.035 // Slow global hue drift
    );
    // Bright areas (high grad3 magnitude) get a hue shift
    hue = fract(hue + pow(length(grad3)*0.6, 2.5));

    // Saturation: Mostly high, with dynamic dips and pulses.
    float sat = 0.75 + 0.25 * abs(sin(noise1 * PI * 1.8 + chaotic_time * 1.2 + noise3 * 0.5)); // Pulsing base
    sat -= length(grad2) * 0.15; // Areas with strong mid-freq flow might slightly desaturate
    sat = clamp(sat, 0.7, 1.0); // Keep it mostly very saturated

    // Value (Brightness): Driven by multiple factors for extreme contrast and "energy".
    float val_base = 0.35 + 0.65 * smoothstep(-0.6, 0.6, noise2); // Base brightness from noise2
    // Rapid flicker from noise3 and high-frequency time modulation
    float val_detail_flicker = 0.5 + 0.5 * sin(noise3 * 15.0 + chaotic_time * 22.0 + noise1 * 6.0);
    // Extremely bright "cores" or "veins" from grad3 magnitude, modulated by noise1
    float val_energy_core = pow(length(grad3) * (1.0 + 0.8 * abs(noise1)), 3.5);
    
    float val = val_base * (0.5 + val_detail_flicker * 0.5) + val_energy_core * 0.7;
    val = pow(val, 1.4); // Crush blacks, boost highs

    // Allow value to go >1 for a bloom/HDR feel before final steps
    vec3 color = hsv2rgb(vec3(hue, sat, clamp(val, 0.0, 1.8)));

    // --- Post-Coloring FX for Extra Insanity ---

    // "Digital Glitch" Lines: Sharp, flickering lines that invert or shift colors.
    float glitch_trigger_fine = fract(noise1*10.1 + noise2*8.3 + noise3*12.7 + chaotic_time*0.33);
    float glitch_line_fine = smoothstep(0.49, 0.5, glitch_trigger_fine) - smoothstep(0.5, 0.51, glitch_trigger_fine);
    
    float glitch_trigger_coarse = fract(noise1*2.2 + noise2*3.1 - chaotic_time*0.11);
    float glitch_block = smoothstep(0.65, 0.7, glitch_trigger_coarse) * (0.5 + 0.5 * abs(sin(chaotic_time*5.0)));


    if (glitch_line_fine > 0.05) {
        color = vec3(1.0) - color * (0.4 + 0.6 * abs(sin(chaotic_time*12.0 + noise3 * 2.0))); // Pulsing inversion
    }
    if (glitch_block > 0.1) {
        color.rg = color.br * (0.7 + 0.3 * abs(cos(chaotic_time * 8.0))); // Channel swap
        color *= (1.0 - glitch_block * 0.7); // Darken blocks
    }
    
    // "Energy Shockwaves" / Additive Brightness Bursts
    float shockwave_val = smoothstep(0.68, 0.7, abs(noise1 + noise2*0.6)) * (1.0 + abs(noise3)); // Trigger
    shockwave_val += pow(max(0.0, noise3 - 0.5) * 2.5, 6.0); // High-noise3 bursts contribute massively
    vec3 shockwave_color = vec3(0.7, 0.85, 1.0) * (0.6 + 0.4 * abs(sin(hue * 2.0 * PI + chaotic_time))); // Color of shockwave depends on hue
    color += shockwave_color * shockwave_val * (0.7 + 0.6*abs(sin(chaotic_time * 8.0))); // Additive, bluish pulse

    // Final Tone Mapping / Contrast Punch / "Overdrive"
    // Using abs to handle potential negative intermediate values gracefully if effects are extreme
    color = pow(abs(color), vec3(1.15, 1.18, 1.22)); // Slightly different powers for channels can be "painterly"
    color = clamp(color, 0.0, 1.0); // Clamp at the very end for standard output

    out_color = vec4(color, 1.0);
}
