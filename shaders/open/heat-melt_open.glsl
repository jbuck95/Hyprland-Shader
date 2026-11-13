#version 320 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

uniform float progress;
uniform float seed;
uniform vec2 surface_size;


            // Ported from skwd-wall heat-melt transition

            float hm_rand(vec2 co) { return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453); }
            vec3 hm_mod289_3(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
            vec2 hm_mod289_2(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
            vec3 hm_permute(vec3 x) { return hm_mod289_3(((x * 34.0) + 1.0) * x); }
            float hm_snoise(vec2 v) {
                const vec4 C = vec4(0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439);
                vec2 i = floor(v + dot(v, C.yy));
                vec2 x0 = v - i + dot(i, C.xx);
                vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
                vec4 x12 = x0.xyxy + C.xxzz;
                x12.xy -= i1;
                i = hm_mod289_2(i);
                vec3 q = hm_permute(hm_permute(i.y + vec3(0.0, i1.y, 1.0)) + i.x + vec3(0.0, i1.x, 1.0));
                vec3 m = max(0.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), 0.0);
                m = m * m; m = m * m;
                vec3 x = 2.0 * fract(q * C.www) - 1.0;
                vec3 h = abs(x) - 0.5;
                vec3 ox = floor(x + 0.5);
                vec3 a0 = x - ox;
                m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);
                vec3 g;
                g.x = a0.x * x0.x + h.x * x0.y;
                g.yz = a0.yz * x12.xz + h.yz * x12.yw;
                return 130.0 * dot(m, g);
            }

            
void main() {

                float p = progress;
                vec2 uv = v_texcoord;
                vec2 tc = uv;
                vec4 win = texture(tex, tc.st);

                vec2 center = vec2(1.0, 1.0);
                float dist = distance(center, uv) - p * exp(hm_snoise(vec2(uv.x, 0.0)));
                float r = p - hm_rand(vec2(uv.x, 0.1));
                float reveal = (dist <= r) ? 1.0 : (p * p * p);

                fragColor = win * reveal;
            }

