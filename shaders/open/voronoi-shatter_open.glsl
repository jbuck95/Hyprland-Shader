#version 320 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

uniform float progress;
uniform float seed;
uniform vec2 surface_size;


            // Ported from skwd-wall voronoi-shatter transition

            vec2 vs_hash2(vec2 p) {
                return fract(sin(vec2(dot(p, vec2(127.1, 311.7)),
                                       dot(p, vec2(269.5, 183.3)))) * 43758.5453);
            }

            
void main() {

                float p = progress;
                vec2 uv = v_texcoord;
                vec2 tc = uv;
                vec4 win = texture(tex, tc.st);

                float scale = 14.0;
                vec2 q = uv * scale;
                vec2 g = floor(q);
                vec2 f = fract(q);
                float min_d = 100.0;
                vec2 cell = g;
                for (int y = -1; y <= 1; y++) {
                    for (int x = -1; x <= 1; x++) {
                        vec2 nb = vec2(float(x), float(y));
                        vec2 r = nb + vs_hash2(g + nb) - f;
                        float d = dot(r, r);
                        if (d < min_d) { min_d = d; cell = g + nb; }
                    }
                }
                float seed_local = vs_hash2(cell).x;
                float shard_p = smoothstep(seed_local * 0.5, seed_local * 0.5 + 0.5, p);
                float reveal = smoothstep(0.0, 0.5, shard_p);

                fragColor = win * reveal;
            }

