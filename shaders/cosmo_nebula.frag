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
// Glowing Star
// ------------------------------------------------------------

float glowingStar(
    vec2 p,
    vec2 center,
    float radius
) {
    float d = length(p - center);
    float core = 1.0 - smoothstep(0.0, radius, d);
    float halo = exp(-d * d / (radius * radius * 12.0));
    return core * 0.7 + halo * 0.4;
}

// ------------------------------------------------------------
// Drifting Cosmic Particles
// ------------------------------------------------------------

float cosmicParticles(
    vec2 p,
    float scale,
    float speed,
    float seed
) {
    vec2 moving = p + vec2(uTime * speed, uTime * speed * 0.35);
    vec2 grid = moving * scale;
    vec2 cell = floor(grid);
    vec2 local = fract(grid) - 0.5;

    float random = hash(cell + seed);
    float present = step(0.90, random);

    vec2 offset = vec2(
        hash(cell + seed + 13.7),
        hash(cell + seed + 29.4)
    ) - 0.5;

    float d = length(local - offset * 0.8);
    float size = mix(0.015, 0.045, hash(cell + seed + 71.2));
    float particle = 1.0 - smoothstep(0.0, size, d);

    return particle * present;
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
    n += fbm(q * 2.8 + vec2(t * 0.04, -t * 0.02)) * 0.35;
    return n;
}

// ------------------------------------------------------------
// Distant Meteor Trails
// ------------------------------------------------------------

float meteorTrail(
    vec2 p,
    vec2 start,
    vec2 direction,
    float length,
    float width,
    float speed,
    float offset
) {
    vec2 d = normalize(direction);
    vec2 q = p - start;
    float along = dot(q, d);
    float across = abs(dot(q, vec2(-d.y, d.x)));

    float head = mod(uTime * speed + offset, 15.0) - 5.0;
    float headDistance = abs(along - head);

    float core = exp(-(headDistance * headDistance) / (width * width * 1.5));
    float trail = smoothstep(head - length, head, along);
    trail *= smoothstep(head - length, head - length * 0.1, along);
    float widthMask = exp(-(across * across) / (width * width * 4.0));

    return core * trail * widthMask;
}

// ------------------------------------------------------------
// Cosmic Cloud
// ------------------------------------------------------------

