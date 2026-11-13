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


            // Ported from skwd-wall bounce transition

            
void main() {

                float p = progress;
                vec2 uv = v_texcoord;
                float PI = 3.14159265358;
                float bounces = 3.0;

                float time = p;
                float stime = sin(time * PI / 2.0);
                float phase = time * PI * bounces;
                float yy = (abs(cos(phase))) * (1.0 - stime);
                float d = uv.y - yy;

                vec2 sample_uv = uv;
                sample_uv.y = uv.y + (1.0 - yy);
                vec2 tc = sample_uv;
                vec4 win = texture(tex, tc.st);

                float reveal = step(d, 0.0);
                fragColor = win * reveal;
            }

