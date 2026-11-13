#version 320 es
// @settle 0.4
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

uniform float time;
uniform float seed;
uniform vec2 surface_size;
uniform vec2 resolution;
uniform vec2 velocity;
uniform vec2 peak_velocity;
uniform float is_moving;
uniform float is_dragging;
uniform float settle;

precision highp float;



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
    float _move_spd = length(velocity);
    float _move_peak_spd = length(peak_velocity);

    float _move_energy_val = clamp(_move_spd / 8000.0, 0.0, 1.0);
    float _move_tail_energy = clamp(_move_peak_spd / 8000.0, 0.0, 1.0) * (1.0 - settle) * (1.0 - settle);
    float _move_energy = (settle > 0.001 || is_moving < 0.5) ? _move_tail_energy : _move_energy_val;

    if (is_dragging > 0.5) {
        _move_energy = max(_move_energy, clamp(_move_spd / 1500.0, 0.08, 0.8));
    }

    if (_move_energy < 0.002) {
        fragColor = texture(tex, v_texcoord);
        return;
    }

    vec2 _move_dir = _move_spd > 1.0 ? normalize(velocity) : (_move_peak_spd > 1.0 ? normalize(peak_velocity) : vec2(0.0, -1.0));
    float _move_progress = 1.0 - _move_energy * 0.75;


    float p = _move_progress;
    vec2 uv = v_texcoord;
    float seed_local = seed * 10.0;
    vec2 res = max(surface_size, vec2(1.0));

    float time = p * 4.0 + seed_local;

    // Window-centered aspect-scaled coordinates
    vec2 p_uv = (uv - 0.5) * 2.0;
    p_uv.x *= res.x / res.y;

    vec2 z = p_uv * 4.0;
    float iterations = min((1.0 - p) * 3.5, 3.0);
    for (float i = 0.0; i < 4.0; i += 1.0) {
        if (i < floor(iterations)) z = target(z, time);
    }
    z = mix(z, target(z, time), fract(iterations));

    vec2 warp_disp = (z - p_uv * 4.0) * 0.06 * (1.0 - p);
    vec2 warped_uv = uv + warp_disp;

    // Frosted glass dispersion blur on edges
    vec4 screen = vec4(0.0);
    float blur_rad = (1.0 - p) * (1.0 - p) * 0.025;
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

    // Reveal calculation
    vec2 center = uv - 0.5;
    float dist = length(center * vec2(1.0, 0.7));
    float appear = (1.0 - dist * 0.85) + (1.0 - clamp(length(z) * 0.15, 0.0, 1.0)) * 0.4;
    float reveal = smoothstep(appear + 0.35, appear - 0.35, (1.0 - p) * 1.6);

    float edge = smoothstep(0.0, 0.5, reveal) * smoothstep(1.0, 0.3, reveal);
    vec3 final_rgb = mix(screen.rgb, glass_tint, edge * 0.8);

    float mask = screen.a * reveal;
    fragColor = vec4(final_rgb * mask, mask);

}
