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


            // Ported from skwd-wall inkwell-drop transition

            
void main() {

                float p = 1.0 - progress;
                vec2 uv = v_texcoord;

                vec2 impact = vec2(0.35, 0.4);
                vec2 c = uv - impact;
                vec2 sz = surface_size.x > 1.0 ? surface_size : (resolution.x > 1.0 ? resolution : vec2(1920.0, 1080.0));
                c.x *= sz.x / max(sz.y, 0.0001);
                float d = length(c);
                float front = p * 1.5;
                float ring1 = sin((d - front) * 80.0) * exp(-abs(d - front) * 6.0);
                float ring2 = sin((d - front + 0.08) * 80.0) * exp(-abs(d - front + 0.08) * 8.0) * 0.6;
                float ring3 = sin((d - front + 0.16) * 80.0) * exp(-abs(d - front + 0.16) * 10.0) * 0.4;
                float ripple = (ring1 + ring2 + ring3) * 0.05 * (1.0 - p * 0.5);
                vec2 dir = (d > 0.001) ? normalize(c) : vec2(0.0);
                vec2 distorted = clamp(uv + dir * ripple, vec2(0.0), vec2(1.0));

                vec2 tc = distorted;
                vec4 win = texture(tex, tc.st);

                float reveal = smoothstep(0.05, -0.02, d - front);
                vec4 mixed = win * reveal;

                float in_bounds = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
                fragColor = mixed * in_bounds;
            }

