#version 300 es
precision highp float;

in vec2 uv;
out vec4 out_color;

uniform vec2 u_resolution;
uniform float u_time;

vec3 palette(float t) {
    vec3 a = vec3(0.5, 0.7, 0.8);
    vec3 b = vec3(-0.4, -0.3, -0.1);
    vec3 c = vec3(1.5, 1.3, 1.4);
    vec3 d = vec3(0.2, 0.4, 0.6);
    return a + b * cos(6.28318 * (c * t + d));
}

float sdBox(in vec2 p, in vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

void main() {
    vec2 st = uv * u_resolution / min(u_resolution.x, u_resolution.y);
    st = st * 4.0 - 2.0;
    
    // Animated grid deformation
    vec2 grid = fract(st + vec2(
        sin(u_time * 0.3 + st.y * 0.7),
        cos(u_time * 0.4 + st.x * 0.6)
    ) * 0.15);
    
    // Distance field for cells
    vec2 gridPos = floor(st);
    vec2 cellCenter = gridPos + 0.5;
    float distToCenter = length(fract(st) - 0.5);
    
    // Pulsing cell size
    float cellSize =.8 + sin(u_time * 0.5 + gridPos.x * 0.3 + gridPos.y * 0.4) * 0.1;
    float shape = sdBox(fract(st) - 0.5, vec2(cellSize));
    
    // Color layers
    vec3 color1 = palette(length(cellCenter) * 0.2 - u_time * 0.1);
    vec3 color2 = palette(length(cellCenter) * 0.3 + u_time * 0.15);
    
    // Dynamic gradient
    float gradient = smoothstep(-0.5, 0.5, sin(dot(grid, vec2(12.9898,78.233)) * 4.0 + u_time * 2.0));
    
    // Combine elements
    float mask = smoothstep(0.3, 0.29, abs(shape) - 0.01);
    vec3 finalColor = mix(color1, color2, gradient) * (1.0 - mask);
    finalColor += vec3(0.8, 0.4, 0.6) * pow(1.0 - mask, 8.0) * (0.5 + 0.5 * sin(u_time * 2.0));
    
    // Soft vignette
    vec2 uvNorm = uv * 2.0 - 1.0;
    float vignette = 1.0 - dot(uvNorm, uvNorm) * 0.3;
    finalColor *= vignette;
    
    // Subtle scanlines
    finalColor *= 0.9 + 0.1 * sin(uv.y * u_resolution.y * 3.14159 * 2.0 + u_time * 2.0);
    
    out_color = vec4(finalColor, 1.0);
}
