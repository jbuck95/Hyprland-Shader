#version 320 es
// @settle 0.35
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
uniform vec2 move_delta;
uniform float is_moving;
uniform float settle;

precision highp float;



/*
    'crumpledWave' by nasana (Created: 2020-01-29)
    Twitter/X: https://twitter.com/nasana_x
    Adapted for Hyprland window transitions.
*/

void main() {
    float _ws_spd = length(velocity);
    float _ws_peak_spd = length(peak_velocity);

    float _ws_slide_energy = clamp(_ws_spd / 10000.0, 0.0, 1.0);
    float _ws_tail_energy = clamp(_ws_peak_spd / 10000.0, 0.0, 1.0) * (1.0 - settle) * (1.0 - settle);
    float _ws_energy = (settle > 0.001 || is_moving < 0.5) ? _ws_tail_energy : _ws_slide_energy;

    if (_ws_energy < 0.002) {
        fragColor = texture(tex, v_texcoord);
        return;
    }

    vec2 _ws_dir = _ws_spd > 1.0 ? normalize(velocity) : (length(move_delta) > 1.0 ? normalize(move_delta) : vec2(1.0, 0.0));
    float _ws_progress = 1.0 - _ws_energy * 0.75;


    float p = _ws_progress;
    vec2 uv = v_texcoord;
    float seed_local = seed * 10.0;
    vec2 res = max(surface_size, vec2(1.0));

    float time = p * 2.5 + seed_local;

    vec2 p_uv = (uv - 0.5) * 2.0;
    p_uv.x *= res.x / res.y;

    vec2 wave_uv = p_uv;
    for (float i = 1.0; i < 8.0; i += 1.0) {
        wave_uv.y += 0.1 * sin(wave_uv.x * i * i + time * 0.8) * sin(wave_uv.y * i * i + time * 0.8);
    }

    vec3 wave_col = clamp(vec3(wave_uv.y - 0.1, wave_uv.y + 0.3, wave_uv.y + 0.95), 0.0, 1.0);

    float wave_disp = wave_uv.y - p_uv.y;
    float distort_strength = (1.0 - p) * (1.0 - p) * 0.4;
    vec2 warped_uv = uv + vec2(sin(wave_uv.y * 5.0) * 0.5, wave_disp) * distort_strength;

    vec2 center = uv - 0.5;
    float dist = length(center * vec2(1.0, 0.7));
    float appear = (1.0 - dist * 0.9) + wave_disp * 1.5;
    float reveal = smoothstep(appear + 0.35, appear - 0.35, (1.0 - p) * 1.6);

    vec4 screen = texture(tex, warped_uv);

    float edge = smoothstep(0.0, 0.5, reveal) * smoothstep(1.0, 0.3, reveal);
    vec3 final_rgb = mix(screen.rgb, wave_col, edge * 0.75);

    float mask = screen.a * reveal;
    fragColor = vec4(final_rgb * mask, mask);

}
