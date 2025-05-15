#version 300 es
precision highp float;

in vec2 uv;
out vec4 out_color;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec4 u_mouse;

#define PI 3.14159265359
#define TAU 6.28318530718

// Gradient noise from IQ
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f*f*(3.0-2.0*f);
    return mix(mix(hash(i+vec2(0,0)), hash(i+vec2(1,0)),u.x),
               mix(hash(i+vec2(0,1)), hash(i+vec2(1,1)),u.x), u.y);
}

mat2 rot(float a) { return mat2(cos(a),-sin(a),sin(a),cos(a)); }

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0,2.0/3.0,1.0/3.0,3.0);
    vec3 p = abs(fract(c.xxx + K.xyz)*6.0-K.www);
    return c.z * mix(K.xxx, clamp(p-K.xxx,0.0,1.0),c.y);
}

void main() {
    vec2 st = (uv - 0.5)*vec2(u_resolution.x/u_resolution.y,1.0);
    vec2 m = u_mouse.xy/u_resolution.xy;
    
    // Core energy field
    vec3 color = vec3(0.0);
    float t = u_time*0.5;
    
    // Hyperbolic tunnel effect
    float tunnel = 0.1/length(st);
    vec2 tunnelUV = st*tunnel*5.0 + vec2(t*0.3);
    
    // Quantum plasma strands
    for(int i=0; i<3; i++) {
        float fi = float(i);
        vec2 p = st*rot(fi*TAU/3.0 + t*0.5);
        float drift = sin(p.x*10.0 + t*2.0)*0.1;
        float plasma = sin(p.x*50.0 + p.y*30.0 + t*5.0 + drift);
        color += hsv2rgb(vec3(fi*0.3 + t*0.1,0.8,0.7)) * 
                 smoothstep(0.4,0.6,plasma) * tunnel;
    }
    
    // Fractal lightning
    vec2 lpos = st*rot(t) + vec2(sin(t),cos(t*0.7));
    for(int i=0; i<5; i++) {
        lpos = abs(lpos)/dot(lpos,lpos) - 0.7;
        color += hsv2rgb(vec3(0.7 + noise(lpos*3.0)*0.3,1.0,1.0)) * 
                 0.1*smoothstep(0.9,1.0,noise(lpos*40.0));
    }
    
    // Vortex distortion
    vec2 vortex = mix(st,m-st,0.3+0.3*sin(t));
    vortex *= rot(length(vortex)*TAU - t*2.0);
    
    // Particle storm
    for(int i=0; i<40; i++) {
        float fi = float(i);
        vec2 p = vec2(sin(fi*312.43),cos(fi*491.21));
        p = 0.5 + 0.5*sin(t + fi + vec2(t*3.0,t*2.0));
        p = (p - 0.5)*2.0;
        float dist = length(st - p);
        float glow = pow(0.01/dist,1.5);
        color += hsv2rgb(vec3(fi*0.1 + t*0.2,0.8,1.0)) * 
                 glow * (0.7 + 0.5*sin(fi*10.0 + t));
    }
    
    // Shockwave from mouse
    if(m.x > 0.0 && m.y > 0.0) {
        float dist = length(st - (m - 0.5)*2.0);
        float wave = smoothstep(0.3,0.0,abs(dist - fract(t)*2.0));
        color += vec3(2.0,1.0,0.5) * wave * pow(tunnel,2.0);
    }
    
    // Post-processing
    color = pow(color,vec3(1.0/0.4545)); // Gamma correction
    color *= 1.0 - smoothstep(0.8,2.0,length(st)); // Vignette
    
    out_color = vec4(color,1.0);
}
