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




            // Ported from skwd-wall plasma-flow transition

            float pf_hash(vec2 p) {
                return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
            }

            float pf_noise(vec2 p) {
                vec2 i = floor(p);
                vec2 f = fract(p);
                f = f * f * (3.0 - 2.0 * f);
                return mix(mix(pf_hash(i), pf_hash(i + vec2(1.0, 0.0)), f.x),
                           mix(pf_hash(i + vec2(0.0, 1.0)), pf_hash(i + vec2(1.0, 1.0)), f.x), f.y);
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

                vec2 flow = vec2(
                    pf_noise(uv * 5.0 + vec2(p * 2.0, 0.0)),
                    pf_noise(uv * 5.0 + vec2(0.0, p * 2.0))
                ) - 0.5;
                float intensity = sin(p * 3.14159) * 0.18;
                vec2 distorted = uv + flow * intensity;

                vec2 tc = distorted;
                vec4 win = texture(tex, tc.st);

                float reveal = smoothstep(0.2, 0.8, p);
                fragColor = win * reveal;
            
}
