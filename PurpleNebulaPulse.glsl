#version 300 es
precision highp float;

in vec2 uv;
out vec4 out_color;

uniform vec2 u_resolution;
uniform float u_time;

#define PI 3.14159265359
#define MAX_STEPS 64
#define MAX_DIST 100.0
#define SURF_DIST 0.005

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

float sdTorus(vec3 p, vec2 t) {
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

float map(vec3 p) {
    // Warped torus geometry
    p.xy *= rot(u_time * 0.3 + p.z * 0.2);
    p.xz *= rot(u_time * 0.25);
    
    float d = sdTorus(p, vec2(1.5 + sin(p.z * 0.5 + u_time) * 0.3, 0.4));
    
    // Add dimensional fluctuations
    d += sin(p.x * 5.0 + u_time * 2.0) * 0.05;
    d += sin(p.y * 3.0 + u_time * 1.5) * 0.03;
    d += sin(p.z * 8.0 + u_time * 3.0) * 0.02;
    
    return d * 0.7;
}

vec3 getParticle(vec2 uv, float depth) {
    vec3 col = vec3(0.0);
    for(int i = 0; i < 8; i++) {
        vec2 off = vec2(hash(vec2(i)) - 0.5, hash(vec2(i * 2)) - 0.5);
        float t = fract(u_time * 0.5 + hash(vec2(i)) * 2.0);
        float size = mix(0.001, 0.01, hash(vec2(i * 3)));
        float dist = length(uv + off * t * 0.5);
        float glow = smoothstep(size * 2.0, 0.0, dist) * 
                    pow(1.0 - t, 3.0) * 
                    (0.5 + 0.5 * sin(hash(vec2(i)) * 10.0 + u_time * 5.0));
        col += vec3(0.5, 0.7, 1.0) * glow * (1.0 + depth * 2.0);
    }
    return col;
}

void main() {
    vec2 st = (uv - 0.5) * vec2(u_resolution.x / u_resolution.y, 1.0);
    
    // Ray setup
    vec3 ro = vec3(0.0, 0.0, -3.0);
    vec3 rd = normalize(vec3(st, 1.0));
    
    // Depth-based color
    float depth = 0.0;
    vec3 col = vec3(0.0);
    
    // Ray marching
    for(int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * depth;
        float d = map(p);
        depth += d * 0.8;
        
        if(d < SURF_DIST || depth > MAX_DIST) break;
        
        // Dimensional glow
        float glow = (1.0 - smoothstep(0.0, 1.0, depth / MAX_DIST)) * exp(-d * 15.0);
        vec3 glowCol = mix(vec3(0.3, 0.5, 0.8), vec3(0.8, 0.4, 0.9), 
                         sin(depth * 0.5 + u_time) * 0.5 + 0.5);
        col += glowCol * glow * 0.1;
    }
    
    // Add floating particles
    col += getParticle(st, depth / MAX_DIST);
    
    // Central energy core
    float coreDist = length(st) * 1.5;
    float core = smoothstep(0.7, 0.0, coreDist) * 
                (0.5 + 0.5 * sin(u_time * 3.0)) * 
                pow(1.0 - depth / MAX_DIST, 3.0);
    col = mix(col, vec3(0.7, 0.8, 1.0), core * 0.5);
    
    // Vignette and color grading
    float vignette = 1.0 - smoothstep(0.5, 1.2, length(st));
    col *= vignette * 1.5;
    col = pow(col, vec3(1.0/2.2));
    
    out_color = vec4(col, 1.0);
}
