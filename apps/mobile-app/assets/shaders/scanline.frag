// Cyberpunk/Liquid Scanline Shader
// Author: Traces AI

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    
    // Scanline moving down
    float scanline = sin(uv.y * 100.0 - uTime * 5.0) * 0.05;
    
    // Color shift (Liquid/Chromatic Aberration)
    float r = 0.0; // Placeholder for texture lookup if we had input image
    
    // Simple gradient for background effect
    vec3 color = vec3(0.0, 0.1, 0.2) + vec3(scanline);
    
    // Liquid Distortion
    float liquid = sin(uv.x * 10.0 + uTime) * 0.01;
    
    fragColor = vec4(color + liquid, 0.5); // 0.5 Opacity
}
