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



// See wobbl_close.glsl for why this uses a simpler scheme than the other
// converted shaders: "Wobbl" has no independent color field of its own.

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

    float t = p * 6.0 + seed_local;

    // ease from the original 0.8*uv+0.1 zoom towards the untouched image
    vec2 zoomed_uv = mix(uv * 0.8 + 0.1, uv, p);

    float wobble_amt = 0.025 * smoothstep(0.0, 1.0, 1.0 - p);
    vec2 wobbled_uv = zoomed_uv + cos(t * vec2(4.0, 6.0) + zoomed_uv * 10.0) * wobble_amt;

    vec4 color = texture(tex, wobbled_uv);

    fragColor = color * p;

}
