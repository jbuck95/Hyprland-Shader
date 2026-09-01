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


            // Ported from skwd-wall fadecolor transition

            
void main() {

                float p = 1.0 - progress;
                vec2 uv = v_texcoord;
                float colorPhase = 0.4;

                vec2 tc = uv;
                vec4 win = texture(tex, tc.st);

                float reveal = smoothstep(colorPhase, 1.0, p);
                fragColor = win * reveal;
            }

