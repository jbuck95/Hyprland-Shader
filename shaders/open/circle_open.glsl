#version 320 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

uniform float progress;
uniform float seed;
uniform vec2 surface_size;


            // Ported from gl-transitions/circleopen.glsl (MIT, gre)

            
void main() {

                float p = progress;
                vec2 uv = v_texcoord;
                float seed_local = seed;

                float smoothness = 0.3;
                float SQRT_2 = 1.414213562;

                vec2 center = vec2(0.5 + (seed_local - 0.5) * 0.15, 0.5 + (seed_local * 0.7 - 0.35) * 0.15);

                float dist = SQRT_2 * distance(center, uv);
                float m = smoothstep(-smoothness, 0.0, dist - p * (1.0 + smoothness));
                float reveal = 1.0 - m;

                vec2 tc = uv;
                vec4 color = texture(tex, tc.st);

                fragColor = color * reveal;
            }

