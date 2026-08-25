#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;
uniform float uTime;

out vec4 fragColor;

// ------------------------------------------------------------
// Hash
// ------------------------------------------------------------

float hash(vec2 p) {
    p = fract(p * vec2(127.1, 311.7));
    p += dot(p, p + 19.19);
    return fract(p.x * p.y);
}

// ------------------------------------------------------------
// Star Field
// ------------------------------------------------------------

float starLayer(vec2 p, float scale, float density, float seed) {
    vec2 grid = p * scale;
    vec2 cell = floor(grid);
    vec2 local = fract(grid) - 0.5;

    float random = hash(cell + seed);
    float present = step(density, random);

    vec2 offset = vec2(
        hash(cell + seed + 17.3),
        hash(cell + seed + 41.7)
    ) - 0.5;

    float distanceToStar = length(local - offset * 0.7);
    float size = mix(0.012, 0.050, hash(cell + seed + 73.1));
    float star = 1.0 - smoothstep(0.0, size, distanceToStar);

    return star * present;
}

// ------------------------------------------------------------
// Value Noise
// ------------------------------------------------------------

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    // Smoothstep interpolation
    f = f * f * (3.0 - 2.0 * f);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// ------------------------------------------------------------
// Fractal Brownian Motion
// ------------------------------------------------------------

float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;

    for (int i = 0; i < 6; i++) {
        value += amplitude * noise(p);
        p *= 2.02;
        amplitude *= 0.5;
    }

    return value;
}

// ------------------------------------------------------------
// Domain Warp
// ------------------------------------------------------------

vec2 warp(vec2 p, float t) {
    // Smoother movement using low-frequency oscillations
    float x = fbm(p + vec2(sin(t * 0.2), t * 0.3));
    float y = fbm(p + vec2(5.2 + cos(t * 0.15), -t * 0.2));

    return p + vec2(x, y) * 0.4;
}

// ------------------------------------------------------------
// Nebula Density
// ------------------------------------------------------------

float nebula(vec2 p, float t) {
    vec2 q = warp(p, t);
    float n = fbm(q * 1.4);

    // Add secondary layer with slightly different warp for depth
    n += fbm(q * 2.8 + vec2(t * 0.04, -t * 0.02)) * 0.35;

    return n;
}

// ------------------------------------------------------------
// Main
// ------------------------------------------------------------

void main() {
    vec2 pos = FlutterFragCoord();
    vec2 uv = pos / uSize;

    float aspect = uSize.x / uSize.y;
    vec2 p = uv;
    p.x *= aspect;
    p -= vec2(aspect * 0.5, 0.5);

    // Global slow time for majestic movement
    float t = uTime * 0.05;

    // ========================================================
    // BASE SPACE
    // ========================================================

    vec3 color = vec3(0.008, 0.012, 0.035);

    // ========================================================
    // LARGE NEBULA LAYERS
    // ========================================================

    // Multi-layer nebula for complex depth
    float n1 = nebula(p * 1.1 + vec2(sin(t * 0.25), cos(t * 0.2)) * 0.2, t);
    float n2 = nebula(p * 1.6 - vec2(cos(t * 0.18), sin(t * 0.15)) * 0.15, t + 4.0);
    float n3 = nebula(p * 2.2 + vec2(t * 0.02), t + 8.0);

    float gas = n1 * 0.5 + n2 * 0.3 + n3 * 0.2;
    gas = smoothstep(0.32, 0.85, gas);

    // ========================================================
    // COSMIC PALETTE
    // ========================================================

    vec3 deepBlue   = vec3(0.03, 0.16, 0.65);
    vec3 azure      = vec3(0.00, 0.55, 1.00);
    vec3 indigo     = vec3(0.14, 0.08, 0.65);
    vec3 violet     = vec3(0.42, 0.12, 1.00);
    vec3 purple     = vec3(0.65, 0.08, 0.95);
    vec3 magenta    = vec3(0.95, 0.04, 0.55);
    vec3 rose       = vec3(1.00, 0.16, 0.48);
    vec3 blueWhite  = vec3(0.45, 0.75, 1.00);

    // ========================================================
    // DYNAMIC COLOR FIELDS
    // ========================================================

    float blueField    = fbm(p * 1.2 + vec2(t * 0.02));
    float violetField  = fbm(p * 1.6 - vec2(t * 0.015));
    float magentaField = fbm(p * 2.0 + vec2(sin(t * 0.15), cos(t * 0.1)));
    float cyanField    = fbm(p * 1.8 + vec2(cos(t * 0.12), sin(t * 0.13)));

    vec3 nebulaColor = vec3(0.0);
    nebulaColor += deepBlue * blueField;
    nebulaColor += azure * cyanField * 0.4;
    nebulaColor += indigo * violetField * 0.4;
    nebulaColor += violet * violetField;
    nebulaColor += purple * magentaField * 0.5;
    nebulaColor += magenta * magentaField * 0.7;
    nebulaColor += rose * magentaField * 0.2;

    nebulaColor /= 3.3;
    color += nebulaColor * gas * 1.35;

    // ========================================================
    // FINE GAS WISPS
    // ========================================================

    float wisps = fbm(p * 5.0 + vec2(t * 0.06, -t * 0.04));
    wisps = smoothstep(0.6, 0.85, wisps);
    color += vec3(0.15, 0.1, 0.3) * wisps * 0.25;

    // ========================================================
    // DARK INTERSTELLAR DUST
    // ========================================================

    float dustLarge = fbm(p * 1.5 - vec2(t * 0.01, t * 0.005));
    float dustFine  = fbm(p * 4.0 + vec2(t * 0.02, -t * 0.015));
    float dust      = mix(dustLarge, dustFine, 0.4);
    float dustMask  = smoothstep(0.35, 0.55, dust);

    color *= (1.0 - dustMask * 0.35);

    // ========================================================
    // GAS EDGES & HOT REGIONS
    // ========================================================

    float gasEdge = smoothstep(0.6, 0.75, gas) * (1.0 - smoothstep(0.75, 0.9, gas));
    color += blueWhite * gasEdge * 0.2;

    float hot = smoothstep(0.7, 0.9, gas);
    float hotNoise = smoothstep(0.4, 0.7, fbm(p * 3.5 + vec2(t * 0.03)));
    color += vec3(0.7, 0.3, 0.9) * hot * hotNoise * 0.2;

    // ========================================================
    // STARS
    // ========================================================

    float tinyStars = starLayer(p + vec2(t * 0.002, -t * 0.001), 80.0, 0.85, 12.0);
    float medStars  = starLayer(p + vec2(-t * 0.003, t * 0.002), 45.0, 0.92, 38.0);
    float bigStars  = starLayer(p + vec2(t * 0.001, t * 0.001), 25.0, 0.97, 82.0);

    float twinkle = 0.8 + 0.2 * sin(uTime * 1.5 + p.x * 20.0 + p.y * 20.0);

    color += vec3(0.8, 0.9, 1.0) * tinyStars * 0.4;
    color += mix(vec3(0.9, 0.95, 1.0), azure, 0.4) * medStars * 0.7 * twinkle;
    color += mix(vec3(1.0, 1.0, 1.0), vec3(1.0, 0.8, 0.6), 0.3) * bigStars * 1.3;

    // ========================================================
    // VIGNETTE & FINAL ADJUST
    // ========================================================

    float dist = length(p);
    float vignette = smoothstep(1.2, 0.4, dist);
    color *= vignette;

    fragColor = vec4(color * 1.1, 1.0);
}
