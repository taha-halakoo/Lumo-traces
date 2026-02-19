#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform sampler2D uTexture;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    
    // Chromatic Aberration strength
    float aberration = 0.005 * sin(uTime * 2.0); // Pulsing aberration
    
    // Split channels
    float r = texture(uTexture, uv + vec2(aberration, 0.0)).r;
    float g = texture(uTexture, uv).g;
    float b = texture(uTexture, uv - vec2(aberration, 0.0)).b;
    float a = texture(uTexture, uv).a;
    
    fragColor = vec4(r, g, b, a);
}
