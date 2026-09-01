#version 320 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

uniform float progress;
uniform float seed;
uniform vec2 surface_size;


            // Ported from skwd-wall pixelfade-wave transition

            
void main() {

                float p = progress;
                vec2 uv = v_texcoord;

                float wave_x = (uv.x + uv.y) * 0.5;
                float wave_p = smoothstep(0.0, 1.0, p * 1.6 - wave_x * 0.6);
                float bump = sin(wave_p * 3.14159);
                float blocks = mix(800.0, 8.0, bump);
                vec2 q = floor(uv * blocks) / blocks + 0.5 / blocks;

                vec2 tc = q;
                vec4 win = texture(tex, tc.st);

                float reveal = smoothstep(0.0, 1.0, wave_p);
                fragColor = win * reveal;
            }

