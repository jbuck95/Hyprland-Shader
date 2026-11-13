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


            // Ported from skwd-wall polka-dots-curtain transition

            
void main() {

                float p = 1.0 - progress;
                vec2 uv = v_texcoord;
                vec2 tc = uv;
                vec4 win = texture(tex, tc.st);

                float dots = 20.0;
                vec2 center = vec2(0.0, 0.0);
                float reveal = step(distance(fract(uv * dots), vec2(0.5, 0.5)), p / max(distance(uv, center), 0.0001));

                fragColor = win * reveal;
            }

