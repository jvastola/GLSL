#version 300 es
precision highp float;

in vec2 uv;
out vec4 out_color;

uniform vec2 u_resolution;
uniform float u_time;

#define PI 3.14159265359

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float circle(vec2 p, float r) {
    return smoothstep(0.02, 0.01, abs(length(p) - r));
}

void main() {
    vec2 st = uv * 2.0 - 1.0;
    st.x *= u_resolution.x / u_resolution.y;
    
    // Animated progress (0-1 range)
    float progress = 0.5 + 0.5 * sin(u_time * 0.5);
    
    // Central orb
    vec3 color = vec3(0.0);
    float orb = circle(st, 0.3);
    color += mix(vec3(0.1), vec3(0.3, 0.5, 1.0), orb);
    
    // Progress ring
    float angle = atan(st.y, st.x) + PI;
    float progressAngle = progress * PI * 2.0;
    float ring = smoothstep(0.02, 0.0, abs(length(st) - 0.4)) *
                step(angle, progressAngle);
    color += vec3(0.4, 0.7, 1.0) * ring * 2.0;
    
    // Rotating triangles
    mat2 rot = mat2(cos(u_time), -sin(u_time), sin(u_time), cos(u_time));
    vec2 triPos = rot * st * 2.0;
    float tri = max(
        abs(triPos.x * 1.7 + triPos.y * 0.5),
        abs(-triPos.x * 1.7 + triPos.y * 0.5)
    );
    tri = smoothstep(0.3, 0.29, tri) * 0.5;
    color += vec3(0.8, 0.9, 1.0) * tri * (0.7 + 0.3 * sin(u_time * 4.0));
    
    // Floating particles
    for(int i = 0; i < 8; i++) {
        float fi = float(i);
        float radius = 0.6 + sin(fi * 12.34 + u_time * 0.5) * 0.1;
        vec2 partPos = vec2(
            cos(fi * 2.4 + u_time) * radius,
            sin(fi * 3.1 + u_time * 1.2) * radius
        );
        float dist = length(st - partPos * 0.7);
        float p = smoothstep(0.03, 0.0, dist);
        color += vec3(0.6, 0.8, 1.0) * p * (0.5 + 0.5 * sin(fi * 10.0 + u_time));
    }
    
    // Hexagonal grid
    vec2 grid = fract(st * 4.0);
    grid = abs(grid - 0.5);
    float hex = smoothstep(0.3, 0.29, max(grid.x * 1.1 + grid.y, grid.y * 1.7));
    color = mix(color, color * 1.2, hex * 0.3);
    
    // Scanlines
    color *= 0.9 + 0.1 * sin(uv.y * u_resolution.y * PI * 2.0);
    
    // Vignette
    color *= 1.0 - pow(length(uv - 0.5) * 1.2, 2.0);
    
    out_color = vec4(color, 1.0);
}
