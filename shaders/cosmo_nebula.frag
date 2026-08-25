#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;
uniform float uTime;

out vec4 fragColor;

// ------------------------------------------------------------
// Hash / pseudo-random
// ------------------------------------------------------------

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// ------------------------------------------------------------
// Smooth noise
// ------------------------------------------------------------

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    f = f * f * (3.0 - 2.0 * f);

    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));

    return mix(
            mix(a, b, f.x),
            mix(c, d, f.x),
            f.y
    );
}

// ------------------------------------------------------------
// Fractal noise
// ------------------------------------------------------------

float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;

    for (int i = 0; i < 5; i++) {
        value += amplitude * noise(p);
        p *= 2.0;
        amplitude *= 0.5;
    }

    return value;
}

// ------------------------------------------------------------
// Soft cosmic cloud
// ------------------------------------------------------------

float cloud(
        vec2 uv,
        vec2 center,
        float radius
) {
    float distance = length(uv - center);

    float shape = 1.0 - smoothstep(
            radius * 0.15,
            radius,
            distance
    );

    return shape;
}

// ------------------------------------------------------------
// Main
// ------------------------------------------------------------

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;

    // Correct aspect ratio.
    float aspect = uSize.x / uSize.y;

    vec2 p = uv;
    p.x *= aspect;

    // Center coordinates.
    p -= vec2(aspect * 0.5, 0.5);

    // --------------------------------------------------------
    // Very slow organic movement
    // --------------------------------------------------------

    float t = uTime * 0.035;

    vec2 flow = vec2(
            sin(t * 0.7),
            cos(t * 0.5)
    ) * 0.08;

    vec2 noisePosition = p * 2.8 + flow;

    float n1 = fbm(noisePosition);

    float n2 = fbm(
            p * 5.0 -
            vec2(t * 0.8, -t * 0.35)
    );

    float nebula = n1 * 0.7 + n2 * 0.3;

    // --------------------------------------------------------
    // Cosmic color fields
    // --------------------------------------------------------

    float blueCloud = cloud(
            p,
            vec2(-0.65, -0.10),
            0.75
    );

    float violetCloud = cloud(
            p,
            vec2(0.35, -0.25),
            0.85
    );

    float magentaCloud = cloud(
            p,
            vec2(0.55, 0.55),
            0.65
    );

    float cyanCloud = cloud(
            p,
            vec2(-0.40, 0.55),
            0.60
    );

    // --------------------------------------------------------
    // Color palette
    // --------------------------------------------------------

    vec3 color = vec3(
            0.015,
            0.020,
            0.065
    );

    color += vec3(
            0.02,
            0.18,
            0.85
    ) * blueCloud * nebula * 0.75;

    color += vec3(
            0.30,
            0.05,
            0.90
    ) * violetCloud * nebula * 0.75;

    color += vec3(
            0.90,
            0.05,
            0.55
    ) * magentaCloud * nebula * 0.55;

    color += vec3(
            0.00,
            0.55,
            0.95
    ) * cyanCloud * nebula * 0.45;

    // --------------------------------------------------------
    // Subtle gas variation
    // --------------------------------------------------------

    float gas = smoothstep(
            0.25,
            0.85,
            nebula
    );

    color += vec3(
            0.08,
            0.04,
            0.16
    ) * gas;

    // Keep the deepest areas dark.
    color *= 0.85 + nebula * 0.35;

    fragColor = vec4(color, 1.0);
}