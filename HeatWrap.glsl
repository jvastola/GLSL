#version 300 es
precision highp float;
precision highp sampler2D;

in vec2 uv;
out vec4 out_color;

uniform vec2 u_resolution;
uniform float u_time;

#include "https://raw.githubusercontent.com/stegu/psrdnoise/main/src/psrdnoise2.glsl"

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main() {
    vec2 st = uv * vec2(u_resolution.x / u_resolution.y, 1.0);
    float aspect = u_resolution.y / 128.0;
    vec2 tile_uv = st * aspect;
    
    float time = u_time * 0.8;
    vec2 grad1, grad2;
    
    // Layer 1: Base pattern
    float zoom1 = 1.5 + 0.3 * sin(time * 0.2);
    vec2 pos1 = tile_uv * zoom1 + vec2(time * 0.1, time * 0.08);
    float noise1 = psrdnoise(pos1, vec2(zoom1), time * 0.5, grad1);
    
    // Layer 2: Subtle details
    float zoom2 = 4.0;
    vec2 pos2 = tile_uv * zoom2 + grad1 * 0.3;
    float noise2 = psrdnoise(pos2, vec2(zoom2), time * 1.2, grad2);
    
    // Color generation
    float hue = fract(noise1 * 0.5 + noise2 * 0.3 + time * 0.05);
    float sat = 0.6 + noise1 * 0.2;
    float val = 0.7 + noise2 * 0.3;
    
    vec3 color = hsv2rgb(vec3(hue, sat, val));
    
    // Gentle contrast enhancement
    color = pow(color, vec3(1.2));
    
    // Soft pulsing effect
    color *= 0.9 + 0.1 * sin(time * 2.0);
    
    out_color = vec4(clamp(color, 0.0, 1.0), 1.0);
}
