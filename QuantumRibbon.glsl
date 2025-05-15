#version 300 es
precision highp float;

in vec2 uv;
out vec4 out_color;

uniform vec2 u_resolution;
uniform float u_time;

#include "https://raw.githubusercontent.com/stegu/psrdnoise/main/src/psrdnoise2.glsl"

#define PI 3.14159265359

vec3 spectral_color(float t) {
    return 0.5 + 0.5 * cos(2.0 * PI * t + vec3(0.0, 0.333, 0.777));
}

float fbm(vec2 p) {
    float total = 0.0;
    float amplitude = 1.0;
    vec2 grad_dummy;
    
    for(int i = 0; i < 5; i++) {
        total += psrdnoise(p, vec2(0.0), 0.0, grad_dummy) * amplitude;
        p *= 2.0;
        amplitude *= 0.5;
    }
    return total;
}

void main() {
    vec2 st = uv * 2.0 - 1.0;
    st.x *= u_resolution.x / u_resolution.y;
    
    // Hyperdimensional rotation parameters
    float time = u_time * 0.5;
    vec4 quat = vec4(
        sin(time * 0.7) * 0.3,
        cos(time * 0.6) * 0.4,
        sin(time * 0.8) * 0.2,
        cos(time * 0.5) * 0.3
    );
    
    // Projected coordinate system
    vec3 pos = vec3(st, 0.0);
    pos.xy += vec2(sin(time + st.y * 2.0), cos(time + st.x * 1.5)) * 0.2;
    
    // Quantum interference pattern
    float pattern = 0.0;
    vec2 grad_dummy;
    for(int i = 0; i < 7; i++) {
        float fi = float(i);
        vec3 offset = vec3(
            sin(fi * 1.7 + time * 0.5),
            cos(fi * 2.3 + time * 0.6),
            sin(fi * 0.9 + time * 0.4)
        ) * 0.15;
        
        vec3 qpos = pos + offset;
        float wave = sin(
            qpos.x * 20.0 + 
            qpos.y * (18.0 + sin(time * 0.3) * 5.0) + 
            qpos.z * 25.0 * cos(time * 0.2)
        );
        
        // Using fractal brownian motion noise
        pattern += abs(wave * fbm(qpos.xy * 3.0 + vec2(time * 0.1)));
    }
    
    // Energy core calculations
    float energy = smoothstep(0.3, 0.7, pattern * 0.4);
    energy *= 1.0 - smoothstep(0.5, 1.2, length(st));
    
    // Color quantum superposition
    vec3 color = spectral_color(pattern * 0.3 + time * 0.1);
    color = mix(color, color.grb, sin(time * 0.5 + st.x * 3.0) * 0.3 + 0.3);
    color = mix(color, color.brg, smoothstep(0.4, 0.6, energy));
    
    // Temporal flickering using psrdnoise
    vec2 grad_flicker;
    float flicker = psrdnoise(uv + vec2(time), vec2(10.0), time * 0.1, grad_flicker);
    color *= 0.9 + 0.2 * flicker;
    
    // Holographic effect
    float diffraction = sin((st.x + st.y) * 50.0 + time * 5.0) * 0.1;
    color = mix(color, color.brg, abs(diffraction) * energy);
    
    out_color = vec4(pow(color, vec3(1.0/2.2)), 1.0);
}
