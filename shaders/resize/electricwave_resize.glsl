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
uniform vec2 size_velocity;
uniform vec2 peak_size_velocity;
uniform float is_resizing;
uniform float is_dragging;
uniform float settle;

precision highp float;



/*
    'Electric Wave / CineShader' by nasana (Created: 2020-01-30)
    Twitter/X: https://twitter.com/nasana_x
    Adapted for Hyprland window transitions.
*/

void main() {
    float _resize_spd = length(size_velocity);
    float _resize_peak_spd = length(peak_size_velocity);

    float _resize_energy_val = clamp(_resize_spd / 1200.0, 0.0, 1.0);
    float _resize_tail_energy = clamp(_resize_peak_spd / 1200.0, 0.0, 1.0) * (1.0 - settle) * (1.0 - settle);
    float _resize_energy = (settle > 0.001 || is_resizing < 0.5) ? _resize_tail_energy : _resize_energy_val;

    if (is_dragging > 0.5) {
        _resize_energy = max(_resize_energy, clamp(_resize_spd / 400.0, 0.08, 0.8));
    }

    if (_resize_energy < 0.002) {
        fragColor = texture(tex, v_texcoord);
        return;
    }

    vec2 _resize_dir = normalize(size_velocity);
    float _resize_progress = 1.0 - _resize_energy * 0.75;


    float p = _resize_progress;
    vec2 uv = v_texcoord;
    float seed_local = seed * 10.0;
    vec2 res = max(surface_size, vec2(1.0));

    float time = p * 2.5 + seed_local;

    vec2 p_uv = (uv - 0.5) * 2.0;
    p_uv.x *= res.x / res.y;

    vec2 wave_uv = p_uv;
    for (float i = 1.0; i < 10.0; i += 1.0) {
        wave_uv.x += (0.6 / i) * cos(i * 2.5 * wave_uv.y + time);
        wave_uv.y += (0.6 / i) * cos(i * 1.5 * wave_uv.x + time);
    }

    float glow = 0.1 / max(abs(sin(time - wave_uv.y - wave_uv.x)), 0.02);
    vec3 glow_col = clamp(vec3(glow * 0.8, glow * 0.9, glow * 1.1), 0.0, 3.0);
    float energy = clamp(glow * 0.25, 0.0, 1.0);

    vec2 disp = wave_uv - p_uv;
    float distort_strength = (1.0 - p) * (1.0 - p) * 0.35;
    vec2 warped_uv = uv + disp * distort_strength;

    vec2 center = uv - 0.5;
    float dist = length(center * vec2(1.0, 0.7));
    float appear = (1.0 - dist * 0.9) + energy * 0.6;
    float reveal = smoothstep(appear + 0.35, appear - 0.35, (1.0 - p) * 1.6);

    vec4 screen = texture(tex, warped_uv);

    float edge = smoothstep(0.0, 0.5, reveal) * smoothstep(1.0, 0.3, reveal);
    vec3 final_rgb = mix(screen.rgb, screen.rgb + glow_col * 0.6, edge * 0.85);

    float mask = screen.a * reveal;
    fragColor = vec4(final_rgb * mask, mask);

}
