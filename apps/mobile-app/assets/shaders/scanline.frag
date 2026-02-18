#version 460 core
precision highp float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    vec2 center = vec2(0.5, 0.5);
    vec2 pos = uv - center;
    
    float dist = length(pos);
    float angle = atan(pos.y, pos.x);
    
    // Radar Sweep
    float sweep = mod(angle - uTime * 2.0, 6.28318);
    float beam = smoothstep(0.0, 0.5, sweep) * (1.0 - smoothstep(0.5, 1.0, sweep));
    // Sharp leading edge
    float radar = smoothstep(0.0, 0.1, -mod(angle + uTime * 3.0, 6.28318));
    
    // Concentric circles (Ripple)
    float circles = sin(dist * 50.0 - uTime * 5.0);
    float ripple = smoothstep(0.9, 1.0, circles) * (1.0 - dist); // Fade out at edges
    
    // Liquid Color: Neon Green/Cyan mix
    vec3 col = mix(vec3(0.0, 1.0, 0.8), vec3(0.0, 0.4, 1.0), dist);
    
    // Alpha mask
    float alpha = (radar * 0.3 + ripple * 0.5) * (1.0 - smoothstep(0.4, 0.5, dist));
    
    fragColor = vec4(col * alpha, alpha);
}
