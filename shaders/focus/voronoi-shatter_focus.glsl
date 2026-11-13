#version 320 es
// @duration 0.45
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

uniform float time;
uniform float progress;
uniform float seed;
uniform vec2 surface_size;
uniform vec2 resolution;

precision highp float;




            // Ported from skwd-wall voronoi-shatter transition

            vec2 vs_hash2(vec2 p) {
                return fract(sin(vec2(dot(p, vec2(127.1, 311.7)),
                                       dot(p, vec2(269.5, 183.3)))) * 43758.5453);
            }

            

void main() {
    float _focus_p_raw = clamp(progress, 0.0, 1.0);
    float _focus_env = sin(_focus_p_raw * 3.14159265);

    if (_focus_env < 0.001) {
        fragColor = texture(tex, v_texcoord);
        return;
    }

    float _focus_progress = 1.0 - _focus_env * 0.85;



                float p = _focus_progress;
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
