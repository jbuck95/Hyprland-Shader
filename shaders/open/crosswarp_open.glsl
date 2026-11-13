#version 320 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

uniform float progress;
uniform float seed;
uniform vec2 surface_size;


            // Ported from skwd-wall crosswarp transition

            
void main() {

                float p = progress;
                vec2 uv = v_texcoord;

                float x = smoothstep(0.0, 1.0, (p * 2.0 + uv.x - 1.0));
                vec2 warped = clamp((uv - 0.5) * x + 0.5, vec2(0.0), vec2(1.0));

                vec2 tc = warped;
                vec4 win = texture(tex, tc.st);

                float in_bounds = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
                fragColor = win * x * in_bounds;
            }

