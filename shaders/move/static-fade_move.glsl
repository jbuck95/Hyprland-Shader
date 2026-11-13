#version 320 es
// @settle 0.4
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

uniform float time;
uniform float seed;
uniform vec2 surface_size;
uniform vec2 resolution;
uniform vec2 velocity;
uniform vec2 peak_velocity;
uniform float is_moving;
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
    float _move_spd = length(velocity);
    float _move_peak_spd = length(peak_velocity);

    float _move_energy_val = clamp(_move_spd / 8000.0, 0.0, 1.0);
    float _move_tail_energy = clamp(_move_peak_spd / 8000.0, 0.0, 1.0) * (1.0 - settle) * (1.0 - settle);
    float _move_energy = (settle > 0.001 || is_moving < 0.5) ? _move_tail_energy : _move_energy_val;

    if (is_dragging > 0.5) {
        _move_energy = max(_move_energy, clamp(_move_spd / 1500.0, 0.08, 0.8));
    }

    if (_move_energy < 0.002) {
        fragColor = texture(tex, v_texcoord);
        return;
    }

    vec2 _move_dir = _move_spd > 1.0 ? normalize(velocity) : (_move_peak_spd > 1.0 ? normalize(peak_velocity) : vec2(0.0, -1.0));
    float _move_progress = 1.0 - _move_energy * 0.75;



                float p = _move_progress;
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
