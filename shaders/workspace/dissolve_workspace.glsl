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



            float hash(vec2 p) {
                return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
            }

            float noise(vec2 p) {
                vec2 i = floor(p);
                vec2 f = fract(p);
                f = f * f * (3.0 - 2.0 * f);
                float a = hash(i);
                float b = hash(i + vec2(1.0, 0.0));
                float c = hash(i + vec2(0.0, 1.0));
                float d = hash(i + vec2(1.0, 1.0));
                return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
            }

            float fbm(vec2 p) {
                float v = 0.0;
                float amp = 0.5;
                for (int i = 0; i < 4; i++) {
                    v += amp * noise(p);
                    p *= 2.0;
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
                float seed_local = seed * 100.0;

                float rp = 1.0 - p;

                float particle_noise = fbm(uv * 8.0 + seed_local);
                float fine_noise = hash(floor(uv * 60.0) + seed_local);

                float direction_bias = (1.0 - uv.x) * 0.4 + uv.y * 0.4;
                float dissolve_threshold = particle_noise * 0.5 + fine_noise * 0.2 + direction_bias;

                float reveal = smoothstep(dissolve_threshold - 0.15, dissolve_threshold + 0.15, p * 1.6);

                float drift = rp * rp;
                vec2 drift_dir = normalize(vec2(1.0, -1.0));
                float drift_amount = drift * 0.08 * (particle_noise + fine_noise * 0.5);
                vec2 displaced_uv = uv + drift_dir * drift_amount * (1.0 - reveal);

                vec2 tex_coords = displaced_uv;
                vec4 color = texture(tex, tex_coords.st);

                float alpha = smoothstep(0.0, 0.1, p);

                fragColor = color * reveal * alpha;
            
}
