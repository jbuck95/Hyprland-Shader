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


            // Ported from skwd-wall overexposure transition

            
void main() {

                float p = 1.0 - progress;
                vec2 uv = v_texcoord;
                float strength = 0.6;
                float PI = 3.141592653589793;

                vec2 tc = uv;
                vec4 win = texture(tex, tc.st);

                float to_m = p + sin(PI * p) * strength;
                vec4 mixed = vec4(
                    win.r * win.a * to_m,
                    win.g * win.a * to_m,
                    win.b * win.a * to_m,
                    win.a * p
                );

                fragColor = mixed;
            }

