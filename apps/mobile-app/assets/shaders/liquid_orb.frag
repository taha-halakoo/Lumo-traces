#version 460 core
precision highp float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uMouse;

out vec4 fragColor;

mat2 rot(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

// 3D Noise function for organic movement
float noise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix(fract(sin(dot(i + vec3(0, 0, 0), vec3(12.9898, 78.233, 45.543))) * 43758.5453),
                       fract(sin(dot(i + vec3(1, 0, 0), vec3(12.9898, 78.233, 45.543))) * 43758.5453), f.x),
                   mix(fract(sin(dot(i + vec3(0, 1, 0), vec3(12.9898, 78.233, 45.543))) * 43758.5453),
                       fract(sin(dot(i + vec3(1, 1, 0), vec3(12.9898, 78.233, 45.543))) * 43758.5453), f.x), f.y),
               mix(mix(fract(sin(dot(i + vec3(0, 0, 1), vec3(12.9898, 78.233, 45.543))) * 43758.5453),
                       fract(sin(dot(i + vec3(1, 0, 1), vec3(12.9898, 78.233, 45.543))) * 43758.5453), f.x),
                   mix(fract(sin(dot(i + vec3(0, 1, 1), vec3(12.9898, 78.233, 45.543))) * 43758.5453),
                       fract(sin(dot(i + vec3(1, 1, 1), vec3(12.9898, 78.233, 45.543))) * 43758.5453), f.x), f.y), f.z);
}

float map(vec3 p) {
    p.xy *= rot(uTime * 0.15); // Slower rotation
    p.xz *= rot(uTime * 0.1);
    
    // Base Sphere
    float d = length(p) - 1.2;
    
    // Viscous Displacement (Thicker liquid feel)
    float displacement = sin(2.0 * p.x + uTime * 0.8) * 
                         sin(2.0 * p.y + uTime * 0.9) * 
                         sin(2.0 * p.z + uTime * 0.7) * 0.25;
    
    // Subtle surface noise
    float n = noise(p * 1.5 + uTime * 0.3) * 0.08;
    
    return d + displacement + n;
}

vec3 calcNormal(vec3 p) {
    const float h = 0.001;
    const vec2 k = vec2(1, -1);
    return normalize(k.xyy * map(p + k.xyy * h) +
                     k.yyx * map(p + k.yyx * h) +
                     k.yxy * map(p + k.yxy * h) +
                     k.xxx * map(p + k.xxx * h));
}

vec3 render(vec3 ro, vec3 rd) {
    float t = 0.0;
    for (int i = 0; i < 64; i++) {
        vec3 p = ro + rd * t;
        float d = map(p);
        t += d;
        if (d < 0.001 || t > 10.0) break;
    }
    
    if (t < 10.0) {
        vec3 p = ro + rd * t;
        vec3 n = calcNormal(p);
        
        vec3 viewDir = -rd;
        float fresnel = pow(1.0 - max(dot(n, viewDir), 0.0), 3.0); // Sharper fresnel
        
        // TRACES Brand Palette
        // Deep Liquid Blue (Shadows/Body)
        vec3 colA = vec3(0.0, 0.1, 0.3); 
        // Electric Cyan (Midtones)
        vec3 colB = vec3(0.0, 0.8, 1.0);
        // Neon Purple/Pink (Highlights/Iridescence)
        vec3 colC = vec3(0.6, 0.0, 1.0); 
        
        // Environment Reflection
        vec3 ref = reflect(rd, n);
        float env = smoothstep(0.9, 1.0, sin(ref.y * 5.0 + uTime) * sin(ref.x * 5.0));
        
        // Mixing
        vec3 color = mix(colA, colB, n.y * 0.5 + 0.5);
        color += colC * fresnel * 2.0; // Strong iridescent rim
        color += vec3(1.0) * env * 0.8; // Sharp glass highlights
        
        return color;
    }
    return vec3(0.0);
}

void main() {
    vec2 uv = (FlutterFragCoord().xy * 2.0 - uResolution.xy) / min(uResolution.x, uResolution.y);
    
    vec3 ro = vec3(0.0, 0.0, 3.8);
    vec3 rd = normalize(vec3(uv, -1.0));
    
    // Enhanced Chromatic Aberration
    vec3 col;
    // Red channel offset
    col.r = render(ro, normalize(vec3(uv + vec2(0.008, 0.0), -1.0))).r;
    // Green channel center
    col.g = render(ro, rd).g;
    // Blue channel offset
    col.b = render(ro, normalize(vec3(uv - vec2(0.008, 0.0), -1.0))).b;
    
    // Vignette / Alpha mask
    float dist = length(uv);
    float alpha = smoothstep(1.4, 0.2, dist);
    
    // Add brightness to alpha for "Glow" effect
    alpha *= clamp(length(col) * 1.2, 0.0, 1.0);
    
    fragColor = vec4(col, alpha);
}
