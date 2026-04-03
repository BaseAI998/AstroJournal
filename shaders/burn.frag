// An extremely minimal and compatible fragment shader for Flutter

#include <flutter/runtime_effect.glsl>

uniform vec2 resolution;
uniform float progress;     
uniform sampler2D image;

out vec4 fragColor;

// --- Hash and Noise ---
vec2 hash22(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)),
             dot(p, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

// Simplex Noise
float simplexNoise(vec2 p) {
    const float K1 = 0.366025404; // (sqrt(3)-1)/2;
    const float K2 = 0.211324865; // (3-sqrt(3))/6;

    vec2 i = floor(p + (p.x + p.y) * K1);
    vec2 a = p - i + (i.x + i.y) * K2;
    vec2 o = (a.x > a.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec2 b = a - o + K2;
    vec2 c = a - 1.0 + 2.0 * K2;

    vec3 h = max(0.5 - vec3(dot(a, a), dot(b, b), dot(c, c)), 0.0);
    vec3 n = h * h * h * h * vec3(dot(a, hash22(i + 0.0)),
                                  dot(b, hash22(i + o)),
                                  dot(c, hash22(i + 1.0)));
    return dot(n, vec3(70.0));
}

// FBM based on Simplex Noise
float fbm(vec2 p) {
    float f = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 5; i++) {
        f += amp * simplexNoise(p);
        p *= 2.0;
        amp *= 0.5;
    }
    // Normalize to roughly 0.0 - 1.0
    return f * 0.5 + 0.5;
}

// --- Color Palettes ---
// Real fire has distinct bands: white core -> yellow -> orange -> red -> dark smoke/ash
vec4 getFireColor(float x) {
    // x is the distance from the burning edge (0.0 = destroyed, 1.0 = inner flame)
    
    vec4 ashColor = vec4(0.05, 0.05, 0.05, 0.8); // Dark grey ash
    vec4 darkRed = vec4(0.5, 0.0, 0.0, 1.0);     // Cooling fire
    vec4 orange = vec4(1.0, 0.4, 0.0, 1.0);      // Main flame
    vec4 yellow = vec4(1.0, 0.9, 0.2, 1.0);      // Hot inner flame
    vec4 white = vec4(1.0, 1.0, 1.0, 1.0);       // Hottest core
    
    if (x < 0.2) return mix(ashColor, darkRed, x / 0.2);
    if (x < 0.5) return mix(darkRed, orange, (x - 0.2) / 0.3);
    if (x < 0.8) return mix(orange, yellow, (x - 0.5) / 0.3);
    return mix(yellow, white, (x - 0.8) / 0.2);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / resolution.xy;
    
    // Original image texture
    vec4 texColor = texture(image, uv);
    
    // We don't process empty pixels at all
    if (texColor.a < 0.01) {
        fragColor = texColor;
        return;
    }

    // --- 1. Burn Pattern Generation ---
    // Scale for the noise (smaller scale = bigger flames)
    vec2 noiseUV = uv * 3.0; 
    
    // Flame animation: moves upward over time
    float time = progress * 3.0;
    noiseUV.y -= time * 1.5; 
    noiseUV.x += sin(time + uv.y * 3.0) * 0.2; // Slight wavering
    
    // Generate the "burn map" (0.0 to 1.0)
    float burnMap = fbm(noiseUV * 4.0);
    
    // --- 2. Progression Control ---
    // To make it burn from the edges inward, we calculate a mask
    // We'll use a simple vertical sweep + noise, or a center-out sweep.
    // Let's use a bottom-to-top sweep mixed with center-out for a paper-burning feel.
    float distFromCenter = length(uv - vec2(0.5, 0.5)) * 1.5;
    
    // The "front" of the fire. 
    // progress goes 0.0 -> 1.0. We map it to cover the whole image.
    // We subtract burnMap so the fire has a ragged edge.
    float fireFront = (progress * 2.0) - distFromCenter - burnMap * 0.6;
    
    // --- 3. Rendering ---
    
    // If fireFront > 0.1, the paper is completely gone
    if (fireFront > 0.15) {
        fragColor = vec4(0.0); // Transparent
        return;
    }
    
    // If fireFront < 0.0, the fire hasn't reached here yet. Show pure paper.
    if (fireFront < -0.1) {
        fragColor = texColor;
        return;
    }
    
    // We are IN the fire band (-0.1 to 0.15).
    // Normalize this band to 0.0 (paper side) to 1.0 (ash side)
    float fireBand = (fireFront - (-0.1)) / 0.25; 
    
    // Reverse it so 1.0 is the hot edge near paper, 0.0 is the ash fading out
    float fireIntensity = 1.0 - fireBand; 
    
    // --- 4. Deformation & Charring (Crucial for realism) ---
    // Right before it burns, paper turns black/brown (charring)
    vec4 charColor = vec4(0.05, 0.03, 0.02, texColor.a);
    
    // As fire gets closer, paper chars
    float charAmount = smoothstep(0.7, 1.0, fireIntensity); // Only char right at the fire's edge
    vec4 basePaper = mix(charColor, texColor, charAmount);
    
    // --- 5. Add the Flames ---
    // We add actual additive fire colors ON TOP of the paper
    vec4 fire = getFireColor(fireIntensity);
    
    // The fire is brightest in the middle of the band, and fades at the edges
    float flameVisibility = sin(fireIntensity * 3.14159); 
    // We use pow to make the flames sharper and more distinct
    flameVisibility = pow(flameVisibility, 2.0); 
    
    // Additive blending for the fire (light adds up)
    vec3 finalRGB = basePaper.rgb + (fire.rgb * flameVisibility * 1.5);
    
    // The ash end (fireIntensity near 0) should fade to transparent
    float finalAlpha = texColor.a * smoothstep(0.0, 0.2, fireIntensity);
    
    fragColor = vec4(finalRGB, finalAlpha);
}