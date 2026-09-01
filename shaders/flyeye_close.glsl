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


            // Ported from skwd-wall flyeye transition

            
void main() {

                float p = 1.0 - progress;
                vec2 uv = v_texcoord;

                float sz = 0.04;
                float zoom = 50.0;
                float inv = 1.0 - p;
                vec2 disp = sz * vec2(cos(zoom * uv.x), sin(zoom * uv.y));
                vec2 sample_uv = uv + inv * disp;

                vec2 tc = sample_uv;
                vec4 win = texture(tex, tc.st);

                fragColor = win * p;
            }

