#version 320 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

uniform float progress;
uniform float seed;
uniform vec2 surface_size;


            // Ported from skwd-wall wave-warp transition

            
void main() {

                float p = progress;
                vec2 uv = v_texcoord;

                float smoothness = 0.5;
                vec2 dir = vec2(1.0, 0.0);
                vec2 v = normalize(dir);
                v /= abs(v.x) + abs(v.y);
                float d = v.x * 0.5 + v.y * 0.5;
                float m = 1.0 - smoothstep(-smoothness, 0.0, v.x * uv.x + v.y * uv.y - (d - 0.5 + p * (1.0 + smoothness)));

                vec2 warped = clamp((uv - 0.5) * m + 0.5, vec2(0.0), vec2(1.0));
                vec2 tc = warped;
                vec4 win = texture(tex, tc.st);

                float in_bounds = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
                fragColor = win * m * in_bounds;
            }

