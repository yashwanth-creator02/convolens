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
// Value Noise
// ------------------------------------------------------------

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    f = f * f * (3.0 - 2.0 * f);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    return mix(
            mix(a, b, f.x),
            mix(c, d, f.x),
            f.y
    );
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
    float x = fbm(
            p + vec2(
                    0.0,
                    t * 0.35
            )
    );

    float y = fbm(
            p + vec2(
                    5.2,
                    -t * 0.25
            )
    );

    return p + vec2(x, y) * 0.45;
}

// ------------------------------------------------------------
// Nebula Density
// ------------------------------------------------------------

float nebula(vec2 p, float t) {
    vec2 q = warp(p, t);

    float n = fbm(q * 1.4);

    n += fbm(
            q * 2.8 + vec2(t * 0.05)
    ) * 0.35;

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

    p -= vec2(
            aspect * 0.5,
            0.5
    );

    float t = uTime * 0.08;

    // ========================================================
    // BASE SPACE
    // ========================================================

    vec3 color = vec3(
            0.010,
            0.015,
            0.045
    );

    // ========================================================
    // LARGE NEBULA
    // ========================================================

    float n1 = nebula(
            p * 1.15 +
            vec2(
                    sin(t * 0.30),
                    cos(t * 0.24)
            ) * 0.15,
            t
    );

    float n2 = nebula(
            p * 1.65 -
            vec2(
                    cos(t * 0.22),
                    sin(t * 0.18)
            ) * 0.12,
            t + 3.0
    );

    float n3 = nebula(
            p * 2.4,
            t + 8.0
    );

    float gas =
    n1 * 0.55 +
    n2 * 0.30 +
    n3 * 0.15;

    gas = smoothstep(
            0.35,
            0.82,
            gas
    );

    // ========================================================
    // COSMIC PALETTE
    // ========================================================

    vec3 deepBlue = vec3(
            0.03,
            0.16,
            0.65
    );

    vec3 azure = vec3(
            0.00,
            0.55,
            1.00
    );

    vec3 indigo = vec3(
            0.14,
            0.08,
            0.65
    );

    vec3 violet = vec3(
            0.42,
            0.12,
            1.00
    );

    vec3 purple = vec3(
            0.65,
            0.08,
            0.95
    );

    vec3 magenta = vec3(
            0.95,
            0.04,
            0.55
    );

    vec3 rose = vec3(
            1.00,
            0.16,
            0.48
    );

    vec3 blueWhite = vec3(
            0.45,
            0.75,
            1.00
    );

    // ========================================================
    // COLOR FIELDS
    // ========================================================

    float blueField = fbm(
            p * 1.3 +
            vec2(t * 0.03)
    );

    float violetField = fbm(
            p * 1.7 -
            vec2(t * 0.025)
    );

    float magentaField = fbm(
            p * 2.1 +
            vec2(
                    sin(t * 0.18),
                    cos(t * 0.12)
            )
    );

    float cyanField = fbm(
            p * 1.9 +
            vec2(
                    cos(t * 0.16),
                    sin(t * 0.14)
            )
    );

    vec3 nebulaColor = vec3(0.0);

    nebulaColor += deepBlue * blueField;
    nebulaColor += azure * cyanField * 0.45;
    nebulaColor += indigo * violetField * 0.45;
    nebulaColor += violet * violetField;
    nebulaColor += purple * magentaField * 0.55;
    nebulaColor += magenta * magentaField * 0.75;
    nebulaColor += rose * magentaField * 0.22;

    nebulaColor /= 3.4;

    color += nebulaColor * gas * 1.25;

    // ========================================================
    // FINE GAS WISPS
    // ========================================================

    float wisps = fbm(
            p * 5.5 +
            vec2(
                    t * 0.08,
                    -t * 0.05
            )
    );

    wisps = smoothstep(
            0.58,
            0.82,
            wisps
    );

    color += vec3(
            0.18,
            0.10,
            0.35
    ) * wisps * 0.22;

    // ========================================================
    // DARK INTERSTELLAR DUST
    // ========================================================

    float dustLarge = fbm(
            p * 1.8 -
            vec2(
                    t * 0.015,
                    t * 0.008
            )
    );

    float dustFine = fbm(
            p * 4.2 +
            vec2(
                    t * 0.025,
                    -t * 0.018
            )
    );

    float dust = mix(
            dustLarge,
            dustFine,
            0.35
    );

    float dustMask = smoothstep(
            0.38,
            0.52,
            dust
    );

    color *= 1.0 - dustMask * 0.30;

    // ========================================================
    // GAS EDGES
    // ========================================================

    float gasEdge = smoothstep(
            0.58,
            0.78,
            gas
    );

    gasEdge *= 1.0 - smoothstep(
            0.78,
            0.92,
            gas
    );

    color += blueWhite *
    gasEdge *
    0.18;

    // ========================================================
    // HOT NEBULA REGIONS
    // ========================================================

    float hot = smoothstep(
            0.72,
            0.92,
            gas
    );

    float hotNoise = smoothstep(
            0.45,
            0.75,
            fbm(
                    p * 3.8 + vec2(t * 0.04)
            )
    );

    hot *= hotNoise;

    color += vec3(
            0.65,
            0.25,
            0.85
    ) * hot * 0.18;

    // ========================================================
    // DEEP VOID CONTRAST
    // ========================================================

    float voidNoise = fbm(
            p * 0.75
    );

    color *= 0.70 +
    voidNoise * 0.45;

    // ========================================================
    // VIGNETTE
    // ========================================================

    float distanceFromCenter = length(p);

    float vignette = smoothstep(
            1.20,
            0.30,
            distanceFromCenter
    );

    color *= vignette;

    // ========================================================
    // FINAL EXPOSURE
    // ========================================================

    color *= 1.05;

    fragColor = vec4(
            color,
            1.0
    );
}
