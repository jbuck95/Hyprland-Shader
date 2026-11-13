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




            // Ported from skwd-wall ink-splash transition

            float is_hash(vec2 p) {
                return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
            }

            float is_noise(vec2 p) {
                vec2 i = floor(p);
                vec2 f = fract(p);
                f = f * f * (3.0 - 2.0 * f);
                return mix(mix(is_hash(i), is_hash(i + vec2(1.0, 0.0)), f.x),
                           mix(is_hash(i + vec2(0.0, 1.0)), is_hash(i + vec2(1.0, 1.0)), f.x), f.y);
            }

            float is_fbm(vec2 p) {
                float v = 0.0;
                float amp = 0.5;
                for (int i = 0; i < 4; i++) {
                    v += amp * is_noise(p);
                    p *= 2.1;
                    amp *= 0.5;
                }
                return v;
            }

            

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
                vec2 tc = uv;
                vec4 win = texture(tex, tc.st);

                float blob = is_fbm(uv * 3.5);
                float fingers = is_fbm(uv * 14.0);
                float distortion = (blob - 0.5) * 0.5 + (fingers - 0.5) * 0.18;
                vec2 c = uv - vec2(0.5);
                c.x *= surface_size.x / max(surface_size.y, 0.0001);
                float d = length(c);
                float splash_d = d + distortion;
                float boundary = p * 1.7 - 0.15;
                float diff = splash_d - boundary;
                float reveal = smoothstep(0.04, -0.04, diff);

                fragColor = win * reveal;
            
}
