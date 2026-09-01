#version 320 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

uniform float progress;
uniform float seed;
uniform vec2 surface_size;


            // Ported from skwd-wall randomsquares transition

            float rs_rand(vec2 co) {
                return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
            }

            
void main() {

                float p = progress;
                vec2 uv = v_texcoord;
                vec2 tc = uv;
                vec4 win = texture(tex, tc.st);

                vec2 sz = vec2(10.0, 10.0);
                float smoothness = 0.5;
                float r = rs_rand(floor(sz * uv));
                float reveal = smoothstep(0.0, -smoothness, r - (p * (1.0 + smoothness)));

                fragColor = win * reveal;
            }

