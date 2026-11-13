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

            vec2 warp_r;
            float warpedFbm(vec2 p, float t) {
                vec2 q = vec2(fbm(p + vec2(0.0, 0.0)),
                              fbm(p + vec2(5.2, 1.3)));

                warp_r = vec2(fbm(p + 6.0 * q + vec2(1.7, 9.2) + 0.25 * t),
                              fbm(p + 6.0 * q + vec2(8.3, 2.8) + 0.22 * t));

                return fbm(p + 5.0 * warp_r);
            }

            
void main() {

                float p = progress;
                vec2 uv = v_texcoord;
                float seed_local = seed * 100.0;

                float t = p * 12.0 + seed_local;

                float fluid = warpedFbm(uv * 2.0 + seed_local, t);

                vec2 center = uv - 0.5;
                float dist = length(center * vec2(1.0, 0.7));

                float dissolve = (1.0 - dist) * 0.9 + fluid * 0.4;
                float remain = smoothstep(dissolve + 0.3, dissolve - 0.3, p * 1.35);

                float distort_strength = p * p * 0.4;
                vec2 warped_uv = uv + (warp_r - 0.5) * distort_strength;

                vec2 tex_coords = warped_uv;
                vec4 color = texture(tex, tex_coords.st);

                float tail = smoothstep(1.0, 0.85, p);
                fragColor = color * remain * tail;
            }

