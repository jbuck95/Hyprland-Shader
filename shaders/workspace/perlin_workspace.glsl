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



                float pr = _ws_progress;
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
