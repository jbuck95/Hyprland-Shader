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
