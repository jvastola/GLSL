#version 300 es
precision highp float;

in vec2 uv;
out vec4 out_color;

uniform vec2 u_resolution;
uniform float u_time;

#include "https://raw.githubusercontent.com/stegu/psrdnoise/main/src/psrdnoise2.glsl"

#define PI 3.14159265359

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec3 nebula(vec2 uv) {
    vec3 col = vec3(0.0);
    vec2 grad;
    
    // Base nebula with multiple frequencies
    float n1 = psrdnoise(uv * 0.5 + vec2(u_time*0.1), vec2(0.0), u_time*0.05, grad);
    float n2 = psrdnoise(uv * 2.0 + vec2(u_time*0.2), vec2(0.0), u_time*0.1, grad);
    float n3 = psrdnoise(uv * 8.0 + vec2(u_time*0.3), vec2(0.0), u_time*0.2, grad);
    
    // Color layers
    vec3 red = vec3(1.0,0.3,0.2) * pow(n1, 2.0);
    vec3 blue = vec3(0.2,0.4,1.0) * pow(n2, 3.0);
    vec3 purple = vec3(0.8,0.3,1.0) * pow(n3, 4.0);
    
    return red + blue * 0.7 + purple * 0.5;
}

vec3 starfield(vec2 uv) {
    vec3 stars = vec3(0.0);
    for(int i=0; i<50; i++) {
        vec2 p = vec2(hash(vec2(i)), hash(vec2(i*2)));
        p = 0.5 + 0.5*sin(u_time*0.5 + 6.2831*p);
        float dist = length(uv - p);
        float brightness = smoothstep(0.999, 1.0, hash(vec2(i)))*0.8;
        stars += brightness * exp(-400.0*dist*dist);
    }
    return stars;
}

void main() {
    vec2 st = (uv - 0.5) * vec2(u_resolution.x/u_resolution.y, 1.0) * 2.0;
    
    // Black hole distortion
    float radius = length(st);
    vec2 warped = st * (1.0 + 0.5/(1.0 + radius*10.0));
    
    // Cosmic elements
    vec3 nebula = nebula(warped * 1.5);
    vec3 stars = starfield(warped * 2.0);
    
    // Accretion disk
    float disk = smoothstep(0.4, 0.41, radius) * smoothstep(0.6, 0.59, radius);
    vec3 diskColor = hsv2rgb(vec3(radius*2.0 + u_time*0.1, 0.8, 1.0));
    
    // Gravitational lensing
    float lens = smoothstep(0.3, 0.0, radius) * (1.0 + sin(radius*30.0 - u_time*5.0)*0.3);
    
    // Combine elements
    vec3 color = nebula * 2.0 + stars;
    color = mix(color, diskColor, disk * 0.7);
    color += lens * vec3(0.8, 0.9, 1.0) * 0.5;
    
    // Central singularity
    float singularity = pow(smoothstep(0.5, 0.0, radius), 4.0);
    color += vec3(1.0, 0.8, 0.6) * singularity * (1.0 + sin(u_time*10.0)*0.3);
    
    // Vignette
    color *= 1.0 - smoothstep(0.8, 2.0, length(st));
    
    // Gamma correction
    color = pow(color, vec3(1.0/2.2));
    
    out_color = vec4(color, 1.0);
}

mat2 rotate2D(float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}
