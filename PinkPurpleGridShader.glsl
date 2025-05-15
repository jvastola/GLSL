#version 300 es

precision highp float;
precision highp sampler2D;

// normalized coordinates, (0,0) is the bottom left
in vec2 uv;
// resulting fragment color, you may name it whatever you like
out vec4 out_color;

// size of the canvas in pixels
uniform vec2 u_resolution;
// elapsed time since shader compile in seconds
uniform float u_time;
// mouse pixel coordinates are in canvas space, (0,0) is top left
uniform vec4 u_mouse;
// texture array (unused in this version, but kept for signature)
uniform sampler2D u_textures[16];


//==================================================================
// INCLUDES
//==================================================================
#include "https://raw.githubusercontent.com/stegu/psrdnoise/main/src/psrdnoise2.glsl"
#include <lygia/animation/easing/bounce>

//==================================================================
// HELPERS
//==================================================================

// Controls how many tiles repeat across the screen
// Tweak these values!
#define TILE_COUNT 5.0 

#pragma region rotate
vec2 rot(vec2 v, float a){
   float s = sin(a);
   float c = cos(a);
    return mat2(c, -s, s, c) * v;
}
#pragma endregion

// SDF (Signed Distance Function) for a circle
float sdfCircle(vec2 p, float r) {
    return length(p) - r;
}

//==================================================================
// MAIN
//==================================================================
void main(){

    //--------------------------------
    // 1. COORDINATES & TILING
    //--------------------------------
    
    // Calculate Aspect Ratio to aim for square-ish tiles
    vec2 aspect = vec2(u_resolution.x / u_resolution.y, 1.0);
    
    // Scale UVs by TILE_COUNT
    // We use these scaled coordinates as the INPUT to the noise function
    vec2 scaled_uv = uv * TILE_COUNT;
   
    // The PERIOD for the noise function must match the TILE_COUNT
    // If you want non-square tiles, you can use vec2(TILES_X, TILES_Y) here
    // and in the scaled_uv calculation.
    vec2 noise_period = vec2(TILE_COUNT);

    // Calculate the coordinate WITHIN the current tile (0.0 to 1.0)
    // This is used for drawing shapes within the tile.
    vec2 tile_uv = fract(scaled_uv);
    
    // Center the tile coordinates (-0.5 to 0.5)
    // This is often easier for drawing radially symmetric shapes.
     vec2 tile_center_uv = tile_uv - 0.5;
       
    //--------------------------------
     // 2. MOUSE & NOISE
    //--------------------------------
     
    // Normalize mouse (0..1) and flip Y to match UV space
    vec2 mouse = u_mouse.xy / u_resolution;
    mouse.y = 1.0 - mouse.y; // (0,0) is now bottom-left
    
    float time = u_time * 0.4; // Base speed
    
    // Use mouse to slightly offset time or affect noise calculation
    time += mouse.x * 0.5; 
    
    vec2 gradient; // psrdnoise outputs a gradient, we aren't using it here but need the var.
    
    // CRITICAL: Use scaled_uv and noise_period to get seamlessly tiling noise
    float n = psrdnoise(
       scaled_uv * aspect, // Use aspect-corrected coords for less-stretched noise features
       noise_period * aspect, 
       time, 
       gradient);
       
    //--------------------------------
    // 3. VISUALS
    //--------------------------------

    // --- BACKGROUND: Wavy Lines ---
    float line_warp = n * 0.4; // How much noise distorts the lines
    float line_freq = PI * 6.0; // How many lines per tile
    
    // Calculate cosine lines, warped by noise
    float lines = cos( (tile_uv.y + line_warp) * line_freq );
    lines = lines * 0.5 + 0.5; // Remap from (-1..1) to (0..1)
    
    // Mix base colours using the eased line value
     vec3 bg_color = mix(
            vec3(0.1, 0.0, 0.15),      // Dark Purple
            vec3(0.463, 0.169, 0.690), // Mid Purple rgb(118,43,176)
            bounceInOut(lines)         // Use bounce for a sharper, more graphic feel
        );
        
    // --- FOREGROUND: Pulsing/Rotating Shape ---
     
    // Vary rotation based on time and mouse
     float angle = u_time * 0.5 + mouse.y * PI; 
     vec2 rotated_uv = rot(tile_center_uv, angle);
     
    // Pulsing Radius (0..1) using a sine wave
    float pulse = sin(u_time * 3.0 + n * 8.0) * 0.5 + 0.5; 
    float radius = 0.08 + pulse * 0.12;
    
    // Calculate distance to circle
    float circle_dist = sdfCircle(rotated_uv, radius);
    
    // Anti-alias the shape using screen-space derivatives
    float aa = fwidth(circle_dist) * 1.5;
    float shape_mask = 1.0 - smoothstep(-aa, aa, circle_dist);
    
    // Color for the shape
    vec3 shape_color = vec3(0.949, 0.561, 0.792); // Pink rgb(242,143,202)

    //--------------------------------
    // 4. COMPOSITING
    //--------------------------------
    
    // Mix the background and foreground based on the shape's mask
    vec3 final_color = mix(bg_color, shape_color, shape_mask);

    out_color = vec4(final_color, 1.0);
}
