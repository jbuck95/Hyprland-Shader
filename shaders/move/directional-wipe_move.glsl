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




            // Ported from skwd-wall directional-wipe transition

            

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
                vec2 tc = uv;
                vec4 win = texture(tex, tc.st);

                vec2 dir = vec2(1.0, -1.0);
                float smoothness = 0.5;
                vec2 center = vec2(0.5, 0.5);
                vec2 v = normalize(dir);
                v /= abs(v.x) + abs(v.y);
                float d = v.x * center.x + v.y * center.y;
                float reveal = (1.0 - step(p, 0.0)) *
                    (1.0 - smoothstep(-smoothness, 0.0, v.x * uv.x + v.y * uv.y - (d - 0.5 + p * (1.0 + smoothness))));

                fragColor = win * reveal;
            
}
