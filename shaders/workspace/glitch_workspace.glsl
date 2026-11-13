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
uniform vec2 velocity;
uniform vec2 peak_velocity;
uniform vec2 move_delta;
uniform float is_moving;
uniform float settle;

precision highp float;



            float gh(float n) {
                return fract(sin(n) * 43758.5453);
            }

            

void main() {
    float _ws_spd = length(velocity);
    float _ws_peak_spd = length(peak_velocity);

    float _ws_slide_energy = clamp(_ws_spd / 10000.0, 0.0, 1.0);
    float _ws_tail_energy = clamp(_ws_peak_spd / 10000.0, 0.0, 1.0) * (1.0 - settle) * (1.0 - settle);
    float _ws_energy = (settle > 0.001 || is_moving < 0.5) ? _ws_tail_energy : _ws_slide_energy;

    if (_ws_energy < 0.002) {
        fragColor = texture(tex, v_texcoord);
        return;
    }

    vec2 _ws_dir = _ws_spd > 1.0 ? normalize(velocity) : (length(move_delta) > 1.0 ? normalize(move_delta) : vec2(1.0, 0.0));
    float _ws_progress = 1.0 - _ws_energy * 0.75;



                float p = _ws_progress;
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
