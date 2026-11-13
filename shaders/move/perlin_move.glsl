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




            // Ported from skwd-wall perlin transition

            float perlin_random(vec2 co) {
                float a = 12.9898;
                float b = 78.233;
                float c = 43758.5453;
                float dt = dot(co.xy, vec2(a, b));
                float sn = mod(dt, 3.14);
                return fract(sin(sn) * c);
            }

            float perlin_noise(in vec2 st) {
                vec2 i = floor(st);
                vec2 f = fract(st);
                float a = perlin_random(i);
                float b = perlin_random(i + vec2(1.0, 0.0));
                float c = perlin_random(i + vec2(0.0, 1.0));
                float d = perlin_random(i + vec2(1.0, 1.0));
                vec2 u = f * f * (3.0 - 2.0 * f);
                return mix(a, b, u.x) +
                    (c - a) * u.y * (1.0 - u.x) +
                    (d - b) * u.x * u.y;
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



                float pr = _move_progress;
                vec2 uv = v_texcoord;
                vec2 tc = uv;
                vec4 win = texture(tex, tc.st);

                float scale = 4.0;
                float smoothness = 0.01;
                float n = perlin_noise(uv * scale);
                float p = mix(-smoothness, 1.0 + smoothness, pr);
                float lower = p - smoothness;
                float higher = p + smoothness;
                float q = smoothstep(lower, higher, n);
                float reveal = 1.0 - q;

                fragColor = win * reveal;
            
}
