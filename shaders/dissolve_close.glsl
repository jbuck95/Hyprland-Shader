#version 320 es
// @duration 0.5
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

uniform float progress;
uniform float seed;
uniform vec2 surface_size;
uniform vec2 resolution;

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

                float p = progress;
                vec2 uv = v_texcoord;
                float seed_local = seed * 100.0;

                float particle_noise = fbm(uv * 8.0 + seed_local);
                float fine_noise = hash(floor(uv * 60.0) + seed_local);

                float direction_bias = uv.x * 0.4 + (1.0 - uv.y) * 0.4;

                float dissolve_threshold = particle_noise * 0.5 + fine_noise * 0.2 + direction_bias;

                float remain = 1.0 - smoothstep(dissolve_threshold - 0.15, dissolve_threshold + 0.15, p * 1.6);

                float dissolved_amount = 1.0 - remain;
                vec2 drift_dir = normalize(vec2(1.0, -1.0));
                float drift_strength = dissolved_amount * p * p * 0.12;

                float drift_rand = hash(floor(uv * 40.0) + seed_local + 7.0);
                vec2 drift_offset = drift_dir * drift_strength * (0.6 + drift_rand * 0.8);

                float turb = fbm(uv * 12.0 + seed_local + p * 4.0) - 0.5;
                drift_offset += vec2(turb, turb * 0.7) * dissolved_amount * p * 0.03;

                vec2 displaced_uv = uv + drift_offset;

                vec2 tex_coords = displaced_uv;
                vec4 color = texture(tex, tex_coords.st);

                float dust_life = smoothstep(0.0, 0.3, dissolved_amount) *
                                  smoothstep(1.0, 0.5, dissolved_amount);
                float dust_alpha = dust_life * (1.0 - p) * 0.6;

                vec2 base_tex = uv;
                vec4 base_color = texture(tex, base_tex.st);

                vec4 final_color = base_color * remain + color * dust_alpha;

                float tail = smoothstep(1.0, 0.85, p);
                fragColor = final_color * tail;
            }

