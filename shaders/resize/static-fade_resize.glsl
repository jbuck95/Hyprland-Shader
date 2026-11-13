#version 320 es
// @settle 0.35
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

uniform float time;
uniform float seed;
uniform vec2 surface_size;
uniform vec2 resolution;
uniform vec2 size_velocity;
uniform vec2 peak_size_velocity;
uniform float is_resizing;
uniform float is_dragging;
uniform float settle;

precision highp float;




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
    float _resize_spd = length(size_velocity);
    float _resize_peak_spd = length(peak_size_velocity);

    float _resize_energy_val = clamp(_resize_spd / 1200.0, 0.0, 1.0);
    float _resize_tail_energy = clamp(_resize_peak_spd / 1200.0, 0.0, 1.0) * (1.0 - settle) * (1.0 - settle);
    float _resize_energy = (settle > 0.001 || is_resizing < 0.5) ? _resize_tail_energy : _resize_energy_val;

    if (is_dragging > 0.5) {
        _resize_energy = max(_resize_energy, clamp(_resize_spd / 400.0, 0.08, 0.8));
    }

    if (_resize_energy < 0.002) {
        fragColor = texture(tex, v_texcoord);
        return;
    }

    vec2 _resize_dir = normalize(size_velocity);
    float _resize_progress = 1.0 - _resize_energy * 0.75;



                float p = _resize_progress;
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
                fragColor = result * in_bounds;
            
}
