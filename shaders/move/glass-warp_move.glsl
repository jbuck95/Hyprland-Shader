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

            float dist = length(uv - 0.5) * 2.0;
            float start_delay = dist * 0.6;
            float t = clamp((p - start_delay) / (1.0 - start_delay), 0.0, 1.0);
            float strong_t = pow(t, 2.5);

            if (p < start_delay) { fragColor = vec4(0.0); return; }

            vec2 center = vec2(0.5);
            vec2 from_center = uv - center;
            vec2 spawn = center + from_center * 0.1;
            vec2 render_pos = mix(spawn, uv, strong_t);

            vec2 tex_coords = render_pos;
            vec4 color = texture(tex, tex_coords.st);

            bool is_window_area = uv.x >= -0.075 && uv.x <= 1.075 &&
                                  uv.y >= -0.075 && uv.y <= 1.075;

            float alpha = mix(1.0, t, pow(dist, 0.5));
            if (!is_window_area) {
                float ring_fade = 1.0 - smoothstep(0.99, 0.999, p);
                alpha *= ring_fade;
            }
            fragColor = color * alpha;


}
