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


            // Ported from skwd-wall static-fade transition

            float sf_rnd(vec2 st) {
                return fract(sin(dot(st.xy, vec2(10.5302340293, 70.23492931))) * 12345.5453123);
            }

            vec4 sf_static(vec2 st, float offset, float lum) {
                float r = lum * sf_rnd(st * vec2(offset * 2.0, offset * 3.0));
                float g = lum * sf_rnd(st * vec2(offset * 3.0, offset * 5.0));
                float b = lum * sf_rnd(st * vec2(offset * 5.0, offset * 7.0));
                return vec4(r, g, b, 1.0);
            }

            float sf_intensity(float t) {
                float tp = abs(2.0 * (t - 0.5));
                return min(1.0, 1.2 * (1.0 - tp) - 0.1);
            }

            
void main() {

                float p = 1.0 - progress;
                vec2 uv = v_texcoord;
                vec2 tc = uv;
                vec4 win = texture(tex, tc.st);

                float n_pixels = 200.0;
                vec2 uvStatic = floor(uv * n_pixels) / n_pixels;
                vec4 staticColor = sf_static(uvStatic, p, 0.8);
                float staticThresh = sf_intensity(p);
                float staticMix = step(sf_rnd(uvStatic), staticThresh);

                float reveal = step(0.5, p);
                vec4 base = win * reveal;
                vec4 result = mix(base, staticColor, staticMix * smoothstep(0.0, 1.0, p));

                float in_bounds = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
                fragColor = result * win.a * in_bounds;
            }

