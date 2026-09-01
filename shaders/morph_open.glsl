#version 320 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

uniform float progress;
uniform float seed;
uniform vec2 surface_size;


            // Ported from skwd-wall morph transition

            
void main() {

                float p = progress;
                vec2 uv = v_texcoord;
                float strength_v = 0.15;

                vec2 tc0 = uv;
                vec4 cb = texture(tex, tc0.st);
                vec2 ob = ((cb.rg + cb.b) * 0.5) * 2.0 - 1.0;
                vec2 oc = ob * strength_v;
                float w1 = 1.0 - p;

                vec2 sample_uv = uv - oc * w1;
                vec2 tc = sample_uv;
                vec4 win = texture(tex, tc.st);

                fragColor = win * p;
            }

