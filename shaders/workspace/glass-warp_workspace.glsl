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
