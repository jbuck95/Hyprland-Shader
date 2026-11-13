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
    'Warp Speed 2' by David Hoskins 2015 (adapted for Hyprland transition).
    CC BY-NC-SA 3.0 / Fork of https://www.shadertoy.com/view/Msl3WH
*/
vec3 warpSpeedEffect(vec2 uv, float animTime) {
    float s = 0.0;
    float v = 0.0;
    vec3 col = vec3(0.0);
    vec3 init = vec3(sin(animTime * 0.0032) * 0.3, 0.35 - cos(animTime * 0.005) * 0.3, animTime * 0.002);

    for (int r = 0; r < 60; r++) {
        vec3 p = init + s * vec3(uv, 0.05);
        p.z = fract(p.z);
        for (int i = 0; i < 10; i++) {
            p = abs(p * 2.04) / dot(p, p) - 0.9;
        }
        v += pow(dot(p, p), 0.7) * 0.06;
        col += vec3(v * 0.2 + 0.4, 12.0 - s * 2.0, 0.1 + v * 1.0) * v * 0.00003;
        s += 0.035;
    }
    return tanh(col);
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
    float seed_local = seed * 100.0;
    vec2 res = max(surface_size, vec2(1.0));

    float animTime = (p * 3.0 + seed_local) * 58.0;

    vec2 p_uv = (uv - 0.5) * 2.0;
    p_uv.x *= res.x / res.y;

    vec3 col = clamp(warpSpeedEffect(p_uv, animTime), 0.0, 4.0);
    float energy = clamp(dot(col, vec3(0.299, 0.587, 0.114)), 0.0, 1.0);

    vec2 center = uv - 0.5;
    float dist = length(center * vec2(1.0, 0.7));

    float appear = (1.0 - dist * 1.2) + (1.0 - energy) * 0.7;
    float reveal = smoothstep(appear + 0.5, appear - 0.5, (1.0 - p) * 1.8);

    vec2 warp_r = clamp(vec2(dFdx(energy), dFdy(energy)) * 30.0 + 0.5, 0.0, 1.0);
    float distort_strength = (1.0 - p) * (1.0 - p) * 0.35;
    vec2 warped_uv = uv + (warp_r - 0.5) * distort_strength;

    vec4 screen = texture(tex, warped_uv);

    float edge = smoothstep(0.0, 0.6, reveal) * smoothstep(1.0, 0.4, reveal);
    vec3 final_rgb = mix(screen.rgb, col, edge * 0.9);

    float mask = screen.a * reveal;
    fragColor = vec4(final_rgb * mask, mask);

}
