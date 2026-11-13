#version 320 es
// @duration 0.6
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

uniform float progress;
uniform float seed;
uniform vec2 surface_size;
uniform vec2 resolution;

/*
    'Molten Glass' by mherreshoff - 2020-12-19
    Adapted as a molten glass refraction transition for Hyprland.
*/

float rand(float n) {
    return fract(sin(n) * 293.323);
}

float contRand(float n) {
    float i = floor(n);
    float x = fract(n);
    return mix(rand(i), rand(i + 1.0), smoothstep(0.0, 1.0, x));
}

float random(vec3 st) {
    return fract(sin(dot(st, vec3(12.9898, 78.233, 28.334))) * 43758.5453123);
}

#define CS(a) vec2(cos(a), sin(a))

vec2 target(vec2 z, float time) {
    vec2 weightedSum = vec2(0.0);
    float weight = 0.0;
    const float N = 3.0;
    for (float i = 0.0; i < N; i += 1.0) {
        float theta = 6.28318 * (i / N) + (contRand(time * 0.3 + (i * 17.0) + (i / N)) - 0.5);
        vec2 point = 2.0 * CS(theta);
        vec2 d = z - point;
        float L = length(d);
        float w = pow(max(L, 0.01), -2.0);
        float scale = 1.2 + 0.4 * contRand(time * 0.5 + 22.0);
        weight += w;
        weightedSum += scale * w * d;
    }
    return weightedSum / max(weight, 0.001);
}

void main() {
    float p = progress;
    vec2 uv = v_texcoord;
    float seed_local = seed * 10.0;
    vec2 res = surface_size.x > 1.0 ? surface_size : (resolution.x > 1.0 ? resolution : vec2(1920.0, 1080.0));

    float time = p * 4.0 + seed_local;

    // Window-centered aspect-scaled coordinates
    vec2 p_uv = (uv - 0.5) * 2.0;
    p_uv.x *= res.x / res.y;

    vec2 z = p_uv * 4.0;
    float iterations = min(p * 3.5, 3.0);
    for (float i = 0.0; i < 4.0; i += 1.0) {
        if (i < floor(iterations)) z = target(z, time);
    }
    z = mix(z, target(z, time), fract(iterations));

    vec2 warp_disp = (z - p_uv * 4.0) * 0.06 * p;
    vec2 warped_uv = uv + warp_disp;

    // Frosted glass dispersion blur on melt
    vec4 screen = vec4(0.0);
    float blur_rad = p * p * 0.025;
    const float SAMPLES = 8.0;
    for (float i = 0.0; i < SAMPLES; i += 1.0) {
        vec2 offset = vec2(
            random(vec3(warped_uv, i + seed_local)) - 0.5,
            random(vec3(warped_uv, i + 29.0 + seed_local)) - 0.5
        ) * blur_rad;
        screen += texture(tex, clamp(warped_uv + offset, 0.0, 1.0));
    }
    screen /= SAMPLES;

    // Glass refraction caustic highlights
    float glass_rim = length(warp_disp) * 15.0;
    vec3 glass_tint = mix(screen.rgb, screen.rgb * vec3(1.1, 1.15, 1.25) + vec3(0.08, 0.1, 0.15), clamp(glass_rim, 0.0, 0.8));

    // Dissolve calculation
    vec2 center = uv - 0.5;
    float dist = length(center * vec2(1.0, 0.7));
    float dissolve = (1.0 - dist * 0.85) + (1.0 - clamp(length(z) * 0.15, 0.0, 1.0)) * 0.4;
    float remain = smoothstep(dissolve + 0.3, dissolve - 0.3, p * 1.35);

    float edge = smoothstep(0.0, 0.6, remain) * smoothstep(1.0, 0.3, remain);
    vec3 final_rgb = mix(screen.rgb, glass_tint, edge * 0.8);

    float tail = smoothstep(1.0, 0.85, p);
    float mask = screen.a * remain * tail;
    fragColor = vec4(final_rgb * mask, mask);
}
