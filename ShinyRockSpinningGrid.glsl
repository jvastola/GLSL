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

mat2 rotate2D(float angle) {
    return mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
}

float triangleWave(float x) {
    return 2.0 * abs(fract(x) - 0.5) - 1.0;
}

void main() {
    vec2 st = uv * vec2(u_resolution.x / u_resolution.y, 1.0);
    st = st * 4.0 - 2.0;
    
    // Dynamic triangular grid
    float gridSize = 0.8 + sin(u_time * 0.3) * 0.1;
    vec2 gridPos = floor(st / gridSize);
    vec2 gridUV = fract(st / gridSize);
    
    // Pyramid coordinates
    vec2 pyramidUV = gridUV * 2.0 - 1.0;
    pyramidUV = rotate2D(u_time * 0.5 + gridPos.x * 0.7 + gridPos.y * 0.9) * pyramidUV;
    
    // Triangular distance field
    float edge = 0.9;
    float a = atan(pyramidUV.x, pyramidUV.y) + u_time;
    float tri = 1.0 - smoothstep(edge - 0.1, edge, 
        max(abs(pyramidUV.x * 1.7 + pyramidUV.y), 
            -pyramidUV.y * 1.4 + 0.7));
    
    // Color layers
    float hue = fract(length(gridPos) * 0.1 + u_time * 0.05);
    vec3 baseColor = hsv2rgb(vec3(hue, 0.8, 0.9));
    vec3 energyColor = hsv2rgb(vec3(fract(hue + 0.3), 0.9, 1.0));
    
    // Pulsing energy lines
    float energyFlow = sin(gridPos.x * 3.0 + gridPos.y * 5.0 + u_time * 4.0);
    energyFlow *= pow(tri, 2.0) * 1.5;
    
    // Rotating inner triangle
    vec2 innerUV = rotate2D(u_time * 0.8) * pyramidUV;
    float innerTri = 1.0 - smoothstep(0.5, 0.6, 
        max(abs(innerUV.x * 1.7 + innerUV.y), 
            -innerUV.y * 1.4 + 0.4));
    
    // Composition
    vec3 color = mix(baseColor, energyColor, energyFlow);
    color = mix(color, vec3(1.0), innerTri * 0.5);
    
    // Depth shading
    float depth = 1.0 - length(pyramidUV) * 0.7;
    color *= depth * 1.5;
    
    // Glowing edges
    float glow = pow(tri, 4.0) * 2.0;
    color += vec3(0.8, 0.4, 1.0) * glow;
    
    // Hexagonal grid effect
    float hex = smoothstep(0.02, 0.01, 
        abs(gridUV.x - 0.5) + abs(gridUV.y - 0.5));
    color = mix(color, vec3(0.0), hex * 0.3);
    
    // Animated scanlines
    float scanline = sin(st.y * 80.0 + u_time * 5.0) * 0.1 + 0.9;
    color *= scanline;
    
    // Vignette
    float vignette = 1.0 - pow(length(uv - 0.5) * 1.2, 2.0);
    color *= vignette;
    
    out_color = vec4(color, 1.0);
}
