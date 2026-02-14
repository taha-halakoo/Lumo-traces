#version 460 core
precision highp float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uMouse;

out vec4 fragColor;

// Rotate function
mat2 rot(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

// Signed Distance Functions
float sdSphere(vec3 p, float s) {
    return length(p) - s;
}

float sdTorus(vec3 p, vec2 t) {
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

float sdCappedCylinder(vec3 p, float h, float r) {
    vec2 d = abs(vec2(length(p.xz), p.y)) - vec2(r, h);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

// Smooth min for liquid welding
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

// Map the scene: Liquid Magnifying Glass
float map(vec3 p) {
    // Initial Angle
    p.xy *= rot(0.7);
    
    // Global Rotation (Slow spin)
    p.xy *= rot(uTime * 0.1);
    p.xz *= rot(uTime * 0.15);
    
    // Liquid Distortion
    float distortion = 0.05 * sin(3.0 * p.x + uTime * 2.0) * sin(3.0 * p.y + uTime * 1.5) * sin(3.0 * p.z + uTime);
    vec3 pDist = p + distortion;

    // 1. The Rim (Torus)
    vec3 pRim = pDist;
    float dRim = sdTorus(pRim, vec2(1.0, 0.15));

    // 2. The Lens (Flattened Sphere)
    vec3 pLens = pDist;
    pLens.y *= 2.5; 
    float dLens = sdSphere(pLens, 0.95);

    // 3. The Handle (Cylinder)
    vec3 pHandle = pDist;
    pHandle.x -= 1.8; 
    pHandle.xy *= rot(1.57);
    // Add handle rotation
    pHandle.xz *= rot(uTime * 0.5); 
    float dHandle = sdCappedCylinder(pHandle, 0.8, 0.15);

    // Combine Shapes
    float d = smin(dRim, dHandle, 0.3);
    d = min(d, dLens);
    
    return d;
}

// Calculate normal
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
    float d = 0.0;
    
    for (int i = 0; i < 64; i++) {
        vec3 p = ro + rd * t;
        d = map(p);
        t += d;
        if (d < 0.001 || t > 20.0) break;
    }
    
    if (t < 20.0) {
        vec3 p = ro + rd * t;
        vec3 n = calcNormal(p);
        vec3 lightPos = vec3(2.0, 2.0, 4.0);
        vec3 l = normalize(lightPos - p);
        
        float diff = max(dot(n, l), 0.0);
        float spec = pow(max(dot(reflect(-l, n), -rd), 0.0), 32.0);
        
        // Colors
        vec3 baseColor = vec3(0.0, 0.6, 0.9);
        baseColor += vec3(0.2, 0.0, 0.4) * sin(dot(n, vec3(0,1,0)) * 5.0 + uTime);

        float fresnel = pow(1.0 - max(dot(n, -rd), 0.0), 3.0);
        
        return baseColor * (diff + 0.2) + vec3(1.0) * spec + vec3(0.5, 0.8, 1.0) * fresnel;
    }
    return vec3(0.0);
}

void main() {
    vec2 uv = (FlutterFragCoord().xy * 2.0 - uResolution.xy) / min(uResolution.x, uResolution.y);
    
    vec3 ro = vec3(0.0, 0.0, 6.0); 
    vec3 rd = normalize(vec3(uv, -1.5));
    
    // Chromatic Aberration
    // Trace 3 rays slightly offset
    vec3 colR = render(ro, normalize(vec3(uv + vec2(0.005, 0.0), -1.5)));
    vec3 colG = render(ro, rd);
    vec3 colB = render(ro, normalize(vec3(uv - vec2(0.005, 0.0), -1.5)));
    
    vec3 col = vec3(colR.r, colG.g, colB.b);
    float alpha = length(col); // Simple alpha approx
    
    fragColor = vec4(col, clamp(alpha, 0.0, 1.0));
}