float cosmicCloud(vec2 p, float t, float scale, float seed) {
    vec2 q = p * scale + vec2(t * 0.035, -t * 0.018);
    q += vec2(sin(t * 0.11 + seed) * 0.35, cos(t * 0.08 + seed) * 0.28);

    float large = fbm(q);
    float medium = fbm(q * 1.8 + vec2(-t * 0.025, t * 0.018));
    float fine = fbm(q * 3.6 + vec2(t * 0.015, -t * 0.02));

    float cloud = large * 0.60 + medium * 0.28 + fine * 0.12;
    return smoothstep(0.38, 0.78, cloud);
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

    float t = uTime * 0.05;

    // Toned down base space
    vec3 color = vec3(0.006, 0.010, 0.025);

    // Nebula Layers
    float n1 = nebula(p * 1.1 + vec2(sin(t * 0.25), cos(t * 0.2)) * 0.2, t);
    float n2 = nebula(p * 1.6 - vec2(cos(t * 0.18), sin(t * 0.15)) * 0.15, t + 4.0);
    float n3 = nebula(p * 2.2 + vec2(t * 0.02), t + 8.0);

    float gas = smoothstep(0.32, 0.85, n1 * 0.5 + n2 * 0.3 + n3 * 0.2);

    // Cosmic Palette (Slightly Toned Down)
    vec3 deepBlue   = vec3(0.02, 0.12, 0.50);
    vec3 azure      = vec3(0.00, 0.40, 0.75);
    vec3 indigo     = vec3(0.10, 0.05, 0.50);
    vec3 violet     = vec3(0.30, 0.10, 0.75);
    vec3 purple     = vec3(0.50, 0.05, 0.75);
    vec3 magenta    = vec3(0.75, 0.03, 0.45);
    vec3 rose       = vec3(0.85, 0.12, 0.40);
    vec3 blueWhite  = vec3(0.35, 0.60, 0.85);

    float blueField    = fbm(p * 1.3 + vec2(t * 0.03));
    float violetField  = fbm(p * 1.7 - vec2(t * 0.025));
    float magentaField = fbm(p * 2.1 + vec2(sin(t * 0.18), cos(t * 0.12)));
    float cyanField    = fbm(p * 1.9 + vec2(cos(t * 0.16), sin(t * 0.14)));

    vec3 nebulaColor = vec3(0.0);
    nebulaColor += deepBlue * blueField;
    nebulaColor += azure * cyanField * 0.4;
    nebulaColor += indigo * violetField * 0.4;
    nebulaColor += violet * violetField;
    nebulaColor += purple * magentaField * 0.5;
    nebulaColor += magenta * magentaField * 0.7;
    nebulaColor += rose * magentaField * 0.2;

    nebulaColor /= 3.3;
    color += nebulaColor * gas * 1.1;

    // Gas Wisps & Dust
    float wisps = smoothstep(0.6, 0.85, fbm(p * 5.0 + vec2(t * 0.06, -t * 0.04)));
    color += vec3(0.12, 0.08, 0.25) * wisps * 0.2;

    float dust = mix(fbm(p * 1.5 - vec2(t * 0.01, t * 0.005)), fbm(p * 4.0 + vec2(t * 0.02, -t * 0.015)), 0.4);
    color *= (1.0 - smoothstep(0.35, 0.55, dust) * 0.3);

    // Cosmic Clouds
    float cBlue = cosmicCloud(p + vec2(-0.35, 0.12), t, 1.15, 1.0);
    float cViolet = cosmicCloud(p + vec2(0.28, -0.18), t + 4.0, 1.35, 4.0);
    float cMagenta = cosmicCloud(p + vec2(0.05, 0.30), t + 8.0, 1.70, 8.0);

    float cloudDepth = smoothstep(0.25, 0.75, cBlue * 0.45 + cViolet * 0.35 + cMagenta * 0.20);
    vec3 cCol = vec3(0.02, 0.20, 0.80) * cBlue * 0.4 + vec3(0.25, 0.05, 0.80) * cViolet * 0.5 + vec3(0.70, 0.03, 0.45) * cMagenta * 0.3;
    color += cCol * cloudDepth * 0.5;

    // Cloud Edges
    color += vec3(0.1, 0.5, 0.9) * smoothstep(0.48, 0.65, cBlue) * (1.0 - smoothstep(0.65, 0.82, cBlue)) * 0.25;
    color += vec3(0.4, 0.2, 0.9) * smoothstep(0.50, 0.68, cViolet) * (1.0 - smoothstep(0.68, 0.84, cViolet)) * 0.25;

    // Stars & Particles
    float tinyStars = starLayer(p + vec2(t * 0.002, -t * 0.001), 80.0, 0.85, 12.0);
    float medStars  = starLayer(p + vec2(-t * 0.003, t * 0.002), 45.0, 0.92, 38.0);
    float twinkle = 0.8 + 0.2 * sin(uTime * 1.5 + p.x * 20.0);

    color += vec3(0.7, 0.8, 0.9) * tinyStars * 0.3;
    color += mix(vec3(0.8, 0.9, 1.0), azure, 0.4) * medStars * 0.5 * twinkle;

    float pNear = cosmicParticles(p, 25.0, 0.005, 360.0);
    color += vec3(0.4, 0.7, 1.0) * pNear * 0.25;

    // Hero Stars
    float pulse1 = 0.85 + 0.15 * sin(uTime * 1.2);
    color += vec3(0.6, 0.8, 1.0) * glowingStar(p, vec2(-0.42, 0.24), 0.016) * pulse1;
    float pulse2 = 0.85 + 0.15 * sin(uTime * 0.8 + 2.0);
    color += vec3(0.7, 0.4, 1.0) * glowingStar(p, vec2(0.32, -0.18), 0.012) * pulse2;

    // Shooting Stars (Meteor Trails)
    float m1 = meteorTrail(p, vec2(-1.2, 0.4), vec2(1.0, -0.3), 1.0, 0.006, 0.8, 0.0);
    float m2 = meteorTrail(p, vec2(0.8, 0.6), vec2(-1.0, -0.5), 0.8, 0.004, 0.6, 7.0);
    float mGlow = 1.0 + cloudDepth * 1.5;
    color += vec3(0.6, 0.8, 1.0) * m1 * mGlow * 0.8;
    color += vec3(0.8, 0.6, 1.0) * m2 * mGlow * 0.8;

    // Final Polish
    float cosmicGlow = exp(-length(p) * length(p) * 1.5);
    color += vec3(0.02, 0.05, 0.15) * cosmicGlow;

    float vignette = smoothstep(1.2, 0.4, length(p));
    color *= vignette;

    fragColor = vec4(color * 1.05, 1.0);
}
