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



            float gh(float n) {
                return fract(sin(n) * 43758.5453);
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

                float intensity = (1.0 - p) * (1.0 - p);

                float tick = floor(p * 60.0) + seed * 1000.0;
                float r1 = gh(tick * 1.13);
                float r2 = gh(tick * 2.37);
                float r3 = gh(tick * 3.71);
                float r4 = gh(tick * 4.19);
                float r5 = gh(tick * 5.53);
                float r6 = gh(tick * 6.91);

                vec2 off_r = vec2(r1 - 0.5, r2 - 0.5) * intensity * 0.12;
                vec2 off_g = vec2(r3 - 0.5, r4 - 0.5) * intensity * 0.12;
                vec2 off_b = vec2(r5 - 0.5, r6 - 0.5) * intensity * 0.12;

                float slice = floor(uv.y * 20.0);
                float slice_offset = (gh(slice + tick) - 0.5) * intensity * 0.08;

                vec2 uv_r = uv + off_r + vec2(slice_offset * 0.7, 0.0);
                vec2 uv_g = uv + off_g + vec2(slice_offset * -0.5, 0.0);
                vec2 uv_b = uv + off_b + vec2(slice_offset * 0.3, 0.0);

                vec2 tc_r = uv_r;
                vec2 tc_g = uv_g;
                vec2 tc_b = uv_b;

                vec4 color;
                color.r = texture(tex, tc_r.st).r;
                color.g = texture(tex, tc_g.st).g;
                color.b = texture(tex, tc_b.st).b;
                color.a = max(max(
                    texture(tex, tc_r.st).a,
                    texture(tex, tc_g.st).a),
                    texture(tex, tc_b.st).a);

                float big_glitch = step(0.85, gh(tick * 0.77));
                vec2 shift = vec2((gh(tick * 1.5) - 0.5) * 0.06 * big_glitch * intensity, 0.0);
                vec2 tc_shift = uv + shift;
                vec4 shifted = texture(tex, tc_shift.st);
                color = mix(color, shifted, big_glitch * intensity * 0.4);

                float scanline = 1.0 - sin(uv.y * surface_size.y * 3.14159) * 0.06 * intensity;
                color.rgb *= scanline;

                float alpha = smoothstep(0.0, 0.15, p);
                fragColor = color * alpha;
            
}
