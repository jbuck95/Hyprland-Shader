#version 320 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

uniform float progress;
uniform float seed;
uniform vec2 surface_size;


            // Ported from skwd-wall crazy-parametric transition

            
void main() {

                float p = progress;
                vec2 uv = v_texcoord;

                float a = 4.0;
                float b = 1.0;
                float amplitude = 120.0;
                float smoothness = 0.1;
                vec2 dir = uv - vec2(0.5);
                float dist = length(dir);
                float xx = (a - b) * cos(p) + b * cos(p * ((a / b) - 1.0));
                float yy = (a - b) * sin(p) - b * sin(p * ((a / b) - 1.0));
                vec2 offset = dir * vec2(sin(p * dist * amplitude * xx), sin(p * dist * amplitude * yy)) / smoothness;

                vec2 tc = uv;
                vec4 win = texture(tex, tc.st);

                float reveal = smoothstep(0.2, 1.0, p);
                fragColor = win * reveal;
            }

